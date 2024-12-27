# cl-scribble-mode - Major mode for editing Scribble documents with Common Lisp symbols

This is a fork that slightly changes scribble syntax to support Common Lisp symbols.

What's more, it enables autocompletion from Sly/Slime.

If you find something that can be enhanced or you find a problem, don't hesitate to post an issue.

Tested only with `Corfu`.

## Example

<img src="/images/cl-scribble-example.png" alt="CL Scribble example">

## Installation

Clone this project into your emacs configuration.

``` shell
git clone git@github.com:HectareaGalbis/cl-scribble-mode.git
```

Now, in your `init.el` file, load `cl-scribble-mode.el` after `slime` or `sly` are loaded:

``` emacs-lisp
(add-to-list 'load-path (concat user-emacs-directory "cl-scribble-mode/"))
(load "cl-scribble-mode")
```
