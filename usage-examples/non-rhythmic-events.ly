\version "2.19.80"
\include "oll-core/package.ily"
\loadModule stylesheets.span
{
  %a' \span something \with { item = Staff.KeySignature } \key a \major a'
  %\once \override Staff.OttavaBracket.color = #red
  \span something
  \clef bass
  \ottava 1
  c'' d''
}