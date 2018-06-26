---
documentclass: ollmanual
title: The `stylesheets.span` Module
author: Urs Liska
date: \today
toc: yes
---

\lysetoption{includepaths}{/home/uliska/git/oll-lib}

The openLilyLib package \ollPackage{stylesheets} includes the
\ollPackage{stylesheets.span} module.  Its main feature is the \cmd{span}
command which is loosely modeled after the `<span>` element from HTML. It “marks
up” a given music expression with a class or type and provides an interface to
apply styling functions, either as visual reminders during the editing process
or as persistent formatting similar to character styles -- or HTML spans.
Additionally spans can trigger annotations from the
\ollPackage{scholarly.annotate} package, and they form the components of a
\ollPackage{scholarly.choice} \cmd{choice}.


# Basic Usage

In order to use the \ollPackage{stylesheets.span} module openLilyLib and the
\ollPackage{stylesheets} package have to be properly installed. Then the module
can be loaded with

```lilypond
\include "oll-core/package.ily"
\loadModule stylesheets.span
```

The most basic use of \cmd{span} is marking up a music expression with an
arbitrary name:

```{.lilypond include=basic-sequential.ly}
```

This indicates that the two `d` are in some way “blurred” and is mostly equivalent to writing

```html
This is some <span class="blurred">blurred</span> text.
```

In HTML. And just like in HTML/CSS this doesn't actually make the word look in any specific way, the user will have to supply style sheets to actually do that job. However, in our case the two notes are by default colored with “darkmagenta”:

\lilypondfile{basic-sequential.ly}

\cmd{span} first looks for a registered styling function for the class
`blurred`.  Since we haven't specified one there is no visual modification of
the music.  By default spans are colored, so \cmd{span} looks for a *color*
specified for the `blurred` class. And since we didn't specify one either a
default color is used instead. So without any further precautions \cmd{span} can
be used with an arbitrary class name and will still have that default coloring
available.

\ollIssue{TODO:}

Additionally `class="blurred"` will be attached to all grob elements in a resulting SVG file. *(NOTE: this has to be implemented!)*

## Additional properties

In addition to the class name a span can be assigned additional properties by
inserting an additional \cmd{with \{\}} block after the class name. The only
attribute supported natively by spans is `item`, which targets the span to a
specific grob type within the music.

```{.lilypond include=basic-with-item.ly}
```

Will only color the beams instead of the whole music.

\lilypondfile{basic-with-item.ly}

It is also possible to target grobs from other contexts:

```{.lilypond include=basic-with-context-item.ly}
```
\lilypondfile{basic-with-context-item.ly}

Additional custom attributes are allowed but don't have any immediate effect
from withing the \ollPackage{span} module. However, they are carried along with
the music expression, so any custom styling function (see below) can read it out
and respond appropriately. Additionally attributes will be attached to resulting
SVG objects, and they play an important role in other packages building on top
of \ollPackage{stylesheets.span}.

## Application of \cmd{span}

Spans can be applied to in different ways to address different situations,
namely different types of music expressions.

\ollMargin{Sequential Music Expressions}

The examples above represent the first case, sequential music expressions.
In this case the span includes all of the music within that expression, but it
may be good to keep in mind that an *annotation* is attached to the *first*
element within this music expression.


\ollMargin{Single Music Elements}

If the command is followed by a single music element like a note or a rest
the span will include only this element, and (of course) the annotation is
directly attached to this too.  

Again it is possible to target specific grob types with the `item` attribute. as
can be seen in the second instance, where in the `eis'` only the accidental is
colored.

```{.lilypond include=basic-single.ly}
```
\lilypondfile{basic-single.ly}

Note that it is only possible to address elements this way that are *implicitly*
created from the note or rest, such as accidentals, beams or flags. Elements
that are *attached* to the note such as articulations, text or dynamics can
*not* be addressed like this.


\ollMargin{Post-events}

To address articulations, dynamics and other so called *post-event* elements it
is possible to apply \cmd{span} as a post-event too.

```{.lilypond include=basic-post-event.ly}
```
\lilypondfile{basic-post-event.ly}

For technical reasons it is *possible* to specify an `item` attribute, but this
can't do any good and should be avoided. The post-event application is
translated into a \cmd{tweak} that affects the music element directly, without
specifying any target item.


\ollMargin{Non-rhythmic Events}

Finally it is possible to mark up *non-rhythmic* events such as key or time
signatures, rehearsal or metronome marks etc. Typically these are not in the
`Voice` but in a higher context and therefore need a two-element `item`
attribute. However, \cmd{span} tries to determine the target automatically if no
`item` attribute is provided, and a number of elements are already supported:

