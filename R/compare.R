#' Compare two data frames
#' @param .data_a A data frame
#' @param .data_b A data frame
#' @param by tidy-select selection of columns
#' @param allow_bothNA Logical. If TRUE a missing value in both data frames is
#' considered as equal
#' @param ncol_by_out Number of by-columns to include in `col_diffs` and
#' `unmatched_rows` output
#' @param coerce Logical. If False only columns with the same class are compared.
#' @param comparison The output of a `tablecompare::tablecompare()` call.

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
      table = c('a', 'b'),
      name = c(.data_a_chr, .data_b_chr),
      ncol = c(ncol(.data_a), ncol(.data_b)),
      nrow = c(nrow(.data_a), nrow(.data_b))
    )

  .data_a <- setkeyv(as.data.table(.data_a)[, i := .I], by_names)
  .data_b <- setkeyv(as.data.table(.data_b)[, i := .I], by_names)

  assert_unique(.data_a, all_of(by_names), by_chr = by_chr)
  assert_unique(.data_b, all_of(by_names), by_chr = by_chr)

  cols <- merge_split(
    get_contents(.data_a[, -'i']), get_contents(.data_b[, -'i']), by = column,
    present_ind = class
  )
  setorder(cols$common, class_a, class_b, column)
  if (nrow(cols$unmatched)) setorder(cols$unmatched, table, class, column)

  cols <- list(
    by = cols$common[column %in% by_names],
    compare = cols$common[!column %in% by_names],
    unmatched = cols$unmatched
  )

  if (nrow(cols$unmatched)) {
    quietly(set)(.data_a, j = cols$unmatched['a', column], value = NULL)
    quietly(set)(.data_b, j = cols$unmatched['b', column], value = NULL)
  }

  .data <- merge_split(
    .data_a, .data_b, by = all_of(by_names), present_ind = i,
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
  value_diffs <-
    lapply(to_compare, function(name) {
      cols_comp <- glue("{name}_{c('a', 'b')}")
      cols_keep <- c('i_a', 'i_b', cols_comp, by_names_out)
      out <-
        .data$common[, ..cols_keep] %>%
          setnames(cols_comp, c("val_a", "val_b"))
      if (allow_bothNA) {
        out[fcoalesce(val_a != val_b, is.na(val_a) + is.na(val_b) == 1L)]
      } else {
        out[fcoalesce(val_a != val_b, is.na(val_a), is.na(val_b))]
      }
    }) %>%
      setNames(to_compare)

    cols$compare[, n_diffs := sapply(value_diffs, nrow)[column]]
    cols$compare <- cols$compare[, .(column, n_diffs, class_a, class_b)]
    if (nrow(cols$unmatched)) {
      cols$unmatched <- cols$unmatched[, .(table, column, class)]
    }

    cols$compare[, value_diffs := value_diffs[column]]
    setkey(cols$compare, column)

    structure(
      list(tables = table_summ,
           by = cols$by,
           summ = cols$compare,
           unmatched_cols = cols$unmatched,
           unmatched_rows = .data$unmatched),
      class = 'tbcmp_compare')
}

#' @rdname tblcompare
#' @export
value_diffs <- function(comparison) {
  if (!inherits(comparison, 'tbcmp_compare')) {
    abort("`comparison` must be output of `tablecompare::compare()`")
  }
  comparison$summ[, value_diffs[[1]], keyby = column]
}

# Helpers ---------

merge_split <- function(.data_a, .data_b, by, present_ind, ncol_by_out = Inf) {
  # merge with all = TRUE, then split into common and unmatched
  by_names <- name_select(enquo(by), .data_a)
  by_names_out <- by_names[seq_len(min(ncol_by_out, length(by_names)))]
  present_ind <- arg_to_char(present_ind, shorten = FALSE)

  setnames(.data_a, function(x) suffix(x, 'a', exclude = by_names))
  setnames(.data_b, function(x) suffix(x, 'b', exclude = by_names))
  .data <- merge(.data_a, .data_b, by = by_names, all = TRUE)
  setnames(.data_a, function(x) unsuffix(x, 'a', exclude = by_names))
  setnames(.data_b, function(x) unsuffix(x, 'b', exclude = by_names))

  var_a <- glue("{present_ind}_a")
  var_b <- glue("{present_ind}_b")
  .data_split <- .data[, fcase(is.na(get(var_b)), 'a',
                               is.na(get(var_a)), 'b',
                               rep(TRUE, .N), 'common')]
  .data <- split(.data, .data_split)

  .data$unmatched <-
    imap_dfr(.data[c("a", "b")], ~ {
      if (!is.null(.x)) {
        cols_keep <- c(glue("{present_ind}_{.y}"), by_names_out)
        setnames(
          .x[, ..cols_keep],
          function(x) unsuffix(x, .y, exclude = by_names_out)
        )
      }
    }, .id = 'table') %>%
      as.data.table
  if (nrow(.data$unmatched)) setkey(.data$unmatched, table)
  .data[c("a", "b")] <- NULL
  .data
}

suffix <- function(x, suffix, exclude = character()) {
  include <- !x %in% exclude
  x[include] <- paste0(x[include], '_', suffix)
  x
}

unsuffix <- function(x, suffix, exclude = character()) {
  include <- !x %in% exclude
  x[include] <- sub(glue("_{suffix}$"), "", x[include])
  x
}
