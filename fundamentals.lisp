(in-package :maca)

(defun value (arg)
  (list 'value arg))

(defmacro value-if (need-value arg)
  `(if ,need-value
	   (list 'value ,arg)
	   ,arg))


;; --------------------------------
;; fundamentals

;; these operators are just meant to be used by the compiler
;; don't use it
(defparameter *fundamentals*
  '(;;((list 'glue 'nil 'semicolon 'newline) (rewrite m-glue nil))
	((list* 'glue clauses)              (rewrite m-glue clauses))
	((list 'paren (list 'paren clause)) (rewrite m-redundant-paren clause))
	((list 'paren clause)               (rewrite m-paren clause))
	((list 'bracket clause)             (rewrite m-bracket clause))
	((list* 'comma clauses)             (rewrite m-comma clauses))
	((list 'blk clause)                 (rewrite m-block clause))
	((list 'value arg)                  (rewrite m-need-value arg))
	((list '// str)                     (rewrite m-comment str))
	((list 'raw-string str)             (rewrite m-raw-string str))))

(defun m-glue (s env need-value args)
  (declare (ignore need-value))
  (format s "~{~a~}"
		  (mapcar
		   #'(lambda (arg)
			   (let ((true-arg (or (cdr (assoc arg *aliases*)) arg)))
				 (typecase true-arg
				   (null "") 
				   (cons (m-compile nil env nil true-arg))
				   ;;						   (atom (m-compile nil env true-arg))
				   (string (format nil "\"~a\"" true-arg))
				   (symbol (let ((str (symbol-name true-arg)))
							 (cond
							   ((char= (aref str 0) #\@) (m-compile nil env nil true-arg))
							   ((every #'(lambda (c) (or (not (both-case-p c))
														 (upper-case-p c)))
									   str)
								 (string-downcase str))
							   (t str))))
				   (t (format nil "~a" true-arg)))))
			   args)))

(defmaca m-paren (arg)
  `(glue lparen ,arg rparen))
(defun m-redundant-paren (s env need-value arg)
  (declare (ignore need-value))
  (m-compile s env nil `(paren ,arg)))
(defmaca m-bracket (arg)
  `(glue lbracket ,arg rbracket))
(defmaca m-block (arg)
  `(glue lbrace newline ,arg rbrace))
(defmaca m-comma (args)
  `(glue ,@(mapcan
			#'(lambda (arg) (list arg 'comma))
			(butlast args))
		 ,(if need-value
			  `(value ,@(last args))
			  (car (last args)))))

(defun m-comment (s env need-value string)
  (declare (ignore need-value))
  (declare (ignore env))
  (format s "/* ~a */~%" string))
(defun m-raw-string (s env need-value string)
  (declare (ignore need-value))
  (declare (ignore env s))
  string)

(defmaca m-need-value (arg)
  (setf next-need-value t)
  arg)
