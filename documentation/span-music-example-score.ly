\include "oll-core/package.ily"
\loadModule stylesheets.span
{
  \tagSpan something \with {
    example = \score {
      { c' ( d' ) }
      \layout {
        \context { \Voice \omit Stem }
        \context { \Staff \omit TimeSignature \omit Clef \omit StaffSymbol }
      }
    }
  } { c' } d'
}