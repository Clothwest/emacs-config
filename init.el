;;; package management

(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

(require 'use-package)

(setq custom-file (locate-user-emacs-file ".cloth/custom-file.el"))
(load custom-file 'noerror 'nomessage)

(add-to-list 'load-path (locate-user-emacs-file ".cloth/lisp/"))
(require 'cloth-system)
(require 'cloth-project)

;;; package security
(setq package-check-signature nil)

;;; local config
(dolist (file (file-expand-wildcards
               (expand-file-name ".cloth/lisp/.local/*.el" user-emacs-directory)))
  (load file 'noerror 'nomessage))

;;; coding system
(prefer-coding-system 'utf-8)

;;; interface and feedback
(setq inhibit-startup-message t)
(setq ring-bell-function #'ignore)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;;; editing behavior
(repeat-mode 1)
(delete-selection-mode 1)

;;; position indicators
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(global-hl-line-mode 1)

;;; parentheses
(electric-pair-mode 1)
(show-paren-mode 1)

;;; file handling

(setq create-lockfiles nil)
(setq make-backup-files nil)
(setq delete-by-moving-to-trash t)

(setq auto-save-default t)
(let ((auto-save-dir (locate-user-emacs-file ".cloth/var/autosaves/")))
  (make-directory auto-save-dir t)
  (setq auto-save-list-file-prefix (expand-file-name ".saves-" auto-save-dir)
        auto-save-file-name-transforms `((".*" ,auto-save-dir sha256))))

;;; custom keybind
(global-set-key (kbd "C-/") #'undo-only)
(global-set-key (kbd "C-?") #'undo-redo)
(global-set-key (kbd "C-c m") #'set-mark-command)
(global-set-key (kbd "C-c i") #'overwrite-mode)
(global-set-key (kbd "C-c x") #'make-directory)
(global-set-key (kbd "C-x C-'") #'uncomment-region)
(global-set-key (kbd "C-c c") #'compile)
(global-set-key (kbd "C-c g") #'recompile)
(global-set-key (kbd "M-o") #'other-window)

;;; indentation
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;;; whitespace
(use-package whitespace
  :hook
  (find-file . whitespace-mode)
  :custom
  (whitespace-style '(face trailing tabs tab-mark spaces space-mark)))

(dolist (mode-hook '(c-mode-hook
                     c++-mode-hook
                     emacs-lisp-mode-hook
                     meson-mode-hook))
  (add-hook mode-hook
            (lambda ()
              (add-hook 'before-save-hook
                        #'delete-trailing-whitespace
                        nil
                        t))))

;;; window split

(defun cloth/split-window (window)
  "Split WINDOW right when its frame has only one ordinary window."
  (let ((ordinary-window-count 0))
    (dolist (candidate
             (window-list (window-frame window) 'nomini))
      (unless (window-parameter candidate 'window-side)
        (setq ordinary-window-count (1+ ordinary-window-count))))

    (when (= ordinary-window-count 1)
      (let ((split-width-threshold 160))
        (if (window-splittable-p window t)
            (progn
              (with-selected-window window
                (split-window-right)))
          (let ((split-height-threshold 60))
            (when (window-splittable-p window)
              (with-selected-window window
                (split-window-below)))))))))

(setq split-window-preferred-function #'cloth/split-window)

;;; dired

(use-package dired
  :custom
  (dired-dwim-target t)
  (dired-listing-switches "-alh"))

;;; minibuffer completion

(use-package savehist
  :init
  (savehist-mode 1))

(use-package vertico
  :ensure t
  :init
  (vertico-mode 1))

(use-package consult
  :ensure t
  :bind
  (("C-x b" . consult-buffer)
   ("M-s l" . consult-line)
   ("M-s r" . consult-ripgrep)))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

;;; in-buffer completion

(use-package corfu
  :ensure t
  :init
  (global-corfu-mode 1)
  :custom
  (corfu-cycle t))

(use-package cape
  :ensure t
  :hook
  (completion-at-point-functions . cape-dabbrev)
  (completion-at-point-functions . cape-file))

;;; editing

(use-package move-text
  :ensure t
  :bind
  (("M-p" . move-text-up)
   ("M-n" . move-text-down)))

(use-package multiple-cursors
  :ensure t
  :bind
  (("C->" . mc/mark-next-like-this)
   ("C-<" . mc/mark-previous-like-this)
   ("C-c C-/" . mc/mark-all-like-this)
   ("C-}" . mc/skip-to-next-like-this)
   ("C-{" . mc/skip-to-previous-like-this)
   ("C-c <" . mc/unmark-next-like-this)
   ("C-c >" . mc/unmark-previous-like-this)))

(use-package misc
  :custom
  (duplicate-line-final-position 1)
  :bind
  (("C-c d" . duplicate-dwim)))

;;; selection highlighting
(use-package region-occurrences-highlighter
  :ensure t
  :custom-face
  (region-occurrences-highlighter-face ((t (:inherit highlight))))
  :config
  (global-region-occurrences-highlighter-mode 1))

;;; compilation

(use-package compile
  :custom
  (compilation-scroll-output t))

(use-package ansi-color
  :hook
  (compilation-filter . ansi-color-compilation-filter))

;;; version control
(use-package magit
  :ensure t
  :bind
  (("C-x g" . magit-status)))

;;; eglot
(setq eglot-stay-out-of '(flymake))
(use-package eglot
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-edits '((eglot-rename . summary)
                                (eglot-code-actions . summary)
                                (t . maybe-summary)))
  (eglot-ignored-server-capabilities '(:inlayHintProvider
                                       :documentOnTypeFormattingProvider))
  :hook
  (c-mode . eglot-ensure))

;;; clock
(use-package time
  :custom
  (display-time-format "Clothwest %H:%M")
  (display-time-default-load-average nil)
  :config
  (display-time-mode 1))

;;; font
(setq cloth/font-family "Cascadia Mono"
      cloth/font-height 100
      cloth/font-weight 'normal)

;;; theme
(use-package gruber-darker-theme
  :ensure t
  :no-require t
  :config
  (load-theme 'gruber-darker t)
  (set-face-attribute 'default nil
                      :family cloth/font-family
                      :height cloth/font-height
                      :weight cloth/font-weight))

;;; help
(use-package which-key
  :init
  (which-key-mode 1))

;;; cc mode

(setq-default c-basic-offset 4)
(setq c-default-style
      '((java-mode . "java")
        (awk-mode . "awk")
        (other ."bsd")))

(add-hook 'c-mode-hook
          (lambda ()
            (c-toggle-comment-style -1)))

;;; meson
(use-package meson-mode
  :ensure t
  :mode (("meson\\.build\\'" . meson-mode)
         ("meson\\.options\\'" . meson-mode)
         ("meson_options\\.txt\\'" . meson-mode)))

;;; rainbow mode
(use-package rainbow-mode
  :ensure t)

;;; git modes
(use-package git-modes
  :ensure t)
