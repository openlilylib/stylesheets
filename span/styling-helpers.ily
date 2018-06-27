% Helper to simplify the implementation of 'wrap functions
% wrap-span takes a list of override definitions as pairs:
% - symbol-list-or-symbol? to specify the target grob and property
% - any Scheme value for the property value

#(define (overrides-list? obj)
   (and (list? obj)
        (every
         (lambda (elt)
           (and (pair? elt)
                (symbol-list-or-symbol? (car elt))))
         obj)))

% Apply all rules from props as a \temporary \override
% before issuing the music and \revert-ing the overrides.
#(define wrap-span
   (define-music-function (props music)(overrides-list? ly:music?)
     (make-sequential-music
      (append
       (map
        (lambda (o)
          (temporary (overrideProperty (car o) (cdr o))))
        props)
       (list music)
       (map
        (lambda (o)
          #{ \revert #(car o) #})
        props)))))


