#lang scheme
(require (planet bzlib/http:1:0)
         (planet dherman/json:3:0)
         web-server/servlet
         web-server/servlet-env)


(define (redirect? response)
  (let ([code (http-client-response-code response)])
    (<= 300 code 306)))

(define (get-prop k l)
  (let ([result (assoc k l)])
    (and result (cdr result))))


(define (deshorten url)
  (let ([resp (http-get url)])
    (if (redirect? resp)
        (get-prop "Location" (http-client-response-headers resp))
        url)))

(define *cache* (make-hash))

(define (deshorten/caching url)
  (if (hash-has-key? *cache* url)
      (hash-ref *cache* url)
      (let ([long (deshorten url)])
        (hash-set! *cache* url long)
        long)))

(define (thread-receive-all)
  (let ([msg (thread-try-receive)])
    (if msg
        (cons msg (thread-receive-all))
        '())))

(define (results->hash results)
  (define (fn ls)
    (match-define (list short long) ls)
    (cons (string->symbol short)
          long))
  (make-immutable-hash (map fn results)))

(define (deshorten* urls)
  (let* ([parent (current-thread)]
         [child  (lambda (url)
                   (thread (lambda ()
                             (thread-send parent `(,url ,(deshorten/caching url))))))])
    (for-each sync (map child urls))
    (results->hash (thread-receive-all))))

(define (js-response str)
  (make-response/full 200 #"OK" (current-seconds)
                      #"application/javascript" '()
                      (list (string->bytes/utf-8 str))))

(define (start req)
  (let* ([url      (request-uri req)]
         [query    (url-query url)]
         [shorts   (get-prop 'short query)]
         [callback (get-prop 'callback query)])
    (js-response
     (if (and shorts callback)
         (let ([data (deshorten* (regexp-split #rx"," shorts))])
           (string-append callback "(" (jsexpr->json data) ")"))
         "/* the format is http://hostname/?short=foo,...&callback=callback */"))))

(define (serve-deshortener)
  (serve/servlet start
                 #:servlet-path "/"
                 #:launch-browser? #f
                 #:listen-ip #f))