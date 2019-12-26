\version "2.19.80"
\include "oll-core/package.ily"
\loadModule stylesheets.span
#(define reverse-span
   (define-styling-function
    (let
    ((dummy (displayMusic music)))
    (make-sequential-music
     
      (ly:music-property music 'elements)
      )
      
    )))
\setSpanFunc reverse #reverse-span
music = \relative {
  c' c g' g | a a g2 | f4 f e e | d d c2
}
<<
  \new Staff \music
  \new Staff { \tagSpan reverse { c' c g' g | a a g2 | f4 f e e | d d c2 } }
>>
