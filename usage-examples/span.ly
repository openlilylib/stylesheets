%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
% This file is part of openLilyLib,                                           %
%                      ===========                                            %
% the community library project for GNU LilyPond                              %
% (https://github.com/openlilylib)                                            %
%              -----------                                                    %
%                                                                             %
% Package: stylesheets                                                        %
%          ===========                                                        %
%                                                                             %
% openLilyLib is free software: you can redistribute it and/or modify         %
% it under the terms of the GNU General Public License as published by        %
% the Free Software Foundation, either version 3 of the License, or           %
% (at your option) any later version.                                         %
%                                                                             %
% openLilyLib is distributed in the hope that it will be useful,              %
% but WITHOUT ANY WARRANTY; without even the implied warranty of              %
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               %
% GNU General Public License for more details.                                %
%                                                                             %
% You should have received a copy of the GNU General Public License           %
% along with openLilyLib. If not, see <http://www.gnu.org/licenses/>.         %
%                                                                             %
% openLilyLib is maintained by Urs Liska, ul@openlilylib.org                  %
% and others.                                                                 %
%       Copyright Urs Liska, Kieren MacMillan 2018                            %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% stylesheets.span module usage examples

\version "2.19.80"

\include "oll-core/package.ily"
\loadModule stylesheets.span


% General configuration
% Uncomment to deactivate styling completely
%\setOption stylesheets.span.use-styles ##f

% Uncomment to suppress default coloring.
% Note that specific functions have to implement coloring/avoidance themselves
%\setOption stylesheets.span.use-default-coloring ##f

\paper {
  tagline = ##f
}

\markup \bold { Usage examples for the \typewriter "\\span" function }

\markup \vspace #1
\markup {
  Apply \typewriter "\\span" to a  sequential music expression.
  Fall back to default coloring.
}
\relative {
  c' d \span undefined-type { e f }
}

\markup {
  Apply \typewriter "\\span red-span" to a  sequential music expression.
  Color for \typewriter red-span has been defined.
}
\setSpanColor red-span #red
\relative {
  c' d \span red-span { e f }
}

#(define fancy-span
   (define-styling-function
     (wrap-span
      `(((Slur thickness) . 3)
        ((Slur color) . ,magenta)
        ((Beam positions) . (3 . 0)))
     music)
      ))

\markup \justify {
  Apply \typewriter "\\span fancy-span" to a  sequential music expression.
  Color is not used because a music function for the styling has been provided
  with \typewriter "\\setSpanFuncs".
}

\setSpanFunc fancy-span #fancy-span
\relative {
  c' d \span fancy-span { e8 -. [ ( f ) e f ] } g8 ( f e d )
}


#(define highlight-item-span
   (define-styling-function
     #{
       \temporary \override #item #'color = #magenta
       \mark "|->"
       #music
       \mark "<-|"
       \revert #item #'color
     #}
      ))

\markup \justify {
  Apply \typewriter "\\span highlight-item-span" to a sequential music expression
  and specify a grob type to affect. The function inserts marks at the beginning
  and the end of the music expression and only affect the given item (grob type).
  The first occurence highlights \typewriter Staff.Clef, the second \typewriter
  DynamicText. Note that the functions must implement all the business logic to
  handle different grob types on their own.
}
\setSpanFunc highlight-item-span #highlight-item-span
\relative {
  c'4 d \span highlight-item-span \with {
    item = Staff.Clef
  } { d8 -. [ ( f\p ) \clef alto e \clef treble  f\ff ] } |
  g8\mp ( f e d ) \span highlight-item-span \with {
    item = DynamicText
  } { e8-! g\sf ( a-. ) a \pp }
}

\markup \justify {
  Apply \typewriter "\\span red-span" to a single music expression (falling back
  to simple coloring). By default this applies to the \typewriter NoteEvent and
  consequently to the note head.
}
\relative {
  c'4 \span red-span d e2
}


\markup \justify {
  Apply \typewriter "\\span red-span" to a single music expression. The \typewriter
  item attribute makes the span affect the Flag. Note that this only works for
  direct elements of the note, i.e. notehead, stem or Flag. Further objects \italic
  attached to the note event are not touched.
}
\relative {
  c'4 \span red-span \with { item = Flag } d8-.\noBeam \p ( e f )
}


\markup \justify {
  Apply \typewriter "\\span red-span" and \typewriter "\\span blue-span" as post-event
  functions. They affect the immediately following item. As there is neither a function
  nor a color defined for \typewriter blue-span we have the same fallback color as
  in the first examples.
}
\relative {
  c'2 d8-.-\span red-span \p -\span blue-span ( e f ) g
}