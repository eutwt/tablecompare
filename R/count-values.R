#' Check for existence of multiple values per group
#'
#' @description
#' \code{count_values()} returns values of \code{by} variables for which the \code{.data} has
#' multiple unique rows, along with the number of unique rows for each
#' combination of values, only considering columns in \code{col}.
#'
#' \code{assert_single_value()} throws an error if there are multiple unique rows for
#' any combination of \code{by} variable values, only considering columns in \code{col}.
#'
#' @param .data A data frame or data table
#' @param col tidy-select. Columns in \code{.data}. When counting the number of unique
#' rows, only the columns specified in \code{col} are considered.
#' @param by tidy-select. Columns in \code{.data}.
#' @param setkey Logical. Should the output be keyed by \code{by} cols?
#'
#' @return
#' \describe{
#' \item{\code{count_values()}}{A \code{data.table} with the (filtered)
#' \code{by} columns and an additional column "n_vals" which shows the number of
#' unique rows in \code{.data} having the combination of \code{by} values shown
#' in the output row.}
#'
#' \item{\code{assert_single_value()}}{No return value. Called to throw an
#' error depending on the input.}
#' }

#' @examples
#' df <- read.table(text = "
#' x y z
#' a 1 3
#' a 1 3
#' a 2 4
#' a 2 4
#' a 2 2
#' b 1 1
#' b 1 2
#' ", header = TRUE)
#'
#' count_values(df, z, by = c(x, y))
#'
#' \dontrun{
#' assert_single_value(df, z, by = c(x, y))
#' }
#'
#' @rdname count-values
#' @export
count_values <- function(.data, col, by, setkey = FALSE) {
  if (missing(col) || missing(by)) {
    abort(glue("Must provide arguments `col` and `by`"))
  }
  col_names <- name_select(enexpr(col), .data)
  by_names <- name_select(enexpr(by), .data)
  out <-
    seij(.data, j = c(col_names, by_names)) %>%
    as.data.table() %>%
    unique() %>%
    .[, .(n_vals = .N), by = by_names] %>%
    .[n_vals > 1]
  if (setkey) {
    setkeyv(out, by_names)[]
  } else {
    out[]
  }
}

#' @rdname count-values
#' @export
assert_single_value <- function(.data, col, by) {
  if (missing(col) || missing(by)) {
    abort(glue("Must provide arguments `col` and `by`"))
  }
  first_multival <- head(count_values(.data, {{ col }}, {{ by }}), 1)
  if (nrow(first_multival) > 0) {
    first_multival_print <- capture.output(print(first_multival, row.names = FALSE))
    data_chr <- arg_to_char(.data, 15)
    col_char <- arg_to_char(col)
    by_char <- arg_to_char(by, 20)
    msg <- c(
      glue("Input `{data_chr}` has multiple unique rows within a single group"),
      glue("grouping: `{by_char}`"),
      glue("columns considered: `{col_char}`")
    )
    tip <- glue("Use `count_values()` to see all groups with multiple values.")
    abort(c(msg, first_multival_print, tip))
  }
  invisible()
}
