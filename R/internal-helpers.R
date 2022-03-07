#' @keywords internal

arg_abort_msg <- function(.arg, .fun) {
  glue("Progblem with `{.arg}` arguemtn to `{.fun}`")
}

get_output <- function(x) {
  capture.output(print(x)) %>%
    glue_collapse('\n')
}

shorten <- function(x, maxlen = 10) {
  if (length(x) > 1) {
    x <- glue_collapse(x, '')
    abort(c("Input to `shorten` has length > 1. Input is:", x))
  }
  if (nchar(x) > maxlen) {
    glue("{substr(x, 1, maxlen - 3)}...")
  } else {
    x
  }
}

arg_to_char <- function(arg, maxlen = 10, shorten = TRUE) {
  if (!shorten) {
    maxlen <- Inf
  }
  arg_name <- deparse(substitute(arg))
  char <-
    match.call(definition = sys.function(-1), call = sys.call(-1)) %>%
      as.list() %>%
      '[['(arg_name) %>%
      deparse
  shorten(char, maxlen = maxlen)
}

char_class <- function(x) {
  glue_collapse(class(x), ', ')
}

as_colname <- function(x, maxlen = 8) {
  substr(make.names(x), 1, 8)
}

name_select <- function(quo, .data) {
  names(eval_select(quo, .data))
}

seij <- function(.data, i, j) {
  `[.data.frame`(.data, i, j)
}

run_anyway <- function(expr) {
  tryCatch({expr}, error = function(e){})
}

intercept <- function(fun) {
  function(...) {
    warn <- err <- NULL
    res <- withCallingHandlers(
      tryCatch(fun(...), error = function(e) {
        err <<- conditionMessage(e)
        NULL
      }),
      warning = function(w) {
        warn <<- append(warn, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    # have to use named x or else rlang::abort will complain
    if (!is.null(warn)) {
      warn <- setNames(warn, rep('x', length(warn)))
    }
    if (!is.null(err)) {
      err <- setNames(err, rep('x', length(err)))
    }
    list(res = res, warn = warn, err = err)
  }
}
