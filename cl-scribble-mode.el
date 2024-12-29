;;; cl-scribble-mode.el --- Major mode for editing Scribble documents -*- lexical-binding: t; -*-

;; Copyright (c) 2014 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/scribble-mode
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "24"))

;; This file is NOT part of GNU Emacs.

;;; License:

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
;; A major mode for editing Scribble documents.
;;
;; You can install [geiser][] to `scribble-mode-hook' to eldoc and auto
;; completion support:
;;
;;     (add-hook 'scribble-mode-hook #'geiser-mode)
;;
;; [geiser]: http://www.nongnu.org/geiser/

;;; Code:

(defgroup cl-scribble-mode nil
  "Major mode for editing Scribble documents."
  :prefix "cl-scribble-mode-"
  :group 'languages)

(defcustom cl-scribble-mode-executable "scribble"
  "Path to scribble executable."
  :type 'string
  :group 'cl-scribble-mode)

(defvar cl-scribble-mode-imenu-generic-expression
  `(("Title"
     ,(rx "@title" (? (: "[" (* (not (any "]")))) "]") "{" (group (+ (not (any "}")))) "}")
     1)
    ("Section"
     ,(rx "@" (* "sub") "section" (? (: "[" (* (not (any "]")))) "]") "{" (group (+ (not (any "}")))) "}")
     1)))

(defvar cl-scribble-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Whitespace
    (modify-syntax-entry ?\t "    " table)
    (modify-syntax-entry ?\n ">   " table)
    (modify-syntax-entry ?\f "    " table)
    (modify-syntax-entry ?\r "    " table)
    (modify-syntax-entry ?\s "    " table)

    (modify-syntax-entry ?\" "\"   " table)
    (modify-syntax-entry ?\\ "\\   " table)

    ;; Special characters
    (modify-syntax-entry ?' "'   " table)
    (modify-syntax-entry ?` "'   " table)
    (modify-syntax-entry ?, "'   " table)
    (modify-syntax-entry ?@ "'   " table)
    (modify-syntax-entry ?: "_ " table)

    ;; Comments
    (modify-syntax-entry ?\@ "' 1" table)
    (modify-syntax-entry ?\; "' 2" table)
    (modify-syntax-entry ?\n ">"   table)

    (modify-syntax-entry ?# "w 14" table)

    ;; Brackets and braces balance for editing convenience.
    (modify-syntax-entry ?\[ "(]  " table)
    (modify-syntax-entry ?\] ")[  " table)
    (modify-syntax-entry ?{  "(}  " table)
    (modify-syntax-entry ?}  "){  " table)
    (modify-syntax-entry ?\( "()  " table)
    (modify-syntax-entry ?\) ")(  " table)
    table)
  "Syntax table for `cl-scribble-mode'.")

(defvar cl-scribble-mode-font-lock-keywords
  `(;; keywords
    (,(rx (or space "(" "[" "{") (group (zero-or-one "#") ":" (+ (not (any space ")" "]" "}")))))
     (1 font-lock-builtin-face))
    ;; t nil
    (,(regexp-opt '("t" "nil") 'symbols)
     (1 font-lock-constant-face))
    ;; functions
    (,(rx (group "@" (+ (not (any space "[" "{" "(")))))
     (1 font-lock-function-name-face)))
  "Font lock for `cl-scribble-mode'.")

;;;###autoload
(define-derived-mode cl-scribble-mode prog-mode "CL Scribble"
  "Major mode for editing scribble files.

\\{cl-scribble-mode-map}"
  (set (make-local-variable 'comment-start) "@;")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'comment-multi-line) nil)
  (set (make-local-variable 'font-lock-defaults)
       '(cl-scribble-mode-font-lock-keywords))
  (set (make-local-variable 'imenu-generic-expression)
       cl-scribble-mode-imenu-generic-expression)
  (imenu-add-to-menubar "Contents"))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.scrbl\\'" . cl-scribble-mode))

;; Completions
(defun cl-scribble-complete-sly-symbol ()
  (let* ((thing (thing-at-point 'symbol))
         (bounds (bounds-of-thing-at-point 'symbol)))
    (list (car bounds)
          (cdr bounds)
          (and thing
               (car (funcall sly-complete-symbol-function thing))))))

(defun cl-scribble-complete-slime-symbol ()
  (let* ((thing (thing-at-point 'symbol))
         (bounds (bounds-of-thing-at-point 'symbol)))
    (list (car bounds)
          (cdr bounds)
          (and thing
               (slime-simple-completions thing)))))

(defun cl-scribble--setup-completion ()
  (let ((complete-function nil)
        (buffers (buffer-list)))
    (while (and buffers (not complete-function))
      (let ((buffer (car buffers)))
        (with-current-buffer buffer
          (cond
           ((member 'sly-mode minor-mode-list)
            (setq complete-function 'cl-scribble-complete-sly-symbol))
           ((member 'slime-mode minor-mode-list)
            (setq complete-function 'cl-scribble-complete-slime-symbol)))))
      (setq buffers (cdr buffers)))
    (when complete-function
      (setq-local completion-at-point-functions (list complete-function)))))

(add-hook 'cl-scribble-mode-hook 'cl-scribble--setup-completion)

(defun cl-scribble--setup-repl-initialization (complete-function)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (eq major-mode 'cl-scribble-mode)
        (setq-local completion-at-point-functions (list complete-function))))))

(add-hook 'sly-mode-hook (lambda ()
                           (cl-scribble--setup-repl-initialization 'cl-scribble-complete-sly-symbol)))
(add-hook 'slime-mode-hook (lambda ()
                             (cl-scribble--setup-repl-initialization 'cl-scribble-complete-slime-symbol)))

(provide 'cl-scribble-mode)

;;; cl-scribble-mode.el ends here
