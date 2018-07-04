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
     (or (assq-ref colors type)
         (assq-ref colors 'default))))

% Set the highlighting color for a given edit type
setSpanColor =
#(define-void-function (type col)(symbol? color?)
   (setChildOption '(stylesheets span span-colors) type col))

% stylesheets.span.functions should actually be registered here,
% but this is moved to the main module.ily file because the
% default functions have to be defined first before being
% attached to a lookup list.


% Retrieve a styling function for the given span-class.
% If none is registered for the span-class return the 'noop function.
getSpanFunc =
#(define-scheme-function (type)(symbol?)
   (let ((functions (getOption '(stylesheets span functions))))
     (or (assq-ref functions type)
         (assq-ref functions 'noop))))

% Store a styling function for a given span-class.
% <func> must be a music-function, typically created through define-styling-function.
setSpanFunc =
#(define-void-function (type func)(symbol? procedure?)
   (setChildOption '(stylesheets span functions) type func))


% Validators are functions validating a span. By default the span
% module does not define any validators, but for example the
% scholarly.editorial-markup module does so, and users/libraries
% are strongly encouraged to make use of that functionality.
%
% Validators are scheme-functions created with the define-span-validator
% macro.
\registerOption stylesheets.span.validators
#'((generic . #f))

setSpanValidator =
#(define-void-function (span-class validator) (symbol? procedure?)
   (setChildOption '(stylesheets span validators) span-class validator))