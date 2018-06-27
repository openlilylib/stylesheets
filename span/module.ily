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

% Define a new music property that will hold information about the span.
% This is not directly used within the stylesheets.span module but can
% be useful for others, for example in the scholarly.editorial-markup module.
#(set-object-property! 'span-annotation 'music-type? alist?)
#(set-object-property! 'span-annotation 'music-doc
   "Properties of a \\span expression")

% Music property to point to the first or single music element
% within a music expression.
#(set-object-property! 'anchor 'music-type? ly:music?)
#(set-object-property! 'anchor 'music-doc
   "Pointer to the music element the annotation is attached to")

% Create custom property 'annotation
% to pass information from the music function to the engraver
#(set-object-property! 'input-annotation 'backend-type? alist?)
#(set-object-property! 'input-annotation 'backend-doc "custom grob property")


\include "config.ily"

%%%%%%%%%%%%%%%%%%%%%%%%
% Styling functions

%{
  If the stylesheets.span.use-styles option is set spans will be styled
  through a default or custom styling function. Styling functions are
  created through the macro define-styling-function and registered
  for a given span class with \setSpanFunc.

  The module provides the two default styling functions
  - style-default (color the span)
  - style-noop (do not modify the music)

  Note that styling functions can also be used to *add* score elements
  (e.g. marks, spanners, etc.) instead of only *style* the existing items.
%}

\include "styling-helpers.ily"

