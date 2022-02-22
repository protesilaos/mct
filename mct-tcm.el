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
;; Completions' buffer and send them as input in the minibuffer.

;;; Code:

;;;; General utilities

;; NOTE 2022-02-22: This is highly experimental!

(defun mct-tcm--redirect-self-insert (&rest _args)
  "Redirect to the minibuffer per `mct-tcm-continuous-self-insert'."
  (when-let* ((mct-tcm-mode)
              (keys (this-single-command-keys))
              (char (aref keys 0))
              (mini (active-minibuffer-window)))
    (when (and (char-or-string-p char)
               (not (event-modifiers char)))
      (select-window mini)
      (insert char))))

(defun mct-tcm--setup-redirect-self-insert ()
  "Set up `mct-tcm-continuous-self-insert'."
  (when (mct--minibuffer-p)
    (add-hook 'pre-command-hook #'mct-tcm--redirect-self-insert nil t)))

;; FIXME 2022-02-22: Silence message when key binding is undefined.
(define-minor-mode mct-tcm-mode
  "MCT extension to narrow through the Completions."
  :global t
  (if mct-tcm-mode
      (add-hook 'completion-list-mode-hook #'mct-tcm--setup-redirect-self-insert)
    (remove-hook 'completion-list-mode-hook #'mct-tcm--setup-redirect-self-insert)))

(provide 'mct)
;;; mct.el ends here
