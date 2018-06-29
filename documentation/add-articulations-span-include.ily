\include "oll-core/package.ily"
\loadModule stylesheets.span
marcatoSpan =
#(define-styling-function
   #{
     \mark \markup \italic "marcato"
     \addArticulations -\marcato #music
   #})
\setSpanColor marcato #darkcyan
\setSpanFunc marcato #marcatoSpan