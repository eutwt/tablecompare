#' Show the contents of a data frame
#' @param .data A data frame
#' @param cat_nrow Logical. If true, the number of rows is `cat`ed out
#' @param big_mark Passed to the `big.mark` argument of `format` when formatting
#' the number of rows

#' @rdname contents
#' @export
contents <- function(.data, cat_nrow = TRUE, big_mark = ',') {
  if (!ncol(.data)) return(data.table())
  if (cat_nrow) {
    cat("Number of Rows:", format(nrow(.data), big.mark = big_mark),  "\n")
  }
  get_contents(.data)
}

get_contents <- function(.data) {
  out <-
    as.data.table(.data[1,]) %>%
      .[, lapply(.SD, function(x) glue_collapse(class(x), ', '))] %>%
      transpose(keep.names = 'column') %>%
      setnames('V1', 'class') %>%
      setorder(class, column)
  out[]
}
