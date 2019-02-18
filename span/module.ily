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

\loadModule stylesheets.util

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


\include "config.ily"

% Helper function to extract the ly:music? expression that holds
% the input-annotation, either the music itself or its first sub-element.
#(define (get-anchor music)
   (let ((anchor (ly:music-property music 'anchor)))
     (cond
      ((not (null? anchor)) anchor)
      ((memq 'event-chord (ly:music-property music 'types))
       (first (ly:music-property music 'elements)))
      (else music))))


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
%   the variable music-type ('sequential, 'chord, 'post-event, 'rhythmic, 'non-rhythmic)
%   that can be accessed if necessary for further styling decisions.
% - item
%   if present it defines which grobs to affect. Can be either
%   a symbol or (for style-type = 'wrap or 'once) a symbol-list?
%   (or ##f as equivalent to not present)

% A music expression that includes a 'span-annotation music-property,
% either attached to the main music expression (for non-sequential music)
% or to an 'anchor music-property, which is the first rhythmic-event
% in a sequential music expression.
#(define (span-music? obj)
   (and (ly:music? obj)
        (let*
         ((anchor (get-anchor obj))
          (span-annotation (ly:music-property anchor 'span-annotation)))
         (not (null? span-annotation)))))

% Infer the Context.Grob list to be overridden for non-rhythmic events,
% based on the music type.
#(define (infer-item location music)
   (let*
    ((parse-context-spec
      ;; Determine the type of a context-specification music
      (lambda ()
        (cond
         ;; Check for \bar
         ((eq? 'whichBar (ly:music-property (ly:music-property music 'element) 'symbol))
          '(Staff BarLine))
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
         (multi-measure-rest . (MultiMeasureRest))
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
      ((anchor (get-anchor music))
       (span-annotation (ly:music-property anchor 'span-annotation))
       (span-class (assq-ref span-annotation 'span-class))
       (item (assq-ref span-annotation 'item))
       (style-type (assq-ref span-annotation 'style-type))
       (location (assq-ref span-annotation 'location)))
      ;; insert (unquoted) user generated code
      ;; code must return the processed music expression
      (let*
       ((processed-music ,@(if (string? docstring) code (cons docstring code)))
        (is-now-sequential?
         (memq 'sequential-music (ly:music-property processed-music 'types)))
        )
       ;; reattach the anchor to the music expression for further use
       (if is-now-sequential?
           (begin
            (assq-set! span-annotation 'style-type 'wrap)
            (ly:music-set-property! processed-music 'anchor anchor)))
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

% Create and attach a temporary Example staff
#(define make-music-example
   (define-void-function (mus anchor annot) (ly:music? ly:music? list?)
     (let ((example (assq-ref annot 'example)))
       (if example
           (if (or (ly:score? example) (ly:music? example))
               (if (not (assq-ref annot 'is-post-event?))
                   (let*
                    ((example-score
                      (if (ly:score? example) example #{ \score { #example  \layout {} } #}))
                     ;                  (scorify-music example))
                     (alignment (or (assq-ref annot 'example-alignment) 0))
                     (direction (or (assq-ref annot 'example-direction) 1))
                     ;
                     ; TODO:
                     ; - enable sizing of example
                     ; - enable suppression of clef and timesig
                     ;
                     (chord
                      (let ((anchor-chord (ly:music-property mus 'anchor-chord)))
                        (if (null? anchor-chord) #f anchor-chord)))
                     (text-script
                      (make-music
                       'TextScriptEvent
                       'tweaks `((self-alignment-X . ,alignment)
                                 (direction        . ,direction))
                       'text (markup #:score example-score))))
                    (if (assq-ref annot 'is-chord?)
                        (ly:music-set-property! mus 'elements
                          (append
                           (ly:music-property mus 'elements)
                           (list text-script)))
                        (ly:music-set-property! anchor 'articulations
                          (append
                           (ly:music-property anchor 'articulations)
                           (list text-script)))))
                   (oll:warn "Example cannot be created for post-event music, skipping."))
               (oll:warn "Example must be LilyPond music or a score expression. Found ~a" example))))))

% Create and attach a temporary Ossia staff
%
% TODO: This does not work yet!
% It is called and doesn't cause problems but the ossia isn't created.
% A working standalone example (thanks to David Kastrup)
% is given in comments below
#(define make-ossia
   (define-music-function (mus anchor annot) (ly:music? ly:music? list?)
     (let*
      ((name #f)
       (ossia-music (assq-ref annot 'ossia-music))
       (ossia-omit (or (assq-ref annot 'ossia-omit) '())))
      (if ossia-music
          (set! mus
                #{
                  \applyContext
                  #(lambda (context)
                     (set! name (ly:context-id (ly:context-find context 'Staff))))
                  << \new Staff = "ossia" \with {
                    #(let ((align (assq-ref annot 'ossia-direction)))
                       (if (or (not align) (= align UP))
                           (ly:make-context-mod
                            `((apply
                               ,(lambda (c)
                                  (set! (ly:context-property c 'alignAboveContext) name)))))))
                    #@(map
                    (lambda (grob)
                    (omit (list grob)))
                    ossia-omit)
                     } { #ossia-music }
                     #mus
                  >>
                #}))
      mus)))

%{
ossia =
#(define-music-function
  (ossia-music music) (ly:music? ly:music?)
  (let*
   ((name #f))
   (make-sequential-music
    (list
     (make-apply-context
      (lambda (context)
        (set! name (ly:context-id (ly:context-find context 'Staff)))))
     #{
       << \new Staff \with {
         #(ly:make-context-mod
           `((apply
              ,(lambda (c)
                 (set! (ly:context-property c 'alignAboveContext) name)))))
         #@(map
         (lambda (grob)
         (omit (list grob)))
         '())
          } { #ossia-music }
          #music
       >>
     #}))))
ossia =
#(define-music-function
  (ossia-music music) (ly:music? ly:music?)
  (let*
   ((name #f))

   (make-sequential-music
    (list
     (make-apply-context
      (lambda (context)
        (set! name (ly:context-id (ly:context-find context 'Staff)))))
     #{
       << \new Staff \with {
         #(if #t
              (ly:make-context-mod
               `((apply
                  ,(lambda (c)
                     (set! (ly:context-property c 'alignAboveContext) name))))))
         #@(map
           (lambda (grob)
             (omit (list grob)))
           '())
          } { #ossia-music }
          #music
       >>
     #}))))

\new Staff = "My Staff"
\relative {
  g'8 a b c
  \ossia { d c b a } { c b a g }
  g b d b g2
}
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions to create the span and span annotation
%

% Macro creating a scheme-function to validate a span's annotation.
% The function expects a <span-class> symbol, and an <annotation> alist.
% <warning-message> is available and can be written to from within the body.
% The body must be one expression evaluating to a 'valid' boolean?
% <annotation> can be modified to update the annotation (e.g. with default values).
%
% If the span is not 'valid' a warning is issued, and if <warning-message>
% has been set! from the function body it is appended to the warning.
#(define-macro (define-span-validator docstring . code)
   ; all wrapping code is (semi)quoted
   `(define-scheme-function
     (span-class annotation)(symbol? alist?)
     ,(if (string? docstring)
          docstring
          "define-styling-function was here")
     (let*
      ((warning-message "")
       (valid
        ,@(if (string? docstring) code (cons docstring code))))
      (if (not valid)
          (oll:warn "Invalid '~a' span. ~a" span-class warning-message))
      annotation)))

% Generic span validator, called for *all* spans.
% - ensures that all annotations with ann-type (input-annotations)
%   also have a 'message' set.
% - ensures that if a footnote is created some message text is available.
% - ensures that if a balloon text is created a message text is available.
#(define generic-span-validator
   (define-span-validator
    (let*
     ((ann-type (assq-ref annotation 'ann-type))
      (message (assq-ref annotation 'message))
      (footnote-offset (assq-ref annotation 'footnote-offset))
      (footnote-text (assq-ref annotation 'footnote-text))
      (balloon-offset (assq-ref annotation 'balloon-offset))
      )
     (if (or
          (and ann-type (not message))
          (and footnote-offset (not (or message footnote-text)))
          (and balloon-offset (not (or message balloon-text))))
         (set! annotation
               (append annotation '((message . "No message provided")))))
     #t)))

% Validate a span's annotation.
% If a generic validator is registered it is called,
% followed by a class-specific validator if available.
#(define (validate-annotation annotation)
   (let*
    ((span-class (assq-ref annotation 'span-class))
     ;; plug in an optional (custom) generic validator
     (generic-validator (getOption '(stylesheets span validators generic)))
     ;; retrieve a validator function for the span-class
     (validator (getChildOptionWithFallback
                 '(stylesheets span validators) span-class #f)))
    ;; Generic validation: annotations require a 'message attribute
    (set! annotation (generic-span-validator span-class annotation))
    (if generic-validator
        (set! annotation (generic-validator span-class annotation)))
    (if validator
        (validator span-class annotation)
        annotation)))

% Create and return a basic alist describing a span.
% Can be used to build an span-annotation for scholarly.annotate

% with the attributes given
% in the \with {} block (if any) plus some more calculated ones:
% - music-type
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
#(define (make-span-annotation span-class attrs location music)
   (let*
    ((annot (if attrs (context-mod->props attrs) '()))
     (music-type
      (cond
       ((memq 'event-chord (ly:music-property music 'types)) 'chord)
       ((not (null? (ly:music-property music 'elements))) 'sequential)
       ((memq 'post-event (ly:music-property music 'types)) 'post-event)
       ((memq 'rhythmic-event (ly:music-property music 'types)) 'rhythmic)
       (else 'non-rhythmic)))
     (anchor
      (case music-type
        ((sequential)
         (let ((first-element (first (ly:music-property music 'elements))))
           (if (memq 'event-chord (ly:music-property first-element 'types))
               (first (ly:music-property first-element 'elements))
               first-element)))
        ((chord) (first (ly:music-property music 'elements)))
        (else #f)))
     (style-type
      (case music-type
        ((sequential chord) 'wrap)
        ((post-event rhythmic) 'tweak)
        (else 'once)))

     ;; Process the 'item property to be compatible,
     ;; the different style-types require different ways
     ;; the
     (item
      (let
       ((orig-item
         (let
          ;; First ensure <item> is a symbol, a symbol list or #f
          ((i (assq-ref annot 'item)))
          (cond
           ((string? i) (string->symbol i))
           ((symbol-list? i) i)
           ((and (list? i) (every string? i))
            (map (lambda (s)
                   (symbol->string s)) i))
           (else #f)))))
       ;; Process item type depending on style-type
       (case style-type
         ((once)
          ;; For 'once we need a list (even with one element)
          (cond
           ((list? orig-item) orig-item)
           ((symbol? orig-item) (list orig-item))
           ;; look up from a list of provided music types
           (else (infer-item location music))))
         ((wrap) orig-item)
         ((tweak)
          ;; For 'tweak there must not be a list (e.g. Staff.Clef)
          ;; In that case we try to simply use the last element of the list
          (if (list? orig-item)
              (begin
               (ly:input-warning
                location
                "Item for a \\tweak modification must not be a symbol-list: ~a.
Using only last element from that list."
                orig-item)
               (last orig-item))
              orig-item)))))
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
    ;; Set or update 'item. Since we don't know whether there is one already set
    ;; we have to use the double 'set!' invocation.
    (set! annot (assq-set! annot 'item item))
    ;; If we have an ann-type string convert it to symbol
    (let ((ann-type (assq-ref annot 'ann-type)))
      (if (and ann-type (string? ann-type))
          (set! annot (assq-set! annot 'ann-type (string->symbol ann-type)))))
    (ly:music-set-property! (or anchor music) 'span-annotation
      (validate-annotation
       (append annot
         `((music-type . ,music-type)
           (style-type . ,style-type)
           (span-class . ,span-class)
           (location . ,location)
           (context-id . ,context-id)))))
    (if anchor (ly:music-set-property! music 'anchor anchor))
    (or anchor music)))

% If the span-annotation has an ann-type attribute
% we attach the annotation as 'input-annotation to the grob.
% In this case we'll also have to make sure ann-type is a symbol.
#(define (make-input-annotation span-annotation music anchor)
   (let ((ann-type (assq-ref span-annotation 'ann-type)))
     (if ann-type
         (if (ollModuleLoaded 'scholarly 'annotate)
             (if (eq? (assq-ref span-annotation 'style-type) 'once)
                 (begin
                  (set! music
                        (make-sequential-music
                         (append
                          (list
                           (once (overrideProperty
                                  (append
                                   ;; we know this is a list
                                   (assq-ref span-annotation 'item)
                                   '(input-annotation))
                                  span-annotation)))
                          (list music))))
                  (ly:music-set-property! music 'anchor
                    (second
                     (ly:music-property music 'elements)))
                  music)
                 (begin
                  (propertyTweak
                   'input-annotation
                   (assq-set! span-annotation 'ann-type ann-type)
                   anchor)
                  music))
             (oll:warn "'~a' annotation present but scholarly.annotate not loaded. Skipping!"
               ann-type))
         music)))


% Encode a \tagSpan like a <span class=""> in HTML.
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
% - music (mandatory)
%   the music to be annotated
tagSpan =
#(define-music-function (span-class attrs music)
   (symbol? (ly:context-mod?) ly:music?)
   (if
    ;; Skip empty sequential music expressions because they'll crash
    (and (memq 'sequential-music (ly:music-property music 'types))
         (null? (ly:music-property music 'elements)))
    #{ #}
    (let*
     ;; create annotation, determine anchor and attach the annotation to the anchor
     ((anchor (make-span-annotation span-class attrs (*location*) music))
      (span-annotation (ly:music-property anchor 'span-annotation)))
     (make-footnote music anchor span-annotation)
     (make-balloon music anchor span-annotation)
     (make-music-example music anchor span-annotation)
     (make-ossia music anchor span-annotation)
     ;; optionally create an input-annotation for scholarly.annotate
     ;; (note that this attaches to the *grob*, not to the *music*)
     (set! music (make-input-annotation span-annotation music anchor))
     (if (getOption '(stylesheets span use-styles))
         (begin
          ;; Apply the styling function
          (set! music ((getSpanFunc span-class) music))
          (if (getOption '(stylesheets span use-colors))
              ;; Apply coloring
              (set! music ((getSpanFunc 'default) music)))))
     music)))
