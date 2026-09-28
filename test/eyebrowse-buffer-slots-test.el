;;; eyebrowse-buffer-slots-test.el --- Tests for eyebrowse-buffer-slots  -*- lexical-binding: t; -*-

;;; Commentary:

;; Tests for `eyebrowse-buffer-slots'.  Run with:
;;
;;   emacs -Q --batch -l test/eyebrowse-buffer-slots-test.el -f ert-run-tests-batch-and-exit

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

(ert-deftest eyebrowse-buffer-slots-finds-saved-and-live-slots ()
  "Saved slots come from their configs; the current slot from live windows."
  (let ((eyebrowse-persist-window-configs nil)
        (a (get-buffer-create "eyebrowse-test-a"))
        (b (get-buffer-create "eyebrowse-test-b")))
    (unwind-protect
        (progn
          (eyebrowse-mode 1)
          (delete-other-windows)
          (switch-to-buffer a)
          (eyebrowse-switch-to-window-config 2)
          (switch-to-buffer b)
          (eyebrowse-switch-to-window-config 3)
          (switch-to-buffer a)
          (should (equal (eyebrowse-buffer-slots a) '(1 3)))
          (should (equal (eyebrowse-buffer-slots "eyebrowse-test-b") '(2)))
          ;; Slot 3's saved config is stale once its window changes.
          (switch-to-buffer b)
          (should (equal (eyebrowse-buffer-slots a) '(1)))
          (should (equal (eyebrowse-buffer-slots b) '(2 3)))
          (should-not (eyebrowse-buffer-slots "eyebrowse-test-missing")))
      (eyebrowse-mode -1)
      (set-frame-parameter nil 'eyebrowse-window-configs nil)
      (kill-buffer a)
      (kill-buffer b))))

(provide 'eyebrowse-buffer-slots-test)

;;; eyebrowse-buffer-slots-test.el ends here
