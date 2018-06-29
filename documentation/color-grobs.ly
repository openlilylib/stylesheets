\include "oll-core/package.ily"
\loadModule stylesheets.util.styling-helpers
\relative {
  c'8 d
  \colorGrobs #'(NoteHead Beam (Staff Clef) TextScript) #red ##t
  c8 \noBeam d \clef bass b16 ( a-. g-. f ) g4 ^\markup "Highlighted"
  \colorGrobs #'(NoteHead Beam (Staff Clef) TextScript) #red ##f
  \clef tenor
  c8 \noBeam d \clef bass b16 ( a-. g-. f ) g4 ^\markup "Highlighted"
}