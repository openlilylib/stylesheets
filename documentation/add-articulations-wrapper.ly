\include "oll-core/package.ily"
\loadModule stylesheets.span
marcatoSpan =
#(define-music-function (music)(ly:music?)
   #{ \addArticulations -\marcato #music #})
\relative {
  c'' d \marcatoSpan { e16 d c b a g f e d c b a }
}
