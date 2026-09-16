;;; lean4-workshop.el --- run, check, and debug the workshop from Emacs  -*- lexical-binding: t; -*-

;; Repo-level support, matching the sibling convention: every workshop and
;; book-companion repo in this family carries <repo-name>.el at the top level.
;;
;; Everything here shells out to the same `lean' binary the Makefile and CI
;; use, so a result seen in Emacs and a result seen in a terminal come from
;; one code path. LSP (lean4-mode + lsp-mode) is layered on top for goal
;; display and hover; it is optional, and every command below works without
;; it.
;;
;; The repo's .dir-locals.el loads this file and runs `l4w/setup' the
;; first time a file under the repo is visited; answer `!' to the
;; local-variables prompt once.  Or load it from init and call `l4w/setup'.
;; Bindings live under C-c l in Lean and Org buffers.
;;
;; Workflow:
;;   C-c l e     open an exercise (completing-read across exercises/)
;;   C-c l c     check the current file with `lean' (compile buffer, clickable)
;;   C-c l r     run the current file's `main' with `lean --run'
;;   C-c l <     run `main' with a file on stdin (exercise W09)
;;   C-c l n/p   next/previous `sorry'
;;   C-c l t     occur over every `sorry' in the buffer: the to-do list
;;   C-c l s     open the matching solution
;;   C-c l a     check every exercise, or every solution with a prefix arg
;;   C-c l v     #eval an expression in the context of the current file
;;   C-c l k     #check an expression in the context of the current file
;;   C-c l o     insert a `set_option ... in' debugging prefix
;;   C-c l x     pick the elan toolchain used by every command above
;;   C-c l m     run a Makefile target
;;   C-c l g     tangle lean4-programming.org, then check the result
;;   C-c l P     export lean4-programming.org to PDF
;;   C-c l N     new scratch/<name>.lean with a main, for fizzbuzz and friends
;;   C-c l ?     this list

;;; Code:

