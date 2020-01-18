(require 'dash)

(defconst math-display-delims
  '(("\\begin{align}" "\\end{align}")
    ("\\begin{align\*}" "\\end{align\*}")
    ("\\begin{displaymath}" "\\end{displaymath}")
    ("\\begin{mathpar}" "\\end{mathpar}")
    ("\\begin{equation}" "\\end{equation}")
    ("\\begin{equation*}" "\\end{equation*}")
    ("\\[" "\\]"))
  "Delimiters of math mode, except $.")

(defun latex-in-math-mode ()
  "Check if we are currently in math mode. Uses
`math-display-delims' variable and relies on auctex to fontify
the math mode correctly."
  (interactive)
  (let ((cur (point)))
    (if (equal (char-after cur) 92) ;; if the character we are looking at is \ then we
                            ;; might be looking at \end{...}. In this case we
                            ;; must check if the previous character is in
                            ;; font-latex-math-face.
        (latex/check-if-math-face (get-text-property (max (- cur 1) (point-min)) 'face))
      ;; Otherwise we check as follows. The character we are looking at must be
      ;; in font-latex-math-face. But if we are looking at the opening $ then we must also
      ;; check the previous character, since $ is already in
      ;; font-latex-math-face.
      (and (latex/check-if-math-face (get-text-property cur 'face))
         (if (equal (char-after cur) 36) ;; if the char we are looking at is $
             (latex/check-if-math-face (get-text-property (max (- cur 1) (point-min)) 'face))
           t))
        )
    ))

(defun latex/check-if-math-face (fp)
  "Check if `font-latex-math-face' is a face in `fp'."
  (cond
   ((symbolp fp) (equal fp 'font-latex-math-face))
   ((listp fp) (member 'font-latex-math-face fp))
   )
  )

(defun latex/start-of-math-environment ()
  "Returns a `nil' if we are not looking at the start of a math
environment. Otherwise it returns the length of the start delimiter,
e.g., 1 if $."
  (if (equal (char-after) 36) (list 1) ;; check if we are looking at $ first
    (-keep #'(lambda (pair)
               (when (looking-at-p (regexp-quote (first pair))) (length (first pair))))
           math-display-delims)))

(defun latex/end-of-math-environment ()
  "Returns a `nil' if we are not looking at the end of a math
environment. Otherwise it returns the length of the end delimiter,
e.g., 1 if $."
  (if (equal (char-before) 36) (list 1) ;; check if we are just after $ first
    (-keep #'(lambda (pair)
               (save-excursion (ignore-errors ;; backward-char will signal an error if we try to go back too far
                                 (backward-char (length (second pair)))
                                 (when (looking-at-p (regexp-quote (second pair)))
                                   (length (second pair)))
                                 )))
           math-display-delims)))

(defun latex/remove-math-delims (str)
  "Remove math delimiters at the beginning and end of the given string.
There can be whitespace at the beginning and at the end of the
string. If it is, it is left there."
  (with-temp-buffer 
    (insert str)
    (first-nsp-after (point-min))
    (let ((x (latex/start-of-math-environment)))
      (when x
        (delete-char (first x))
        ;; remove the newlines as well (in case there is a newline). This
        ;; works better when removing \begin{...}, since otherwise there is
        ;; redundant space left.
        (remove-newline-forward)))
    (first-nsp-before (point-max))
    (let ((x (latex/end-of-math-environment)))
      (when x
        (delete-char (- (first x)))
        (remove-newline-backward)))
    (buffer-string)
    )
  )

(defun remove-newline-forward ()
  "This is technically incorrect, but correct in practice."
  (while (member (char-after) (list 10 13)) ;; 10 is \n, 13 is \r
    (delete-char 1)
    )
  )

(defun remove-newline-backward ()
  "This is technically incorrect, but correct in practice."
  (while (member (char-before) (list 10 13)) ;; 10 is \n, 13 is \r
    (delete-char -1)
    )
  )

(defun insert-for-yank/remove-math-delims (phi str)
  (funcall phi  (if (and (equal major-mode 'latex-mode)
                         (latex-in-math-mode))
                    (latex/remove-math-delims str)
                  str)))

(advice-add 'insert-for-yank :around 'insert-for-yank/remove-math-delims)

;; to disable the above advice
;; (advice-remove 'insert-for-yank 'insert-for-yank/remove-math-delims)
