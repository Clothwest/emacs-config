(require 'project)
(require 'cl-generic)
(require 'seq)

;;; find-program
(setq find-program
      "d:/.devEnv_me/Git/Git/usr/bin/find.exe")

;; required-paths -> glob but from root e.g. "build/" -> "./build/"
;; ignored-paths  -> glob               e.g. "build/" -> "build/"
(defun cloth/project/make-config (&optional type required-paths ignored-paths)
  (list :type type
        :required-paths required-paths
        :ignored-paths ignored-paths))

;;; metadata-files
(defconst cloth/project/metadata-files
  (list "./.project*.eld"
        "./.cloth/.project*.eld"))

;;; not-project-file
(defconst cloth/project/not-project-files
  (list "./.not-project*.eld"))

(defun cloth/project/make-metadata-configs ()
  (mapcar
   (lambda (metadata-file)
     (cloth/project/make-config
      'other
      (list metadata-file)))
   cloth/project/metadata-files))

;;; configs
(defconst cloth/project/configs
  (append

   (list
    (cloth/project/make-config
     'meson
     '("./meson.build" "./build/")
     '("./build/")))

   (cloth/project/make-metadata-configs)))

(defun cloth/project/path-exists (rel-path base-dir)
   (not (null
         (file-expand-wildcards
          (expand-file-name rel-path base-dir)
          t))))

(defun cloth/project/paths-exists (rel-paths base-dir)
  (and rel-paths
       (seq-every-p
        (lambda (path)
          (cloth/project/path-exists path base-dir))
        rel-paths)))

(defun cloth/project/root-disabled (dir)
  (and cloth/project/not-project-files
       (seq-some
        (lambda (file)
          (cloth/project/path-exists file dir))
        cloth/project/not-project-files)))

(defun cloth/project/make-project (root config)
  (list 'cloth-project
        :root root
        :config config))

(defun cloth/project/matching-config (dir)
  (unless (cloth/project/root-disabled dir)
    (seq-find
     (lambda (config)
       (cloth/project/paths-exists
        (plist-get config :required-paths)
        dir))
     cloth/project/configs)))

(defun cloth/project/find (start-dir)
  (let ((root
         (locate-dominating-file
          start-dir
          #'cloth/project/matching-config)))
    (when root
      (cloth/project/make-project
       root
       (cloth/project/matching-config root)))))

(defun cloth/project/get-root (project)
  (plist-get (cdr project) :root))

(defun cloth/project/get-config (project)
  (plist-get (cdr project) :config))

(defun cloth/project/config-ignored-paths (config)
  (plist-get config :ignored-paths))

(defun cloth/project/get-metadata-file (root)
  (seq-some
   (lambda (pattern)
     (seq-find
      #'file-regular-p
      (file-expand-wildcards
       (expand-file-name pattern root)
       t)))
   cloth/project/metadata-files))

(defun cloth/project/read-metadata (file)
  (when (and file (file-regular-p file))
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (skip-chars-forward " \t\r\n")
      (unless (eobp)
        (read (current-buffer))))))

(defun cloth/project/metadata-ignored-paths (root)
  (plist-get
   (cloth/project/read-metadata
    (cloth/project/get-metadata-file root))
   :ignored-paths))

;;; root
(cl-defmethod project-root ((project (head cloth-project)))
  (cloth/project/get-root project))

;;; ignores

(cl-defmethod project-ignores :around (project _dir)
  (append (cloth/project/metadata-ignored-paths (project-root project))
          (cl-call-next-method)))

(cl-defmethod project-ignores ((project (head cloth-project)) _dir)
  (append (cloth/project/config-ignored-paths (cloth/project/get-config project))
          (cl-call-next-method)))

;;; hook
(add-hook 'project-find-functions
          #'cloth/project/find
          t)

(provide 'cloth-project)
