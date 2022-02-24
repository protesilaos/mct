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
;; An extension to MCT that intercepts single character keys in the
;; Completions' buffer and sends them as input in the minibuffer.  In
;; practice, this means that the user can start typing something in the
;; minibuffer, switch to the Completions to select something, realise
;; that they need to narrow further, type some further input which takes
;; them back to the minibuffer.

;;; Code:

;;;; General utilities

(require 'mct)

;; FIXME 2022-02-22: Silence message when key binding is undefined.
;;;###autoload
(define-minor-mode mct-tcm-mode
  "MCT extension to narrow through the Completions.
It intercepts any single character input (without modifiers) in
the Completions' buffer and passes it to the minibuffer as input.
This practically means that the user can switch to the
Completions and then type something to bring focus to the
minibuffer while narrowing to the given input."
  :global t
  :group 'mct
  (if mct-tcm-mode
      (add-hook 'completion-list-mode-hook #'mct-tcm--setup-redirect-self-insert)
    (remove-hook 'completion-list-mode-hook #'mct-tcm--setup-redirect-self-insert)))

(defun mct-tcm--redirect-self-insert (&rest _args)
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
      (setq-local mct-live-completion 'visible)
      (setq-local mct-live-update-delay 0)
      (setq-local mct-minimum-input 0)
      (insert char))))

(declare-function mct--minibuffer-p "mct")

(defun mct-tcm--setup-redirect-self-insert ()
  "Set up `mct-tcm--redirect-self-insert'."
  (when (mct--minibuffer-p)
    (add-hook 'pre-command-hook #'mct-tcm--redirect-self-insert nil t)))

(provide 'mct-tcm)
;;; mct-tcm.el ends here
