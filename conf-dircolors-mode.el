;;; conf-dircolors-mode.el --- A major mode to edit dircolors files  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Yevhen Tukubaiev

;; Author: Yevhen Tukubaiev <etukubaev2@gmail.com>
;; Keywords: languages, unix
;; Package-Requires: ((emacs "24"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Version: 1.0
;; URL: https://github.com/geuonne/conf-dircolors-mode.el

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode to edit `dircolors` configuration files.
;; See `man:dircolors(1)`, `man:dir_colors(5)` for details about dircolors.
;; See also dircolors plugin for Vim:
;; https://github.com/vim/vim/blob/master/runtime/syntax/dircolors.vim

;; `conf-dircolors-propertize-ansi-itself' function is mainly inspired
;; from `rainbow-colorize-ansi' function from `rainbow-mode' library.

;; As in `rainbow-mode' library, matched strings are propertized either
;; with `xterm-color-filter' (if `xterm-color' library is available) or
;; `ansi-color-apply'.


;;; Code:
;;;; Dependencies and declarations
(require 'conf-mode)
(unless (require 'xterm-color nil t)
  (require 'ansi-color))

(declare-function ansi-color-apply "ansi-color")
(declare-function xterm-color-filter "ext:xterm-color")


;;;; Font lock
(defconst conf-dircolors-keywords
  '("TERM" "COLORTERM" ; Terminal-specific section starters
    "LEFT" "LEFTCODE" "RIGHT" "RIGHTCODE" "END" "ENDCODE" ; Sequence codes
    "COLOR" "OPTIONS" "EIGHTBIT" ; Slackware-specific flags
    "NORM" "NORMAL" "RESET" ; Miscellaneous
    "DIR" "FILE" ; Basic file types
    "LNK" "LINK" "SYMLINK" ; Symbolic/physical links
    "MISSING" "ORPHAN"
    "MULTIHARDLINK"
    "BLK" "BLOCK" "CHR" "CHAR" ; Special file types
    "DOOR" "FIFO" "PIPE" "SOCK"
    "EXEC" "STICKY" "CAPABILITY" ; File attributes
    "OWT" "STICKY_OTHER_WRITABLE" "OWR" "OTHER_WRITABLE"
    "SGID" "SETGID" "SUID" "SETUID")
  "Known keywords for dircolors files.")

;;;###autoload
(defconst conf-dircolors-file-regexp "/\\(\\.dir_colors\\|DIR_COLORS\\)\\'"
  "Regular expression for matching dircolors files.")

(add-to-list 'conf-space-keywords-alist
             `(,conf-dircolors-file-regexp . ,(combine-and-quote-strings conf-dircolors-keywords "\\|")))

(defun conf-dircolors-propertize-ansi-itself ()
  "Propertize string representing ANSI sequence numbers with properties of itself."
  (let ((xterm-color (featurep 'xterm-color))
        ;; At least one character ("_") must be present between start
        ;; and end codes in order for string to be propertized.
        (string (concat "\e[" (match-string-no-properties 2) "m" "_" "\e[0m"))
        face-prop)
    (save-match-data
      (setq face-prop (get-text-property
                       0
                       (if xterm-color 'face 'font-lock-face)
                       (funcall (if xterm-color #'xterm-color-filter #'ansi-color-apply) string)))
      (unless (listp (or (car-safe face-prop) face-prop))
        (setq face-prop (list face-prop))))
    (when face-prop (put-text-property (match-beginning 2) (match-end 2) 'face face-prop))))

(defvar conf-dircolors-font-lock-keywords
  (append '(("^[[:blank:]]*\\([^[:blank:]#]+\\)[[:blank:]]+\\([[:digit:];]+\\)"
             (2 (conf-dircolors-propertize-ansi-itself))))
          conf-space-font-lock-keywords)
  "Font-lock keywords to add for propertizing ANSI sequences.")


;;;; Major mode setup
;;;###autoload
(define-derived-mode conf-dircolors-mode conf-space-mode "Conf[Dircolors]"
  "Conf Mode starter for space separated dircolors files.
Comments start with `#' and \"assignments\" are with `\s'.

For details see `conf-mode', man:dircolors(1) and man:dir_colors(5).  Example:

# Conf mode font-lock this right with \\[conf-dircolors-mode] (dir_colors)

TERM                   linux
NORMAL                 00
NORM                   00 # alias for norm

COLOR                  tty

*.txt                  44"
  (conf-mode-initialize "#" 'conf-dircolors-font-lock-keywords)
  (conf-quote-normal nil))

;;;###autoload
(add-to-list 'auto-mode-alist `(,conf-dircolors-file-regexp . conf-dircolors-mode))


;;;; Code end
(provide 'conf-dircolors-mode)

;;; conf-dircolors-mode.el ends here
