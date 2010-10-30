(require 'load-relative)
(require-relative-list
 '("send" "track" "cmdbuf") "dbgr-")

(defun dbgr-tb-init ()
  (interactive)
  (let ((buffer (current-buffer))
  	(cmdbuf (dbgr-get-cmdbuf))
  	(process)
  	)
    (with-current-buffer-safe cmdbuf
      (setq process (get-buffer-process (current-buffer)))
      (dbgr-cmdbuf-info-in-srcbuf?= dbgr-cmdbuf-info 
    				   (not (dbgr-cmdbuf? buffer)))
      (setq dbgr-track-divert-output? 't)
      (dbgr-send-command "backtrace")
      (let ((bt-buffer (get-buffer-create
			(format "*%s backtrace*" (buffer-name))))
	    (divert-string dbgr-track-divert-string)
	    )
	(with-current-buffer bt-buffer
	  (setq buffer-read-only nil)
	  (delete-region (point-min) (point-max))
	  (if divert-string (insert divert-string))
	  )
	)
    )
  )
)
