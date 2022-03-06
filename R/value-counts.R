#' Check for duplicate values
#' todo: add return value description
#'
#'
#' `count_values()` returns groups with non-unique values, along with the number
#' of unique values in each group
#' `assert_single_value()` throws an error if any groups with multiple values
#' exist
#'
#' `count_dupes()` returns values of `by` variables for whih the `.data` has
#' multiple rows, along with the number of rows for each combination of values
#' `assert_unique()` throws an error if there are multiple rows for any
#' combination of `by` variable values
#'
#' @param .data A data frame or data frame extension (e.g. a tibble)
#' @param col tidy-select. A single column in `.data`
#' @param by tidy-select. Columns in `.data`
#' @param setkey Logical. Should the output be keyed by `by` cols?

#' @rdname value-counts
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

#' @rdname value-counts
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

#' @rdname value-counts
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

#' @rdname value-counts
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
      setcolorder('n_rows', before = 1)
  if (nrow(first_dupe) > 0) {
    first_dupe_print <- capture.output(
      print(first_dupe[], row.names = FALSE, trun.cols = TRUE)
    )
    abort(c(msg, "First duplicate:", first_dupe_print, msg2))
  }
  invisible()
}