```{.lilypond include=non-rhythmic-events.ly}
```

\lilypondfile{non-rhythmic-events.ly}

Elements that can be directly targeted like this are \cmd{time}, \cmd{key},
\cmd{clef}, \cmd{mark}, and \cmd{tempo}.


# Configuration

The \ollPackage{stylesheets.span} package has two configuration options that can
be set independently with \cmd{setOption}: \option{stylesheets.span.use-styles}
and \option{stylesheets.span.use-colors}. By default both options are set to
`##t`.

If `use-styles` is set to `##f` then *no* styling or coloring will be applied at
all.

If `use-colors` is set to `##f` then styling functions will be applied but
coloring will be switched off (except if a styling function explicitly
introduces colors). A typical use case is to apply styles as persistent
visualization and deactivate the coloring for the final publication stage.


## Coloring

As indicated above the application of colors is a two-stage process. First
\cmd{span} looks for a color registered for the requested span class, and if
none is available the default fallback color is used instead. The default color
is pre-set to `darkmagenta`, but this can be changed like with colors in
general.

Like with HTML span classes are essentially empty to start with, and styling
information has to be supplied by users or libraries. But other packages that
build upon \cmd{span}, such as \ollPackage{scholarly} provide a greater set of
predefined styles.

\ollLilyfuncdef{setSpanColor}{span-class color}{}

Store a color for a span class. Originally only the `'default` color is
registered, but it can be overwritten using this command.


## Managing Styling Functions

Styling functions are used to apply styles to the given music expression. Two
styling functions are predefined: \option{style-default} (colors the music) and
\option{style-noop} (does nothing).

Like with colors there is a two-stage process of retrieving styling functions.
If a styling function is registered for the requested span class it is applied
(before coloring is applied). Otherwise the music is not affected -- by applying
the `'noop` function.

\ollLilyfuncdef{setSpanFunc}{span-class function}{}

Store a styling function for a class. The predefined functions for `'default`
and `'noop` should not be overwritten, although it's possible to do so with this
function.

New styling functions should be created using the macro
\option{define-styling-function} which is explained in depth below.

# Custom Styling Functions

\cmd{span} applies styling functions, and we have seen that two such functions
are predefined by the module. Of course the true power of spans is only used
when custom styling functions actually apply some real styling. By its nature it
is not trivial to create robust styling functions, but the package provides some
assistance with the process through the \option{define-styling-function} macro
and some helper functions.

## The `define-styling-function` Macro

\option{define-styling-function} is a Scheme macro that creates and returns a
specific form of music function that can be registered using \cmd{setSpanFunc}.
This music function expects one `ly:music?` argument and returns the modified
(styled) music.

The general syntax for the macro is `(define-styling-function exp1 exp2 ...
expN)` where `expN` must evaluate to the modified music expression and where
`exp1` may be a docstring.

The music function created by the macro takes exactly one argument of type
`span-music?`, which doesn't have to be declared explicitly. `span-music?` is a
music expression that has an `'anchor` property, which in turn has a
`'span-annotation` property. But this is something one doesn't have to worry
about because it is handled automatically by \cmd{span}. Inside the function
this is bound to the name `music`.

A number of properties from the music are extracted by the macro and available
automatically within the music function:

* `anchor`  
  A music expression, referring to either the first element in `music` or
  to `music` itself
* `span-annotation`  
  The span's annotation, attached to `anchor`
* `span-class`
* `location`  
  The input location which may be used for error reporting
* `style-type`  
  Determines *how* the styling has to be applied. One out of
  `wrap`, `tweak`, `once`
* `item`  
  A symbol, a symbol-list or `##f`. If present it specifies the grob type
  to affect. There is some validation performed depending on `style-type`.

Note that while most of these are extracted from `span-annotation` just for
convenience it is of course possible to access arbitrary (custom) attributes
through \option{assq-ref span-annotation '<attr-name>}.

## Basic Styling Function / Handling Style Types

The music function is passed a music expression, but as we have seen \cmd{span}
can be applied in various ways -- requiring different approaches to applying the
styling. If you know the span is only going to be applied in one way (e.g.
acting upon sequential music) you can ignore the difference, but general-purpose
functions must discern and act accordingly. This can cleanly be inspected with
the implementation of `style-default` in the span module file:

```lilypond
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
```

\option{(define-styling-function)} creates a procedure (concretely a LilyPond
music-function) and *binds* it to the name `style-default`. Note that there is
no additional function interface (argument list and types) because this is
implicitly done by the macro. The whole procedure is written as one \option{let}
block and evaluates to the modified music expression.

The incoming music expression is available in the function as \option{music}.
The span class is available as `span-class`, which is used to retrieve the
class's defined color with \option{getSpanColor} (or the fallback default
color).

