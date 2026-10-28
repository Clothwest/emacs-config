(require 'project)
(require 'cl-generic)
(require 'seq)

;;; .project.eld
;; :ignroed -> glob
;; :included
;; :commands [TODO]

;;; project patterns
(defconst cloth/project/metadata-file-patterns
  (list "./.project.eld"
        "./.cloth/.project.eld"))

;;; project disabled patterns
(defconst cloth/project/not-project-file-patterns
  (list "./.not-project.eld"))

;;; helper functions

(defun cloth/project/find-file (patterns dir)
  (seq-some
   (lambda (pattern)
     (seq-find #'file-regular-p
               (file-expand-wildcards
                (expand-file-name pattern dir))))
   patterns))

(defun cloth/project/is-root (dir)
  (and
   (cloth/project/find-file
    cloth/project/metadata-file-patterns
    dir)
   ;; root disabled
   (not (cloth/project/find-file
         cloth/project/not-project-file-patterns
         dir))))

(defun cloth/project/read-metadata (file)
  (when (and file (file-regular-p file))
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (skip-chars-forward " \t\r\n")
      (unless (eobp)
        (read (current-buffer))))))

;;; project functions

(defun cloth/project/find-project (start-dir)
  (let ((root
         (locate-dominating-file
          start-dir
          (lambda (dir)
            (or (cloth/project/is-root dir)
                (file-directory-p
                 (expand-file-name ".git" dir)))))))
    (when (and root (cloth/project/is-root root))
      (list 'cloth-project
            :root
            (expand-file-name root)
            :metadata
            (cloth/project/read-metadata
             (cloth/project/find-file
              cloth/project/metadata-file-patterns
              (expand-file-name root)))))))

(cl-defmethod project-root ((project (head cloth-project)))
  (plist-get (cdr project) :root))

(cl-defmethod project-ignores ((project (head cloth-project)) _dir)
  (append
   (plist-get (plist-get (cdr project) :metadata) :ignored)
   (cl-call-next-method)))

(cl-defmethod project-files ((project (head cloth-project)) &optional dirs)
  (let* ((project-files-relative-names nil)
         (files (cl-call-next-method))
         (root (project-root project))
         (included (plist-get (plist-get (cdr project) :metadata) :included)))
    (dolist (included-path included)
      (let* ((path (expand-file-name included-path root))
             (included-files (cond ((file-regular-p path) (list path))
                                   ((file-directory-p path) (directory-files-recursively path "")))))
        (dolist (included-file included-files)
          (when (and (file-regular-p included-file)
                     (seq-some
                      (lambda (dir)
                        (file-in-directory-p included-file dir))
                      (or dirs (list root))))
            (push included-file files)))))
    (delete-dups files)))

(add-hook 'project-find-functions #'cloth/project/find-project)

(provide 'cloth-project)