% Create a styling function for a span
% The resulting music function must take exactly one argument
% of type span-music? and returns the styled music content.
%
% A list of expressions can be specified, where the last one
% must evaluate to the (modified) music.
% The first expression may be a docstring.
%
% Inside the function the following variables are available:
% - anchor
%   The music element where the annotation is attached to
% - span-annotation
%   an annotation with properties of the span
% - span-class
%   the class/type of the span
% - style-type
%   one out of '(wrap tweak once), determining what kind of
%   modification can be applied to the music.
%   NOTE: the span-annotation includes further details, especially
%   the flags is-sequential?, is-rhythmic-event?, and is-post-event?
%   that can be accessed if necessary for further styling decisions.
% - item
%   if present it defines which grobs to affect. Can be either
%   a symbol or (for style-type = 'wrap or 'once) a symbol-list?
%   (or ##f as equivalent to not present)

% A music exression that has an 'anchor property, which is a music
% expression (the first element or the music expression itself)
% containing a 'span-annotation property.
#(define (span-music? obj)
   (and (ly:music? obj)
        (let ((anchor (ly:music-property obj 'anchor)))
          (and (not (null? anchor))
               (let ((span-annotation (ly:music-property anchor 'span-annotation)))
                 (not (null? span-annotation)))))))

% Infer the Context.Grob list to be overridden for non-rhythmic events,
% based on the music type.
#(define (infer-item location music)
   (let*
    ((parse-context-spec
      ;; Determine the type of a context-specification music
      (lambda ()
        (cond
         ;; Check for \clef
         ((let
           ((elements
             (ly:music-property (ly:music-property music 'element) 'elements)))
           (eq? 'clefGlyph (ly:music-property (first elements) 'symbol)))
          '(Staff Clef))
         (else #f))))
     (types (ly:music-property music 'types))
     (property-path
      (any
       (lambda (type)
         (if (memq (car type) types)
             (let ((result (cdr type)))
               (if (procedure? result) (result) result))
             #f))
       `((context-specification . ,parse-context-spec)
         (key-change-event . (Staff KeySignature))
         (mark-event . (Score RehearsalMark))
         (ottava-music . (Staff OttavaBracket))
         (tempo-change-event . (Score MetronomeMark))
         (time-signature-music . (Staff TimeSignature)))
       )))
    (or property-path
        (ly:input-warning location "Music type not supported
for \\once \\override: ~a" types))))


#(define-macro (define-styling-function docstring . code)
   ; all wrapping code is (semi)quoted
   `(define-music-function
     (music)(span-music?)
     ,(if (string? docstring)
          docstring
          "define-styling-function was here")
     (let*
      ((anchor (ly:music-property music 'anchor))
       (span-annotation (ly:music-property anchor 'span-annotation))
       (span-class (assq-ref span-annotation 'span-class))
       (style-type (assq-ref span-annotation 'style-type))
       (location (assq-ref span-annotation 'location))
       ;; Process the 'item property to be compatible,
       ;; the different style-types require different ways
       ;; the
       (item
        (let ((orig-item (assq-ref span-annotation 'item)))
          (case style-type
            ((once)
             (cond
              ((list? orig-item) orig-item)
              ((symbol? orig-item) (list orig-item))
              (else (infer-item location music))))
            ((wrap) orig-item)
            ((tweak)
             (if (list? orig-item)
                 (begin
                  (ly:input-warning
                   location
                   "Item for a \\tweak modification must not be a symbol-list: ~a.
Using only last element from that list."
                   orig-item)
                  (last orig-item))
                 orig-item))))))
      ;; insert (unquoted) user generated code
      ;; code must return the processed music expression
      (let ((processed-music ,@(if (string? docstring) code (cons docstring code))))
        ;; reattach the anchor to the music expression for further use
        (ly:music-set-property! processed-music 'anchor anchor)
        processed-music))))

% Default (fallback) styling font that simply applies coloring
% to the affected music, using the appropriate method for the style-type
#(define style-default
   (define-styling-function
    (let ((col (getSpanColor span-class)))
      (case style-type
        ((wrap)
         (if item
             ;; colorMusic from oll-core.color-music
             (colorMusic (list item) col music)
             (colorMusic col music)))
        ((tweak)
         ;; if item is present it is a symbol
         (let ((target (if item (list item 'color) 'color)))
           (propertyTweak target col music)))
        ((once)
         ;; item is guaranteed to be a symbol list
         (make-sequential-music
          (list
           (once (overrideProperty (append item '(color)) col))
           music)))))))

% Passthrough function
#(define style-noop
   (define-styling-function
    music))

% List of highlighting function pairs.
% The two predefined items should not be changed,
% additional functions to support specific edit types
% may be stored using \setEditFuncs
%
% This should actually be registered in config.ily
% but that has to wait until the functions have been defined
\registerOption stylesheets.span.functions
#`((default . ,style-default)
   (noop . ,style-noop))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions to modify the music expression
%
% The following functions modify the music expression *in-place*,
% effectively adding elements to it.


% Create and attach a footnote if one is requested.
% - Footnote is created when 'footnote-offset is set
% - If 'footnote-text is set this is used as footnote text
%   else the 'message is copied to the footnote.
#(define make-footnote
   (define-void-function (mus anchor annot) (ly:music? ly:music? list?)
     (let ((offset (assq-ref annot 'footnote-offset)))
       (if offset
           (let*
            ;; Determine footnote text
            ((text (or (assq-ref annot 'footnote-text)
                       (assq-ref annot 'message)))
             (mark (assq-ref annot 'footnote-mark)))
            (if mark
                ;; specify footnote mark
                (footnote mark offset (string-append mark " " text) anchor)
                ;; use auto-incremented footnote number
                (footnote offset text anchor)))))))

% TODO: Adapt this to the new structure:
#(define make-balloon
   (define-void-function (mus anchor annot) (ly:music? ly:music? list?)
     ))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions to create the span and span annotation
%


% Create and return a basic alist describing a span.
% Can be used to build an span-annotation for scholarly.annotate

% with the attributes given
% in the \with {} block (if any) plus some more calculated ones:
% - is-sequential?
% - is-rhythmic-event?
% - is-post-event?
%   to discern between edits/annotations that have to be treated with \tweak
% - context-id
%   Set up a reasonable default value if no better data can later
%   be inferred from the actual context in the engraver:
%   Initially 'context-id is a string composed from the input file and the
%   directory containing it: <directory>.<file>
% - span-class
%   is simply stored in the annotation
% - location
%   is also stored in the annotation.
#(define (make-span-annotation span-class attrs location mus)
   (let*
    ;
    ; TODO: use type-checking provided for context-mod->props
    ; (ensure some properties are set with default values (e.g. 'message')
    ;
    ((annot (if attrs (context-mod->props attrs) '()))
     (is-sequential? (not (null? (ly:music-property mus 'elements))))
     (is-rhythmic-event? (memq 'rhythmic-event (ly:music-property mus 'types)))
     (is-post-event? (memq 'post-event (ly:music-property mus 'types)))
     (anchor (if is-sequential? (first (ly:music-property mus 'elements)) mus))
     (style-type
      (cond
       (is-sequential? 'wrap)      ;; sequential music expression
       (is-rhythmic-event? 'tweak) ;; single music events
       (is-post-event? 'tweak)     ;; post-event
       (else 'once)))              ;; non-rhythmic events such as clefs, keys, etc.
     (item (let
            ((i (assq-ref annot 'item)))
            ;; ensure <item> is a symbol, a symbol list or #f
            (cond
             ((string? i) (string->symbol i))
             ((symbol-list? i) i)
             ((and (list? i) (every string? i))
              (map (lambda (s)
                     (symbol->string s)) i))
             (else #f))))
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
    ;(if item
    (assq-set! annot 'item item)
    ;)
    ;; add several manual properties to the given <attrs>
    (ly:music-set-property! anchor 'span-annotation
      (append annot
        `((is-sequential? . ,is-sequential?)
          (is-post-event? . ,is-post-event?)
          (is-rhythmic-event? . ,is-rhythmic-event?)
          (style-type . ,style-type)
          (span-class . ,span-class)
          (location . ,location)
          (context-id . ,context-id))))
    (ly:music-set-property! mus 'anchor anchor)
    anchor))


% Retrieve the styling information corresponding to the span type
% and apply them to the music expression.
% Distinguishes between wrappable and tweakable music expressions
% and calls the appropriate span function.

% Encode a \span like a <span class=""> in HTML.
% Typically used to markup up some single or sequential music expression
% to "be" something.
% Apart from the encoding aspect \span typically produces some visual highlighting,
% either temporarily during the editing process or as a persistent styling.
% Arguments:
% - span-class (symbol?)
%   specify the type of case.
%   This may be arbitrary names but highlighting support has to be provided
%   by the user.
% - attrs (optional)
%   \with {} block with further specification of the case.
%   Currently only <item> is supported, used for specifying a target grob-type
%   (
% - mus (mandatory)
%   the music to be annotated
%

tagSpan =
#(define-music-function (span-class attrs music)
   (symbol? (ly:context-mod?) ly:music?)
   (let*
    ;; create annotation, determine anchor and attach the annotation to the anchor
    ((anchor (make-span-annotation span-class attrs (*location*) music))
     (span-annotation (ly:music-property anchor 'span-annotation)))
    (make-footnote music anchor span-annotation)
    (make-balloon music anchor span-annotation)
    (if (getOption '(stylesheets span use-styles))
        (begin
         ;; Apply the styling function
         (set! music ((getSpanFunc span-class) music))
         (if (getOption '(stylesheets span use-colors))
             ;; Apply coloring
             (set! music ((getSpanFunc 'default) music)))))
    (if (assq-ref span-annotation 'ann-type)
        (propertyTweak 'input-annotation span-annotation anchor))
    music))