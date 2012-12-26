;;; Copyright (C) 2012 Rocky Bernstein <rocky@gnu.org>
(eval-when-compile (require 'cl))
  
(require 'load-relative)
(require-relative-list '("../../common/track" 
			 "../../common/core" 
			 "../../common/lang")
		       "dbgr-")
(require-relative-list '("init") "dbgr-pydb-")


;; FIXME: I think the following could be generalized and moved to 
;; dbgr-... probably via a macro.
(defvar pydb-minibuffer-history nil
  "minibuffer history list for the command `pydb'.")

(easy-mmode-defmap pydb-minibuffer-local-map
  '(("\C-i" . comint-dynamic-complete-filename))
  "Keymap for minibuffer prompting of gud startup command."
  :inherit minibuffer-local-map)

;; FIXME: I think this code and the keymaps and history
;; variable chould be generalized, perhaps via a macro.
(defun pydb-query-cmdline (&optional opt-debugger)
  (dbgr-query-cmdline 
   'pydb-suggest-invocation
   pydb-minibuffer-local-map
   'pydb-minibuffer-history
   opt-debugger))

(defun pydb-parse-cmd-args (orig-args)
  "Parse command line ARGS for the annotate level and name of script to debug.

ARGS should contain a tokenized list of the command line to run.

We return the a list containing
- the command processor (e.g. python) and it's arguments if any - a list of strings
- the name of the debugger given (e.g. pydb) and its arguments - a list of strings
- the script name and its arguments - list of strings
- whether the annotate or emacs option was given ('-A', '--annotate' or '--emacs) - a boolean

For example for the following input 
  (map 'list 'symbol-name
   '(python2.6 -O -Qold ./gcd.py a b))

we might return:
   ((python2.6 -O -Qold) (pydb) (./gcd.py a b) 't)

NOTE: the above should have each item listed in quotes.
"

  ;; Parse the following kind of pattern:
  ;;  [python python-options] pydb pydb-options script-name script-options
  (let (
	(args orig-args)
	(pair)          ;; temp return from 
	(python-opt-two-args '())
	;; Python doesn't have mandatory 2-arg options in our sense,
	;; since the two args can be run together, e.g. "-C/tmp" or "-C /tmp"
	;; 
	(python-two-args '())
	;; pydb doesn't have any arguments
	(pydb-two-args '())
	(pydb-opt-two-args '())
	(interp-regexp 
	 (if (member system-type (list 'windows-nt 'cygwin 'msdos))
	     "^python[-0-9.]*\\(.exe\\)?$"
	   "^python[-0-9.]*$"))

	;; Things returned
	(annotate-p nil)
	(debugger-args '())
	(debugger-name nil)
	(interpreter-args '())
	(script-args '())
	(script-name nil)
	)

    (if (not (and args))
	;; Got nothing: return '(nil, nil)
	(list interpreter-args debugger-args script-args annotate-p)
      ;; else
      ;; Strip off optional "python" or "python182" etc.
      (when (string-match interp-regexp
			  (file-name-sans-extension
			   (file-name-nondirectory (car args))))
	(setq interpreter-args (list (pop args)))

	;; Strip off Python-specific options
	(while (and args
		    (string-match "^-" (car args)))
	  (setq pair (dbgr-parse-command-arg 
		      args python-two-args python-opt-two-args))
	  (nconc interpreter-args (car pair))
	  (setq args (cadr pair))))

      ;; Remove "pydb" from "pydb --pydb-options script
      ;; --script-options"
      (setq debugger-name (file-name-sans-extension
			   (file-name-nondirectory (car args))))
      (unless (string-match "^\\(pydb\\|cli.py\\)$" debugger-name)
	(message 
	 "Expecting debugger name `%s' to be `pydb' or `cli.py'"
	 debugger-name))
      (setq debugger-args (list (pop args)))

      ;; Skip to the first non-option argument.
      (while (and args (not script-name))
	(let ((arg (car args)))
	  (cond
	   ;; Options with arguments.
	   ((string-match "^-" arg)
	    (setq pair (dbgr-parse-command-arg 
			args pydb-two-args pydb-opt-two-args))
	    (nconc debugger-args (car pair))
	    (setq args (cadr pair)))
	   ;; Anything else must be the script to debug.
	   (t (setq script-name arg)
	      (setq script-args args))
	   )))
      (list interpreter-args debugger-args script-args annotate-p))))

(defvar pydb-command-name) ; # To silence Warning: reference to free variable
(defun pydb-suggest-invocation (debugger-name)
  "Suggest a pydb command invocation via `dbgr-suggest-invocaton'"
  (dbgr-suggest-invocation pydb-command-name pydb-minibuffer-history 
			   "python" "\\.py"))

(defun pydb-reset ()
  "Pydb cleanup - remove debugger's internal buffers (frame,
breakpoints, etc.)."
  (interactive)
  ;; (pydb-breakpoint-remove-all-icons)
  (dolist (buffer (buffer-list))
    (when (string-match "\\*pydb-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w
          (delete-window w)))
      (kill-buffer buffer))))

;; (defun pydb-reset-keymaps()
;;   "This unbinds the special debugger keys of the source buffers."
;;   (interactive)
;;   (setcdr (assq 'pydb-debugger-support-minor-mode minor-mode-map-alist)
;; 	  pydb-debugger-support-minor-mode-map-when-deactive))


(defun pydb-customize ()
  "Use `customize' to edit the settings of the `pydb' debugger."
  (interactive)
  (customize-group 'pydb))

(provide-me "dbgr-pydb-")
