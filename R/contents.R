#' Show the contents of a data frame
#' @param .data A data frame
#' @return A \code{data.table} having the below-listed columns, one row per column in \code{.data}
#' \describe{
#'   \item{column}{The name of the column in \code{.data} (character)}
#'   \item{class}{
#'       Shows the output of a \code{class()} call on the column in \code{.data}
#'       (character). If \code{class()} returns a length > 1 vector, the elements
#'       are combined into one comma-separated string
#'  }
#' }
#' @examples
#' \donttest{
#' contents(ToothGrowth)
#' #>    column   class
#' #>    <char>  <char>
#' #> 1:   supp  factor
#' #> 2:   dose numeric
#' #> 3:    len numeric
#' }
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
