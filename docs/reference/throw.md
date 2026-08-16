# Throw informative error messages

Helpers to generate readable and informative error messages for package
users.

## Usage

``` r
throw(..., call = sys.call(sys.parent()), subclass = NULL)

rethrow(error, call = sys.call(sys.parent()))

rethrow_on_error(expr, call = sys.call(sys.parent()))

box_error(message, call = NULL, subclass = NULL)
```

## Arguments

- ...:

  arguments to be passed to `fmt`

- call:

  the calling context from which the error is raised

- subclass:

  an optional subclass name for the error condition to be raised

- error:

  an object of class `c("error", "condition")` to rethrow

- expr:

  an expression to evaluate inside `tryCatch`

- message:

  the error message

## Value

If it does not throw an error, `rethrow_on_error` returns the value of
evaluating `expr`.

`box_error` returns a new ‘box’ error condition object with a given
message and call, and optionally a given subclass type.

## Details

For `rethrow`, the `call` argument overrides the rethrown error’s own
stored call.
