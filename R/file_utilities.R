# writeAlizer: An R Package to Generate Automated Writing Quality and Curriculum-Based Measurement (CBM) Scores
# Copyright (C) 2020 Sterett H. Mercer
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see https://www.gnu.org/licenses/.
#
# This file includes functions to import and pre-process Coh-Metrix, ReaderBench,
# and GAMET output files

#' Import a GAMET output file into R.
#'
#' @importFrom utils read.csv
#' @importFrom tools file_path_sans_ext
#' @importFrom dplyr mutate_all
#' @importFrom dplyr mutate_if
#' @importFrom magrittr %>%
#' @param path A string giving the path and filename to import.
#' @export
#' @seealso
#' \code{\link{predict_quality}}
#' @examples
#' ##Example 1:
#' #Using a sample data file included with writeAlizer package
#'
#' #load package
#' library(writeAlizer)
#'
#' #get path of sample GAMET output file
#' file_path <- system.file("extdata", "sample_gamet.csv", package = "writeAlizer")
#'
#' #see path to sample file
#' file_path
#'
#' #import file and store as "gamet_file"
#' gamet_file <- import_gamet(file_path)
#'
#' ##Example 2:
#' #To import as "gamet_file" a GAMET file (sample name: gamet_output.csv)
#' #that is stored in the working directory
#' \dontrun{
#' gamet_file <- import_gamet('gamet_output.csv')
#' }
import_gamet<-function(x){
  #read the dataset
  dat_read<-function(x){
    # read data and modify the path
    d<-read.csv(x, header=T)
    d.name <-basename(d$filename)
    d.ID<- tools::file_path_sans_ext(d.name)
    d$ID <- do.call(rbind, strsplit(d.ID,"\\\\"))[, 2]
    return(d)
  }
  #data preparationn
  dat_prep<-function(d){
    # select the variables
    d %>%
      na_if("NaN") %>%
      select("ID","error_count","word_count","grammar","misspelling") %>%
      mutate_if(is.factor, as.numeric) %>%
      mutate_if(is.character, as.numeric) %>%
      mutate(per_gram=round(grammar/word_count,6)) %>%
      mutate(per_misspell=round(misspelling/word_count,6)) %>%
      arrange(ID)
  }
  dat_prep(dat_read(x))
}

#' Import a Coh-Metrix output file(.csv) into R.
#' @importFrom magrittr %>%
#' @importFrom utils read.csv
#' @importFrom tools file_path_sans_ext
#' @importFrom dplyr mutate_all
#' @importFrom dplyr mutate_if
#' @param path A string giving the path and filename to import.
#' @export
#' @seealso
#' \code{\link{predict_quality}}
#' @examples
#' ##Example 1:
#' #Using a sample data file included with writeAlizer package
#'
#' #load package
#' library(writeAlizer)
#'
#' #get path of sample Coh-Metrix output file
#' file_path <- system.file("extdata", "sample_coh.csv", package = "writeAlizer")
#'
#' #see path to sample file
#' file_path
#'
#' #import file and store as "coh_file"
#' coh_file <- import_coh(file_path)
#'
#' ##Example 2:
#' #To import as 'coh_file' a Coh-Metrix file (sample name: coh_output.csv)
#' #that is stored in the working directory
#' \dontrun{
#' coh_file <- import_coh("coh_output.csv")
#' }

import_coh<-function(x){
    #read the dataset
    dat_read<-function(x){
      # read data and modify the path
      d<-read.csv(x, header=T)
      d.name <-basename(d$filename)
      d.ID<- tools::file_path_sans_ext(d.name)
      d$ID <- do.call(rbind, strsplit(d.ID,"\\\\"))[, 2]
      return(d)
    }
    #data preparationn
    dat_prep<-function(d){
      # select the variables
      d %>%
        na_if("NaN") %>%
        mutate_if(is.factor, as.numeric) %>%
        mutate_if(is.character, as.numeric) %>%
        arrange(ID)
    }
    dat_prep(dat_read(x))
  }

