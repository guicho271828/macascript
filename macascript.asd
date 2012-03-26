

(defsystem macascript
    :description "Yet another Javascript compiler : Macascript"
    :version "0.2"
    :author "Masataro Asai <guicho2.71828@gmail.com>"
    :licence "Public Domain"
	:components ((:file "maca-core")
				 (:file "fundamentals")
				 (:file "functions")
				 (:file "iterations")
				 (:file "conditions")
				 (:file "ops")
				 (:file "literals")
				 (:file "misc"))
	:serial t)


;; (recompile)
;; (setf *recompile-compiler* t)