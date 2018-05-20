% This is based upon an engraver example by Thomas Morley
% (http://lists.gnu.org/archive/html/lilypond-devel/2018-05/msg00058.html)
% and on information about output-attributes.class by Paul Morris
% (http://lists.gnu.org/archive/html/lilypond-devel/2018-05/msg00068.html)

\version "2.19.80"

TstEngraver =
#(lambda (context)
   (make-engraver
    (acknowledgers
     ((grob-interface engraver grob source-engraver)
      (ly:message "Grob: ~a" grob)
      (let* ((output-attributes (ly:grob-property grob 'output-attributes '()))
             (classes (assoc-get 'class output-attributes)))
        (ly:message "output-attributes: ~a" output-attributes)
        (ly:message "class: ~a" classes)
        (if classes
            (for-each
             (lambda (class)
               (case class
                 ((grey)
                  (ly:grob-set-property! grob 'color grey))
                 ((addition)
                  (ly:grob-set-property! grob 'color red)
                  (ly:grob-set-property! grob 'line-thickness 4))
                 ((deletion)
                  (ly:grob-set-property! grob 'color grey)
                 (ly:grob-set-property! grob 'dash-definition
                   (list (list 0 1 0.4 0.75))))))
             classes)))))))

\layout {
  \context {
    \Voice
    \consists \TstEngraver
  }
}

class =
#(define-music-function (grob-type name)(string? symbol-list-or-symbol?)
   #{
     \override #grob-type #'(output-attributes class) = #name
   #})

{
  \class Slur addition
  a4( b c' d')
  e' d'
  \class Tie deletion
  c'~
  \class NoteHead deletion
  c'
}
