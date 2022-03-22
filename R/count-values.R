#' Check for existence of multiple values per group
#'
#' @description
#' `count_values()` returns values of `by` variables for which the `.data` has
#' multiple unique rows, along with the number of unique rows for each
#' combination of values, only considering columns in `col`
#'
#' `assert_single_value()` throws an error if there are multiple unique rows for
#' any combination of `by` variable values, only considering columns in `col`
#'
#' @param .data A data frame or data table
#' @param col tidy-select. A single column in `.data`
#' @param by tidy-select. Columns in `.data`
#' @param setkey Logical. Should the output be keyed by `by` cols?
#'
#' @examples
#' \dontrun{
#' df <- read.table(text = '
#' x y z
#' a 1 3
#' a 1 3
#' a 2 4
#' a 2 4
#' a 2 2
#' b 1 1
#' b 1 2
#' ', header = TRUE)
#'
#' assert_single_value(df, z, by = c(x, y))
#' #> Error in `assert_single_value()`:
#' #> ! Column `z` is not unique by `c(x, y)`.
#' #> •       x     y n_vals
#' #> •  <char> <int>  <int>
#' #> •       a     2      2
#' #> • Use `count_values()` to see all groups with multiple values.
#'
#' count_values(df, z, by = c(x, y))
#' #>         x     y n_vals
#' #>    <char> <int>  <int>
#' #> 1:      a     2      2
#' #> 2:      b     1      2
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
      as.data.table %>%
      unique %>%
      .[, .(n_vals = .N), by = by_names] %>%
      .[n_vals > 1]
  if (setkey)
    setkeyv(out, by_names)[]
  else
    out[]
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
    col_char <- arg_to_char(col)
    by_char <- arg_to_char(by, 20)
    msg <- glue("Column `{col_char}` is not unique by `{by_char}`.")
    msg2 <- glue("Use `count_values()` to see all groups with multiple values.")
    abort(c(msg, first_multival_print, msg2))
  }
  invisible()
}
