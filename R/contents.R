#' Show the contents of a data frame
#' @param .data A data frame or data table
#'
#' @return A \code{data.table} with one row per column in \code{.data} and columns
#' "column": The name of the column in \code{.data}, "class": the names of classes
#' the column inherits from (as returned by \code{class()}), collapsed into a single string.
#'
#' @examples
#' contents(ToothGrowth)
#'
#' @rdname contents
#' @export
contents <- function(.data) {
  if (!ncol(.data)) {
    return(data.table())
  }
  get_contents(.data)
}

get_contents <- function(.data) {
  out <-
    as.data.table(.data[1, ]) %>%
    .[, lapply(.SD, function(x) glue_collapse(class(x), ", "))] %>%
    transpose(keep.names = "column") %>%
    setnames("V1", "class") %>%
    setorder(class, column)
  out[]
}
