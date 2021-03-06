
#' Tabulation Methods
#'
#' \code{rtablulate} provides a number of methods to derive
#' \code{\link{rtable}}s. Conceptually the \code{rtabulate} has it's origin in
#' \code{\link{tapply}}.
#' 
#' The data is split into cell-data and a function can be specified that return
#' a data structre (or \code{\link{rcell}}).
#'   
#' @param x either a vector or \code{data.frame}
#' @param ... arguments passed to methods
#' 
#' @return an \code{\link{rtable}} project
#' 
#' @author Adrian Waddell
#'       
#' @export
#' 
rtabulate <- function(x, ...) {
  UseMethod("rtabulate")
}


#' Do not split data into columns or row in \code{rtabulate}
#' 
#' \code{\link{rtabulate}} has the arguments \code{col_by} and \code{row_by}
#' which can either take a vector or if no splitting is needed the return value
#' of \code{no_by}.
#' 
#' @param name row name or column name
#' 
#' @export
#' 
no_by <- function(name) {
  structure(name, class = "no_by")
}

#' Check if object inherits from the \code{no_by} Class
#' 
#' Functions to test inheritance on \code{no_by}
#' 
#' @param x an object
#' 
#' @return \code{TRUE} or \code{FALSE}
#' 
#' @export
is.no_by <- function(x) {
  is(x, "no_by")
}

rtabulate_header <- function(col_by, Ntot, N=NULL, format="(N=xx)") {
  if (!is.factor(col_by) && !is.no_by(col_by)) stop("col_by is required to be a factor or no_by object")
  
  lvls <- if (is.no_by(col_by)) as.vector(col_by) else levels(col_by)
  
  if (is.null(format)) {
    rheader(lvls)
  } else {
    if (is.null(N)) {
      N <- if (is.no_by(col_by)) Ntot else tapply(col_by, col_by, length)
    }
    rheader(
      rrowl("", lvls),
      rrowl("", unname(N), format = format)
    )
  }
}

# rtabulate default for vectors
# 
# this method is used for vectors of type \code{logical} and \code{numeric}
# 
# see parameter descrition for rtabulate.numeric
#
rtabulate_default <- function(x, col_by = no_by("col_1"), FUN = NULL, ..., row_data_arg=FALSE,
                              format = NULL, row.name = "", indent  = 0, col_total = "(N=xx)") {
  
  if (is.null(FUN)) stop("FUN is required")
  
  stop_if_has_na(col_by)
  
  tbl_header <- rtabulate_header(col_by, length(x), format=col_total)
  
  xs <- if (is.no_by(col_by)) {
    setNames(list(x), col_by)
  } else {
    if (length(x) != length(col_by)) stop("dimension missmatch x and col_by")
    split(x, col_by, drop = FALSE)
  }

  col_data <- if (row_data_arg) {
    lapply(xs, FUN, x, ...)
  } else {
    lapply(xs, FUN, ...)
  }
  
  rr <- rrowl(row.name = row.name, col_data, format = format, indent = indent)
  
  rtable(header = tbl_header, rr)
  
}

