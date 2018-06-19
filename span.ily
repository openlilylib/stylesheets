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

% stylesheets.span module
%
% Provides the function \span <type> <attrs> <mus>
% to encode and highlight "spans" of music.
% A span may enclose a single element (also accessible as
% post-event "\tweak") or a sequential music expression.
% If highlighting functions are provided they will be applied
% to the enclosed music.

\loadModule oll-core.util.color-music

% Optional target grob type for the tweak
% Either a symbol, a <context>.<grob> symbol-list or the boolean #f
#(define (span-item? obj)
   (or (symbol-list-or-symbol? obj)
       (and (boolean? obj) (not obj))))

% Define a new music property that will hold information about the span.
% This is not directly used within the stylesheets.span module but can
% be useful for others, for example in the scholarly.editorial-markup module.
#(set-object-property! 'span-type 'music-type? symbol?)
#(set-object-property! 'span-type 'music-doc
   "Store the type of a span")


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration and default behaviour

% Toggle the application of editorial command styling in general
\registerOption stylesheets.span.use-styles ##t

% Toggle the automatic coloring
% When ##t (default) all span types without defined highlighting functions
% will fallback to the "default" behaviour: coloring all grobs
% with the type's defined span-color (or a general fallback color).
\registerOption stylesheets.span.use-default-coloring ##t

% List of colors for the different editorial commands
% If for a given command no color is defined (which is initially the case)
% the fallback 'default will be used instead.
\registerOption stylesheets.span.span-colors
#`((default . ,darkmagenta))

