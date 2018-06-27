\version "2.19.80"
\include "oll-core/package.ily"
\loadModule stylesheets.span
#(define fancy-span
   (define-styling-function
    (wrap-span
     `(((Slur thickness) . 3)
       ((Slur color) . ,magenta)
       ((Beam positions) . (3 . 0)))
     music)))
\setSpanFunc fancy-span #fancy-span
\relative {
  c' d \tagSpan fancy-span { e8 -. [ ( f ) e f ] } g8 ( f e d )
  \tagSpan fancy-span d [ ( e ] )
}