#' Import a ReaderBench output file(.csv) into R.
#'
#' @importFrom magrittr %>%
#' @importFrom utils modifyList read.table
#' @importFrom dplyr na_if
#' @export
#' @seealso
#' \code{\link{predict_quality}}
#' @param path A string giving the path and filename to import.
#' @examples
#' #' ##Example 1:
#' #Using a sample data file included with writeAlizer package
#'
#' #load package
#' library(writeAlizer)
#'
#' #get path of sample ReaderBench output file
#' file_path <- system.file("extdata", "sample_rb.csv", package = "writeAlizer")
#'
#' #see path to sample file
#' file_path
#'
#' #import file and store as "rb_file"
#' rb_file <- import_rb(file_path)
#'
#' ##Example 2:
#' #To import as "rb_file" a ReaderBench file (sample name: rb_output.csv)
#' #that is stored in the working directory
#' \dontrun{
#' rb_file <- import_rb("rb_output.csv")
#' }
#'
import_rb <-function(x){
  # handling the string in the readerbench outputs
  dat_read<-function(x){
    con <- file(x,"r")
    first_line <- readLines(con,n=1)
    close(con)

    if (first_line=="SEP=,"){
      d<-read.table(
        text = readLines(x, warn = FALSE),
        header = TRUE,
        sep = ",", skip=1
      )
    }

    if (first_line!="SEP=,"){
      d<-read.table(
        text = readLines(x, warn = FALSE),
        header = TRUE,
        sep = ",")
    }
    return(d)
  }
  # truncating the outputs
  dat_prep<-function(d) {
    d %>%
      na_if("NaN") %>%
      dplyr::select(!contains("AvgWordsList")) %>%
      #exclude sentiment analysis results for readerbench with any length
      dplyr::rename(ID = File.name)  %>%
      dplyr::mutate_if(is.factor, as.numeric) %>%
      dplyr::mutate_if(is.character, as.numeric) %>%
      #make any factors and chars numeric
      arrange(ID)
  }
  dat_prep(dat_read(x))
}

#' Import a ReaderBench output file(.csv) and GAMET output file (.csv) into R, and merge the two files.
#'
#' @importFrom magrittr %>%
#' @importFrom utils modifyList read.csv read.table
#' @importFrom tools file_path_sans_ext
#' @importFrom dplyr na_if mutate_all
#' @export
#' @seealso
#' \code{\link{predict_quality}}
#' @param rb_path A string giving the path and ReaderBench filename to import.
#' @param gamet_path A string giving the path and GAMET filename to import.
#' @examples
#' ##Example 1:
#' #Using a sample data files included with writeAlizer package
#'
#' #load package
#' library(writeAlizer)
#'
#' #get path of sample ReaderBench output file
#' file_path1 <- system.file("extdata", "sample_rb.csv", package = "writeAlizer")
#'
#' #see path to sample ReaderBench file
#' file_path1
#'
#' #get path of sample GAMET output file
#' file_path2 <- system.file("extdata", "sample_gamet.csv", package = "writeAlizer")
#'
#' #see path to sample GAMET file
#' file_path2
#'
#' #import files, merge, and store as "rb_gam_file"
#' rb_gam_file <- import_merge_gamet_rb(file_path1, file_path2)
#'
#' ##Example 2:
#' #To import as "rb_gam_file" a ReaderBench file (sample name: rb_output.csv)
#' #and GAMET file (sample name: gamet_output.csv) stored in the working
#' #directory and then merge them
#' \dontrun{
#' rb_gam_file <- import_merge_gamet_rb("rb_output.csv", "gamet_output.csv")
#' }

import_merge_gamet_rb <- function(x, y) {
  f.rb<- import_rb(x)
  f.gmt<-import_gamet(y)
  merge<-merge(f.rb, f.gmt, by.x="ID", by.y="ID")
  return(merge)
}
