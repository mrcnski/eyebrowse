;;; eyebrowse-winner-test.el --- Tests for the winner integration  -*- lexical-binding: t; -*-

;;; Commentary:

;; Tests for the per-window-config winner histories (see the "Winner
;; integration" section of eyebrowse.el).  Run with:
;;
;;   emacs -Q --batch -l test/eyebrowse-winner-test.el -f ert-run-tests-batch-and-exit
;;
;; Batch Emacs runs no command loop, so the hooks winner records through
;; (`window-configuration-change-hook', `post-command-hook') never fire on
;; their own.  `eyebrowse-winner-test--record' drives them by hand,
;; mimicking one interactive command that changed the window layout.

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
(require 'winner)

(defmacro eyebrowse-winner-test--fixture (&rest body)
  "Run BODY with a single window and fresh eyebrowse and winner state."
  `(progn
     (winner-mode 1)
     (delete-other-windows)
     (setq winner-ring-alist nil
           winner-currents nil
           winner-modified-list nil
           eyebrowse--winner-rings nil)
     ;; Re-seed winner's "current layout" snapshot, as in a session where
     ;; winner-mode was already on before any window changes.
     (winner-remember)
     (eyebrowse--set 'window-configs nil)
     (eyebrowse-init)
     (let ((eyebrowse-winner-integration t)
           (eyebrowse-new-workspace t))
       ,@body)))

(defun eyebrowse-winner-test--record ()
  "Make winner record a layout change, as after an interactive command."
  (setq this-command (gensym))
  (winner-change-fun)
  (winner-save-old-configurations))

(defun eyebrowse-winner-test--stash (slot)
  "Return the ring stashed for SLOT on the selected frame, if any."
  (alist-get slot (alist-get (selected-frame) eyebrowse--winner-rings)))

(defun eyebrowse-winner-test--live-ring ()
  "Return the frame's live winner ring, if any."
  (cdr (assq (selected-frame) winner-ring-alist)))

(defun eyebrowse-winner-test--undo ()
  "Invoke `winner-undo' the way a keypress would."
  (setq this-command 'winner-undo
        last-command (gensym))
  (winner-undo))

(ert-deftest eyebrowse-winner-stash-and-restore ()
  "Each workspace keeps its own ring across switches."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (delete-other-windows) (eyebrowse-winner-test--record)
   (let ((ring1 (eyebrowse-winner-test--live-ring)))
     (should (ring-p ring1))
     (should (> (ring-length ring1) 1))
     (eyebrowse-switch-to-window-config 2)
     ;; Slot 1's history is stashed; the fresh slot starts with none.
     (should (eq (eyebrowse-winner-test--stash 1) ring1))
     (should-not (eyebrowse-winner-test--live-ring))
     ;; History made in slot 2 lands in a new, distinct ring.
     (split-window) (eyebrowse-winner-test--record)
     (let ((ring2 (eyebrowse-winner-test--live-ring)))
       (should (ring-p ring2))
       (should-not (eq ring1 ring2))
       ;; Switching back reinstalls slot 1's ring and stashes slot 2's.
       (eyebrowse-switch-to-window-config 1)
       (should (eq (eyebrowse-winner-test--live-ring) ring1))
       (should (eq (eyebrowse-winner-test--stash 2) ring2))))))

(ert-deftest eyebrowse-winner-switch-is-not-undoable ()
  "The switch itself is erased from winner's records."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (eyebrowse-switch-to-window-config 2)
   ;; The frame is not queued for a history save...
   (should-not (memq (selected-frame) winner-modified-list))
   ;; ...and winner's "current layout" snapshot is the new workspace's, so
   ;; the next save cannot push the old workspace's layout.
   (should (winner-equal (winner-conf) (winner-configuration)))))

(ert-deftest eyebrowse-winner-undo-works-after-switch-back ()
  "Undo in a workspace restores that workspace's own earlier layout."
  (eyebrowse-winner-test--fixture
   ;; Two windows, then one, in slot 1.
   (split-window) (eyebrowse-winner-test--record)
   (delete-other-windows) (eyebrowse-winner-test--record)
   (should (= (length (window-list)) 1))
   ;; Detour through another workspace and back.
   (eyebrowse-switch-to-window-config 2)
   (eyebrowse-switch-to-window-config 1)
   ;; Undo restores slot 1's own two-window layout.
   (eyebrowse-winner-test--undo)
   (should (= (length (window-list)) 2))))

