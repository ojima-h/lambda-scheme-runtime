(require json)
(require net/http-client)

(define-values (filename handler-name)
  (let* ([_handler (getenv "_HANDLER")]
         [hs (string-split _handler ":")])
    (values (string-join (drop-right hs 1) ":")
            (string->symbol (last hs)))))
(define lambda_task_root (getenv "LAMBDA_TASK_ROOT"))
(define-values (api host port)
  (let* ([_api (getenv "AWS_LAMBDA_RUNTIME_API")]
         [ps (string-split _api ":")])
    (values _api (car ps) (string->number (cadr ps)))))

;
; Error Handlers
;
(define (init-error-handler error)
  (http-sendrecv
    host
    (string-append "http://" api "/2018-06-01/runtime/init/error")
    #:port port
    #:data (with-output-to-string
            (lambda ()
              (write-json
                (hasheq 'errorMessage (exn-message error)
                        'errorType "InitializeException"))))
    #:method "POST")
  (raise error))

(define (make-invoke-error-handler request-id)
  (lambda (error)
    (http-sendrecv
      host
      (string-append "http://" api "/2018-06-01/runtime/invocation/" request-id "/error")
      #:port port
      #:data (with-output-to-string
              (lambda ()
                (write-json
                  (hasheq 'errorMessage (exn-message error)
                          'errorType . "InvokeException"))))
      #:method "POST")
    (raise error)))

;
; Load Handler
;
(define handler
  (let ([ns (make-base-namespace)])
    (parameterize ([current-namespace ns])
      (namespace-require 'racket ns)
      (load filename))
    (namespace-variable-value handler-name #t #f ns)))

;
; Event Loop
;
(let loop ()
  (define-values (status _headers body)
    (http-sendrecv
      host
      (string-append "http://" api "/2018-06-01/runtime/invocation/next")
      #:port port))

  (define headers
    (make-hash
      (map
        (lambda (v)
          (let* ([vs (string-split (bytes->string/utf-8 v) ":" #:trim? #f)]
                 [key (string-trim (car vs))]
                 [val (string-trim (string-join (cdr vs) ":"))])
            (cons key val)))
        _headers)))
  (define requet-id (hash-ref headers "Lambda-Runtime-Aws-Request-Id"))

  (define event (read-json body))
  (define context (hasheq))

  (define response (handler event context))

  (http-sendrecv
    host
    (string-append "http://" api "/2018-06-01/runtime/invocation/" requet-id "/response")
    #:port port
    #:data
      (cond
        [(or (hash? response) (list? response))
          (with-output-to-string (lambda () (write-json response)))]

        [(void? response) ""]

        [else (~a response)])
    #:method "POST")

  (loop))
