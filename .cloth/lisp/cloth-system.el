(defun cloth/open-current-directory-in-explorer ()
  (interactive)
  (w32-shell-execute "open" default-directory))

(defun cloth/open-current-directory-in-powershell ()
  (interactive)
  (w32-shell-execute "open" "powershell.exe" nil 1))

;;; keybind
(global-set-key (kbd "C-c e") #'cloth/open-current-directory-in-explorer)
(global-set-key (kbd "C-c s") #'cloth/open-current-directory-in-powershell)

(provide 'cloth-system)
