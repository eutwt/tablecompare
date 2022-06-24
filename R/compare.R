#' Compare two data frames
#'
#' @param .data_a A data frame or data table
#' @param .data_b A data frame or data table
#' @param by tidy-select. Selection of columns to use when matching rows between
#' \code{.data_a} and \code{.data_b}. Both data frames must be unique on \code{by}.
#' @param allow_bothNA Logical. If \code{TRUE} a missing value in both data frames is
#' considered as equal
#' @param ncol_by_out Number of by-columns to include in \code{value_diffs} and
#' \code{unmatched_rows} output
#' @param coerce Logical. If \code{FALSE} only columns with the same class are compared.
#' @param comparison An object of class "tbcmp_compare" (the output of a
#' \code{tablecompare::tablecompare()} call)
#' @param col tidy-select. A single column
#'
#' @return
#' \describe{
#' \item{\code{tblcompare()}}{A "tbcmp_compare"-class object, which is a list
#' of \code{data.table}s having the following elements:
#' \describe{
#'   \item{tables}{
#'     A \code{data.table} with one row per input table showing the number of rows
#'     and columns in each.
#'   }
#'   \item{by}{
#'     A \code{data.table} with one row per \code{by} column showing the class
#'     of the column in each of the input tables.
#'  }
#'  \item{summ}{
#'    A \code{data.table} with one row per column common to \code{.data_a} and
#'    \code{.data_b} and columns "n_diffs" showing the number of values which
#'    are different between the two tables, "class_a"/"class_b" the class of the
#'    column in each table, and "value_diffs" a (nested) \code{data.table} showing
#'    the rows in each input table where values are unequal, the values in each
#'    table, and one column for each of the first \code{ncol_by_out} \code{by} columns for
#'    the identified rows in the input tables.
#'  }
#'  \item{unmatched_cols}{
#'    A \code{data.table} with one row per column which is in one input table but
#'    not the other and columns "table": which table the column appears in,
#'    "column": the name of the column, and "class": the class of the
#'    column.
#'  }
#'  \item{unmatched_rows}{
#'    A \code{data.table} which, for each row present in one input table but not
#'    the other, contains the columns "table": which table the row appears in,
#'    "i" the row number of the input row, and one column for each of the first
#'    \code{ncol_by_out} \code{by} columns for each row.
#'  }
#' }
#' }
#' \item{\code{value_diffs()}}{A \code{data.table} with one row for each element
#' of \code{col} found to be unequal between the input tables (
#' \code{.data_a} and \code{.data_b} from the original \code{tblcompare()} call)
#' The output table has columns "i_a"/"i_b": the row number of the element in the input
#' tables, "val_a"/"val_b": the value of \code{col} in the input tables, and one column for
#' each of the first \code{ncol_by_out} \code{by} columns for the identified rows in the
#' input tables.}
#'
#' \item{\code{all_value_diffs()}}{A \code{data.table} of the \code{value_diffs()}
#' output for all columns having at least one value difference, combined row-wise
#' into a single table. To facilitate this combination into a single table, the
#' "val_a" and "val_b" columns are coerced to character.}
#' }


