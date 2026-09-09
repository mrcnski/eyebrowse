;;; eyebrowse-indicator-test.el --- Indicator tests -*- lexical-binding: t; -*-

;; Run with emacs -Q --batch -l test/eyebrowse-indicator-test.el
;; -f ert-run-tests-batch-and-exit from the package directory.
(let ((here (file-name-directory (or load-file-name buffer-file-name))))
  (add-to-list 'load-path (expand-file-name ".." here)))
(unless (require 'dash nil t)
  (let ((dash (car (last (file-expand-wildcards "~/.local/emacs/elpa/dash-*" t)))))
    (when dash (add-to-list 'load-path dash))
    (require 'dash)))

(require 'ert)
(require 'eyebrowse)

(ert-deftest eyebrowse-indicator-target-lifecycle ()
  "Move between all targets, preserve existing content, and undo installation."
  (let ((eyebrowse-persist-window-configs nil)
        (eyebrowse-indicator-target 'mode-line)
        (mode-line-misc-info '("" display-time-string))
        (header-line-format nil)
        (frame-title-format "Emacs"))
    (unwind-protect
        (progn
          (eyebrowse-mode 1)
          (eyebrowse-mode 1)
          (should (= (length mode-line-misc-info) 3))
          (should (assoc 'eyebrowse-mode mode-line-misc-info))
          (customize-set-variable 'eyebrowse-indicator-target 'header-line)
          (should (equal mode-line-misc-info '("" display-time-string)))
          (should (equal (car header-line-format) ""))
          (should (eq (car (cadr header-line-format)) 'eyebrowse-mode))
          (customize-set-variable 'eyebrowse-indicator-target 'frame-title)
          (should-not header-line-format)
          (should (equal frame-title-format '("Emacs" eyebrowse-indicator-string)))
          (eyebrowse-mode 1)
          (should (equal frame-title-format '("Emacs" eyebrowse-indicator-string)))
          (customize-set-variable 'eyebrowse-indicator-target nil)
          (should (equal frame-title-format "Emacs"))
          (should (equal mode-line-misc-info '("" display-time-string)))
          (should-not header-line-format)
          (customize-set-variable 'eyebrowse-indicator-target 'frame-title))
      (eyebrowse-mode -1))
    (should (equal frame-title-format "Emacs"))
    (should (equal mode-line-misc-info '("" display-time-string)))))

(ert-deftest eyebrowse-indicator-preserves-later-format-changes ()
  "Disabling must preserve changes another package or the user made."
  (let ((eyebrowse-persist-window-configs nil)
        (eyebrowse-indicator-target 'mode-line)
        (mode-line-misc-info nil)
        (frame-title-format "Emacs")
        (header-line-format "Header"))
    (unwind-protect
        (progn
          (eyebrowse-mode 1)
          (setq mode-line-misc-info (append mode-line-misc-info '(other-indicator)))
          (customize-set-variable 'eyebrowse-indicator-target 'header-line)
          (should (equal mode-line-misc-info '(other-indicator)))
          (setq header-line-format "New header")
          (customize-set-variable 'eyebrowse-indicator-target 'frame-title)
          (should (equal header-line-format "New header"))
          (setq frame-title-format "New title"))
      (eyebrowse-mode -1))
    (should (equal frame-title-format "New title"))
    (should (equal header-line-format "New header"))))

(ert-deftest eyebrowse-indicator-lifecycle ()
  "Refresh before consumers, follow workspace changes, and clear on disable."
  (let ((eyebrowse-persist-window-configs nil)
        (eyebrowse-mode-line-style 'always)
        (eyebrowse-indicator-format " -- %s")
        (eyebrowse-indicator-change-hook
         (copy-sequence eyebrowse-indicator-change-hook))
        observed)
    (add-hook 'eyebrowse-indicator-change-hook
              (lambda () (setq observed eyebrowse-indicator-string)))
    (unwind-protect
        (progn
          (eyebrowse-mode 1)
          (should (equal observed
                         (concat " -- " (substring-no-properties
                                         (eyebrowse-mode-line-indicator)))))
          (should-not (text-properties-at 0 observed))
          (eyebrowse-rename-window-config (eyebrowse--get 'current-slot) "example")
          (should (string-match-p "example" observed))
          (let ((eyebrowse-mode-line-style 'hide))
            (run-hooks 'eyebrowse-indicator-change-hook)
            (should (equal observed ""))))
      (eyebrowse-mode -1))
    (should (equal observed ""))
    (run-hooks 'eyebrowse-indicator-change-hook)
    (should (equal observed ""))))

;;; eyebrowse-indicator-test.el ends here
