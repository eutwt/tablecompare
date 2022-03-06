# Error on input with duplicates

    Input `.data_a` is not unique by `c(disp, cyl)`.
    * First duplicate:
    * Key: <disp, cyl>
    *  n_rows  disp   cyl
    *   <int> <num> <num>
    *       2   160     6
    * Use `count_dupes()` to see all duplicates.

# value_diffs example

    Code
      comp
    Output
      $tables
          table   name  ncol  nrow
         <char> <char> <int> <int>
      1:      a   df_a    13    11
      2:      b   df_b    12    12
      
      $by
         column   class_a   class_b
         <char>    <char>    <char>
      1:    car character character
      
      $summ
      Key: <column>
          column n_diffs class_a   class_b       value_diffs
          <char>   <int>  <char>    <char>            <list>
       1:     am       0 numeric   numeric <data.table[0x5]>
       2:   carb       0 numeric   numeric <data.table[0x5]>
       3:    cyl       0 numeric   numeric <data.table[0x5]>
       4:   disp       2 numeric   numeric <data.table[2x5]>
       5:   drat       0 numeric   numeric <data.table[0x5]>
       6:   gear       0 numeric   numeric <data.table[0x5]>
       7:     hp       0 numeric   numeric <data.table[0x5]>
       8:    mpg       2 numeric   numeric <data.table[2x5]>
       9:   qsec       0 numeric   numeric <data.table[0x5]>
      10:     vs       0 numeric   numeric <data.table[0x5]>
      11:     wt       0 numeric character <data.table[0x5]>
      
      $unmatched_cols
      Key: <table>
          table     column   class
         <char>     <char>  <char>
      1:      a extracol_a numeric
      
      $unmatched_rows
      Key: <table>
          table     i        car
         <char> <int>     <char>
      1:      a     1  Mazda RX4
      2:      a    11    extra_a
      3:      b    10  Merc 280C
      4:      b    11 Merc 450SE
      5:      b    12    extra_b
      

---

    Code
      comp$summ[, value_diffs[[1]], .(column)]
    Output
      Key: <column>
         column   i_a   i_b val_a val_b            car
         <char> <int> <int> <num> <num>         <char>
      1:   disp     3     2 109.0 108.0     Datsun 710
      2:   disp     4     3 259.0 258.0 Hornet 4 Drive
      3:    mpg     7     6  14.3  16.3     Duster 360
      4:    mpg     8     7  24.4  26.4      Merc 240D

# value_diffs example allow_bothNA = FALSE

    Code
      comp
    Output
      $tables
          table   name  ncol  nrow
         <char> <char> <int> <int>
      1:      a   df_a    13    11
      2:      b   df_b    12    12
      
      $by
         column   class_a   class_b
         <char>    <char>    <char>
      1:    car character character
      
      $summ
      Key: <column>
          column n_diffs class_a   class_b       value_diffs
          <char>   <int>  <char>    <char>            <list>
       1:     am       0 numeric   numeric <data.table[0x5]>
       2:   carb       0 numeric   numeric <data.table[0x5]>
       3:    cyl       1 numeric   numeric <data.table[1x5]>
       4:   disp       2 numeric   numeric <data.table[2x5]>
       5:   drat       0 numeric   numeric <data.table[0x5]>
       6:   gear       0 numeric   numeric <data.table[0x5]>
       7:     hp       0 numeric   numeric <data.table[0x5]>
       8:    mpg       2 numeric   numeric <data.table[2x5]>
       9:   qsec       0 numeric   numeric <data.table[0x5]>
      10:     vs       0 numeric   numeric <data.table[0x5]>
      11:     wt       0 numeric character <data.table[0x5]>
      
      $unmatched_cols
      Key: <table>
          table     column   class
         <char>     <char>  <char>
      1:      a extracol_a numeric
      
      $unmatched_rows
      Key: <table>
          table     i        car
         <char> <int>     <char>
      1:      a     1  Mazda RX4
      2:      a    11    extra_a
      3:      b    10  Merc 280C
      4:      b    11 Merc 450SE
      5:      b    12    extra_b
      

---

    Code
      comp$summ[, value_diffs[[1]], .(column)]
    Output
      Key: <column>
         column   i_a   i_b val_a val_b            car
         <char> <int> <int> <num> <num>         <char>
      1:    cyl     3     2    NA    NA     Datsun 710
      2:   disp     3     2 109.0 108.0     Datsun 710
      3:   disp     4     3 259.0 258.0 Hornet 4 Drive
      4:    mpg     7     6  14.3  16.3     Duster 360
      5:    mpg     8     7  24.4  26.4      Merc 240D

# value_diffs example coerce = FALSE

    Code
      comp
    Output
      $tables
          table   name  ncol  nrow
         <char> <char> <int> <int>
      1:      a   df_a    13    11
      2:      b   df_b    12    12
      
      $by
         column   class_a   class_b
         <char>    <char>    <char>
      1:    car character character
      
      $summ
      Key: <column>
          column n_diffs class_a   class_b       value_diffs
          <char>   <int>  <char>    <char>            <list>
       1:     am       0 numeric   numeric <data.table[0x5]>
       2:   carb       0 numeric   numeric <data.table[0x5]>
       3:    cyl       0 numeric   numeric <data.table[0x5]>
       4:   disp       2 numeric   numeric <data.table[2x5]>
       5:   drat       0 numeric   numeric <data.table[0x5]>
       6:   gear       0 numeric   numeric <data.table[0x5]>
       7:     hp       0 numeric   numeric <data.table[0x5]>
       8:    mpg       2 numeric   numeric <data.table[2x5]>
       9:   qsec       0 numeric   numeric <data.table[0x5]>
      10:     vs       0 numeric   numeric <data.table[0x5]>
      11:     wt      NA numeric character                  
      
      $unmatched_cols
      Key: <table>
          table     column   class
         <char>     <char>  <char>
      1:      a extracol_a numeric
      
      $unmatched_rows
      Key: <table>
          table     i        car
         <char> <int>     <char>
      1:      a     1  Mazda RX4
      2:      a    11    extra_a
      3:      b    10  Merc 280C
      4:      b    11 Merc 450SE
      5:      b    12    extra_b
      

---

    Code
      comp$summ[, value_diffs[[1]], .(column)]
    Output
      Key: <column>
         column   i_a   i_b val_a val_b            car
         <char> <int> <int> <num> <num>         <char>
      1:   disp     3     2 109.0 108.0     Datsun 710
      2:   disp     4     3 259.0 258.0 Hornet 4 Drive
      3:    mpg     7     6  14.3  16.3     Duster 360
      4:    mpg     8     7  24.4  26.4      Merc 240D