#' tabulate a numeric vector
#' 
#' by default the \code{\link[stats]{fivenum}} function is applied to the
#' vectors associated to the cells
#' 
#' 
#' @inheritParams rrow
#' @param x a vecor
#' @param col_by a \code{\link{factor}} of length \code{nrow(x)} that defines
#'   which levels in \code{col_by} define a column. If data should not be split
#'   into columns use the \code{\link{no_by}} function.
#' @param FUN a function that processes the cell data, if \code{row_data_arg} is
#'   set to \code{TRUE} the a second argument with the row data is passed to
#'   \code{FUN}
#' @param ... arguments passed to \code{FUN}
#' @param row_data_arg call \code{FUN} with the row data as the second argument 
#' @param format if \code{FUN} does not return a formatted \code{\link{rcell}}
#'   then the \code{format} is applied
#' @param row.name if \code{NULL} then the \code{FUN} argument is deparsed and
#'   used as \code{row.name} of the \code{\link{rrow}}
#' @param col_total a format string for displaying the number of elements in the
#'   column header. If \code{NULL} then no header row for the column is
#'   displayed.
#' 
#' @inherit rtabulate return
#' 
#' @export
#' 
#' @examples 
#'
#' rtabulate(iris$Sepal.Length)
#'  
#' rtabulate(iris$Sepal.Length, col_by = no_by("Sepal.Length"))
#'  
#' with(iris,  rtabulate(x = Sepal.Length, col_by = Species, row.name = "fivenum"))
#'
#' SL <- iris$Sepal.Length
#' Sp <- iris$Species
#' rbind(
#'   rtabulate(SL, Sp, length, row.name = "n"),
#'   rtabulate(SL, Sp, function(x)c(mean(x), sd(x)), format = "xx.xx (xx.xx)", row.name = "Mean (SD)"),
#'   rtabulate(SL, Sp, median, row.name = "Median"),
#'   rtabulate(SL, Sp, range, format = "xx.xx - xx.xx", row.name = "Min - Max")
#' )
#' 
#' 
#' 
rtabulate.numeric <- function(x, col_by = no_by("col_1"), FUN = mean, ...,
                              row_data_arg = FALSE, format = NULL, row.name = NULL,
                              indent  = 0, col_total = "(N=xx)") {
  if (is.null(row.name)) row.name <- paste0(deparse(substitute(FUN)))
  rtabulate_default(x = x, col_by = col_by, FUN = FUN, ...,
                    row_data_arg = row_data_arg, format = format,
                    row.name = row.name, indent = indent,
                    col_total = col_total)
}

#' tabulate a logical vector
#' 
#' @inheritParams rtabulate.numeric
#' 
#' @inherit rtabulate return
#' 
#' @export
#' 
#' @examples 
#' rtabulate(iris$Species == "setosa")
#' 
#' rtabulate(iris$Species == "setosa", no_by("Species"), row.name = "n (n/N)")
#' 
#' # default: percentages equal \code{TRUE}
#' with(iris, rtabulate(Sepal.Length < 5, Species, row.name = "Sepal.Length < 5"))
#'  
#' # precentages with proportion of cell number of \code{TRUE}s to overvall
#' # number of \code{TRUE}s
#' with(iris, rtabulate(Sepal.Length < 5, Species, row.name = "Sepal.Length < 5",
#'   FUN = function(cell_data, row_data) sum(cell_data) * c(1, 1/sum(row_data)), 
#'   row_data_arg = TRUE
#' ))
#' 
rtabulate.logical <- function(x, col_by = no_by("col_1"),
                              FUN = function(x) sum(x) * c(1, 1/length(x)),
                              ...,
                              row_data_arg = FALSE,
                              format = "xx.xx (xx.xx%)",
                              row.name = "",
                              indent = 0,
                              col_total = "(N=xx)"
                              ) {
  if (is.null(row.name)) row.name <- paste0(deparse(substitute(FUN)))
  rtabulate_default(x = x, col_by = col_by, FUN = FUN, ...,
                    row_data_arg = row_data_arg, format = format,
                    row.name = row.name, indent = indent,
                    col_total = col_total)
}