#' @rdname tblcompare
#' @export
tblcompare <- function(.data_a, .data_b, by, allow_bothNA = TRUE, ncol_by_out = 3,
                       coerce = TRUE) {
  if (missing(by)) {
    abort("Argument `by` cannot be missing")
  }
  by_names <- name_select(enquo(by), .data_a)
  ncol_by_out <- min(ncol_by_out, length(by_names))
  by_names_out <- by_names[seq_len(ncol_by_out)]
  by_chr <- arg_to_char(by, 20)
  .data_a_chr <- arg_to_char(.data_a)
  .data_b_chr <- arg_to_char(.data_b)
  table_summ <-
    data.table(
      table = c("a", "b"),
      name = c(.data_a_chr, .data_b_chr),
      ncol = c(ncol(.data_a), ncol(.data_b)),
      nrow = c(nrow(.data_a), nrow(.data_b))
    )

  .data_a <- setkeyv(as.data.table(.data_a)[, i := .I], by_names)
  .data_b <- setkeyv(as.data.table(.data_b)[, i := .I], by_names)

  assert_unique(.data_a, all_of(by_names), by_chr = by_chr)
  assert_unique(.data_b, all_of(by_names), by_chr = by_chr)

  cols <- merge_split(
    get_contents(.data_a[, -"i"]), get_contents(.data_b[, -"i"]),
    by = column,
    present_ind = class
  )
  setorder(cols$common, class_a, class_b, column)
  setorder(cols$unmatched, table, class, column)
  setcolorder(cols$unmatched, c('table', 'column', 'class'))

  cols <- list(
    by = cols$common[column %in% by_names],
    compare = cols$common[!column %in% by_names],
    unmatched = cols$unmatched
  )

  if (nrow(cols$unmatched)) {
    quietly(set)(.data_a, j = cols$unmatched["a", column], value = NULL)
    quietly(set)(.data_b, j = cols$unmatched["b", column], value = NULL)
  }

  .data <- merge_split(
    .data_a, .data_b,
    by = all_of(by_names), present_ind = i,
    ncol_by_out = ncol_by_out
  )
  rm(.data_a, .data_b)
  if (is.null(.data$common)) {
    abort("No rows found in common. Check data and `by` argument.")
  }

  if (coerce) {
    to_compare <- cols$compare$column
  } else {
    to_compare <- cols$compare[class_a == class_b, column]
  }
  value_diffs <- lapply(to_compare, function(name) {
    val_a <- sym(glue("{name}_a"))
    val_b <- sym(glue("{name}_b"))

    inject(
      .data$common[
        i = {
          if (allow_bothNA) {
            fcoalesce(!!val_a != !!val_b, is.na(!!val_a) + is.na(!!val_b) == 1L)
          } else {
            fcoalesce(!!val_a != !!val_b, is.na(!!val_a), is.na(!!val_b))
          }
        },
        j = .(i_a, i_b, val_a = !!val_a, val_b = !!val_b, !!!syms(by_names_out))
      ]
    )
  }) %>%
    setNames(to_compare)

  cols$compare[, n_diffs := sapply(value_diffs, nrow)[column]]
  cols$compare <- cols$compare[, .(column, n_diffs, class_a, class_b)]

  cols$compare[, value_diffs := value_diffs[column]]
  setkey(cols$compare, column)

  structure(
    list(
      tables = table_summ,
      by = cols$by,
      summ = cols$compare,
      unmatched_cols = cols$unmatched,
      unmatched_rows = .data$unmatched
    ),
    class = "tbcmp_compare"
  )
}

#' @rdname tblcompare
#' @export
value_diffs <- function(comparison, col){
  UseMethod("value_diffs")
}

value_diffs.tbcmp_compare <- function(comparison, col) {
  col_nm <- name_select(enquo(col), simulate_df(comparison$summ$column))
  if (length(col_nm) != 1) {
    abort("must provide single column to `col`")
  }
  comparison$summ[col_nm, value_diffs[[1]]]
}

#' @rdname tblcompare
#' @export
all_value_diffs <- function(comparison) {
  UseMethod("all_value_diffs")
}

all_value_diffs.tbcmp_compare <- function(comparison) {
  val_cols <- c("val_a", "val_b")
  comparison$summ[n_diffs > 0,
    {
      copy(value_diffs[[1]])[,
        (val_cols) := lapply(.SD, as.character),
        .SDcols = val_cols
      ]
    },
    keyby = column
  ]
}

# Helpers ---------

merge_split <- function(.data_a, .data_b, by, present_ind, ncol_by_out = Inf) {
  # merge with all = TRUE, then split into common and unmatched
  by_names <- name_select(enquo(by), .data_a)
  by_names_out <- by_names[seq_len(min(ncol_by_out, length(by_names)))]
  present_ind <- arg_to_char(present_ind, shorten = FALSE)

  setnames(.data_a, function(x) suffix(x, "a", exclude = by_names))
  setnames(.data_b, function(x) suffix(x, "b", exclude = by_names))
  .data <- merge(.data_a, .data_b, by = by_names, all = TRUE)

  p_a <- sym(glue("{present_ind}_a"))
  p_b <- sym(glue("{present_ind}_b"))
  inject(.data[, a_na := is.na(!!p_a)])
  is_unmatched <- inject(.data[, a_na | is.na(!!p_b)])
  unmatched <- inject(
    .data[
      i = is_unmatched,
      j = .(
        table = fifelse(a_na, "b", "a"),
        present_ind = fifelse(a_na, !!p_b, !!p_a),
        !!!syms(by_names_out)
      )
    ]
  )
  setnames(unmatched, "present_ind", present_ind)
  setkey(unmatched, table)
  set(.data, j = 'a_na', value = NULL)

  list(unmatched = unmatched, common = .data[!is_unmatched])
}

suffix <- function(x, suffix, exclude = character()) {
  include <- !x %in% exclude
  x[include] <- paste0(x[include], "_", suffix)
  x
}

unsuffix <- function(x, suffix, exclude = character()) {
  include <- !x %in% exclude
  x[include] <- sub(glue("_{suffix}$"), "", x[include])
  x
}
