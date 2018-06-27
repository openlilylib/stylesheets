\include "oll-core/package.ily"
\loadModule stylesheets.span
{
  \tagSpan dubious \with {
    footnote-text = "I'm a generated footnote"
    footnote-offset = #'(2 . -1)
  } { c' d' e' f' }
  c''4 -\tagSpan crazy \with {
    footnote-text = "Can attach to post-events"
    footnote-offset = #'(1 . 2)
  } -!
  \tagSpan funny \with {
    message = "The message will be used as footnote text and custom marks can be used"
    footnote-offset = #'(1 . -4)
    footnote-mark = "*"
  }
  c''2.
}
