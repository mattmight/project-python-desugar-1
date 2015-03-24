#lang racket


(require pywalk)




;;; Normalize return
(define (canonicalize-return stmt)
  (match stmt
    [`(Return)  (list '(Return (NameConstant None)))]
    [else       (list stmt)]))


  

;;; Lift defaults
(define (lift-defaults stmt)
  
  ; <local definitions go here>
  
  ; A helper:
  (define (strip-defaults! arguments)
    (match arguments
      [`(Arguments
         (args . ,ids)
         (arg-types . ,arg-types)
         (vararg ,vararg . ,vararg-type) 
         (kwonlyargs . ,kwonlyargs) 
         (kwonlyarg-types . ,kwonlyarg-types)
         (kw_defaults . ,kw_defaults)
         (kwarg ,kwarg . ,kwarg-type)
         (defaults . ,defaults))
       ;=>
       (error "put something here!")]))
  
       
  (match stmt
    
    [`(FunctionDef 
       (name ,id)
       (args ,args)
       (body . ,body)
       (decorator_list . ,decorators)
       (returns ,returns))
     
     (error "reconstitute the function def")]
     
    [else (list stmt)]))







;;; Lift annotations
(define (lift-annotations stmt)

  ; <similar local definitions as lift-defaults>
  
  (match stmt
    [`(FunctionDef 
       (name ,id)
       (args ,args)
       (body . ,body)
       (decorator_list . ,decorators)
       (returns ,returns))
     
     (error "reconstitute the FunctionDef")]
    
    [else (list stmt)]))

       
       
    
    

;;; Lift decorators
(define (lift-decorators stmt)
  
  (define (apply-decorators id decs)
    (match decs
      ['()  '()]
      [(cons dec rest)
       (cons (assign `(Name ,id) (call dec (list `(Name ,id))))
             (apply-decorators id rest))]))
  
  (match stmt
    [`(FunctionDef 
       (name ,id)
       (args ,args)
       (body . ,body)
       (decorator_list . ,decorators)
       (returns ,returns))
     
     (error "finish me")]
     
     [`(ClassDef
        (name ,id)
        (bases . ,bases)
        (keywords . ,keywords)
        (starargs ,starargs)
        (kwargs ,kwargs)
        (body . ,body)
        (decorator_list . ,decorators))
      
      (error "finish me")]

    [else     (list stmt)]))
    
    
    


;;; Flatten assignments
(define (flatten-assign stmt)
  (match stmt
    [`(Assign (targets (Name ,id)) (value ,expr))
     (list stmt)]
    
    [`(Assign (targets (,(or 'Tuple 'List) . ,exprs)) (value ,expr))
     ; TODO: split tuple assignments apart
     (error "finish me")]
       
    [`(Assign (targets ,t1 ,t2 . ,ts) (value ,expr))
     (error "finish me")]
     
    [else (list stmt)]))



;;; Convert for to while
(define (eliminate-for stmt)
  (match stmt
    
    ; (For (target <expr>) (iter <expr>) (body <stmt>*) (orelse <stmt>*))
    [`(For (target ,target)
           (iter ,iter)
           (body . ,body)
           (orelse . ,orelse))
     
     (error "todo: build a while stmt")]
              
    
    [else    (list stmt)]))


;;; Insert locals


;;; Insert locals adds a (Local <var> ...) statement to the top
;;; of function and class bodies, so that you know which variables
;;; are assigned in that scope.
(define (insert-locals stmt)
  (match stmt
    
    [`(FunctionDef 
       (name ,id)
       (args ,args)
       (body . ,body)
       (decorator_list . ,decorators)
       (returns ,returns))
     
     (list
      `(FunctionDef 
       (name ,id)
       (args ,args)
       (body (Local ,@(set->list (locally-assigned body))) . ,body)
       (decorator_list . ,decorators)
       (returns ,returns)))]
    
    [`(ClassDef
       (name ,id)
       (bases . ,bases)
       (keywords . ,keywords)
       (starargs ,starargs)
       (kwargs ,kwargs)
       (body . ,body)
       (decorator_list . ,decorators))
     (append
      (list 
       `(ClassDef
         (name ,id)
         (bases ,@bases)
         (keywords ,@keywords)
         (starargs ,starargs)
         (kwargs ,kwargs)
         (body (Local ,@(set->list (locally-assigned body))) ,@body)
         (decorator_list . ,decorators))))]
       
    [else (list stmt)]))
     
      
        



;;; Eliminate classes

(define (eliminate-classes-expr expr . _)
  
  ; Store the fields in a dictionary:
  (define $fields '(Name __dict__))

  ; If it's a class variable, replace it with a dictionary look-up:
  (match expr
    [`(Name ,var) 
     ; =>
     (if (eq? (var-scope) 'class)
         `(Subscript ,$fields (Index (Str ,(symbol->string var))))
         expr)]
    
    [else expr]))



(define (eliminate-classes-stmt stmt)
  
  (match stmt
    [`(ClassDef
       (name ,id)
       (bases . ,bases)
       (keywords . ,keywords)
       (starargs ,starargs)
       (kwargs ,kwargs)
       (body . ,body)
       (decorator_list . ,decorators))
     
     (error "complete me!")]
    
    [else  (list stmt)]))

       
      

(define prog (read))



(set! prog (walk-module prog #:transform-stmt insert-locals))

(set! prog (walk-module prog #:transform-stmt canonicalize-return))

;; Uncomment each of these as you finish them:

;(set! prog (walk-module prog #:transform-stmt lift-decorators))

;(set! prog (walk-module prog #:transform-stmt lift-defaults))

;(set! prog (walk-module prog #:transform-stmt lift-annotations))

;(set! prog (walk-module prog #:transform-stmt eliminate-for))

;(set! prog (walk/fix prog #:transform-stmt flatten-assign))


;(set! prog (walk-module prog #:transform-expr/bu eliminate-classes-expr))

;(set! prog (walk-module prog #:transform-stmt eliminate-classes-stmt))


(write prog)

