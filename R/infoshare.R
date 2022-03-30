# Automatically download data from Stats NZ's Infoshare website

# Requires RSelenium to be installed

#' Start Selenium server connection
#'
#' @param selenium_port The port number to use for the connection to Selenium server (default 4567L)
#' @param selenium_browser The browser for Selenium to use (default Google Chroms)
#' @param selenium_verbose Should Selenium operate in verbose mode? (default FALSE)
#' @param ... Other parameters passed to RSelenium::rsDriver() to set up the Selenium connection
#'
#' @return A connection to the Selenium server
#' @export
start_selenium <- function(selenium_port = 4567L,
                           selenium_browser = "chrome",
                           selenium_verbose = FALSE,
                           ...) {
  # Set up connection to Selenium server
  selenium_driver <- RSelenium::rsDriver(port = selenium_port,
                                         browser = selenium_browser,
                                         verbose = selenium_verbose,
                                         ...)
  return(selenium_driver)
}

#' Stop Selenium server
#'
#' @param selenium_connection A connection to a Selenium server created by start_selenium()
#'
#' @return Nothing
#' @export
stop_selenium <- function(selenium_connection) {
  selenium_connection$server$stop()
}

#' Download one or more data series from Infoshare
#'
#' @param selenium_connection A connection to a Selenium server created by start_selenium()
#' @param series_ids A character vector of Stats NZ series IDs
#' @param target_directory The directory downloaded CSV files will be saved
#' @param target_filename Name of downloaded CSV file. If NULL (the default), a generic name will be used.
#' @param browser_dl_directory The directory where downloaded files by the browser are saved
#'
#' @return TRUE if data was successfully downloaded, otherwise FALSE
#' @export
download_infoshare <- function(selenium_connection,
                               series_ids,
                               target_directory,
                               target_filename = NULL,
                               browser_dl_directory = "~/Downloads") {

  if (length(series_ids) > 100) {
    stop("Infoshare only allows up to 100 series IDs to be retrieved at one time. Please try again with fewer series IDs")
  }

  selenium_client <- selenium_connection$client

  # Save temporary .sch file with series IDs
  sch <- tibble::tibble(id = series_ids)
  sch_file <- here::here(paste0(target_directory, "/temp.sch"))
  readr::write_csv(x = sch,
                   file = sch_file,
                   col_names = FALSE)

  # Remove any previous ExportDirect download file
  dl_file <- paste0(browser_dl_directory, "/ExportDirect.csv")
  if (file.exists(dl_file)) {
    delete_confirm <- readline(prompt = paste0("ExportDirect.csv file already exists in ",
                                               browser_dl_directory,
                                               ", ok to delete it? (y/n) "))
    if (tolower(delete_confirm) == "y") {
      file.remove(dl_file)
    } else {
      stop("Stopping - please remove the file and try again")
    }
  }

  # Manipulate Export Direct page
  selenium_client$navigate("https://infoshare.stats.govt.nz/infoshare/exportdirect.aspx")
  dates_selectall <- selenium_client$findElement(using = "id",
                                                 value = "ctl00_MainContent_TimeVariableSelector_lblSelectAll")
  dates_selectall$clickElement()
  file_button <- selenium_client$findElement(using = "id",
                                             value = "ctl00_MainContent_fuSearchFile")

  file_button$clickElement()
  file_button$sendKeysToElement(list(sch_file))
  download_button <- selenium_client$findElement(using = "id",
                                                 value = "ctl00_MainContent_btnGenerate")
  download_button$clickElement()

  # Wait for download file to appear (up to 30 sec timeout)
  dl_timeout <- 0
  while(!file.exists(dl_file) & (dl_timeout < 30)) {
    Sys.sleep(1)
    dl_timeout <- dl_timeout + 1
  }

  # Set exit status if download successful
  status <- file.exists(dl_file)

  # Rename and move downloaded file if it exists
  if (file.exists(dl_file)) {
    file.copy(from = dl_file,
              to = target_directory)
    file.remove(dl_file)
    if (!is.null(target_filename)) {
      file.rename(from = paste0(target_directory, "/ExportDirect.csv"),
                  to = paste0(target_directory,
                              "/",
                              target_filename))
    } else {
      file.rename(from = paste0(target_directory, "/ExportDirect.csv"),
                  to = paste0(target_directory,
                              "/ExportDirect ",
                              format(Sys.time(), "%Y-%m-%d %I%m%S"),
                              ".csv"))
    }
  }

  # Remove temporary .sch file
  file.remove(sch_file)

  return(status)
}

