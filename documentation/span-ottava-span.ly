\version "2.19.80"
\include "oll-core/package.ily"
\loadModule stylesheets.span
#(define ottava-span
   (define-styling-function
    #{
      \ottava 1
      #music
      \ottava 0
    #}))
\setSpanFunc ottava #ottava-span
\relative {
  c'' e \tagSpan ottava { g g } | c,1
}