(ert-deftest eyebrowse-winner-same-command-change-is-not-lost ()
  "A layout change made by the very command that switches is recorded."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (should (= (length (window-list)) 2))
   ;; One command deletes a window AND switches workspace: the change is
   ;; still pending (no post-command save has run) when the switch happens.
   (setq this-command (gensym))
   (delete-other-windows)
   (winner-change-fun)
   (eyebrowse-switch-to-window-config 2)
   (eyebrowse-switch-to-window-config 1)
   ;; Undo restores the two-window layout from before the delete.
   (eyebrowse-winner-test--undo)
   (should (= (length (window-list)) 2))))

(ert-deftest eyebrowse-winner-fresh-workspace-has-no-history ()
  "Undo in a brand-new workspace finds nothing to undo."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (eyebrowse-switch-to-window-config 2)
   (should (= (length (window-list)) 1))
   (eyebrowse-winner-test--undo)
   ;; Slot 1's two-window layout must not leak in here.
   (should (= (length (window-list)) 1))))

(ert-deftest eyebrowse-winner-move-remaps-ring ()
  "Moving a workspace to another slot takes its ring along."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (eyebrowse-switch-to-window-config 2)
   (let ((ring1 (eyebrowse-winner-test--stash 1)))
     (should ring1)
     (eyebrowse-move-window-config 1 7)
     (should (eq (eyebrowse-winner-test--stash 7) ring1))
     (should-not (eyebrowse-winner-test--stash 1)))))

(ert-deftest eyebrowse-winner-swap-remaps-rings ()
  "Swapping slots swaps their rings, including the current slot's."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (eyebrowse-switch-to-window-config 2)
   (split-window) (eyebrowse-winner-test--record)
   (eyebrowse-switch-to-window-config 1)
   ;; Now in slot 1: its ring is live (and aliased in the stash), slot 2's
   ;; ring is stashed.
   (let ((ring1 (eyebrowse-winner-test--live-ring))
         (ring2 (eyebrowse-winner-test--stash 2)))
     (eyebrowse-swap-window-configs 1 2)
     ;; The workspace follows its config: we are now slot 2, still with
     ;; ring1 live; the stashed entries traded places.
     (should (= (eyebrowse--get 'current-slot) 2))
     (should (eq (eyebrowse-winner-test--live-ring) ring1))
     (should (eq (eyebrowse-winner-test--stash 2) ring1))
     (should (eq (eyebrowse-winner-test--stash 1) ring2)))))

(ert-deftest eyebrowse-winner-delete-drops-ring ()
  "Deleting a workspace discards its stashed ring."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (eyebrowse-switch-to-window-config 2)
   (should (eyebrowse-winner-test--stash 1))
   (eyebrowse--delete-window-config 1)
   (should-not (eyebrowse-winner-test--stash 1))))

(ert-deftest eyebrowse-winner-clone-copies-history ()
  "A clone gets the history; the original keeps an independent copy."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (let ((ring1 (eyebrowse-winner-test--live-ring)))
     (eyebrowse-clone-window-config)
     (should (= (eyebrowse--get 'current-slot) 2))
     ;; The live ring travels with the clone; the original's stash entry is
     ;; a copy, so the histories diverge from here on.
     (should (eq (eyebrowse-winner-test--live-ring) ring1))
     (let ((copy (eyebrowse-winner-test--stash 1)))
       (should (ring-p copy))
       (should-not (eq copy ring1))
       (should (= (ring-length copy) (ring-length ring1)))))))

(ert-deftest eyebrowse-winner-clone-in-place-copies-history ()
  "Cloning without switching gives the clone the copy instead."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (let ((ring1 (eyebrowse-winner-test--live-ring)))
     (eyebrowse-clone-window-config t)
     (should (= (eyebrowse--get 'current-slot) 1))
     (should (eq (eyebrowse-winner-test--live-ring) ring1))
     (let ((copy (eyebrowse-winner-test--stash 2)))
       (should (ring-p copy))
       (should-not (eq copy ring1))))))

(ert-deftest eyebrowse-winner-forget-frame ()
  "Deleting a frame drops all of its stashed rings."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (eyebrowse-switch-to-window-config 2)
   (should (alist-get (selected-frame) eyebrowse--winner-rings))
   (eyebrowse--winner-forget-frame (selected-frame))
   (should-not (alist-get (selected-frame) eyebrowse--winner-rings))))

(ert-deftest eyebrowse-winner-integration-can-be-disabled ()
  "With the integration off, switches leave winner's state alone."
  (eyebrowse-winner-test--fixture
   (split-window) (eyebrowse-winner-test--record)
   (let ((ring1 (eyebrowse-winner-test--live-ring))
         (eyebrowse-winner-integration nil))
     (eyebrowse-switch-to-window-config 2)
     (should-not (eyebrowse-winner-test--stash 1))
     (should (eq (eyebrowse-winner-test--live-ring) ring1)))))

(provide 'eyebrowse-winner-test)
;;; eyebrowse-winner-test.el ends here