`style-type` denotes the way \cmd{span} is applied to the music and can take one
out of the values `wrap`, `tweak` and `once`, and we organize the choice with a
`case` expression. In general our function has to act differently depending on
the application type.

\ollMargin{wrap}

`wrap` stands for a sequential music expression that will be surrounded by
\cmd{override} and \cmd{revert} statements. In this case we use
\option{color-music}, a helper function from the
\ollPackage{oll-core.color-music} module. This will color all or selected grobs,
depending on whether an `item` is present.

`item` is another variable made available through the macro. It can be a symbol
(grob name) or a symbol-list (context and grob).

\ollMargin{tweak}

`tweak` is applied to post-event music and single music elements (usually notes
or rests). In this case the modification has to be applied to the music as a
tweak (where it is guaranteed that `music` is a single, non-sequential music
expression).

If `item` is present it should be used to target specific grobs, which usually
makes sense only for single music items, not for post-events. If music is a note
then item might refer to the Accidental or other implicitly created grobs (but
not to attached articulations or markup). It is not possible to have `item` as a
symbol-list here (it's not valid to write `\tweak Score.RehearsalMark color
#red`), but the macro takes care of that, issuing a warning and extracting the
last element from a given symbol list.

\ollMargin{once}

`once` is applied to non-rhythmic events like key or time signatures, rehearsal
and tempo marks etc which have to be styled with a \cmd{once} \cmd{override}.
The macro will ensure that `item` is a symbol list here, so one can always
append the property.

Different from tweaks that modify the music in-place it is important to notice
that `once` has to return a sequential music with the override(s) and the
original music after that.


## Adding Elements to the Music

Styling functions are not limited to tweaking grob properties but can also *add*
elements to the music or its elements. Typical use cases would be marks at the
beginning and the end, (text) spanners or similar items.

```{.lilypond include=ottava-span.ly}
```
\lilypondfile{ottava-span.ly}

In this example the span `ottava` sets the ottava of the wrapped music. Of
course this could be achieved with little extra effort using \cmd{ottava}
directly, but a) one may prefer this type of encoding, b) this is just an
example after all, and c) this approach is extensible by having the styling
function respond to custom span attributes.

## Applying Grob-specific Styling Functions

While the styling functions seen so far typically affect *all* or *specific*
grobs real-world use cases may want to handle different grobs differently. For
example a span class visualizing editorial additions will probably want to apply
different styles to different grobs, for example parenthesizing for accidentals,
dashing for slurs and small-print for note heads etc. Or some grobs should only
be styled when passed explicitly as `item` etc. This adds a significant level of
complexity to creating and maintaining styling functions, basically a matrix of
style-types and grob-types.

\ollIssue{TODO}

This whole topic has to be investigated and then documented. Hopefully we'll
find solutions to simplify the definition of grob handling functions in a way
similar to what `wrap-span` does with overrides.


## Helper Functions

We have seen `colorMusic` as a helper function to color *all* grobs without
having to write out all the overrides explicitly. But the \ollPackage{span}
module defines more helper functions to assist with the creation of styling
functions. *(Note: this is work in progress and more should become available
over time)*

\ollFuncdef{wrap-span}{props music}{}

\option{wrap-span} takes a music expression and “wraps” it with temporary
overrides as specified by the `props` list. This is a list of pairs (although
not really an association list) with a property path as each pair's first and a
value as the second element. The property path is a symbol list consisting of a
grob name and a property, and optionally a context, e.g. `'(Slur thickness)` or
`'(Score RehearsalMark extra-offset)`

`wrap-span` will go through this list and produce a \cmd{temporary}
\cmd{override} for each element, then pass through the original music and add
\cmd{revert} statements for all overrides.

```{.lilypond include=wrap-span.ly}
```
\lilypondfile{wrap-span.ly}

Note that in this example there is no `case` switch for the different
`style-type` values, which means that the styling function may fail in some
cases (but that may be OK, depending on the use case). For the first invocation
it is clear how it works, setting the overrides before and the reverts after the
music. In the second case `music` is the single note event, but still the
wrapping takes effect. This is because the reverts are inserted after the note,
and therefore they take effect for the note itself. However, applying
`fancy-span` as a post-event would fail.
