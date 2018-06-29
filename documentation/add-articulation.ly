\version "2.19.80"
\include "oll-core/package.ily"
\loadModule stylesheets.span
\relative {
  c'' d \addArticulations -! { e16 d c b a g f e d c b a }
}
\relative {
  c''4 d \addArticulations ^\f { e g, c, g'' g,, c }
}