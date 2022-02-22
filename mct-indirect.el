;;; mct-indirect.el --- Indirect MCT motions in the Completions' buffer -*- lexical-binding: t -*-

;; Copyright (C) 2021-2022  Free Software Foundation, Inc.

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
;; Extension for MCT which keeps the point in the minibuffer instead of
;; cycling between the minibuffer and the Completions' buffer.
;;
;; Based on the `vcomplete' library of Daniel Semyonov:
;; <https://git.sr.ht/~dsemy/vcomplete>.

;;; Code:

;;;; General utilities

(require 'mct)

(defmacro mct-indirect-with-completions-buffer (&rest body)
  "Evaluate BODY with the Completions' buffer temporarily current."
  (declare (debug (&rest form)))
  `(when-let ((window (mct--get-completion-window)))
     (save-current-buffer
       (set-buffer (window-buffer window))
       (unless (derived-mode-p 'completion-list-mode)
         (user-error
          "The Completions' buffer is set to an incorrect mode"))
       ,@body)))

(defun mct-indirect--move-in-completions (arg)
  "Move ARG completions in the Completions' buffer."
  (unless (mct--get-completion-window)
    (mct--show-completions))
  (mct-indirect-with-completions-buffer
   (next-completion arg)
   (set-window-point window (point))
   (mct--completions-candidate-highlight)))

(defun mct-indirect-next-completion (&optional arg)
  "Move indirectly to previous candidate.
With optional numeric ARG, move to next ARGth candidate."
  (interactive "p" mct-minibuffer-mode)
  (mct-indirect--move-in-completions (or arg 1)))

(defun mct-indirect-previous-completion (&optional arg)
  "Move indirectly to previous candidate.
With optional numeric ARG, move to previous ARGth candidate."
  (interactive "p" mct-minibuffer-mode)
  (mct-indirect--move-in-completions (or (- arg) -1)))

(defun mct-indirect-choose-completion ()
  "Choose the completion at point in the Completions' buffer."
  (interactive)
  (when (mct--get-completion-window)
    (switch-to-completions)
    (choose-completion)))

;;;###autoload
(define-minor-mode mct-indirect-mode
  "Select completion candidates indirectly.
The standard MCT behaviour is to move the point to the
Completions' buffer while performing the relevant motions.
Whereas this mode keeps the point fixed in the minibuffer while
repositioning an overlay that selects the candidate.

This has the benefit of allowing the user to narrow the list of
candidates at any time.  The downside is that the Completions
buffer is not longer treated as a regular buffer."
  :init-value nil
  :global t
  :group 'mct
  (if mct-indirect-mode
      (progn
        (advice-add #'mct-switch-to-completions-top :override #'mct-indirect-next-completion)
        (advice-add #'mct-switch-to-completions-bottom :override #'mct-indirect-previous-completion)
        (advice-add #'minibuffer-complete-and-exit :override #'mct-indirect-choose-completion))
    (advice-remove #'mct-switch-to-completions-top #'mct-indirect-next-completion)
    (advice-remove #'mct-switch-to-completions-bottom #'mct-indirect-previous-completion)
    (advice-remove #'minibuffer-complete-and-exit #'mct-indirect-choose-completion)))

(provide 'mct-indirect)
;;; mct-indirect.el ends here
