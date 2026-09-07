![][image]

## About

Manage your window configurations in a simple manner using workspaces!
Eyebrowse displays the current state of your workspaces in the modeline by
default.

## This fork

This fork continues development past the last [upstream] release
(0.7.8).  The significant additions:

- **Support for naming (tagging) workspaces**
- **Per-workspace winner histories**
- **Persistence across restarts**
- **Cloning, dragging and swapping**
- ... and more!

See [CHANGELOG.md](CHANGELOG.md) for the full list.  The fork
requires Emacs 27.1 or later.

## Screenshot

![][screenshot]

See the lighter and the modeline indicator at the right side of the
bottom modeline?  That's what you get to see after enabling eyebrowse.

## Installation

This fork is not on MELPA.  Clone the repository and load it from
your init file:

    (use-package eyebrowse
      :load-path "path/to/eyebrowse"
      :config (eyebrowse-mode t))

(Upstream eyebrowse is still available from [MELPA (stable)].)

## Quick Tutorial

Use `M-x eyebrowse-mode` to enable `eyebrowse` interactively.  If you
want to enable it automatically on startup, add `(eyebrowse-mode t)`
to your init file (either `~/.emacs` or `~/.emacs.d/init.el`).

You start with your current window config on slot 1.  Once you hit
`C-c C-w 2`, you will see the modeline indicator appearing and showing
slot 1 and 2 with slot 2 slightly emphasized.  Slot 1 has been saved
automatically for you and contains your last window config.  Do
something meaningful like a window split, then hit `C-c C-w 1`.  The
window config on slot 2 is saved and the window config from slot 1 is
loaded.  Try switching back and forth between them with `C-c C-w '` to
get a feeling for how subsequent window manipulations are handled.

To make keeping track of workspaces easier, a tagging feature was
added.  Use `C-c C-w ,` to set a tag for the current window config, it
will both appear in the modeline indicator and when using `M-x
eyebrowse-switch-to-window-config`.  Setting the tag to an empty value
will undo this change.

## Key bindings

The default keymap prefix is `C-c C-w`, but I (the fork author) strongly
recommend setting more ergonomic bindings (e.g. `s-1`, `s-2`, ... to switch
workspaces):

```elisp
(use-package eyebrowse
  :load-path "~/.emacs.d/packages/eyebrowse"
  :bind (
         ("s-," . eyebrowse-prev-window-config)
         ("s-." . eyebrowse-next-window-config)
         ("s-<" . eyebrowse-drag-window-config-left)
         ("s->" . eyebrowse-drag-window-config-right)
         ("s-0" . eyebrowse-switch-to-window-config-0)
         ("s-1" . eyebrowse-switch-to-window-config-1)
         ("s-2" . eyebrowse-switch-to-window-config-2)
         ("s-3" . eyebrowse-switch-to-window-config-3)
         ("s-4" . eyebrowse-switch-to-window-config-4)
         ("s-5" . eyebrowse-switch-to-window-config-5)
         ("s-6" . eyebrowse-switch-to-window-config-6)
         ("s-7" . eyebrowse-switch-to-window-config-7)
         ("s-8" . eyebrowse-switch-to-window-config-8)
         ("s-9" . eyebrowse-switch-to-window-config-9)
         ("s-C-0" . eyebrowse-switch-to-window-config-10)
         ("s-C-1" . eyebrowse-switch-to-window-config-11)
         ("s-C-2" . eyebrowse-switch-to-window-config-12)
         ("s-C-3" . eyebrowse-switch-to-window-config-13)
         ("s-C-4" . eyebrowse-switch-to-window-config-14)
         ("s-C-5" . eyebrowse-switch-to-window-config-15)
         ("s-C-6" . eyebrowse-switch-to-window-config-16)
         ("s-C-7" . eyebrowse-switch-to-window-config-17)
         ("s-C-8" . eyebrowse-switch-to-window-config-18)
         ("s-C-9" . eyebrowse-switch-to-window-config-19)
         ("s-=" . eyebrowse-close-window-config)
         ("s--" . eyebrowse-rename-window-config)
         ("s-+" . eyebrowse-clone-window-config)
         )

  :init

  ;; Free up keybindings unnecessarily stolen by eyebrowse.
  (setq eyebrowse-keymap-prefix (kbd ""))

  ;; ...
```

## Internals

This mode basically wraps what `C-x r w` and `C-x r j` would do, but
takes care of automatically saving and loading to a separate data
structure for you and does it in a slightly different manner (see
`window-state-put` and `window-state-get` for more details) to allow for
features like persistency in combination with [desktop.el].

## Notes

The `window-state-put` and `window-state-get` functions do not save
all window parameters.  If you use features like side windows that
store the window parameters `window-side` and `window-slot`, you will
need to customize `window-persistent-parameters` for them to be saved
as well:

    (add-to-list 'window-persistent-parameters '(window-side . writable))
    (add-to-list 'window-persistent-parameters '(window-slot . writable))

## Persistence

This fork can persist window configs across restarts on its own: set
`eyebrowse-persist-window-configs` to a non-nil value.  Pair it with
[desktop.el], which brings back the buffers the configs refer to.

## Alternatives

**Note:** outdated!

The two most popular window configuration packages are [elscreen] and
[escreen].  Both are fairly old and have their share of bugs.  The
closest package I've found so far to eyebrowse with workspace-specific
buffers would be [perspective].  [wconf] is a minimal alternative with
half the lines of code (and features).  To have fancy features such as
morphing, try [workgroups] or [workgroups2].

## Name

Actually, I wanted to name this mode "eyebrows" for no real reason,
but then a silly typo happened.  The typo stuck.  So did the new name.

[image]: img/eyebrows.gif
[upstream]: https://depp.brause.cc/eyebrowse
[ranger]: https://ranger.github.io/
[screenshot]: img/scrot.png
[MELPA (stable)]: http://melpa.org/
[evil]: https://bitbucket.org/lyro/evil/wiki/Home
[desktop.el]: https://www.gnu.org/software/emacs/manual/html_node/emacs/Saving-Emacs-Sessions.html#Saving-Emacs-Sessions
[\#52]: https://github.com/wasamasa/eyebrowse/issues/52
[elscreen]: https://github.com/shosti/elscreen
[escreen]: https://github.com/emacsattic/escreen
[perspective]: https://github.com/nex3/perspective-el
[wconf]: https://github.com/ilohmar/wconf
[workgroups]: https://github.com/tlh/workgroups.el
[workgroups2]: https://github.com/pashinin/workgroups2
