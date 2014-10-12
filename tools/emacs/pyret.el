(eval-when-compile (require 'cl))
(defvar pyret-mode-hook nil)
(defun pyret-smart-tab ()
  "This smart tab is minibuffer compliant: it acts as usual in
    the minibuffer. Else, if mark is active, indents region. Else if
    point is at the end of a symbol, expands it. Else indents the
    current line."
  (interactive)
  (if (minibufferp)
      (unless (minibuffer-complete)
        (dabbrev-expand nil))
    (if mark-active
        (indent-region (region-beginning)
                       (region-end))
        (indent-for-tab-command))))
(defun pyret-indent-from-punctuation (&optional N)
  (interactive "^p")
  (or N (setq N 1))
  (self-insert-command N)
  (pyret-smart-tab))

(defun pyret-indent-initial-punctuation (&optional N)
  (interactive "^p")
  (or N (setq N 1))
  (self-insert-command N)
  (when (save-excursion
          (beginning-of-line) 
          (and (looking-at pyret-initial-operator-regex) (not (pyret-in-string))))
    (pyret-smart-tab)))

(defvar pyret-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'newline-and-indent)
    (define-key map (kbd "|") 'pyret-indent-from-punctuation)
    (define-key map (kbd "}") 'pyret-indent-from-punctuation)
    (define-key map (kbd "]") 'pyret-indent-from-punctuation)
    (define-key map (kbd "+") 'pyret-indent-initial-punctuation)
    (define-key map (kbd "-") 'pyret-indent-initial-punctuation)
    (define-key map (kbd "*") 'pyret-indent-initial-punctuation)
    (define-key map (kbd "/") 'pyret-indent-initial-punctuation)
    (define-key map (kbd "=") 'pyret-indent-initial-punctuation)
    (define-key map (kbd "<") 'pyret-indent-initial-punctuation)
    (define-key map (kbd ">") 'pyret-indent-initial-punctuation)
    (define-key map (kbd "`")
      (function (lambda (&optional N)
                  (interactive "^p")
                  (message "Got here")
                  (or N (setq N 1))
                  (self-insert-command N)
                  (ignore-errors
                    (when (and (not (pyret-in-string))
                               (save-excursion (forward-char -3) (looking-at "```"))
                               (not (looking-at "```")))
                      (save-excursion (self-insert-command 3)))))))
    (define-key map (kbd "d")
      (function (lambda (&optional N)
                  (interactive "^p")
                  (or N (setq N 1))
                  (self-insert-command N)
                  (ignore-errors
                    (when (save-excursion (forward-char -3) (pyret-END))
                      (pyret-smart-tab))))))
    (define-key map (kbd "f")
      (function (lambda (&optional N)
                  (interactive "^p")
                  (or N (setq N 1))
                  (self-insert-command N)
                  (ignore-errors
                    (when (or (save-excursion (forward-char -7) (pyret-ELSEIF))
                              (save-excursion (forward-char -2) (pyret-IF)))
                      (pyret-smart-tab))))))
    (define-key map (kbd "t")
      (function (lambda (&optional N)
                  (interactive "^p")
                  (or N (setq N 1))
                  (self-insert-command N)
                  (ignore-errors
                    (when (save-excursion (forward-char -6) (pyret-EXCEPT))
                      (pyret-smart-tab))))))
    (define-key map (kbd ":")
      (function (lambda (&optional N)
                  (interactive "^p")
                  (or N (setq N 1))
                  (self-insert-command N)
                  (ignore-errors
                    (when (or (save-excursion (forward-char -5) (pyret-ELSE))
                              (save-excursion (forward-char -4) (pyret-TRY))
                              (save-excursion (forward-char -5) (pyret-WITH))
                              (save-excursion (forward-char -8) (pyret-SHARING))
                              (save-excursion (forward-char -5) (pyret-CHECK))
                              (save-excursion (forward-char -8) (pyret-EXAMPLES))
                              (save-excursion (forward-char -6) (pyret-WHERE))
                              (save-excursion (forward-char -6) (pyret-BLOCK))
                              (save-excursion (forward-char -6) (pyret-GRAPH)))
                      (pyret-smart-tab))))))
    map)
  "Keymap for Pyret major mode")

(defconst pyret-ident-regex "[a-zA-Z_][a-zA-Z0-9$_\\-]*")
(defconst pyret-keywords
   '("fun" "lam" "method" "var" "when" "import" "provide" "type" "newtype" "check"
     "data" "end" "except" "for" "from" "cases" "shadow" "let" "letrec"
     "and" "or" "is" "raises" "satisfies" "violates" "mutable" "cyclic" "lazy"
     "as" "if" "else" "deriving"))
(defconst pyret-keywords-hyphen
  '("provide-types" "type-let" "is-not" "raises-other-than"
    "does-not-raise" "raises-satisfies" "raises-violates"))
(defconst pyret-keywords-colon
   '("doc" "try" "with" "then" "else" "sharing" "where" "case" "graph" "block" "ask" "otherwise"))
(defconst pyret-keywords-percent
   '("is"))
(defconst pyret-paragraph-starters
  '("|" "fun" "lam" "cases" "data" "for" "sharing" "try" "except" "when" "check" "ask:"))

(defconst pyret-punctuation-regex
  (regexp-opt '(":" "::" "=>" "->" "<" ">" "<=" ">=" "," "^" "(" ")" "[" "]" "{" "}" 
                "." "!" "\\" "|" "=" "==" "<>" "+" "%" "*" "/"))) ;; NOTE: No hyphen by itself
(defconst pyret-initial-operator-regex
  (concat "^[ \t]*\\_<" (regexp-opt '("-" "+" "*" "/" "<" "<=" ">" ">=" "==" "<>" "." "!" "^" "is" "satisfies" "raises")) "\\_>"))
(defconst pyret-ws-regex "\\(?:[ \t\n]\\|#.*?\n\\)")


(defconst pyret-bootstrap-keywords
  '("val"))
(defconst pyret-bootstrap-keywords-colon
  '("examples"))
(defconst pyret-bootstrap-paragraph-starters
  '("examples"))

(defun pyret-add-lists (dest src)
  (mapcar (lambda (kw) (add-to-list dest kw)) src))
(defmacro pyret-del-lists (dest src)  
  `(mapcar (lambda (kw) (setq ,dest (delete kw ,dest))) ,src))
(defun pyret-add-bootstrap-keywords ()
  (pyret-add-lists 'pyret-keywords           pyret-bootstrap-keywords)
  (pyret-add-lists 'pyret-keywords-colon     pyret-bootstrap-keywords-colon)
  (pyret-add-lists 'pyret-paragraph-starters pyret-bootstrap-paragraph-starters))
(defun pyret-remove-bootstrap-keywords ()
  (pyret-del-lists pyret-keywords           pyret-bootstrap-keywords)
  (pyret-del-lists pyret-keywords-colon     pyret-bootstrap-keywords-colon)
  (pyret-del-lists pyret-paragraph-starters pyret-bootstrap-paragraph-starters))


(defun pyret-recompute-lexical-regexes ()
  (defconst pyret-keywords-regex (regexp-opt pyret-keywords))
  (defconst pyret-keywords-hyphen-regex (regexp-opt pyret-keywords-hyphen))
  (defconst pyret-keywords-colon-regex (regexp-opt pyret-keywords-colon))
  (defconst pyret-keywords-percent-regex (regexp-opt pyret-keywords-percent))
  (defconst pyret-font-lock-keywords-1
    (list
     `(";" . font-lock-keyword-face)
     `("\\(```\\(?:\\\\[`\\]\\|[^`\\]\\|``?[^`]\\)*?```\\)" 
       (1 '(face font-lock-string-face font-lock-multiline t) t))
     `(,(concat 
         "\\(^\\|[ \t]\\|" pyret-punctuation-regex "\\)\\("
         pyret-keywords-colon-regex
         "\\)\\(:\\)") 
       (1 font-lock-builtin-face) (2 font-lock-keyword-face) (3 font-lock-builtin-face))
     `(,(concat 
         "\\(^\\|[ \t]\\|" pyret-punctuation-regex "\\)\\("
         pyret-keywords-percent-regex
         "\\)\\(%\\)") 
       (1 font-lock-builtin-face) (2 font-lock-keyword-face) (3 font-lock-builtin-face))
     `(,(concat 
         "\\(^\\|[ \t]\\|" pyret-punctuation-regex "\\)\\("
         pyret-keywords-hyphen-regex
         "\\)")
       (1 font-lock-builtin-face) (2 font-lock-keyword-face))
     `(,(concat 
         "\\(^\\|[ \t]\\|" pyret-punctuation-regex "\\)\\("
         pyret-keywords-regex "-" pyret-ident-regex
         "\\)[ \t]*\\((\\)")
       (1 font-lock-builtin-face) (2 font-lock-function-name-face) (3 font-lock-builtin-face))
     `(,(concat 
         "\\(^\\|[ \t]\\|" pyret-punctuation-regex "\\)\\("
         pyret-keywords-regex "-" pyret-ident-regex
         "\\)")
       (1 font-lock-builtin-face) (2 font-lock-variable-name-face))
     `(,(concat 
         "\\(^\\|[ \t]\\|" pyret-punctuation-regex "\\)\\("
         pyret-keywords-regex
         "\\)\\b")
       (1 font-lock-builtin-face) (2 font-lock-keyword-face))
     `(,pyret-punctuation-regex . font-lock-builtin-face)
     `(,(concat "\\_<" (regexp-opt '("true" "false") t) "\\_>") . font-lock-constant-face)
     )
    "Minimal highlighting expressions for Pyret mode")

  (defconst pyret-font-lock-keywords-2
    (append
     (list
      ;; "| IDENT(whatever) =>" is a function name
      `(,(concat "\\([|]\\)[ \t]+\\(" pyret-ident-regex "\\)(.*?)[ \t]*=>")
        (1 font-lock-builtin-face) (2 font-lock-function-name-face))
      ;; "| KEYWORD =>" is a variable name
      `(,(concat "\\([|]\\)[ \t]+\\(" pyret-keywords-regex "\\)[ \t]*=>")
        (1 font-lock-builtin-face) (2 font-lock-keyword-face))
      ;; "| IDENT =>" is a variable name
      `(,(concat "\\([|]\\)[ \t]+\\(" pyret-ident-regex "\\)[ \t]*=>")
        (1 font-lock-builtin-face) (2 font-lock-variable-name-face))
      ;; "| IDENT (", "| IDENT with", "| IDENT" are all considered type names
      `(,(concat "\\([|]\\)[ \t]+\\(" pyret-ident-regex "\\)[ \t]*\\(?:(\\|with\\|$\\|end\\|;\\)")
        (1 font-lock-builtin-face) (2 font-lock-type-face))
      )
     pyret-font-lock-keywords-1
     (list
      ;; "data IDENT: IDENT" without the leading |
      ;; or "data IDENT<blah>: IDENT
      `(,(concat "\\(\\<data\\>\\)" pyret-ws-regex "+"
                 "\\(" pyret-ident-regex "\\)\\(<.*?>\\)?"
                 pyret-ws-regex "*\\(:\\)" pyret-ws-regex "*\\(" pyret-ident-regex "\\)")
        (1 font-lock-keyword-face) (2 font-lock-type-face) (4 font-lock-builtin-face) (5 font-lock-type-face))
      ;; "data IDENT"
      `(,(concat "\\(\\<data\\>\\)[ \t]+\\(" pyret-ident-regex "\\)") 
        (1 font-lock-keyword-face) (2 font-lock-type-face))
      `(,(concat "\\(" pyret-ident-regex "\\)[ \t]*::[ \t]*\\(" pyret-ident-regex "\\)") 
        (1 font-lock-variable-name-face) (2 font-lock-type-face))
      `(,(concat "\\(->\\)[ \t]*\\(" pyret-ident-regex "\\)")
        (1 font-lock-builtin-face) (2 font-lock-type-face))
      `(,(regexp-opt '("<" ">")) . font-lock-builtin-face)
      `(,(concat "\\(" pyret-ident-regex "\\)[ \t]*\\((\\)")  (1 font-lock-function-name-face))
      `(,pyret-ident-regex . font-lock-variable-name-face)
      '("-" . font-lock-builtin-face)
      ))
    "Additional highlighting for Pyret mode")

  (defconst pyret-font-lock-keywords pyret-font-lock-keywords-2
    "Default highlighting expressions for Pyret mode")
  )

(defconst pyret-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?$ "w" st)
    (modify-syntax-entry ?# "< b" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?: "." st)
    (modify-syntax-entry ?^ "." st)
    (modify-syntax-entry ?= "." st)
    (modify-syntax-entry ?- "_" st)
    (modify-syntax-entry ?, "." st)
    (modify-syntax-entry ?' "\"" st)
    (modify-syntax-entry ?{ "(}" st)
    (modify-syntax-entry ?} "){" st)
    (modify-syntax-entry ?. "." st)
    (modify-syntax-entry ?\; "." st)
    ;(modify-syntax-entry ?` "\"" st)
    st)
  "Syntax table for pyret-mode")


;; Eleven (!) kinds of indentation:
;; bodies of functions
;; bodies of cases (these indent twice, but lines beginning with a pipe indent once)
;; bodies of data declarations (these also indent twice excepting the lines beginning with a pipe)
;; bodies of sharing declarations
;; bodies of try blocks
;; bodies of except blocks
;; additional lines inside unclosed parentheses
;; bodies of objects (and list literals)
;; unterminated variable declarations
;; field definitions
;; lines beginning with a period or operators

(defsubst pyret-is-word (c)
  (and c
       (or 
        (and (>= c ?0) (<= c ?9)) ;; digit
        (and (>= c ?a) (<= c ?z)) ;; lowercase
        (and (>= c ?A) (<= c ?Z)) ;; uppercase
        (= c ?_)
        (= c ?$)
        (= c ?\\)
        (= c ?-))))

(defsubst pyret-in-string ()
  (equal (get-text-property (point) 'face) 'font-lock-string-face))
(defsubst pyret-keyword (s) 
  (if (or (pyret-is-word (preceding-char))
          (pyret-in-string)) nil
    (let ((i 0)
          (slen (length s)))
      (cond
       ((< (point-max) (+ (point) slen))              nil)
       ((pyret-is-word (char-after (+ (point) slen))) nil)
       (t
        (catch 'break
          (while (< i slen)
            (if (= (aref s i) (char-after (+ (point) i)))
                (incf i)
              (throw 'break nil)))
          t))))))
(defsubst pyret-char (c)
  (and (= (char-after) c)
       (not (pyret-in-string))))
      
(defsubst pyret-FUN () (pyret-keyword "fun"))
(defsubst pyret-LAM () (pyret-keyword "lam"))
(defsubst pyret-METHOD () (pyret-keyword "method"))
(defsubst pyret-VAR () (pyret-keyword "var"))
(defsubst pyret-LET () (pyret-keyword "let"))
(defsubst pyret-LETREC () (pyret-keyword "letrec"))
(defsubst pyret-CASES () (pyret-keyword "cases"))
(defsubst pyret-WHEN () (pyret-keyword "when"))
(defsubst pyret-ASKCOLON () (pyret-keyword "ask:"))
(defsubst pyret-THEN () () (pyret-keyword "then:"))
(defsubst pyret-IF () (pyret-keyword "if"))
(defsubst pyret-ELSEIF () (pyret-keyword "else if"))
(defsubst pyret-ELSE () (pyret-keyword "else:"))
(defsubst pyret-OTHERWISE () (pyret-keyword "otherwise:"))
(defsubst pyret-IMPORT () (pyret-keyword "import"))
(defsubst pyret-PROVIDE () (pyret-keyword "provide"))
(defsubst pyret-DATA () (pyret-keyword "data"))
(defsubst pyret-END () (pyret-keyword "end"))
(defsubst pyret-FOR () (pyret-keyword "for"))
(defsubst pyret-FROM () (pyret-keyword "from"))
(defsubst pyret-TRY () (pyret-keyword "try:"))
(defsubst pyret-EXCEPT () (pyret-keyword "except"))
(defsubst pyret-AS () (pyret-keyword "as"))
(defsubst pyret-SHARING () (pyret-keyword "sharing:"))
(defsubst pyret-EXAMPLES () (pyret-keyword "examples"))
(defsubst pyret-CHECK () (pyret-keyword "check"))
(defsubst pyret-WHERE () (pyret-keyword "where:"))
(defsubst pyret-GRAPH () (pyret-keyword "graph:"))
(defsubst pyret-WITH () (pyret-keyword "with:"))
(defsubst pyret-BLOCK () (pyret-keyword "block:"))
(defsubst pyret-PIPE () (pyret-char ?|))
(defsubst pyret-SEMI () (pyret-char ?\;))
(defsubst pyret-COLON () (pyret-char ?:))
(defsubst pyret-COMMA () (pyret-char ?,))
(defsubst pyret-LBRACK () (pyret-char ?[))
(defsubst pyret-RBRACK () (pyret-char ?]))
(defsubst pyret-LBRACE () (pyret-char ?{))
(defsubst pyret-RBRACE () (pyret-char ?}))
(defsubst pyret-LANGLE () (pyret-char ?<))
(defsubst pyret-RANGLE () (pyret-char ?>))
(defsubst pyret-LPAREN () (pyret-char ?())
(defsubst pyret-RPAREN () (pyret-char ?)))
(defsubst pyret-EQUALS () (and (not (pyret-in-string)) (looking-at "=[^>]")))
(defsubst pyret-COMMENT () (and (not (pyret-in-string)) (looking-at "[ \t]*#.*$")))

(defun pyret-has-top (stack top)
  (if top
      (and (equal (car-safe stack) (car top))
           (pyret-has-top (cdr stack) (cdr top)))
    t))

(defstruct
  (pyret-indent
   (:constructor pyret-make-indent (fun cases data shared try except graph parens object vars fields initial-period))
   :named)
   fun cases data shared try except graph parens object vars fields initial-period)

(defun pyret-map-indent (f total delta)
  (let* ((len (length total))
         (ret (make-vector len nil))
         (i 1))
    (aset ret 0 (aref total 0))
    (while (< i len)
      (aset ret i (funcall f (aref total i) (aref delta i)))
      (incf i))
    ret))
(defmacro pyret-add-indent (total delta)  `(pyret-map-indent '+ ,total ,delta))
(defmacro pyret-add-indent! (total delta) `(setf ,total (pyret-add-indent ,total ,delta)))
(defmacro pyret-sub-indent (total delta) `(pyret-map-indent '- ,total ,delta))
(defmacro pyret-sub-indent! (total delta) `(setf ,total (pyret-sub-indent ,total ,delta)))
(defmacro pyret-mul-indent (total delta) `(pyret-map-indent '* ,total ,delta))
(defun pyret-sum-indents (total) 
  (let ((i 1)
        (sum 0)
        (len (length total)))
    (while (< i len)
      (incf sum (aref total i))
      (incf i))
    sum))
(defun pyret-make-zero-indent () (pyret-make-indent 0 0 0 0 0 0 0 0 0 0 0 0))
(defun pyret-zero-indent! (ind)
  (let ((i 1)
        (len (length ind)))
    (while (< i len)
      (aset ind i 0)
      (incf i))))
(defun pyret-copy-indent! (dest src)
  (let ((i 1)
        (len (length dest)))
    (while (< i len)
      (aset dest i (aref src i))
      (incf i))))

(defun pyret-print-indent (ind)
  (format
   "Fun %d, Cases %d, Data %d, Shared %d, Try %d, Except %d, Graph %s, Parens %d, Object %d, Vars %d, Fields %d, Period %d"
   (pyret-indent-fun ind)
   (pyret-indent-cases ind)
   (pyret-indent-data ind)
   (pyret-indent-shared ind)
   (pyret-indent-try ind)
   (pyret-indent-except ind)
   (pyret-indent-graph ind)
   (pyret-indent-parens ind)
   (pyret-indent-object ind)
   (pyret-indent-vars ind)
   (pyret-indent-fields ind)
   (pyret-indent-initial-period ind)))

(defun pyret-make-zero-vector (length)
  (let ((v (make-vector length nil))
        (n 0))
    (while (< n length)
      (aset v n (pyret-make-zero-indent))
      (incf n))
    v))

(defvar pyret-tokens-stack nil
  "Stores the token stack of the parse.  Should only be buffer-local.")
(defvar pyret-nestings-dirty-at-char 0
  "Stores the minimum dirty position of the buffer.  Should only be buffer-local.")
(defvar pyret-nestings-at-line-end nil
  "Stores the deferred open information of the parse.  Should only be buffer-local.")
(defvar pyret-nestings-at-line-start nil
  "Stores the indentation information of the parse.  Should only be buffer-local.")

(defun pyret-compute-nestings (char-min char-max)
  (save-excursion (font-lock-fontify-region (max 1 char-min) char-max))
  (let ((nlen (if pyret-nestings-at-line-start (length pyret-nestings-at-line-start) 0))
        (doclen (count-lines (point-min) (point-max))))
    (cond 
     ((>= (+ doclen 1) nlen)
      (setq pyret-nestings-at-line-start (vconcat pyret-nestings-at-line-start (pyret-make-zero-vector (+ 1 (- doclen nlen)))))
      (setq pyret-nestings-at-line-end (vconcat pyret-nestings-at-line-end (pyret-make-zero-vector (+ 1 (- doclen nlen)))))
      (setq pyret-tokens-stack (vconcat pyret-tokens-stack (make-vector (+ 1 (- doclen nlen)) nil))))
     (t nil)))
  ;; open-* is the running count as of the *beginning of the line*
  ;; cur-opened-* is the count of how many have been opened on this line
  ;; cur-closed-* is the count of how many have been closed on this line
  ;; defered-opened-* is the count of how many have been opened on this line, but should not be indented
  ;; defered-closed-* is the count of how many have been closed on this line, but should not be outdented
  (let* ((line-min (- (line-number-at-pos char-min) 1))
         (line-max (line-number-at-pos char-max))
         (n line-min)
         (open (pyret-make-zero-indent))
         (cur-opened (pyret-make-zero-indent))
         (cur-closed (pyret-make-zero-indent))
         (defered-opened (pyret-make-zero-indent))
         (defered-closed (pyret-make-zero-indent))
         (opens nil))
    ;; (message "Indenting from line %d to %d" line-min line-max)
    (save-excursion
      (goto-char char-min) (beginning-of-line)
      ;; (message "n = %d" n)
      ;; (when (> n 1)
      ;;   (message "indent(%d)     : %s" (- n 2) (pyret-print-indent (aref pyret-nestings-at-line-start (- n 2)))))
      ;; (when (> n 0)
      ;;   (message "indent(%d)     : %s" (- n 1) (pyret-print-indent (aref pyret-nestings-at-line-start (- n 1)))))
      ;; (message "indent(%d)     : %s" n (pyret-print-indent (aref pyret-nestings-at-line-start n)))
      ;; (message "indent(%d)     : %s" (+ n 1) (pyret-print-indent (aref pyret-nestings-at-line-start (+ n 1))))
      ;; (message "indent(%d)     : %s" (+ n 2) (pyret-print-indent (aref pyret-nestings-at-line-start (+ n 2))))
      ;; (when (> n 1)
      ;;   (message "open(%d)     : %s" (- n 2) (pyret-print-indent (aref pyret-nestings-at-line-end (- n 2)))))
      ;; (when (> n 0)
      ;;   (message "open(%d)     : %s" (- n 1) (pyret-print-indent (aref pyret-nestings-at-line-end (- n 1)))))
      ;; (message "open(%d)     : %s" n (pyret-print-indent (aref pyret-nestings-at-line-end n)))
      ;; (message "open(%d)     : %s" (+ n 1) (pyret-print-indent (aref pyret-nestings-at-line-end (+ n 1))))
      ;; (message "open(%d)     : %s" (+ n 2) (pyret-print-indent (aref pyret-nestings-at-line-end (+ n 2))))
      ;; (when (> n 1)
      ;;   (message "stack(%d)     : %s" (- n 2) (aref pyret-tokens-stack (- n 2))))
      ;; (when (> n 0)
      ;;   (message "stack(%d)     : %s" (- n 1) (aref pyret-tokens-stack (- n 1))))
      ;; (message "stack(%d)    : %s" n (aref pyret-tokens-stack n))
      ;; (message "stack(%d)    : %s" (+ n 1) (aref pyret-tokens-stack (+ n 1)))
      ;; (message "stack(%d)    : %s" (+ n 2) (aref pyret-tokens-stack (+ n 2)))
      (pyret-copy-indent! open (aref pyret-nestings-at-line-end n))
      (pyret-copy-indent! (aref pyret-nestings-at-line-start n) open)
      (setq opens (append (aref pyret-tokens-stack n) nil))
      (while (and (<= n line-max) (not (eobp)))
        (pyret-zero-indent! cur-opened) (pyret-zero-indent! cur-closed)
        (pyret-zero-indent! defered-opened) (pyret-zero-indent! defered-closed)
        ;;(message "At start of line %d, open is %s" (+ n 1) open)
        (while (not (eolp))
          (cond
           ((pyret-COMMENT)
            (end-of-line))
           ((and (looking-at "[^ \t]") (pyret-has-top opens '(needsomething)))
            (pop opens) ;; don't advance, because we may need to process that text
            (when (and (pyret-has-top opens '(var))
                     (> (pyret-indent-vars defered-opened) 0)) 
              (decf (pyret-indent-vars defered-opened))
              (pop opens))) ;; don't indent if we've started a RHS already
           ((and (looking-at pyret-initial-operator-regex) (not (pyret-in-string)))
            (incf (pyret-indent-initial-period cur-opened))
            (incf (pyret-indent-initial-period defered-closed))
            (goto-char (match-end 0)))
           ((pyret-COLON)
            (cond
             ((or (pyret-has-top opens '(wantcolon))
                  (pyret-has-top opens '(wantcolonorequal)))
              (pop opens))
             ((or (pyret-has-top opens '(object))
                  (pyret-has-top opens '(shared)))
                  ;;(pyret-has-top opens '(data)))
              ;;(message "Line %d, saw colon in context %s, pushing 'field" (+ 1 n) (car-safe opens))
              (incf (pyret-indent-fields defered-opened))
              (push 'field opens)
              (push 'needsomething opens)))
            (forward-char))
           ((pyret-COMMA)
            (when (pyret-has-top opens '(field))
              (pop opens)
              (cond ;; if a field was just opened (or will be opened), ignore it
               ((> (pyret-indent-fields cur-opened) 0) 
                ;;(message "In comma, cur-opened-fields > 0, decrementing")
                (decf (pyret-indent-fields cur-opened)))
               ((> (pyret-indent-fields defered-opened) 0)
                ;;(message "In comma, defered-opened-fields > 0, decrementing")
                (decf (pyret-indent-fields defered-opened)))
               (t 
                ;;(message "In comma, incrementing defered-closed-fields")
                (incf (pyret-indent-fields defered-closed))))) ;; otherwise decrement the running count
            (forward-char))
           ((pyret-EQUALS)
            (cond
             ((pyret-has-top opens '(wantcolonorequal))
              (pop opens))
             (t 
              (while (pyret-has-top opens '(var))
                (pop opens)
                ;;(message "Line %d, Seen equals, and opens is %s, incrementing cur-closed-vars" (1+ n) opens)
                (incf (pyret-indent-vars cur-closed)))
              ;;(message "Line %d, Seen equals, and opens is %s, incrementing defered-opened-vars" (1+ n) opens)
              (incf (pyret-indent-vars defered-opened))
              (push 'var opens)
              (push 'needsomething opens)))
            (forward-char))
           ((pyret-VAR)
            ;;(message "Line %d, Seen var, current text is '%s', and opens is %s, incrementing defered-opened-vars" (1+ n) (buffer-substring (point) (min (point-max) (+ 10 (point)))) opens)
            (incf (pyret-indent-vars defered-opened))
            (push 'var opens)
            (push 'needsomething opens)
            (push 'wantcolonorequal opens)
            (forward-char 3))
           ((or (pyret-FUN) (pyret-LAM))
            (incf (pyret-indent-fun defered-opened))
            (push 'fun opens)
            (push 'wantcolon opens)
            ;; (push 'wantcloseparen opens)
            ;; (push 'wantopenparen opens)
            (forward-char 3))
           ((pyret-LETREC)
            (incf (pyret-indent-fun defered-opened))
            (push 'let opens)
            (push 'wantcolon opens)
            (forward-char 6))
           ((pyret-LET)
            (incf (pyret-indent-fun defered-opened))
            (push 'let opens)
            (push 'wantcolon opens)
            (forward-char 3))
           ((pyret-METHOD)
            (incf (pyret-indent-fun defered-opened))
            (push 'fun opens)
            (push 'wantcolon opens)
            ;; (push 'wantcloseparen opens)
            ;; (push 'wantopenparen opens)
            (forward-char 6))
           ((pyret-WHEN) ;when indents just like funs
            (incf (pyret-indent-fun defered-opened))
            (push 'when opens)
            (push 'wantcolon opens)
            (forward-char 4))
           ((pyret-FOR) ;for indents just like funs
            (incf (pyret-indent-fun defered-opened))
            (push 'for opens)
            (push 'wantcolon opens)
            (forward-char 3))
           ((looking-at "[ \t]+") (goto-char (match-end 0)))
           ((pyret-CASES)
            (incf (pyret-indent-cases defered-opened))
            (push 'cases opens)
            (push 'wantcolon opens)
            (push 'needsomething opens)
            (push 'wantcloseparen opens)
            (push 'wantopenparen opens)
            (forward-char 5))
           ((pyret-DATA)
            (incf (pyret-indent-data defered-opened))
            (push 'data opens)
            (push 'wantcolon opens)
            (push 'needsomething opens)
            (forward-char 4))
           ((pyret-ASKCOLON)
            (incf (pyret-indent-cases defered-opened))
            (push 'ifcond opens)
            (forward-char 4))
           ((pyret-IF)
            (incf (pyret-indent-fun defered-opened))
            (push 'if opens)
            (push 'wantcolon opens)
            (push 'needsomething opens)
            (forward-char 2))
           ((pyret-ELSEIF)
            (when (pyret-has-top opens '(if))
              (cond
               ((> (pyret-indent-fun cur-opened) 0) (decf (pyret-indent-fun cur-opened)))
               ((> (pyret-indent-fun defered-opened) 0) (decf (pyret-indent-fun defered-opened)))
               (t (incf (pyret-indent-fun cur-closed))))
              (incf (pyret-indent-fun defered-opened))
              (push 'wantcolon opens)
              (push 'needsomething opens))
            (forward-char 7))
           ((pyret-ELSE)
            (when (pyret-has-top opens '(if))
              (cond
               ((> (pyret-indent-fun cur-opened) 0) (decf (pyret-indent-fun cur-opened)))
               ((> (pyret-indent-fun defered-opened) 0) (decf (pyret-indent-fun defered-opened)))
               (t (incf (pyret-indent-fun cur-closed))))
              (incf (pyret-indent-fun defered-opened))
              (push 'wantcolon opens))
            (forward-char 4))
           ((pyret-PIPE)
            (cond 
             ((or (pyret-has-top opens '(object data))
                  (pyret-has-top opens '(field object data)))
              ;(incf (pyret-indent-object cur-closed))
              (cond
               ((pyret-has-top opens '(field))
                (pop opens)
                (cond ;; if a field was just opened (or will be opened), ignore it
                 ((> (pyret-indent-fields cur-opened) 0) 
                  ;;(message "In pipe, cur-opened-fields > 0, decrementing")
                  (decf (pyret-indent-fields cur-opened)))
                 ((> (pyret-indent-fields defered-opened) 0)
                  ;;(message "In pipe, defered-opened-fields > 0, decrementing")
                  (decf (pyret-indent-fields defered-opened)))
                 (t 
                  ;;(message "In pipe, incrementing cur-closed-fields")
                  (incf (pyret-indent-fields cur-closed)))))) ;; otherwise decrement the running count
              (if (pyret-has-top opens '(object))
                  (pop opens)))
             ((pyret-has-top opens '(data))
              (push 'needsomething opens)
              ))
            (forward-char))
           ((pyret-WITH)
            (cond
             ((pyret-has-top opens '(wantopenparen wantcloseparen data))
              (pop opens) (pop opens)
              ;(incf (pyret-indent-object defered-opened))
              (push 'object opens)
              (push 'wantcolon opens))
             ((pyret-has-top opens '(data))
              ;(incf (pyret-indent-object defered-opened))
              (push 'object opens)
              (push 'wantcolon opens)))
            (forward-char 4))
           ;; ((pyret-PROVIDE)
           ;;  (push 'provide opens)
           ;;  (forward-char 7))
           ((pyret-SHARING)
            (incf (pyret-indent-data cur-closed))
            (incf (pyret-indent-shared defered-opened))
            (cond 
             ((pyret-has-top opens '(object data))
              (pop opens) (pop opens)
              ;(incf (pyret-indent-object cur-closed))
              (push 'shared opens)
              (push 'wantcolon opens))
             ((pyret-has-top opens '(data))
              (pop opens)
              (push 'shared opens)
              (push 'wantcolon opens)))
            (forward-char 7))
           ((pyret-WHERE)
            (cond
             ((pyret-has-top opens '(object data))
              (pop opens) (pop opens)
              ;(incf (pyret-indent-object cur-closed))
              (incf (pyret-indent-data cur-closed))
              (incf (pyret-indent-shared defered-opened)))
             ((pyret-has-top opens '(data))
              (pop opens)
              (incf (pyret-indent-data cur-closed))
              (incf (pyret-indent-shared defered-opened)))
             ((pyret-has-top opens '(fun))
              (pop opens)
              (incf (pyret-indent-fun cur-closed))
              (incf (pyret-indent-shared defered-opened)))
             ((pyret-has-top opens '(shared))
              (pop opens)
              (incf (pyret-indent-shared cur-closed))
              (incf (pyret-indent-shared defered-opened)))
             ((not opens)
              (incf (pyret-indent-shared defered-opened))))
            (push 'check opens)
            (push 'wantcolon opens)
            (forward-char 5))
           ((and (pyret-CHECK) (not opens))
            (incf (pyret-indent-shared defered-opened))
            (push 'check opens)
            (push 'wantcolon opens)
            (forward-char 5))
           ((and (pyret-EXAMPLES) (equal pyret-dialect 'Bootstrap) (not opens))
            (incf (pyret-indent-shared defered-opened))
            (push 'check opens)
            (push 'wantcolon opens)
            (forward-char 8))
           ((pyret-TRY)
            (incf (pyret-indent-try defered-opened))
            (push 'try opens)
            (push 'wantcolon opens)
            (forward-char 3))
           ((pyret-BLOCK)
            (incf (pyret-indent-fun defered-opened))
            (push 'block opens)
            (push 'wantcolon opens)
            (forward-char 5))
           ((pyret-GRAPH)
            (incf (pyret-indent-graph defered-opened))
            (push 'graph opens)
            (push 'wantcolon opens)
            (forward-char 5))
           ((pyret-EXCEPT)
            (cond 
             ((> (pyret-indent-try cur-opened) 0) 
              (decf (pyret-indent-try cur-opened)) (incf (pyret-indent-except cur-opened)))
             ((> (pyret-indent-try defered-opened) 0)
              (decf (pyret-indent-try defered-opened)) (incf (pyret-indent-except defered-opened)))
             (t 
              (incf (pyret-indent-try cur-closed)) (incf (pyret-indent-except defered-opened))))
            (when (pyret-has-top opens '(try))
              (pop opens)
              (push 'except opens)
              (push 'wantcolon opens)
              (push 'wantcloseparen opens)
              (push 'wantopenparen opens))
            (forward-char 6))
           ;; ((LANGLE)
           ;;  (incf open-parens) (incf cur-opened-parens)
           ;;  (push 'angle opens)
           ;;  (forward-char))
           ;; ((RANGLE)
           ;;  (decf open-parens) (incf cur-closed-parens)
           ;;  (if (pyret-has-top opens '(angle))
           ;;      (pop opens))
           ;;  (forward-char))
           ((pyret-LBRACK)
            (incf (pyret-indent-object defered-opened))
            (push 'array opens)
            (forward-char))
           ((pyret-RBRACK)
            (save-excursion
              (beginning-of-line)
              (if (and (looking-at "^[ \t]*\\]") (not (pyret-in-string)))
                  (incf (pyret-indent-object cur-closed))
                (incf (pyret-indent-object defered-closed))))
            (if (pyret-has-top opens '(array))
                (pop opens))
            (while (pyret-has-top opens '(var))
              (pop opens)
              ;;(message "Line %d, Seen rbrack, and opens is %s, incrementing defered-closed-vars" (1+ n) opens)
              (incf (pyret-indent-vars defered-closed)))
            (forward-char))
           ((pyret-LBRACE)
            (incf (pyret-indent-object defered-opened))
            (push 'object opens)
            (forward-char))
           ((pyret-RBRACE)
            (save-excursion
              (beginning-of-line)
              (if (and (looking-at "^[ \t]*\\}") (not (pyret-in-string)))
                  (incf (pyret-indent-object cur-closed))
                (incf (pyret-indent-object defered-closed))))
            (when (pyret-has-top opens '(field))
              (pop opens)
              (cond ;; if a field was just opened (or will be opened), ignore it
               ((> (pyret-indent-fields cur-opened) 0) 
                ;;(message "In rbrace, cur-opened-fields > 0, decrementing")
                (decf (pyret-indent-fields cur-opened)))
               ((> (pyret-indent-fields defered-opened) 0)
                ;;(message "In rbrace, defered-opened-fields > 0, decrementing")
                (decf (pyret-indent-fields defered-opened)))
               (t 
                ;;(message "In rbrace, incrementing cur-closed-fields")
                (incf (pyret-indent-fields cur-closed))))) ;; otherwise decrement the running count
            (if (pyret-has-top opens '(object))
                (pop opens))
            (while (pyret-has-top opens '(var))
              (pop opens)
              ;;(message "Line %d, Seen rbrace, and opens is %s, incrementing defered-closed-vars" (1+ n) opens)
              (incf (pyret-indent-vars defered-closed)))
            (forward-char))
           ((pyret-LPAREN)
            (incf (pyret-indent-parens defered-opened))
            (cond
             ((pyret-has-top opens '(wantopenparen))
              (pop opens))
             ((or (pyret-has-top opens '(object))
                  (pyret-has-top opens '(shared))) ; method in an object or sharing section
              (push 'fun opens)
              ;; (push 'wantcolon opens)
              ;; (push 'wantcloseparen opens)
              (incf (pyret-indent-fun defered-opened)))
             (t
              (push 'wantcloseparen opens)))
            (forward-char))
           ((pyret-RPAREN)
            (cond
             ((> (pyret-indent-parens cur-opened) 0) (decf (pyret-indent-parens cur-opened)))
             ((> (pyret-indent-parens defered-opened) 0) (decf (pyret-indent-parens defered-opened)))
             (t (incf (pyret-indent-parens defered-closed))))
            (if (pyret-has-top opens '(wantcloseparen))
                (pop opens))
            (while (pyret-has-top opens '(var))
              (pop opens)
              ;;(message "Line %d, Seen rparen, and opens is %s, incrementing defered-closed-vars" (1+ n) opens)
              (incf (pyret-indent-vars defered-closed)))
            (forward-char))
           ((or (pyret-END) (pyret-SEMI))
            (when (pyret-has-top opens '(object data))
              ;(incf (pyret-indent-object cur-closed))
              (pop opens))
            (let* ((h (car-safe opens))
                   (is-semi (pyret-SEMI))
                   (which-to-close (if is-semi defered-closed cur-closed))
                   (still-unclosed t))
              (while (and still-unclosed opens)
                (cond
                 ;; Things that are not counted
                 ;; provide, wantcolon, wantcolonorequal, needsomething, wantopenparen
                 ;; Things that are counted but not closable by end:
                 ((or (equal h 'object) (equal h 'array))
                  (cond 
                   ((> (pyret-indent-object cur-opened) 0) (decf (pyret-indent-object cur-opened)))
                   ((> (pyret-indent-object defered-opened) 0) (decf (pyret-indent-object defered-opened)))
                   (t (incf (pyret-indent-object which-to-close)))))
                 ((equal h 'wantcloseparen)
                  (cond
                   ((> (pyret-indent-parens cur-opened) 0) (decf (pyret-indent-parens cur-opened)))
                   ((> (pyret-indent-parens defered-opened) 0) (decf (pyret-indent-parens defered-opened)))
                   (t (incf (pyret-indent-parens which-to-close)))))
                 ((equal h 'field)
                  (cond
                   ((> (pyret-indent-fields cur-opened) 0) (decf (pyret-indent-fields cur-opened)))
                   ((> (pyret-indent-fields defered-opened) 0) (decf (pyret-indent-fields defered-opened)))
                   (t (incf (pyret-indent-fields which-to-close)))))
                 ((equal h 'var)
                  (cond
                   ((> (pyret-indent-vars cur-opened) 0) (decf (pyret-indent-vars cur-opened)))
                   ((> (pyret-indent-vars defered-opened) 0) (decf (pyret-indent-vars defered-opened)))
                   (t (incf (pyret-indent-vars which-to-close)))))
                 ;; Things that are counted and closeable by end
                 ((or (equal h 'fun) (equal h 'when) (equal h 'for) (equal h 'if) (equal h 'block) (equal h 'let))
                  (cond
                   ((> (pyret-indent-fun cur-opened) 0) (decf (pyret-indent-fun cur-opened)))
                   ((> (pyret-indent-fun defered-opened) 0) (decf (pyret-indent-fun defered-opened)))
                   (t (incf (pyret-indent-fun which-to-close))))
                  (setq still-unclosed nil))
                 ((or (equal h 'cases) (equal h 'ifcond))
                  (cond
                   ((> (pyret-indent-cases cur-opened) 0) (decf (pyret-indent-cases cur-opened)))
                   ((> (pyret-indent-cases defered-opened) 0) (decf (pyret-indent-cases defered-opened)))
                   (t (incf (pyret-indent-cases which-to-close))))
                  (setq still-unclosed nil))
                 ((equal h 'data)
                  (cond
                   ((> (pyret-indent-data cur-opened) 0) (decf (pyret-indent-data cur-opened)))
                   ((> (pyret-indent-data defered-opened) 0) (decf (pyret-indent-data defered-opened)))
                   (t (incf (pyret-indent-data which-to-close))))
                  (setq still-unclosed nil))
                 ((or (equal h 'shared) (equal h 'check))
                  (cond
                   ((> (pyret-indent-shared cur-opened) 0) (decf (pyret-indent-shared cur-opened)))
                   ((> (pyret-indent-shared defered-opened) 0) (decf (pyret-indent-shared defered-opened)))
                   (t (incf (pyret-indent-shared which-to-close))))
                  (setq still-unclosed nil))
                 ((equal h 'try)
                  (cond
                   ((> (pyret-indent-try cur-opened) 0) (decf (pyret-indent-try cur-opened)))
                   ((> (pyret-indent-try defered-opened) 0) (decf (pyret-indent-try defered-opened)))
                   (t (incf (pyret-indent-try which-to-close))))
                  (setq still-unclosed nil))
                 ((equal h 'except)
                  (cond
                   ((> (pyret-indent-except cur-opened) 0) (decf (pyret-indent-except cur-opened)))
                   ((> (pyret-indent-except defered-opened) 0) (decf (pyret-indent-except defered-opened)))
                   (t (incf (pyret-indent-except which-to-close))))
                  (setq still-unclosed nil))
                 ((equal h 'graph)
                  (cond
                   ((> (pyret-indent-graph cur-opened) 0) (decf (pyret-indent-graph cur-opened)))
                   ((> (pyret-indent-graph defered-opened) 0) (decf (pyret-indent-graph defered-opened)))
                   (t (incf (pyret-indent-graph which-to-close))))
                  (setq still-unclosed nil))
                 )
                (pop opens)
                (setq h (car-safe opens)))
              (if is-semi
                  (forward-char 1)
                (forward-char 3))))
           (t (if (not (eobp)) (forward-char)))))
        ;;(message "At end   of line %d, open is %s" (+ n 1) open)
        (aset pyret-nestings-at-line-start n (pyret-add-indent open (pyret-sub-indent cur-opened cur-closed)))
        (let ((h (car-safe opens)))
          (while (equal h 'var)
            (pop opens)
            (incf (pyret-indent-vars cur-closed))
            (setq h (car-safe opens))))
        ;; (message "Line %d" (+ 1 n))
        ;; (message "Prev open     : %s" (pyret-print-indent open))
        ;; (message "open(%d)      : %s" n (pyret-print-indent (aref pyret-nestings-at-line-end n)))
        (pyret-add-indent! open (pyret-sub-indent (pyret-add-indent cur-opened defered-opened) 
                                                  (pyret-add-indent cur-closed defered-closed)))
        ;; (message "Cur-opened    : %s" (pyret-print-indent cur-opened))
        ;; (message "Defered-opened: %s" (pyret-print-indent defered-opened))
        ;; (message "Cur-closed    : %s" (pyret-print-indent cur-closed))
        ;; (message "Defered-closed: %s" (pyret-print-indent defered-closed))
        ;; (message "New open      : %s" (pyret-print-indent open))
        (incf n)
        (pyret-copy-indent! (aref pyret-nestings-at-line-end n) open)
        (aset pyret-tokens-stack n (append opens nil))
        (pyret-copy-indent! (aref pyret-nestings-at-line-start n) open)
        (if (not (eobp)) (forward-char)))
      (setq pyret-nestings-dirty-at-char char-max)
      ))
  )

(defun print-nestings ()
  "Displays the nestings information in the Messages buffer"
  (interactive)
  (let ((i 0))
    (while (and (< i (length pyret-nestings-at-line-start))
                (< i (line-number-at-pos (point-max))))
      (let* ((indents (aref pyret-nestings-at-line-start i))
             (defered (aref pyret-nestings-at-line-end i)))
        (incf i)
        (message "Line %4d: %s" i (pyret-print-indent indents))
        (message "Open %4d: %s" i (pyret-print-indent defered))
        ))))

(defconst pyret-indent-widths (pyret-make-indent 1 2 2 1 1 1 0 1 1 1 1 1)) ;; NOTE: 0 = indent for graphs
(defun pyret-indent-line ()
  "Indent current line as Pyret code"
  (interactive)
  (pyret-compute-nestings (min (point) pyret-nestings-dirty-at-char) (save-excursion (end-of-line) (point)))
  (let* ((indents (aref pyret-nestings-at-line-start (min (- (line-number-at-pos) 1) (length pyret-nestings-at-line-start))))
         (total-indent (pyret-sum-indents (pyret-mul-indent indents pyret-indent-widths))))
    (save-excursion
      (beginning-of-line)
      (if (looking-at "^[ \t]*[|]")
          (if (> total-indent 0)
              (indent-line-to (* tab-width (- total-indent 1)))
            (indent-line-to 0))
        (indent-line-to (max 0 (* tab-width total-indent)))))
    (if (< (current-column) (current-indentation))
        (forward-char (- (current-indentation) (current-column))))
    ))

(defun pyret-indent-region (start end)
  "Indent current region as Pyret code"
  (interactive)
  (pyret-compute-nestings (min start pyret-nestings-dirty-at-char) (save-excursion (goto-char end) (end-of-line) (point)))
  (let* ((line-min (line-number-at-pos start))
         (line-max (line-number-at-pos end))
         (indent-widths (make-vector (+ 1 (- line-max line-min)) 0))
         (n line-min))
    (save-excursion
      (goto-char start) (beginning-of-line)
      (while (<= n line-max)
        (let* ((indents (aref pyret-nestings-at-line-start (min (- n 1) (length pyret-nestings-at-line-start))))
               (total-indent (pyret-sum-indents (pyret-mul-indent indents pyret-indent-widths))))
          (if (looking-at "^[ \t]*[|]")
              (aset indent-widths (- n line-min) (max 0 (* tab-width (- total-indent 1))))
            (aset indent-widths (- n line-min) (max 0 (* tab-width total-indent)))))
        (incf n)
        (forward-line))
      (setq n line-min) (goto-char start) (beginning-of-line)
      (while (<= n line-max)
        (indent-line-to (aref indent-widths (- n line-min)))
        (incf n)
        (forward-line))
      )
    (if (< (current-column) (current-indentation))
        (forward-char (- (current-indentation) (current-column))))
    ))

(defun pyret-comment-dwim (arg)
  "Comment or uncomment current line or region in a smart way.
For detail, see `comment-dwim'."
  (interactive "*P")
  (require 'newcomment)
  (let ((comment-start "#") (comment-end ""))
    (comment-dwim arg)))


;;; ADAPTED FROM http://sourceforge.net/p/python-mode/patches/26/
;; Syntactic keywords.  This syntactic keyword table allows
;; pyret-mode to handle triple-quoted strings (almost) correctly.

(defvar pyret-font-lock-syntactic-keywords
  '((pyret-quote-in-triple-quoted-string-matcher 0 (1 . nil))
    )
  "Syntactic keyword table for Pyret, which finds quote marks that
should not be considered string delimiters because they are inside
triple-quoted strings, and marks them as punctuation instead.")

(defun pyret-quote-in-triple-quoted-string-matcher (limit)
  "A `font-lock-mode' MATCHER that searches for quote marks (\" or \' or \`)
that should not be considered string delimiters because they are
inside triple-quoted strings.
    It also marks all quote marks it encounters with the text-property
`pyret-strtype', indicating what sort of string begins immediately after
that quote mark.  For open-quote marks, the value is one of:
\"```\", \"\\\"\", \"\\'\".  For close-quote
marks, the value is nil.  For backslashed quotes, quotes in comments,
and non-triple-quotes inside triple-quoted- strings, the value is the
quote mark that opened the string."
  (let (result strtype)
    ;; Find a known starting place & state.
    (cond ((= (point) (car pyret-strtype-cache))
           (setq strtype (cdr pyret-strtype-cache)))
          ((re-search-backward "[`\"\']" nil t)
           (setq strtype (get-text-property (point) 'pyret-strtype))
           (forward-char 1))
          (t nil))
    ;; Scan forward looking for string-internal quotes.
    (while (not result)
      ;; Find the next token.
      (if (re-search-forward "[`\"\'\\#]" limit t)
          (let ((start (match-beginning 0))
                (tok (char-before)))
            ;;(mydebug "%s@%s [in %s]" tok start strtype)
            (cond
             ;; Backslashed char: move over it.
             ((eq tok ?\\) (forward-char 1))
             ;; Comment marker: go to eol unless we're in a string.
             ((eq tok ?\#) (unless strtype (end-of-line)))
             ;; Close quote: set strtype to nil.
             ((and strtype (save-excursion (backward-char 1)
                                           (looking-at strtype)))
              (setq strtype nil) (goto-char (match-end 0)))
             ;; String-internal quote: mark it as normal (non-
             ;; quoting) punctuation.
             (strtype (if (and (member strtype '("```"))
                               (eq tok (elt strtype 0)))
                          (setq result 'found-one)))
             ;; Open quote: set strtype.
             (t (backward-char 1)
                (if (re-search-forward "```\\|\"\\|\'" limit t)
                    (setq strtype (match-string 0))
                  (forward-char 1))))
            ;; Save strtype for future reference.
            (put-text-property start (point) 'pyret-strtype strtype))
        ;; No tokens left
        (setq result 'reached-limit)))
    (setq pyret-strtype-cache (cons (point) strtype))
    (eq result 'found-one)))

(defvar pyret-strtype-cache '(-1 . nil)
  "Cached value indicating what kind of string we're in (if any).
Encoded as a tuple (POS . STRTYPE).  POS is a buffer position --
only use the cache if you're still at that position.  STRTYPE is
one of: \"```\", \"\\\"\", \"\\'\", or nil,
indicating what open quote was used for the string we're currently
in (nil if we're not in a string).")

;; Don't let the 'pyret-strtype' property spread to other characters.
(when (boundp 'text-property-default-nonsticky)
  (add-to-list 'text-property-default-nonsticky '(pyret-strtype . t)))

(defun pyret-mode ()
  "Major mode for editing Pyret files"
  (interactive)
  (kill-all-local-variables)
  (set-syntax-table pyret-mode-syntax-table)
  (use-local-map pyret-mode-map)
  (pyret-remove-bootstrap-keywords)
  (pyret-recompute-lexical-regexes)
  (set (make-local-variable 'pyret-dialect) 'Pyret)
  (set (make-local-variable 'font-lock-defaults) '(pyret-font-lock-keywords))
  (set (make-local-variable 'font-lock-syntactic-keywords) pyret-font-lock-syntactic-keywords)
  (font-lock-refresh-defaults)
  (set (make-local-variable 'comment-start) "#")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'indent-line-function) 'pyret-indent-line)  
  (set (make-local-variable 'indent-region-function) 'pyret-indent-region)  
  (set (make-local-variable 'tab-width) 2)
  (set (make-local-variable 'indent-tabs-mode) nil)
  (set (make-local-variable 'paragraph-start)
       (concat "\\|[ \t]*" (regexp-opt pyret-paragraph-starters)))
  (setq major-mode 'pyret-mode)
  (setq mode-name "Pyret")
  (set (make-local-variable 'pyret-nestings-at-line-start) (vector))
  (set (make-local-variable 'pyret-nestings-at-line-end) (vector))
  (set (make-local-variable 'pyret-tokens-stack) (vector))
  (set (make-local-variable 'pyret-nestings-dirty-at-char) 0)
  (add-hook 'before-change-functions
               (function (lambda (beg end) 
                           (setq pyret-nestings-dirty-at-char 
                                 (min beg pyret-nestings-dirty-at-char))))
               nil t)
  (run-hooks 'pyret-mode-hook))

(define-minor-mode bootstrap-mode
  "The Bootstrap dialect of Pyret"
  :lighter " [Bootstrap]"
  (when (equal major-mode 'pyret-mode)
    (if (equal pyret-dialect 'Pyret) ;; Enabling Bootstrap mode
        (progn
          (setq pyret-dialect 'Bootstrap)
          (pyret-add-bootstrap-keywords))
      (progn
        (setq pyret-dialect 'Pyret)
        (pyret-remove-bootstrap-keywords)))
    (pyret-recompute-lexical-regexes)
    (set (make-local-variable 'font-lock-defaults) '(pyret-font-lock-keywords))
    (font-lock-refresh-defaults)
    (set (make-local-variable 'paragraph-start)
         (concat "\\|[ \t]*" (regexp-opt pyret-paragraph-starters)))
    )
  )

(defun pyret-reload-mode-all-buffers ()
  "Debugging function to help reload the pyret major mode in all open buffers"
  (interactive)
  (mapcar
   (function
    (lambda (b)
      (with-current-buffer b
        (when (equal major-mode 'pyret-mode)
          (text-mode)
          (pyret-mode)))))
   (buffer-list)))


(provide 'pyret)

