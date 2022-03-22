
test_that("count_values correctly counts values", {
  df <- data.frame(x = rep("a", 5), y = rep(1:2, 2:3), z = c(3, 3, 4, 4, 2))

  res <- count_values(df, z, by = c(x, y), setkey = TRUE)
  exp <- data.table(x = "a", y = 2, n_vals = 2) %>%
    setkey(x, y)
  expect_equal(res, exp)

  res <- count_values(df, z, by = c(x, y))
  exp <- data.table(x = "a", y = 2, n_vals = 2)
  expect_equal(res, exp)
})

test_that("assert_single_value errors on multiple values", {
  df <- data.frame(x = rep("a", 5), y = rep(1:2, 2:3), z = c(3, 3, 4, 4, 2))
  expect_snapshot_error(assert_single_value(df, z, by = c(x, y)))
})

test_that("assert_single_value is silent on single value", {
  df <- data.frame(x = rep("a", 5), y = rep(1:2, 2:3), z = c(3, 3, 4, 4, 4))
  expect_silent(assert_single_value(df, z, by = c(x, y)))
})

test_that("count_dupes counts duplicates correctly", {
  df <- data.frame(x = c(1, 2, 3, 4, 4), y = c(6, 6, 7, 3, 3))

  res <- count_dupes(df, by = c(x, y))
  exp <- data.table(x = 4, y = 3, n_rows = 2)
  expect_equal(res, exp)

  res <- count_dupes(df, by = c(x, y), setkey = TRUE)
  exp <- data.table(x = 4, y = 3, n_rows = 2) %>% setkey(x, y)
  expect_equal(res, exp)
})
