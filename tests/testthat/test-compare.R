test_that("Error on input with duplicates", {
 expect_snapshot_error(
   compare(mtcars, mtcars, by = c(disp, cyl))
 )
})

df_a <-
  mtcars %>%
    as.data.table(keep.rownames = "car") %>%
    .[, ':='(disp = replace(disp, 3:4, disp[3:4] + 1),
             cyl = replace(cyl, 3, NA),
             extracol_a = 1)] %>%
    .[1:10] %>%
    rbind(., .[1][, car := "extra_a"])

df_b <-
  mtcars %>%
    as.data.table(keep.rownames = "car") %>%
    .[, ':='(mpg = replace(mpg, 7:8, mpg[7:8] + 2),
             cyl = replace(cyl, 3, NA),
             wt = as.character(wt))] %>%
    .[2:12] %>%
    rbind(., .[1][, car := "extra_b"])


test_that("value_diffs example", {
  comp <- compare(df_a, df_b, by = car)
  expect_snapshot(comp)
  expect_snapshot(comp$summ[, value_diffs[[1]], .(column)])
})

test_that("value_diffs example allow_bothNA = FALSE", {
  comp <- compare(df_a, df_b, by = car, allow_bothNA = FALSE)
  expect_snapshot(comp)
  expect_snapshot(comp$summ[, value_diffs[[1]], .(column)])
})

test_that("value_diffs example coerce = FALSE", {
  comp <- compare(df_a, df_b, by = car, coerce = FALSE)
  expect_snapshot(comp)
  expect_snapshot(comp$summ[, value_diffs[[1]], .(column)])
})
