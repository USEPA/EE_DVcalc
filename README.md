# EE\_DVcalc - Exceptional Events Design Value Calculator

R shiny application developed by Ben Wells, US EPA

Latest Update: September 17, 2026

https://www.epa.gov/air-quality-analysis/exceptional-events-design-value-tool

# Description

The Exceptional Events Design Value tool (EE_DVcalc) allows state, local, and tribal air monitoring agencies to determine the regulatory significance of ozone and PM2.5 concentrations impacted by exceptional events (i.e., whether excluding concentrations affected by exceptional events will affect attainment of the NAAQS) by calculating the impact of excluding these concentrations from the design value, the statistic used to determine whether an ambient air quality monitoring site is meeting the NAAQS.

This repository contains the source code and other files for the EE_DVcalc R shiny app. The ozone and PM2.5 concentration data is retrieved from EPA's Air Quality System (AQS) API directly through the app. However, the app also pulls from some AQS tables that are not currently available through the API. These are updated weekly through an automated process that is server-specific and requires a direct connection to the AQS database. For developers, we have provided a static data file that contains the output from those direct SQL queries.

# Repository Contents
1) aqsdata.Rdata - static data file that provides all AQS data not available through the AQS API 
2) EE_DVcalc_update.Rmd - source code for the weekly process to refresh the AQS data not available through the API. Can only be run by users with direct SQL access to the AQS database. Provided for reference only, not needed to run the app locally.
3) global.r - Global environment variables used in the EE_DVcalc app. Developers will need to make changes to this file for the app to function.
4) server.r and ui.r - scripts that provide the R shiny server-side functions and build the user interface for the app.
5) xlsx folder - contains template files used to write ozone and PM2.5 outputs from the app to Excel, with built-in functions to calculate the DVs

# How to get the application running locally
1) Clone this repository to your local machine.
2) You will need an AQS API key. Instructions on how to register for an API key are here: https://aqs.epa.gov/aqsweb/documents/data_api.html#signup
3) Insert your API username and key into the global.r script by replacing the username and key arguments in the aqs_credentials function. You can also create local environment variables to pass in these arguments if desired.
4) Point to your local copy of aqsdata.Rdata by replacing the last code chunk starting with "## Load monitor metadata, ..." with a single line loading your local copy of aqsdata.Rdata.

# Contact
Ben Wells (Wells.Benjamin@epa.gov)