#' Tabulate Factors
#' 
#' @inheritParams rtabulate.numeric
#' @param row_col_data_args boolean, if \code{TRUE} then \code{FUN} is called
#'   with the first three arguments being the cell, row, and column data,
#'   respectively
#' @param useNA boolean, if \code{TRUE} then \code{NA} values in \code{x} get
#'   turned into a factor level \code{"NA"}, if \code{FALSE} then the \code{NA}
#'   values in \code{x} get dropped.
#' 
#' @inherit rtabulate return
#' 
#' @export
#'
#' @examples 
#' 
#' rtabulate(x = iris$Species)
#' 
#' rtabulate(x = iris$Species, no_by("sum"))
#' 
#' sl5 <- factor(iris$Sepal.Length > 5, levels = c(TRUE, FALSE),
#'    labels = c("S.L > 5", "S.L <= 5"))
#' 
#' rtabulate(iris$Species, col_by=sl5)
#' 
#' rtabulate(iris$Species, col_by=sl5,
#'    FUN = function(cell_data, row_data, col_data) {
#'      if (length(cell_data) > 10) {
#'         length(cell_data) * c(1, 1/length(col_data))
#'      } else {
#'         rcell("-", format = "xx")
#'      }
#'    },
#'    row_col_data_args = TRUE,
#'    format = "xx (xx.xx%)"
#' )
#' 
#' rtabulate(sl5, iris$Species)
#' 
rtabulate.factor <- function(x,
                             col_by = no_by("col_1"), 
                             FUN = length,
                             ...,
                             row_col_data_args = FALSE,
                             useNA = c("no", "ifany", "always"),
                             format = "xx",
                             indent  = 0,
                             col_total = "(N=xx)") {

  stop_if_has_na(col_by)

  useNA <- match.arg(useNA)
  
  tbl_header <- rtabulate_header(col_by, length(x), format=col_total)
  
  if (useNA %in% c("ifany", "always")) {
    if (any("<NA>" %in% levels(x))) stop("cannot use useNA='ifany' or 'always' if there any levels called <NA>")
    
    if (useNA == "always" || any(is.na(x))) {
      levels(x) <- c(levels(x), "<NA>")
      x[is.na(x)] <- "<NA>"
    }
  } 
  
  ## note that splitting with empty-string creates a un-named list element
  if (any(levels(x) == "")) {
    if ("-" %in% levels(x)) stop("x currently cannot have '' and levels called -")
    levels(x) <- gsub("^$", "-", levels(x))
    warning("'' levels were turned into level -")
  }
    
  row_data_list <- split(x, x, drop = FALSE)
  
  cell_data <- if (is.no_by(col_by)) {
    lapply(row_data_list, function(row_i) setNames(list(row_i), col_by))
  } else {
    if (length(x) != length(col_by)) stop("dimension missmatch x and col_by")
    
    df <- data.frame(
      x = x,
      col_by = factor(col_by)
    )
    lapply(split(df, df$x, drop = FALSE), function(row_i) {
      split(row_i$x, row_i$col_by, drop = FALSE)
    })
  }
  
  rrow_data <- if (!row_col_data_args) {
    lapply(cell_data, function(row_i) lapply(row_i, FUN, ...)) 
  } else {
    
    col_data_list <- if (is.no_by(col_by)) {
      setNames(list(x), col_by)
    } else {
      split(x, col_by, drop = FALSE)
    }

    rrow_data_tmp <- lapply(1:length(row_data_list), function(i) {
      rrow_data_i <- lapply(1:length(col_data_list), function(j) {
        FUN(cell_data[[i]][[j]], row_data_list[[i]], col_data_list[[j]], ...)
      })
      names(rrow_data_i) <- names(col_data_list)
      rrow_data_i
    })
    names(rrow_data_tmp) <- names(row_data_list)
    rrow_data_tmp
  }
  
  rrows <- Map(function(row, rowname) rrowl(rowname, row, format = format, indent = indent), 
               rrow_data, names(rrow_data)) 
  
  rtablel(header = tbl_header, rrows)
}