% Retrieve the highlighting color for the given span type.
% If for the requested type no color is stored return the color for 'default
getSpanColor =
#(define-scheme-function (type)(symbol?)
   (let ((colors (getOption '(stylesheets span span-colors))))
     (or (assoc-ref colors type)
         (assoc-ref colors 'default))))

% Set the highlighting color for a given edit type
setSpanColor =
#(define-void-function (type col)(symbol? color?)
   (setChildOption '(stylesheets span span-colors) type col))



%%%%%%%%%%%%%%%%%%%%%%%%
% Styling functions

%{
  Spans are typically highlighted through coloring during the editing
  process, but additionally their purpose is to provide persistent
  visual styling. Note that while the typical approach to doing this
  is tweaking properties it's also possible to *insert* additional
  score elements before or after the span (for example rehearsal marks
  or text spanners).

  Styling functions come in pairs: one that is applied to a
  sequential music expression, the other is applied as a tweak.
  Styling functions expect three arguments:
  - type (symbol?)
    the span type, to look up values like colors etc.
  - item (span-item?)
    Optional "target". If ##f then the tweak isn't targeted at a specific
    grob type. Otherwise the grob type or context.grob-type list is read.

  Within this module two pairs of basic styling functions are defined:
  style-default[-seq|-tweak] and style-noop.
  The default functions will simply color all grobs with the type-
  specific color, while noop simply returns the unaltered music.
  These are used for default highlighting or *no* highlighting.

  The function style-noop can be used anywhere a function is not
  needed, e.g. as a tweak function when only sequential behaviour
  is needed.
%}

#(define style-default-seq
   (define-music-function (type item mus)
     (symbol? span-item? ly:music?)
     (if item
         ;; colorMusic from oll-core.color-music
         (colorMusic (list item) (getSpanColor type) mus)
         (colorMusic (getSpanColor type) mus))))

#(define style-default-tweak
   (define-music-function (type item mus)
     (symbol? span-item? ly:music?)
     (let ((item (if (symbol? item) (list item) item))
           (target (if item (list item 'color) 'color)))
       #{ \tweak #target #(getSpanColor type) #mus #})))

#(define style-noop
   (define-music-function (type item mus)(symbol? span-item? ly:music?)
     mus))

% List of highlighting function pairs.
% The two predefined items should not be changed,
% additional functions to support specific edit types
% may be stored using \setEditFuncs below.
\registerOption stylesheets.span.functions
#`((default ,(cons style-default-seq style-default-tweak))
   (noop ,(cons style-noop style-noop)))


% Retrieve a pair of highlighting functions for the given edit-type
% If highlighting is switched off return the <noop> functions
% If a function pair is present for the given type return the
% corresponding pair, otherwise the <default> pair.
getSpanFuncs =
#(define-scheme-function (type)(symbol?)
   (let ((functions (getOption '(stylesheets span functions))))
     (car
      (or (assq-ref functions type)
          (assq-ref functions
            (if (getOption '(stylesheets span use-default-coloring))
                'default
                'noop))))))

% Store a pair of highlighting functions for a given edit-type
% Both functions must be music-functions expecting a <type> symbol
% and a music expression. The <highlight-func> will be applied
% to sequential music expressions while <tweak-func> is applied
% to single music elements like note-events or other \tweak-able items
setSpanFuncs =
#(define-void-function (type highlight-func tweak-func)(symbol? procedure? procedure?)
   (setChildOption '(stylesheets span functions) type
     (list (cons highlight-func tweak-func))))


% Create and return a basic alist describing a span. Can be used to build
% an input-annotation for scholarly.annotate

% with the attributes given
% in the \with {} block (if any) plus some more calculated ones:
% - is-sequential?
%   to discern between edits/annotations that have to be treated with \tweak
% - context-id
%   Set up a reasonable default value if no better data can be inferred
%   from the actual context in the engraver:
%   Initially 'context-id is a string composed from the input file and the
%   directory containing it: <directory>.<file>
% - span-type
%   is simply stored in the annotation
% - location
%   is also stored in the annotation.
#(define (make-span-description attrs span-type location mus)
   (let*
    ;
    ; TODO: use type-checking provided for context-mod->props
    ;
    ((annot (if attrs (context-mod->props attrs) '()))
     (is-sequential? (not (null? (ly:music-property mus 'elements))))
     (_input-file (string-split (car (ly:input-file-line-char-column location)) #\/ ))
     ;; fallback context name is built from containing directory and filename
     (context-id
      (if (= 1 (length _input-file))
          ;; this happens when the document is called with a relative path
          ;; from the current directory => no parent available
          ;; solution: usethe last element of the current working directory
          (string-join (list (last (os-path-cwd-list)) (last _input-file)) ".")
          ;; absolute or longer relative path, take last two elements
          (string-join (list-tail _input-file (- (length _input-file) 2)) "."))))
    ;; add several manual properties to the given <attrs>
    (append annot
      `((is-sequential? . ,is-sequential?)
        (span-type . ,span-type)
        (location . ,location)
        (context-id . ,context-id)))))


% Retrieve the styling information corresponding to the span type
% and apply them to the music expression.
% Distinguishes between sequential and atomic music expressions
% and calls the appropriate span function.
#(define format-span
   (define-music-function (mus annot)(ly:music? alist?)
     (if (getOption '(stylesheets span use-styles))
         (let*
          ((item
            (let ((i (assoc-ref annot 'item)))
              (if (and i (string? i)) (string->symbol i) i)))
           (span-type (assoc-ref annot 'span-type))
           (edit-func (if (assq-ref annot 'is-sequential?)
                          (car (getSpanFuncs span-type))
                          (cdr (getSpanFuncs span-type)))))
          (ly:music-set-property! mus 'type span-type)
          (edit-func span-type item mus))
         mus)))


% Encode a \span like a <span class=""> in HTML.
% Typically used to markup up some single or sequential music expression
% to "be" something.
% Apart from the encoding aspect \span typically produces some visual highlighting,
% either temporarily during the editing process or as a persistent styling.
% Arguments:
% - span-type (symbol?)
%   specify the type of case, has
% - attrs (optional)
%   \with {} block with further specification of the case.
%   Currently only 'item is supported, used for specifying a target grob-type
% - mus (mandatory)
%   the music to be annotated
%
% The function works as a standalone music function or as a post-event.
span =
#(define-music-function (span-type attrs mus)
   (symbol? (ly:context-mod?) ly:music?)
   (let*
    ((annot (make-span-description attrs span-type (*location*) mus)))
    (format-span mus annot)))
