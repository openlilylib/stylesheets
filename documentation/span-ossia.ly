\version "2.19.80"
\include "oll-core/package.ily"
\loadModule stylesheets.span
{
  \tagSpan something \with {
    ossia-direction = #UP
    ossia-omit = Clef.TimeSignature
    ossia-music =  { d'' }
  } { c' } d'
}