#' Split data.frame and apply functions
#' 
#' @inheritParams rtabulate.factor
#' @param row_by_var name of factor variable in \code{x}
#' @param col_by_var name of factor variable in \code{x}
#' 
#' 
#' @inherit rtabulate return
#' 
#' @export
#' 
#' 
#' @examples 
#' df <- expand.grid(aaa = factor(c("A", "B")), bbb = factor(c("X", "Y", "Z")))
#' df <- rbind(df, df)
#' df$val <- 1:nrow(df)
#' 
#' rtabulate(
#'   x = df,
#'   row_by_var = "aaa",
#'   col_by_var = "bbb",
#'   FUN = function(x) {  
#'      sum(x$val)
#'   }
#' )
#' 
#' rtabulate(
#'   x = iris,
#'   row_by_var = no_by("sum"),
#'   col_by_var = "Species", 
#'   FUN = function(x) sum(x$Sepal.Length)
#' )
#' 
#' rtabulate(
#'   x = iris,
#'   row_by_var = "Species",
#'   col_by_var = no_by("sum"), 
#'   FUN = function(x) sum(x$Sepal.Length)
#' )
#' 
#' tbl <- rtabulate(
#'   x = iris,
#'   FUN = function(cell_data) c(sum(cell_data$Sepal.Length), sd(cell_data$Sepal.Length)),
#'   format = "xx.xx (xx.xx%)"
#' )
#' 
#' tbl 
#' 
#' row.names(tbl)
#' row.names(tbl) <- "Sum of Sepal Length"
#' 
#' tbl
#' 
#' iris2 <- iris
#' iris2$fsl5 <- factor(iris$Sepal.Length > 5, levels = c(TRUE, FALSE),
#'     labels = c("S.L > 5", "S.L <= 5"))
#' 
#' tbl <- rtabulate(
#'   x = iris2,
#'   row_by_var = "fsl5",
#'   col_by_var = "Species", 
#'   FUN = function(x_cell, x_row, x_col) {
#'     if (nrow(x_cell) < 10) {
#'       rcell("-")
#'     } else {
#'       fit <- lm(Sepal.Length ~ Petal.Width, data = x_cell)
#'       m_col <- mean(x_col$Sepal.Length)
#'       m_row <- mean(x_row$Sepal.Length)
#'     
#'       rcell(list(fit, m_col, m_row), format = function(x, output) {
#'         paste("df:", x[[1]]$df.residual,", and", round(x[[2]],1), ", and", round(x[[3]],2))
#'       })
#'     }
#'   } ,
#'   row_col_data_args = TRUE
#' )
#' tbl
rtabulate.data.frame <- function(x,
                                 row_by_var = no_by("row_1"),
                                 col_by_var = no_by("col_1"),
                                 FUN = nrow,
                                 ...,
                                 row_col_data_args = FALSE,
                                 format = "xx",
                                 indent = 0,
                                 col_total = "(N=xx)") {
  
  if (!is.no_by(row_by_var) && !is.factor(x[[row_by_var]])) stop("x[[row_by_var]] currently needs to be a factor")
  if (!is.no_by(col_by_var) && !is.factor(x[[col_by_var]])) stop("x[[col_by_var]] currently needs to be a factor")
  
  tbl_header <- rtabulate_header(if (is.no_by(col_by_var)) col_by_var else x[[col_by_var]], nrow(x), format=col_total)
  
  row_data <- if (is.no_by(row_by_var)) {
    setNames(list(x), row_by_var)
  } else {
    split(x, x[[row_by_var]], drop = FALSE)
  }
  
  col_data <- if (is.no_by(col_by_var)) {
    setNames(list(x), col_by_var)
  } else {
    split(x, x[[col_by_var]], drop = FALSE)
  }
  
  cell_data <- if (is.no_by(col_by_var)) {
    lapply(row_data, function(row_i) setNames(list(row_i), col_by_var))
  } else {
    lapply(row_data, function(row_i) split(row_i, row_i[[col_by_var]], drop = FALSE))
  }
  
  rrow_data <- if (!row_col_data_args) {
    lapply(cell_data, function(row_i) lapply(row_i, FUN, ...))
  } else {
    
    rrow_data_tmp <- lapply(1:length(row_data), function(i) {
      rrow_data_i <- lapply(1:length(col_data), function(j) {
        FUN(cell_data[[i]][[j]], row_data[[i]], col_data[[j]], ...)
      })
      names(rrow_data_i) <- names(col_data)
      rrow_data_i
    })
    names(rrow_data_tmp) <- names(row_data)
    rrow_data_tmp
  }
  
  rrows <- Map(function(row_dat, rowname) {
    rrowl(row.name = rowname, row_dat, format = format, indent = indent)
  }, rrow_data, names(rrow_data))
  
  rtablel(header = tbl_header, rrows)
}



stop_if_has_na <- function(x) {
  if (any(is.na(x))) stop(paste0(deparse(substitute(x)), " does currently not support any NAs"))
}


# #' Create a table with formulation
# #' 
# #' Formula elements on the LHS connected by a + mean stacking
# rtabulate.formula <- function(x, data) {
#   x <- Sepal.Length ~ Species
#   data <- iris
#   
#   # get model frame
#   mf <- match.call(expand.dots = FALSE)
#   names(mf) <- gsub("^x$", "formula", names(mf))
#   m <- match(c("formula", "data"), names(mf), 0L)
#   mf <- mf[c(1L, m)]
#   mf[[1L]] <- quote(stats::model.frame)
#   mf <- eval(mf, parent.frame())
#   
#   
#   
#   attributes(mf)
#   
#   mf <- match.call(lm, call = call("lm", x = Sepal.Length ~ Species, data = iris), expand.dots = FALSE)
#   
#   formula <- Sepal.Length ~ Species
#   
#   terms(formula)
#   
#   str(formula)
# }
