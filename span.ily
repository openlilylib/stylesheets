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
#(set-object-property! 'span-props 'music-type? alist?)
#(set-object-property! 'span-props 'music-doc
   "Properties of a \\span expression")


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration and default behaviour

% Toggle the application of editorial command styling in general
\registerOption stylesheets.span.use-styles ##t

% Toggle the automatic coloring
% When ##t all spans are colored with the span type's defined span-color
% (or a general fallback color)
% Typically this will option will be set to ##f for print production
% while `use-styles` will be kept ##t
\registerOption stylesheets.span.use-colors ##t

% List of colors for the different span types
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

  Styling functions come in pairs: one that is applied by *wrapping*
  the music in code, the other by \tweak.

  Styling functions are defined using the macro define-styling-function,
  and three such functions are predefined: 
  - style-default-wrap
  - style-default-tweak
  - style-noop
  The default functions will simply color all grobs with the type-
  specific color, while noop simply returns the unaltered music.
  These are used for default highlighting or *no* highlighting.
%}

% define macro for simplified creation of styling functions
% Usage:
% (define-styling-function
%   "docstring" (optional)
%   list-of-expressions
%   returning updated music expression)
%
% The macro defines a music function with a single ly:music? argument
% This music expression is expected to include a 'span-props music property
% with at least <span-type> and <item> keys available. Additionally the music
% must have an <anchor> music property.
% The macro makes the following bindings available within the function:
% - music (the incoming music expression)
% - anchor (an element in the list of music elements)
% - item  (a grob name or Context.Grob symbol-list
% - span-type (the type (class) of span
%
% The inner code must evaluate to the modified (styled) music
#(define-macro (define-styling-function docstring . code)
   ; all wrapping code is (semi)quoted
   `(define-music-function
     (music)(ly:music?)
     ,(if (string? docstring) 
          docstring
          "define-my-custom-function was here")     
     (let*
      ((anchor (ly:music-property music 'anchor))
       (span-props (ly:music-property music 'span-props))
       (item (assq-ref span-props 'item))
       (span-type (assq-ref span-props 'span-type)))
      (if (or (not span-props) (not anchor))
          (ly:input-warning "No input annotation" (*location*)))
      ;; insert (unquoted) user generated code
      ;; code must return the processed music expression
      (let ((processed-music ,@(if (string? docstring) code (cons docstring code))))
        ;; reattach the span-props for further use
        (ly:music-set-property! processed-music 'span-props span-props)
        (ly:music-set-property! processed-music 'anchor anchor)
        processed-music))))


#(define style-default-wrap
   (define-styling-function
    (if item
        ;; colorMusic from oll-core.color-music
        (colorMusic (list item) (getSpanColor span-type) music)
        (colorMusic (getSpanColor span-type) music))))

#(define style-default-tweak
   (define-styling-function
    (let ((target (if item (list item 'color) 'color)))
      #{ \tweak #target #(getSpanColor span-type) #music #})))

#(define style-noop
   (define-styling-function
    music))

% List of highlighting function pairs.
% The two predefined items should not be changed,
% additional functions to support specific edit types
% may be stored using \setEditFuncs below.
\registerOption stylesheets.span.functions
#`((default ,(cons style-default-wrap style-default-tweak))
   (noop ,(cons style-noop style-noop)))


% Retrieve a pair of highlighting functions for the given edit-type
% If highlighting is switched off return the <noop> functions
% If a function pair is present for the given type return the
% corresponding pair, otherwise the <default> pair.
getSpanFuncs =
#(define-scheme-function (type)(symbol?)
   (let ((functions (getOption '(stylesheets span functions))))
     (car (or (assq-ref functions type)
              (assq-ref functions 'noop)))))

% Store a pair of highlighting functions for a given edit-type
% Both functions must be music-functions created by define-styling-function.
% The <wrap-func> will be applied
% to sequential music expressions while <tweak-func> is applied
% to single music elements like note-events or other \tweak-able items
setSpanFuncs =
#(define-void-function (type wrap-func tweak-func)(symbol? procedure? procedure?)
   (setChildOption '(stylesheets span functions) type
     (list (cons wrap-func tweak-func))))


% Create and return a basic alist describing a span. 
% Can be used to build an input-annotation for scholarly.annotate

% with the attributes given
% in the \with {} block (if any) plus some more calculated ones:
% - is-postevent?
%   to discern between edits/annotations that have to be treated with \tweak
% - context-id
%   Set up a reasonable default value if no better data can later
%   be inferred from the actual context in the engraver:
%   Initially 'context-id is a string composed from the input file and the
%   directory containing it: <directory>.<file>
% - span-type
%   is simply stored in the annotation
% - location
%   is also stored in the annotation.
#(define (make-span-description span-type attrs location mus)
   (let*
    ;
    ; TODO: use type-checking provided for context-mod->props
    ;
    ((annot (if attrs (context-mod->props attrs) '()))
     (is-postevent? (memq 'post-event (ly:music-property mus 'types)))
     ;     (is-sequential? (not (null? (ly:music-property mus 'elements))))
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
      `(;(is-sequential? . ,is-sequential?)
         (is-postevent? . ,is-postevent?)
         (span-type . ,span-type)
         (location . ,location)
         (context-id . ,context-id)))))


% Retrieve the styling information corresponding to the span type
% and apply them to the music expression.
% Distinguishes between wrappable and tweakable music expressions
% and calls the appropriate span function.
#(define format-span
   (define-music-function (annot mus)(alist? ly:music?)
     ;; attach properties to music expression
     (ly:music-set-property! mus 'span-props annot)
     (let ((anchor (ly:music-property mus 'anchor)))
       (if (getOption '(stylesheets span use-styles))
           (let*
            ((span-type (assoc-ref annot 'span-type))
             (is-postevent? (assq-ref annot 'is-postevent?))
             (item (let
                    ((i (assoc-ref annot 'item)))
                    ;; ensure <item> is a symbol, a symbol list or #f
                    (cond
                     ((string? i) (string->symbol i))
                     ((symbol-list? i) i)
                     ((and (list? i) (every string? i))
                      (map (lambda (s)
                             (symbol->string s)) i))
                     (else #f))))
             ;; Retrieve appropriate styling function
             (edit-func (if is-postevent?
                            (cdr (getSpanFuncs span-type))
                            (car (getSpanFuncs span-type)))))
            ;; Update 'item field with proper type
            (assq-set! annot 'item
              (if (and is-postevent? (list? item)) (last item) item))
            ;; Apply the styling function
            (set! mus (edit-func mus))
            (if (getOption '(stylesheets span use-colors))
                ;; Apply coloring
                (let
                 ((color-func (if is-postevent?
                                  (cdr (getSpanFuncs 'default))
                                  (car (getSpanFuncs 'default)))))
                 (set! mus (color-func mus))))
            (ly:music-set-property! mus 'anchor anchor)
            mus)
           mus))))


% Encode a \span like a <span class=""> in HTML.
% Typically used to markup up some single or sequential music expression
% to "be" something.
% Apart from the encoding aspect \span typically produces some visual highlighting,
% either temporarily during the editing process or as a persistent styling.
% Arguments:
% - span-type (symbol?)
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
% The function works as a standalone music function or as a post-event.
span =
#(define-music-function (span-type attrs mus)
   (symbol? (ly:context-mod?) ly:music?)
   (let*
    ((annot (make-span-description span-type attrs (*location*) mus)))
    (format-span annot mus)))
