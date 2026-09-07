;;; eyebrowse-persist-test.el --- Tests for window config persistence  -*- lexical-binding: t; -*-

;;; Commentary:

;; Tests for `eyebrowse-persist-window-configs'.  Run with:
;;
;;   emacs -Q --batch -l test/eyebrowse-persist-test.el -f ert-run-tests-batch-and-exit

;;; Code:

;; Make the package and its dash dependency loadable under -Q.
(let ((here (file-name-directory (or load-file-name buffer-file-name))))
  (add-to-list 'load-path (expand-file-name ".." here)))
(unless (require 'dash nil t)
  (let ((dash (car (last (file-expand-wildcards "~/.local/emacs/elpa/dash-*" t)))))
    (when dash (add-to-list 'load-path dash))
    (require 'dash)))

(require 'ert)
(require 'eyebrowse)

(defmacro eyebrowse-persist-test--with-mode (&rest body)
  "Run BODY with the mode on and persistence saving to a fresh temp file."
  `(let ((eyebrowse-persist-window-configs t)
         (eyebrowse-save-file
          (expand-file-name (make-temp-name "eyebrowse-persist-test-")
                            temporary-file-directory)))
     (unwind-protect
         (progn
           (eyebrowse-mode 1)
           ,@body)
       (eyebrowse-mode -1)
       (when (file-exists-p eyebrowse-save-file)
         (delete-file eyebrowse-save-file)))))

(defun eyebrowse-persist-test--hooked-p (hook)
  "Non-nil if the save function is on HOOK."
  (and (boundp hook)
       (memq 'eyebrowse--save-window-configs (symbol-value hook))))

(ert-deftest eyebrowse-persist-hooks-follow-the-mode ()
  "Enabling the mode wires the save hooks; disabling removes them."
  (eyebrowse-persist-test--with-mode
   (should (eyebrowse-persist-test--hooked-p 'kill-emacs-hook))
   (should (eyebrowse-persist-test--hooked-p 'desktop-save-hook)))
  (should-not (eyebrowse-persist-test--hooked-p 'kill-emacs-hook))
  (should-not (eyebrowse-persist-test--hooked-p 'desktop-save-hook)))

(ert-deftest eyebrowse-persist-saves-when-desktop-saves ()
  "A desktop save writes the window configs to `eyebrowse-save-file'."
  (eyebrowse-persist-test--with-mode
   (should-not (file-exists-p eyebrowse-save-file))
   (run-hooks 'desktop-save-hook)
   (should (file-exists-p eyebrowse-save-file))))

(ert-deftest eyebrowse-persist-hooks-not-wired-when-off ()
  "With persistence off, the mode leaves the save hooks alone."
  (let ((eyebrowse-persist-window-configs nil))
    (eyebrowse-mode 1)
    (unwind-protect
        (progn
          (should-not (eyebrowse-persist-test--hooked-p 'kill-emacs-hook))
          (should-not (eyebrowse-persist-test--hooked-p 'desktop-save-hook)))
      (eyebrowse-mode -1))))

(provide 'eyebrowse-persist-test)
;;; eyebrowse-persist-test.el ends here
