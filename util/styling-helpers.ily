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

% stylesheets.util (styling-helpers)


% Color or uncolor the given grob types by creating a list of \overrides
% - grob-names: a list of grob names
% - col: the color to be used
% - on: a boolean, if ##f switch coloring *off* again
%   note that col has to be supplied even for *un*coloring.
colorGrobs =
#(define-music-function (grob-names col on)(list? color? boolean?)
   (make-sequential-music
    (map
     (lambda (gn)
       (if on
           #{ \temporary \override #gn . color = #col #}
           #{ \revert #gn . color #}))
     grob-names)))

% Predicate checking for a list that is *not* a color.
% Required to distinguish the optional argument in colorMusic
#(define (list-no-color? obj)
   (and (list? obj)
        (not (every number? obj))))

% Color all grobs in the given music expression
% This is not the most efficient function since it creates overrides
% for *all* registered grob types. But the list of grob names is only
% generated once upon loading and then cached in the closure.
colorMusic =
#(let ((grob-names (map car all-grob-descriptions)))
   (define-music-function (grobs my-color music)
     ((list-no-color?) color? ly:music?)
     (let ((grob-list
            (if (and grobs (not (null? grobs))) grobs grob-names)))
       (make-sequential-music
        (list
         (colorGrobs grob-list my-color #t)
         music
         (colorGrobs grob-list my-color #f))))))




% Helper to simplify the implementation of 'wrap functions
% wrapSpan takes a list of override definitions as pairs:
% - symbol-list-or-symbol? to specify the target grob and property
% - any Scheme value for the property value

#(define (overrides-list? obj)
   (and (list? obj)
        (every
         (lambda (elt)
           (and (pair? elt)
                (symbol-list-or-symbol? (car elt))))
         obj)))

% Apply all rules from props as a \temporary \override
% before issuing the music and \revert-ing the overrides.
#(define wrapSpan
   (define-music-function (props music)(overrides-list? ly:music?)
     (make-sequential-music
      (append
       (map
        (lambda (o)
          #{ \temporary \override #(car o) = #(cdr o) #})
        props)
       (list music)
       (map
        (lambda (o)
          #{ \revert #(car o) #})
        props)))))


% Add the same articulation to all notes and chords in a music expression.
% Works with all unary articulations, dynamics or markup.
% - articulation
%   a single post-event music expression
% - music
%   can be sequential music or a single event
addArticulations =
#(define-music-function (articulation music)(ly:music? ly:music?)
   (let*
    ((_elts (ly:music-property music 'elements))
     ;; wrap single music expression to a list if necessary
     (elements (if (not (null? _elts)) _elts (list music))))
    (for-each
     (lambda (elt)
       (let*
        ((types (ly:music-property elt 'types))
         (is-chord (memq 'event-chord types))
         (anchor (if (or is-chord (memq 'note-event types)) elt #f)))
        (cond
         (is-chord
          ;; append the articulation as a separate element to the event chord
          (ly:music-set-property! anchor 'elements
            (append
             (ly:music-property anchor 'elements)
             (list articulation))))
         (anchor
          ;; add the articulation to the anchor's articulations
          (let ((artics (ly:music-property anchor 'articulations)))
            (ly:music-set-property! anchor 'articulations
              (append artics (list articulation))))))))
     elements)
    music))
