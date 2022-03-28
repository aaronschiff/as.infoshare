# Automated downloads from Infoshare

This R package provides a simple way to automate downloads of time series data from Stats NZ's [Infoshare](https://www.stats.govt.nz/infoshare/default.aspx?AspxAutoDetectCookieSupport=1) website. This site runs on ASP.NET which makes it difficult to scrape. This package uses [RSelenium](https://cran.r-project.org/package=RSelenium) to automate data downloads via the [Export Direct](https://infoshare.stats.govt.nz/infoshare/exportdirect.aspx) page on Infoshare.

## Installation requirements
* Selenium server 
* RSelenium package
* Google Chrome browser
