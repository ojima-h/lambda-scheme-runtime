;;; https://mitpress.mit.edu/sites/default/files/sicp/full-text/book/book-Z-H-24.html#%_sec_3.5
;;;
;;; Exercise 3.69.
;;; Write a procedure triples that takes three infinite streams, S, T, and U, and
;;; produces the stream of triples (Si,Tj,Uk) such that i < j < k. Use triples to
;;; generate the stream of all Pythagorean triples of positive integers, i.e.,
;;; the triples (i,j,k) such that i < j and i2 + j2 = k2.

(require json)

(define integers
  (stream-cons 0 (stream-map (lambda (x) (+ x 1)) integers)))
(define integers+ (stream-rest integers))

(define (interleave s1 s2)
  (if (stream-empty? s1)
      s2
      (stream-cons (stream-first s1)
                   (interleave s2 (stream-rest s1)))))

(define (pairs s t)
  (stream-cons
   (list (stream-first s) (stream-first t))
   (interleave
    (stream-map (lambda (x) (list (stream-first s) x))
                (stream-rest t))
    (pairs (stream-rest s) (stream-rest t)))))

(define (triples s t u)
  (let ((ss (stream-map (lambda (x) (cons (stream-first s) x)) (pairs t u))))
    (stream-cons
      (stream-first ss)
      (interleave
        (stream-rest ss)
        (triples (stream-rest s) (stream-rest t) (stream-rest u))))))

(define pythagorean-triples
  (stream-filter
    (lambda (x) (= (+ (expt (car x) 2)
                      (expt (cadr x) 2))
                   (expt (caddr x) 2)))
    (triples
      integers+
      integers+
      integers+)))

(define (handler event context)
  (let* ((n (string->number (hash-ref (hash-ref event 'queryStringParameters) 'length)))
         (response (hash 'result (stream->list (stream-take pythagorean-triples n)))))
    (hash
      'headers (hash 'Content-Type "application/json")
      'body (with-output-to-string (lambda () (write-json response))))))
