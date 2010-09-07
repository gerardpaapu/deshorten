#lang scheme
(require (planet bzlib/http:1:0)
         (planet dherman/json:3:0)
         web-server/servlet
         web-server/servlet-env)


(define (redirect? response)
  (let ([code (http-client-response-code response)])
    (<= 300 code 306)))

(define (deshorten url)
  (let ([resp (http-get url)])
    (if (redirect? resp)
        (dict-ref (http-client-response-headers resp) "Location")
        url)))

(define *cache* (make-hash))

(define (deshorten/caching url)
  (if (hash-has-key? *cache* url)
      (hash-ref *cache* url)
      (let ([long (deshorten url)])
        (hash-set! *cache* url long)
        long)))

(define (thread-receive-all)
  (cond [(thread-try-receive) =>
         (lambda (msg)
           (cons msg (thread-receive-all)))]
        [else '()]))

(define (results->hash results)
  (define (fn ls)
    (match-define (list short long) ls)
    (cons (string->symbol short)
          long))
  (make-immutable-hash (map fn results)))

(define (p/map fn ls)
  (let* ([parent (current-thread)]
         [child  (lambda (item)
                   (thread (lambda ()
                             (thread-send parent (fn item)))))])
    (for-each sync (map child urls))
    (thread-receive-all)))

(define (deshorten* urls)
  (results->hash (p/map (lambda (url)
                          (cons url (deshorten/caching url)))
                        urls)))

(define (js-response str)
  (make-response/full 200 #"OK" (current-seconds)
                      #"application/javascript" '()
                      (list (string->bytes/utf-8 str))))

(define (start req)
  (let* ([url      (request-uri req)]
         [query    (url-query url)]
         [shorts   (dict-ref query 'short)]
         [callback (dict-ref query 'callback)])
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
