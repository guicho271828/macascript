(in-package :maca)
(defun indents (n)
  (loop for i below n collect 'indent))

(defparameter *miscellaneous*
  '( ;;for the evaluation of single atom at the top level
	((type string str)
	 (values `(compiled ,(format nil "\"~a\"" str)) t 'string))
	((list 'newline-and-indent)
	 (values
	  `(compiled newline ,@(indents (env-indents env)))
	  t 'newline-and-indent))
	
	((list 'sentence sentence) (rewrite m-sentence sentence))
	((list* 'sentences sentences) (rewrite m-sentences sentences))
	((type atom val) 
	 (values (m-compile env `(glue ,val)) t 'atom))

	;; ((list* 'sentence sentence) (rewrite m-js-sentence sentence))
	;; ((list* 'non-sentence sentence) (rewrite m-js-non-sentence sentence))

	((list* 'funcall op args)	 (rewrite m-function-call op args))
	((list* '--- op (as chain-arguments (list* (list* _))))
	 (rewrite m-chain-function-call op chain-arguments))

	((list* (type atom op) arguments)
	 (multiple-value-bind (lmb found-cl) (search-lambda op env)
	   (if lmb
		   (rewrite m-inline-function-call arguments lmb found-cl)
		   (rewrite m-function-call op arguments))))
	((list* scripts) 
	 (values (mapcar #'(lambda (scr) (m-compile env scr)) scripts) t 'list))
	))

(defmaca (m-function-call :environment env :is-value t) (op args)
  (with-check-cc (args)
	(with-set-temps-in-list (env args temps)
	  `(glue ,op (paren (comma ,@temps))))))

(defmaca (m-chain-function-call :is-value t) (op chain-arguments)
  (if chain-arguments
	  `(--- (funcall ,op ,@(car chain-arguments)) ,@(cdr chain-arguments))
	  op))

(defmaca (m-inline-function-call :environment env
								 :return return-as)
	(args lmb found-cl)
  (destructuring-bind (lambda-list . body) lmb
	(let ((temps (mapcar #'(lambda (x)
							 (declare (ignore x))
							 (gensym "INLINE-TMP"))
						 lambda-list))
		  (copying-script nil))
	  (loop
		 for arg in args
		 for temp in temps
		 for param in lambda-list
		 do (setf body (subst temp param body))
		 do (push temp (closure-variables found-cl))
		 do (push `(= ,temp ,arg) copying-script))
	  (if return-as 
		  `(glue (sentences ,@copying-script
							,@(1-or-2-line-set-temp body return-as))
				 (newline-and-indent))
		  (with-set-temp env (body)
			body)))))

(defmaca (m-sentence :environment env) (sent)
  (compile-let* env ((compiled-sent sent))
	(if compiled-sent					;non-nil
		`(glue (newline-and-indent) ,sent semicolon)
		`(glue ,sent))))

(defmaca m-sentences (sents)
  `(glue ,@(mapcar
			#'(lambda (sent) `(sentence ,sent))
			sents)))

(recompile)
(setf *recompile-compiler* t)