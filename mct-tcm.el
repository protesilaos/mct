;;; mct-tcm.el --- MCT which Treats the Completions as the Minibuffer -*- lexical-binding: t -*-

;; Copyright (C) 2022  Free Software Foundation, Inc.

;; Author: Protesilaos Stavrou <info@protesilaos.com>
;; URL: https://gitlab.com/protesilaos/mct
;; Version: 0.5.0
;; Package-Requires: ((emacs "27.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; MCT extension which Treats the Completions as the Minibuffer.  It
;; intercepts any single character input (without Control or Alt
;; modifiers) in the Completions' buffer and passes it to the minibuffer
;; as input.  This practically means that the user can (i) narrow the
;; list of candidates from the minibuffer, (ii) switch to the
;; Completions in anticipation of selecting a candidate, (iii) change
;; their mind and opt to narrow further, (iv) type something to bring
;; focus back to the minibuffer while narrowing to the given input.
;;
;; When the `mct-tcm-mode' is enabled and the above sequence of events
;; takes place, the current session is treated as if it belongs to the
;; `mct-completion-passlist' (read its doc string).

;;; Code:

;;;; General utilities

(require 'mct)

;; FIXME 2022-02-22: Silence message when key binding is undefined.
;;;###autoload
(define-minor-mode mct-tcm-mode
  "MCT extension which Treats the Completions as the Minibuffer.
It intercepts any single character input (without Control or Alt
modifiers) in the Completions' buffer and passes it to the
minibuffer as input.  This practically means that the user
can (i) narrow the list of candidates from the minibuffer, (ii)
switch to the Completions in anticipation of selecting a
candidate, (iii) change their mind and opt to narrow
further, (iv) type something to bring focus back to the
minibuffer while narrowing to the given input.

When this mode is enabled and the above sequence of events takes
place, the current session is treated as if it belongs to the
`mct-completion-passlist' (read its doc string)."
  :global t
  :group 'mct
  (if mct-tcm-mode
      (add-hook 'completion-list-mode-hook #'mct-tcm--setup-redirect-self-insert)
    (remove-hook 'completion-list-mode-hook #'mct-tcm--setup-redirect-self-insert)))

(defun mct-tcm--redirect-self-insert (&rest _)
  "Redirect single character keys as input to the minibuffer."
  (when-let* ((mct-tcm-mode)
              (keys (this-single-command-keys))
              (char (aref keys 0))
              (mini (active-minibuffer-window)))
    (when (and (char-or-string-p char)
               (or (memq 'shift (event-modifiers char))
                   (not (event-modifiers char))))
      (select-window mini)
      (goto-char (point-max))
      (setq-local completion-at-point-functions nil)
      (setq-local mct-live-completion t)
      (setq-local mct-live-update-delay 0)
      (setq-local mct-minimum-input 0)
      ;; FIXME 2022-02-24: Why does Emacs 27 insert twice?  In other
      ;; words, why does it add the character even if the `insert' is
      ;; commented out?
      (when (>= emacs-major-version 28)
        (if (eq char 127) ; DEL or <backspace>
            (delete-char -1)
          (insert char))))))

(defun mct-tcm--setup-redirect-self-insert ()
  "Set up `mct-tcm--redirect-self-insert'."
  (when (mct--minibuffer-p)
    (add-hook 'pre-command-hook #'mct-tcm--redirect-self-insert nil t)))

(provide 'mct-tcm)
;;; mct-tcm.el ends here
