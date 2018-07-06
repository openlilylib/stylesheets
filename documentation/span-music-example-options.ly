\include "oll-core/package.ily"
\loadModule stylesheets.span
{
  \tagSpan something \with {
    example-alignment = #LEFT
    example-direction = #DOWN
    example =  { d'' }
  } { c' } d'
}