#' Check for duplicate rows
#'
#' @description
#' `count_dupes()` returns values of `by` variables for which the `.data` has
#' multiple rows, along with the number of rows for each combination of values.
#'
#' `assert_unique()` throws an error if there are multiple rows for any
#' combination of `by` variable values
#'
#' @param .data A data frame or data table
#' @param by tidy-select. Columns in `.data`
#' @param setkey Logical. Should the output be keyed by `by` cols?
#' @param data_chr optional. character. You can use this argument to manually specify
#' the name of `data` shown in error messages. Useful when using these functions
#' as checks inside other functions.
#' @param by_chr optional. character. You can use this argument to manually specify
#' the name of `by` shown in error messages. Useful when using these functions
#' as checks inside other functions.
#'
#' @examples
#' df <- read.table(text = "
#' x y z
#' 1 6 1
#' 2 6 2
#' 3 7 3
#' 3 7 4
#' 4 3 5
#' 4 3 6
#' ", header = TRUE)
#'
#' count_dupes(df, c(x, y))
#' \dontrun{
#' assert_unique(df, c(x, y))
#' #> Error in `assert_unique()`:
#' #> ! Input `df` is not unique by `c(x, y)`.
#' #> • First duplicate:
#' #> •  n_rows     x     y
#' #> •   <int> <int> <int>
#' #> •       2     3     7
#' #> • Use `count_dupes()` to see all duplicates.
#' }
#'
#' @rdname count-dupes
#' @export
count_dupes <- function(.data, by, setkey = FALSE) {
  if (missing(by)) {
    by <- names(.data)
  } else {
    by <- name_select(enquo(by), .data)
  }
  if (setkey) {
    counts <- as.data.table(.data)[, .(n_rows = .N), keyby = by]
  } else {
    counts <- as.data.table(.data)[, .(n_rows = .N), by = by]
  }
  counts[n_rows > 1]
}

#' @rdname count-dupes
#' @export
assert_unique <- function(.data, by, data_chr, by_chr) {
  if (missing(data_chr)) {
    data_chr <- arg_to_char(.data, 15)
  }
  if (missing(by)) {
    by <- names(.data)
    by_chr <- glue("names({data_chr})")
  } else if (missing(by_chr)) {
    by_chr <- arg_to_char(by, 20)
  }
  msg <- glue("Input `{data_chr}` is not unique by `{by_chr}`.")
  msg2 <- glue("Use `count_dupes()` to see all duplicates.")

  first_dupe <-
    head(count_dupes(.data, {{ by }}), 1) %>%
    setcolorder(c("n_rows", setdiff(names(.), "n_rows")))
  if (nrow(first_dupe) > 0) {
    first_dupe_print <- capture.output(
      print(first_dupe[], row.names = FALSE, trun.cols = TRUE)
    )
    abort(c(msg, "First duplicate:", first_dupe_print, msg2))
  }
  invisible()
}