(require 'subr-x)
(require 'compile)
(require 'org)
(eval-when-compile (require 'flycheck nil t))
(declare-function flycheck-define-checker "flycheck")
(declare-function flycheck-define-command-checker "flycheck")
(declare-function lean4-mode "lean4-mode")
(declare-function lsp "lsp-mode")
(declare-function straight-use-package "straight")
(declare-function package-vc-install "package-vc")
(declare-function lsp-session "lsp-mode")
(declare-function lsp-session-folders "lsp-mode")
(declare-function lsp-workspace-folders-add "lsp-mode")
(declare-function lsp-session-folders-blocklist "lsp-mode")
(declare-function lsp-workspace-blocklist-remove "lsp-mode")
(declare-function org-latex-export-to-pdf "ox-latex")
(defvar org-latex-src-block-backend)
(defvar org-latex-compiler)
(defvar org-latex-listings-langs)
(defvar flycheck-checkers)

(defgroup l4w nil
  "Working lean4-workshop from Emacs."
  :group 'tools
  :prefix "l4w/")

(defcustom l4w/root
  (or (when-let* ((f (or load-file-name buffer-file-name)))
        (file-name-directory f))
      default-directory)
  "Repository root."
  :type 'directory
  :group 'l4w)

(defcustom l4w/lean "lean"
  "The lean binary. elan's shim resolves the toolchain from `lean-toolchain'."
  :type 'string
  :group 'l4w)

(defcustom l4w/toolchain nil
  "Toolchain override passed to elan as `+NAME'.
Nil means whatever `lean-toolchain' pins.  Set interactively with
`l4w/select-toolchain'."
  :type '(choice (const nil) string)
  :group 'l4w)

(defcustom l4w/make "gmake"
  "GNU make."
  :type 'string
  :group 'l4w)

(defcustom l4w/exercise-dirs '("exercises" "exercises/warmup")
  "Directories under `l4w/root' that hold exercise files."
  :type '(repeat string)
  :group 'l4w)

(defcustom l4w/document "lean4-programming.org"
  "The org document that tangles to exercises/Warmup.lean."
  :type 'string
  :group 'l4w)

;;; ------------------------------------------------------------ paths

(defun l4w/--path (rel)
  "REL under the repository root."
  (expand-file-name rel l4w/root))

(defun l4w/--lean-args ()
  "Leading arguments for `lean', including any toolchain override."
  (when l4w/toolchain (list (concat "+" l4w/toolchain))))

(defun l4w/--lean-command (&rest args)
  "A shell command string running lean with ARGS."
  (mapconcat #'shell-quote-argument
             (append (list l4w/lean) (l4w/--lean-args) args)
             " "))

(defun l4w/--current-lean-file ()
  "The Lean file the current buffer is about.
In an Org buffer this is the tangle target, after tangling."
  (cond
   ((derived-mode-p 'org-mode)
    (l4w/tangle)
    (l4w/--path "exercises/Warmup.lean"))
   ((and buffer-file-name (string-suffix-p ".lean" buffer-file-name))
    (when (buffer-modified-p) (save-buffer))
    buffer-file-name)
   (t (user-error "Not a Lean file"))))

(defun l4w/--exercise-files ()
  "Every exercise file, as paths relative to `l4w/root'."
  (let (acc)
    (dolist (dir l4w/exercise-dirs (nreverse acc))
      (dolist (f (directory-files (l4w/--path dir) nil "\\.lean\\'"))
        (push (concat dir "/" f) acc)))))

(defun l4w/--solution-files ()
  "Every solution file, relative to `l4w/root'."
  (let (acc)
    (dolist (dir l4w/exercise-dirs (nreverse acc))
      (let ((sol (l4w/--path (concat dir "/Solutions"))))
        (when (file-directory-p sol)
          (dolist (f (directory-files sol nil "\\.lean\\'"))
            (push (concat dir "/Solutions/" f) acc)))))))

;;; ------------------------------------------------------------ checking

;; Lean prints `file:line:col: error: msg' and `file:line:col: warning: msg',
;; which the built-in `gnu' pattern already understands.  This adds the
;; 4.32+ variant `error(lean.kind):' so the kind does not swallow the match.
(defconst l4w/--error-regexp
  '(lean4 "^\\([^ \n:]+\\.lean\\):\\([0-9]+\\):\\([0-9]+\\): \\(?:\\(error\\)\\|\\(warning\\)\\)\\(?:([^)]*)\\)?:"
          1 2 3 (5)))

(defun l4w/--compile (command &optional name)
  "Run COMMAND from the repository root in a compilation buffer NAME."
  (let ((default-directory l4w/root)
        (compilation-buffer-name-function
         (lambda (_mode) (or name "*lean4-workshop*"))))
    (unless (assq 'lean4 compilation-error-regexp-alist-alist)
      (push l4w/--error-regexp compilation-error-regexp-alist-alist))
    (unless (memq 'lean4 compilation-error-regexp-alist)
      (push 'lean4 compilation-error-regexp-alist))
    (compile command)))

(defun l4w/check ()
  "Check the current Lean file.  No output means done.
The compilation buffer's errors are the to-do list: each `#guard' that
fails names the definition still carrying a `sorry'."
  (interactive)
  (let ((file (l4w/--current-lean-file)))
    (l4w/--compile (l4w/--lean-command (file-relative-name file l4w/root)))))

(defun l4w/run (&optional stdin-file)
  "Run the current file's `main' with `lean --run'.
With STDIN-FILE, feed that file on standard input."
  (interactive)
  (let* ((file (file-relative-name (l4w/--current-lean-file) l4w/root))
         (cmd (l4w/--lean-command "--run" file)))
    (l4w/--compile (if stdin-file
                       (concat cmd " < " (shell-quote-argument
                                          (file-relative-name stdin-file l4w/root)))
                     cmd)
                   "*lean4-run*")))

(defun l4w/run-with-stdin (stdin-file)
  "Run `main' with STDIN-FILE piped in.  Defaults to the file itself,
which is the test W09 asks for: compare with `wc -lw'."
  (interactive
   (list (read-file-name "stdin from: " l4w/root nil t
                         (when buffer-file-name
                           (file-relative-name buffer-file-name l4w/root)))))
  (l4w/run stdin-file))

(defun l4w/check-all (&optional solutions)
  "Check every exercise file in one compilation buffer.
With prefix arg SOLUTIONS, check the solutions instead; those must be
silent apart from `#eval' output."
  (interactive "P")
  (let ((files (if solutions (l4w/--solution-files) (l4w/--exercise-files))))
    (l4w/--compile
     (mapconcat (lambda (f)
                  (concat "echo '== " f "'; " (l4w/--lean-command f)))
                files "; ")
     (if solutions "*lean4-solutions*" "*lean4-exercises*"))))

(defun l4w/make (target)
  "Run Makefile TARGET."
  (interactive
   (list (completing-read "gmake: " (l4w/--make-targets) nil nil nil nil "check")))
  (l4w/--compile (format "%s %s" l4w/make target) "*lean4-make*"))

(defun l4w/--make-targets ()
  "Targets in the Makefile that carry a ## description."
  (with-temp-buffer
    (insert-file-contents (l4w/--path "Makefile"))
    (let (acc)
      (while (re-search-forward "^\\([a-zA-Z_-]+\\):.*## " nil t)
        (push (match-string 1) acc))
      (nreverse acc))))

;;; ------------------------------------------------------------ sorry navigation

(defconst l4w/--sorry-regexp "\\_<sorry\\_>")

(defun l4w/--in-comment-or-string-p ()
  "Non-nil when point is inside a comment or string."
  (let ((state (syntax-ppss)))
    (or (nth 3 state) (nth 4 state))))

(defun l4w/next-sorry ()
  "Jump to the next `sorry' in code, skipping comments and strings."
  (interactive)
  (let ((start (point)) found)
    (save-excursion
      (forward-char (min 1 (- (point-max) (point))))
      (while (and (not found) (re-search-forward l4w/--sorry-regexp nil t))
        (unless (l4w/--in-comment-or-string-p)
          (setq found (match-beginning 0)))))
    (if found
        (goto-char found)
      (goto-char start)
      (message "No further sorry. %s" (l4w/--sorry-summary)))))

(defun l4w/prev-sorry ()
  "Jump to the previous `sorry' in code, skipping comments and strings."
  (interactive)
  (let (found)
    (save-excursion
      (while (and (not found) (re-search-backward l4w/--sorry-regexp nil t))
        (unless (l4w/--in-comment-or-string-p)
          (setq found (match-beginning 0)))))
    (if found
        (goto-char found)
      (message "No earlier sorry. %s" (l4w/--sorry-summary)))))

(defun l4w/--sorry-count ()
  "Number of `sorry' occurrences outside comments in the buffer."
  (save-excursion
    (goto-char (point-min))
    (let ((n 0))
      (while (re-search-forward l4w/--sorry-regexp nil t)
        (unless (l4w/--in-comment-or-string-p) (setq n (1+ n))))
      n)))

(defun l4w/--sorry-summary ()
  "A one-line count."
  (let ((n (l4w/--sorry-count)))
    (if (zerop n) "No sorry left; run l4w/check."
      (format "%d sorry left." n))))

(defun l4w/todo ()
  "List every `sorry' in the buffer.  This is the to-do list."
  (interactive)
  (occur l4w/--sorry-regexp)
  (message "%s" (l4w/--sorry-summary)))

;;; ------------------------------------------------------------ exercises and solutions

(defun l4w/exercise (file)
  "Open exercise FILE."
  (interactive
   (list (completing-read "Exercise: " (l4w/--exercise-files) nil t)))
  (find-file (l4w/--path file))
  (message "%s" (l4w/--sorry-summary)))

(defun l4w/--solution-for (file)
  "Path of the solution matching exercise FILE, or nil.
Ex01_Basics maps to Solutions/Sol01_Basics; W01_Evaluation to
Solutions/S01_Evaluation."
  (let* ((dir (file-name-directory file))
         (base (file-name-nondirectory file))
         (candidates
          (list (replace-regexp-in-string "\\`Ex" "Sol" base)
                (replace-regexp-in-string "\\`W" "S" base))))
    (seq-find #'file-exists-p
              (mapcar (lambda (b) (expand-file-name (concat "Solutions/" b) dir))
                      candidates))))

(defun l4w/--exercise-for (file)
  "Path of the exercise matching solution FILE, or nil."
  (let* ((dir (file-name-directory (directory-file-name (file-name-directory file))))
         (base (file-name-nondirectory file))
         (candidates
          (list (replace-regexp-in-string "\\`Sol" "Ex" base)
                (replace-regexp-in-string "\\`S" "W" base))))
    (seq-find #'file-exists-p
              (mapcar (lambda (b) (expand-file-name b dir)) candidates))))

(defun l4w/solution ()
  "Toggle between an exercise and its solution, in another window."
  (interactive)
  (let* ((file (or buffer-file-name (user-error "No file")))
         (target (if (string-match-p "/Solutions/" file)
                     (l4w/--exercise-for file)
                   (l4w/--solution-for file))))
    (if target
        (find-file-other-window target)
      (user-error "No counterpart for %s" (file-name-nondirectory file)))))

;;; ------------------------------------------------------------ scratch files

(defun l4w/scratch (name)
  "Create scratch/NAME.lean from a small template and open it.
The scratch/ directory is gitignored: fizzbuzz goes here, not in
exercises/.  The template has a `main' so C-c l r works at once."
  (interactive (list (read-string "Scratch file name: " nil nil "FizzBuzz")))
  (let* ((dir (l4w/--path "scratch/"))
         (file (expand-file-name (concat (file-name-sans-extension name) ".lean") dir)))
    (make-directory dir t)
    (find-file file)
    (when (zerop (buffer-size))
      (insert "-- " (file-name-nondirectory file) "\n"
              "-- C-c l c checks, C-c l r runs main, C-c l v evals an expression.\n\n"
              "def main : IO Unit := do\n"
              "  IO.println \"hello\"\n\n"
              "#eval main\n")
      (goto-char (point-min))
      (forward-line 3))
    (l4w/--maybe-enable)))

(defun l4w/help ()
  "Show the C-c l bindings."
  (interactive)
  (with-help-window "*l4w help*"
    (princ "lean4-workshop  (prefix C-c l)\n\n")
    (princ (substitute-command-keys "\\{l4w-mode-map}"))))

;;; ------------------------------------------------------------ debugging without LSP

;; `lean' has no REPL.  The next best thing: append a command to a copy of
;; the current file and run that, so the expression sees every definition
;; in the buffer.  Slow (a full re-elaboration) but exact, and it works in
;; a buffer full of `sorry'.

(defun l4w/--buffer-namespaces ()
  "Names of every `namespace' the buffer declares, outside comments."
  (save-excursion
    (goto-char (point-min))
    (let (acc)
      (while (re-search-forward "^[ \t]*namespace[ \t]+\\([^ \t\n]+\\)" nil t)
        (unless (l4w/--in-comment-or-string-p)
          (push (match-string-no-properties 1) acc)))
      (delete-dups (nreverse acc)))))

(defun l4w/--scratch-file (command)
  "Write the whole buffer plus COMMAND to a scratch file; return its path.
The command goes after the last line, so it sees everything, and is
prefixed with `open NS in' for each namespace the buffer declares,
since those are closed again by then."
  (let* ((scratch (l4w/--path ".l4w-scratch.lean"))
         (body (buffer-substring-no-properties (point-min) (point-max)))
         (namespaces (l4w/--buffer-namespaces))
         (line (if namespaces
                   (format "open %s in %s" (string-join namespaces " ") command)
                 command)))
    (with-temp-file scratch
      (insert body "\n\n" line "\n"))
    scratch))

(defun l4w/--run-command-in-context (command)
  "Run lean on the buffer plus COMMAND; show only the command's own messages.
Uses `lean --json' so every message carries its line, and keeps the ones
on the appended line.  Output from the file's own #eval lines is dropped."
  (let* ((scratch (l4w/--scratch-file command))
         (default-directory l4w/root)
         (own-line (with-temp-buffer
                     (insert-file-contents scratch)
                     (count-lines (point-min) (point-max))))
         (raw (with-temp-buffer
                (apply #'call-process l4w/lean nil t nil
                       (append (l4w/--lean-args)
                               (list "--json" (file-relative-name scratch l4w/root))))
                (buffer-string)))
         (messages
          (delq nil
                (mapcar
                 (lambda (line)
                   (when (string-prefix-p "{" line)
                     (condition-case nil
                         (let* ((msg (json-parse-string line :object-type 'alist))
                                (pos (alist-get 'pos msg))
                                (ln (alist-get 'line pos))
                                (severity (alist-get 'severity msg))
                                (data (alist-get 'data msg)))
                           (when (and (equal ln own-line)
                                      (not (string-match-p "\\`declaration uses" data)))
                             (if (equal severity "information")
                                 data
                               (format "%s: %s" severity data))))
                       (error nil))))
                 (split-string raw "\n" t)))))
    (delete-file scratch)
    (let ((text (string-trim (string-join messages "\n"))))
      (if (string-empty-p text)
          (message "(no output)")
        (with-current-buffer (get-buffer-create "*lean4-eval*")
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert "-- " command "\n" text "\n"))
          (special-mode)
          (display-buffer (current-buffer)))
        (message "%s" (car (split-string text "\n")))))))

(defun l4w/--expr-at-point ()
  "The active region, or the symbol at point."
  (if (use-region-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    (or (thing-at-point 'symbol t) "")))

(defun l4w/--read-expr (command)
  "Prompt for an expression for COMMAND, offering the symbol at point as default."
  (let ((default (l4w/--expr-at-point)))
    (read-string (if (string-empty-p default)
                     (concat command " ")
                   (format "%s (default %s): " command default))
                 nil nil default)))

(defun l4w/eval (expr)
  "#eval EXPR with every definition in the buffer in scope."
  (interactive (list (l4w/--read-expr "#eval")))
  (l4w/--run-command-in-context (concat "#eval " expr)))

(defun l4w/check-expr (expr)
  "#check EXPR with every definition in the buffer in scope."
  (interactive (list (l4w/--read-expr "#check")))
  (l4w/--run-command-in-context (concat "#check " expr)))

(defun l4w/print (name)
  "#print NAME with every definition in the buffer in scope."
  (interactive (list (l4w/--read-expr "#print")))
  (l4w/--run-command-in-context (concat "#print " name)))

(defconst l4w/--options
  '(("trace.Meta.synthInstance true"  . "why an instance did not resolve")
    ("trace.Meta.Tactic.simp true"    . "which simp lemmas fired")
    ("trace.Elab.definition true"     . "how a definition was elaborated")
    ("pp.explicit true"               . "show implicit arguments")
    ("pp.all true"                    . "show everything")
    ("autoImplicit false"             . "reject unbound identifiers instead of binding them")
    ("linter.unusedVariables false"   . "quiet the unused-variable linter")
    ("maxRecDepth 2000"               . "deeper recursion for #guard / #eval"))
  "Options worth reaching for while debugging, with the question each answers.")

(defun l4w/set-option (option)
  "Insert `set_option OPTION in' before the declaration at point.
The `in' form scopes it to one declaration, so it can stay in a commit."
  (interactive
   (list (completing-read
          "set_option: "
          (mapcar (lambda (o) (format "%-34s %s" (car o) (cdr o))) l4w/--options)
          nil nil)))
  (let ((opt (car (split-string option "  +"))))
    (beginning-of-line)
    (insert "set_option " opt " in\n")))

;;; ------------------------------------------------------------ toolchain

(defun l4w/--installed-toolchains ()
  "Toolchains elan knows about."
  (with-temp-buffer
    (call-process "elan" nil t nil "toolchain" "list")
    (let (acc)
      (goto-char (point-min))
      (while (re-search-forward "^\\(leanprover/lean4:v[0-9.]+\\)" nil t)
        (push (match-string 1) acc))
      (nreverse acc))))

(defun l4w/--pinned-toolchain ()
  "The toolchain `lean-toolchain' pins."
  (with-temp-buffer
    (insert-file-contents (l4w/--path "lean-toolchain"))
    (string-trim (buffer-string))))

(defun l4w/select-toolchain (toolchain)
  "Use TOOLCHAIN for every lean command this session.
Choose the pinned one to clear the override.  Useful for checking a
solution against a newer release than the repo pins, which is how the
`Array.mkArray' removal in 4.32 was caught."
  (interactive
   (list (completing-read
          (format "Toolchain (pinned: %s): " (l4w/--pinned-toolchain))
          (l4w/--installed-toolchains) nil t)))
  (setq l4w/toolchain (unless (equal toolchain (l4w/--pinned-toolchain)) toolchain))
  (message "lean %s" (if l4w/toolchain (concat "+" l4w/toolchain) "(pinned)")))

;;; ------------------------------------------------------------ the org document

(defun l4w/tangle ()
  "Tangle the org document to exercises/Warmup.lean."
  (interactive)
  (let ((org (l4w/--path l4w/document)))
    (with-current-buffer (find-file-noselect org)
      (when (buffer-modified-p) (save-buffer))
      (org-babel-tangle))))

(defun l4w/tangle-and-check ()
  "Tangle, then check the tangled file."
  (interactive)
  (l4w/tangle)
  (l4w/--compile (l4w/--lean-command "exercises/Warmup.lean")))

(defun l4w/export-pdf ()
  "Export the org document to PDF with the listings backend.
Mirrors the shell recipe in the document's Build section."
  (interactive)
  (require 'ox-latex)
  (let ((org-latex-src-block-backend 'listings)
        (org-latex-compiler "pdflatex")
        (org-latex-listings-langs (cons '(lean "lean") org-latex-listings-langs)))
    (with-current-buffer (find-file-noselect (l4w/--path l4w/document))
      (org-latex-export-to-pdf))))

;;; ------------------------------------------------------------ editor support

(defconst l4w/--lean4-mode-recipe
  '(lean4-mode :type git :host github :repo "leanprover-community/lean4-mode"
               :files ("*.el" "data"))
  "straight.el recipe for lean4-mode, which is not on MELPA.")

(defun l4w/--ensure-lean4-mode ()
  "Make `lean4-mode' loadable if it is installed anywhere, else install it.
Order: already loadable; a straight.el checkout; a package-vc install
under `package-user-dir' that package.el never initialized (the case
when `package-enable-at-startup' is nil, as it is with straight); then
install through straight if present, else through package-vc.  Returns
non-nil when `lean4-mode' is available afterwards."
  (or (fboundp 'lean4-mode)
      (locate-library "lean4-mode")
      (when (fboundp 'straight-use-package)
        (ignore-errors (straight-use-package l4w/--lean4-mode-recipe))
        (locate-library "lean4-mode"))
      (let* ((elpa (expand-file-name (if (boundp 'package-user-dir) package-user-dir "~/.emacs.d/elpa")))
             (dir (car (file-expand-wildcards (expand-file-name "lean4-mode*" elpa) t)))
             (autoloads (and dir (expand-file-name "lean4-mode-autoloads.el" dir))))
        (when (and autoloads (file-exists-p autoloads))
          (add-to-list 'load-path dir)
          (load autoloads nil t)
          t))
      (when (fboundp 'package-vc-install)
        (ignore-errors
          (package-vc-install "https://github.com/leanprover-community/lean4-mode")
          (locate-library "lean4-mode")))))

(defun l4w/install-lean4-mode ()
  "Install lean4-mode through straight.el or package-vc, whichever is present."
  (interactive)
  (if (l4w/--ensure-lean4-mode)
      (message "lean4-mode available: %s" (locate-library "lean4-mode"))
    (user-error "Could not install lean4-mode; see the README")))

;; Fallback major mode so .lean files are readable when lean4-mode is
;; absent.  Comments, strings and the keywords the exercises use; nothing
;; else.
(defvar l4w/lean-fallback-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?- ". 12b" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?/ ". 14" st)
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?' "_" st)
    (modify-syntax-entry ?? "_" st)
    (modify-syntax-entry ?! "_" st)
    (modify-syntax-entry ?« "(»" st)
    (modify-syntax-entry ?» ")«" st)
    (modify-syntax-entry ?⟨ "(⟩" st)
    (modify-syntax-entry ?⟩ ")⟨" st)
    st))

(defconst l4w/lean-fallback-font-lock
  `((,(regexp-opt '("def" "theorem" "lemma" "example" "inductive" "structure"
                    "instance" "class" "namespace" "end" "open" "in" "where"
                    "deriving" "partial" "termination_by" "decreasing_by"
                    "by" "fun" "match" "with" "if" "then" "else" "let" "mut"
                    "for" "while" "repeat" "break" "return" "do" "have"
                    "show" "from" "import" "variable" "universe" "abbrev"
                    "private" "protected" "noncomputable" "unsafe" "macro"
                    "syntax" "notation" "section")
                  'symbols)
     . font-lock-keyword-face)
    ("#\\(?:eval\\|check\\|guard\\|print\\|reduce\\|exit\\)\\_>" . font-lock-preprocessor-face)
    ("\\_<sorry\\_>" . font-lock-warning-face)
    ("\\_<\\(?:Nat\\|Int\\|Float\\|Bool\\|String\\|Char\\|List\\|Array\\|Option\\|Type\\|Prop\\|IO\\|Unit\\|Sort\\)\\_>"
     . font-lock-type-face)
    ("\\_<\\(?:rfl\\|simp\\|exact\\|intro\\|apply\\|cases\\|induction\\|constructor\\|omega\\|decide\\|rw\\|unfold\\|calc\\|trivial\\|assumption\\|contradiction\\|exact?\\|aesop\\)\\_>"
     . font-lock-builtin-face)))

;;;###autoload
(define-derived-mode l4w/lean-fallback-mode prog-mode "Lean4(fallback)"
  "Minimal Lean 4 mode for when lean4-mode is not installed."
  :syntax-table l4w/lean-fallback-syntax-table
  (setq-local font-lock-defaults '(l4w/lean-fallback-font-lock))
  (setq-local comment-start "-- ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "--+\\s-*")
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 2))

;; flycheck: run lean on the file itself, since a standalone exercise has
;; no Lake project and a temp copy would lose nothing.
(with-eval-after-load 'flycheck
  (flycheck-define-checker lean4-standalone
    "Check a standalone Lean 4 file with the lean binary."
    :command ("lean" source-inplace)
    :error-patterns
    ((error line-start (file-name) ":" line ":" column ": error"
            (optional "(" (id (+ (not (any ")")))) ")") ": " (message) line-end)
     (warning line-start (file-name) ":" line ":" column ": warning"
              (optional "(" (id (+ (not (any ")")))) ")") ": " (message) line-end))
    :modes (lean4-mode l4w/lean-fallback-mode))
  (add-to-list 'flycheck-checkers 'lean4-standalone t))

;;; ------------------------------------------------------------ keymap and minor mode

(defvar l4w-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c l e") #'l4w/exercise)
    (define-key map (kbd "C-c l c") #'l4w/check)
    (define-key map (kbd "C-c l r") #'l4w/run)
    (define-key map (kbd "C-c l <") #'l4w/run-with-stdin)
    (define-key map (kbd "C-c l a") #'l4w/check-all)
    (define-key map (kbd "C-c l n") #'l4w/next-sorry)
    (define-key map (kbd "C-c l p") #'l4w/prev-sorry)
    (define-key map (kbd "C-c l t") #'l4w/todo)
    (define-key map (kbd "C-c l s") #'l4w/solution)
    (define-key map (kbd "C-c l v") #'l4w/eval)
    (define-key map (kbd "C-c l k") #'l4w/check-expr)
    (define-key map (kbd "C-c l #") #'l4w/print)
    (define-key map (kbd "C-c l o") #'l4w/set-option)
    (define-key map (kbd "C-c l x") #'l4w/select-toolchain)
    (define-key map (kbd "C-c l m") #'l4w/make)
    (define-key map (kbd "C-c l g") #'l4w/tangle-and-check)
    (define-key map (kbd "C-c l P") #'l4w/export-pdf)
    (define-key map (kbd "C-c l N") #'l4w/scratch)
    (define-key map (kbd "C-c l ?") #'l4w/help)
    (define-key map (kbd "C-c C-c") #'l4w/check)
    map)
  "Keymap for `l4w-mode'.")

;;;###autoload
(define-minor-mode l4w-mode
  "Workshop commands under C-c l."
  :lighter (:eval (format " l4w[%d]" (l4w/--sorry-count)))
  :keymap l4w-mode-map)

(defun l4w/--in-repo-p ()
  "Non-nil when the current buffer's file lives under `l4w/root'."
  (and buffer-file-name
       (string-prefix-p (file-truename l4w/root)
                        (file-truename buffer-file-name))))

(defun l4w/--maybe-enable ()
  "Turn on `l4w-mode' for files in the repo."
  (when (l4w/--in-repo-p) (l4w-mode 1)))

;;;###autoload
(defun l4w/setup ()
  "Wire everything up: .lean major mode, minor mode in the repo, LSP if present.
Idempotent; call from init or once per session."
  (interactive)
  (setq compilation-scroll-output 'first-error)
  (l4w/--ensure-lean4-mode)
  (add-to-list 'auto-mode-alist
               (cons "\\.lean\\'" (if (fboundp 'lean4-mode) #'lean4-mode #'l4w/lean-fallback-mode)))
  (add-hook 'find-file-hook #'l4w/--maybe-enable)
  (when (fboundp 'lean4-mode)
    (add-hook 'lean4-mode-hook #'l4w/--maybe-enable)
    (when (fboundp 'lsp)
      ;; Register the repo as a workspace folder up front, and drop any
      ;; blocklisted ancestor.  lsp-mode checks the blocklist before the
      ;; session folders, so a blocklisted home directory (one "do not
      ;; ask again" long ago) silences the server for every file here.
      (require 'lsp-mode)
      (let ((root (directory-file-name (file-truename l4w/root))))
        (dolist (blocked (lsp-session-folders-blocklist (lsp-session)))
          (when (string-prefix-p (file-name-as-directory (file-truename blocked)) (file-name-as-directory root))
            (message "lean4-workshop: removing %s from the lsp blocklist" blocked)
            (lsp-workspace-blocklist-remove blocked)))
        (unless (member root (lsp-session-folders (lsp-session)))
          (lsp-workspace-folders-add root)))
      (add-hook 'lean4-mode-hook #'lsp)))
  (add-hook 'org-mode-hook #'l4w/--maybe-enable)
  (dolist (b (buffer-list))
    (with-current-buffer b (l4w/--maybe-enable)))
  (message "lean4-workshop: %s, lean %s, %s"
           (if (fboundp 'lean4-mode) "lean4-mode" "fallback mode (M-x l4w/install-lean4-mode)")
           (l4w/--pinned-toolchain)
           (if (fboundp 'lsp) "lsp-mode" "no LSP")))

(provide 'lean4-workshop)
;;; lean4-workshop.el ends here
