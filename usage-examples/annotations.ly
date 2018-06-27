\include "oll-core/package.ily"
\loadModule stylesheets.span
\loadModule scholarly.annotate
{
  \tagSpan dubious \with {
    ann-type = critical-remark
    author = "Harry Potter"
    message = "I'm a generated footnote"
  } { c' d' e' f' }
}
