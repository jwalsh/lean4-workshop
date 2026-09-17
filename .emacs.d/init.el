;;; init.el --- isolated Emacs profile for lean4-workshop  -*- lexical-binding: t; -*-

;; Launched by bin/l4w-emacs as `emacs -nw --init-directory .emacs.d`.
;; Everything installs under .emacs.d/elpa, which is gitignored; your own
;; ~/.emacs.d is never read or written.  First launch fetches lsp-mode,
;; lsp-ui, company, flycheck and lean4-mode; later launches are instant.

;;; Code:

;; Pin isolation to this file's own location regardless of how it was
;; loaded.  `--init-directory` already sets `user-emacs-directory`
;; before this runs, but loading this file directly from another
;; running Emacs (`M-x load-file`, `eval-buffer`) leaves it pointing at
;; that Emacs's own ~/.emacs.d, which sends `package-install` and
;; `custom-file` there instead — real pollution of a real config, not
;; hypothetical: it happened, see the incident this line fixes.
(setq user-emacs-directory
      (file-name-directory (or load-file-name buffer-file-name
                                (error "init.el: can't find my own path"))))

(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function #'ignore
      custom-file (expand-file-name "custom.el" user-emacs-directory)
      ;; This machine's libgccjit cannot invoke gcc, so JIT native
      ;; compilation only burns CPU and pops warnings.  Byte-code is fine.
      native-comp-async-report-warnings-errors 'silent
      native-comp-jit-compilation nil
      native-comp-enable-subr-trampolines nil
      package-user-dir (expand-file-name "elpa" user-emacs-directory)
      package-archives '(("gnu"    . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa"  . "https://melpa.org/packages/")))

(let ((backups (expand-file-name "backups/" user-emacs-directory)))
  (make-directory backups t)
  (setq backup-directory-alist `(("." . ,backups))
        auto-save-file-name-transforms `((".*" ,backups t))
        auto-save-list-file-prefix (expand-file-name "auto-save-list/" user-emacs-directory)
        lock-file-name-transforms `((".*" ,backups t))))

(package-initialize)

(defvar l4w-profile/packages '(lsp-mode lsp-ui company flycheck magit-section keycast)
  "Packages the profile needs from the archives.")

(let ((missing (seq-remove #'package-installed-p l4w-profile/packages)))
  (when (or missing (not (package-installed-p 'lean4-mode)))
    (package-refresh-contents))
  (mapc #'package-install missing)
  (unless (package-installed-p 'lean4-mode)
    (package-vc-install "https://github.com/leanprover-community/lean4-mode")))

;; Repo support library: C-c l ... bindings, check/run/eval, sorry navigation.
(load (expand-file-name "../lean4-workshop.el" user-emacs-directory) nil t)

;; Fail in place: diagnostics inline next to the offending line, goals on
;; hover, completion.  No breadcrumb bar, no snippets.
(setq lsp-headerline-breadcrumb-enable nil
      lsp-enable-snippet nil
      lsp-ui-sideline-show-diagnostics t
      lsp-ui-sideline-show-hover nil
      lsp-ui-doc-enable nil
      lsp-signature-auto-activate nil
      lsp-idle-delay 0.3
      company-idle-delay 0.2
      company-minimum-prefix-length 2)
(add-hook 'lsp-mode-hook #'company-mode)
(add-hook 'lsp-mode-hook #'lsp-ui-mode)

;; The Lean server sends workspace/inlayHint/refresh; lsp-mode has no
;; handler for it and logs a warning per request, which pops *Warnings*
;; under the editor every few seconds.  Acknowledge it and move on.
(with-eval-after-load 'lean4-mode
  (dolist (id '(lean4-lsp lean4-lsp-tramp))
    (when-let* ((client (gethash id lsp-clients)))
      (puthash "workspace/inlayHint/refresh" (lambda (_workspace _params) nil)
               (lsp--client-request-handlers client)))))

(l4w/setup)

;; Show keystrokes in the header line, leaving the mode line free for
;; Lean/LSP status (mode, server port, sorry count, flycheck counts).
;; Mainly useful when this session is being driven or watched rather
;; than typed into directly.
(require 'keycast)
(if (fboundp 'keycast-header-line-mode) (keycast-header-line-mode 1) (keycast-mode 1))

(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(show-paren-mode 1)
(column-number-mode 1)
(global-set-key (kbd "C-c l ?") #'l4w/help)

(when (file-exists-p custom-file) (load custom-file nil t))
;;; init.el ends here
