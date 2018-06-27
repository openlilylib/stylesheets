\include "oll-core/package.ily"
\loadModule stylesheets.span
{
  \span dubious \with {
    footnote-text = "I'm a generated footnote"
    footnote-offset = #'(2 . -1)
  } { c' d' e' f' }
  c''4 -\span crazy \with {
    footnote-text = "Can attach to post-events"
    footnote-offset = #'(1 . 2)
  } -!
  \span funny \with {
    message = "The message will be used as footnote text and custom marks can be used"
    footnote-offset = #'(1 . -4)
    footnote-mark = "*"
  }
  c''2.
}
