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
3) global.R - Global environment variables used in the EE_DVcalc app. Developers will need to make changes to this file for the app to function.
4) server.R and ui.R - scripts that provide the R shiny server-side functions and build the user interface for the app.
5) xlsx folder - contains template files used to write ozone and PM2.5 outputs from the app to Excel, with built-in functions to calculate the DVs
6) deploy.R - deployment script for staging Posit Connect deployments only.

# Data workflow

The application uses two data sources:

- Concentration data is retrieved through the AQS API when users click
  **Get Selections**. API credentials and network access are needed even when
  the app uses the bundled metadata file.
- Monitor metadata, exceptional-event concurrences, ozone method codes and
  monitoring seasons, and PM2.5 sampling schedules are loaded at startup.
  With `public.server <- TRUE`, `global.R` reads these from the
  `<app_owner>/EE_DVcalc_AQSdata` pin on Posit Connect. With
  `public.server <- FALSE`, it loads `aqsdata.Rdata` from the app folder.

The bundled file is a static snapshot; it is not updated automatically when
the app runs. Local and staging results may differ from public results if the
snapshot and the public pin contain different metadata or concurrences.
Keep `aqsdata.Rdata` and the `xlsx/` templates available in a staging deployment.

## Refresh the supporting data

`EE_DVcalc_update.Rmd` is provided for reference only, not needed to run the
app locally. The server-specific weekly process requires direct AQS database
access and publishes the supporting data to the `EE_DVcalc_AQSdata` pin.
It is separate from running or publishing the Shiny app.

If a newer snapshot is needed for testing, obtain an updated `aqsdata.Rdata`
from the developer. Confirm that it contains the same nine objects expected
by `global.R`; publishing the app does not refresh this snapshot.

# Requirements and credentials

Use R and, for the RStudio workflow, RStudio. The app requires the R packages
`shiny`, `RAQSAPI`, `pins`, and `openxlsx`; `deploy.R` additionally requires
`rsconnect` and Git. This repository does not currently include a package
lockfile or specify a tested R version.

Set `AQS_USER` and `AQS_API_KEY` in your local `.Renviron` file for AQS API
access. Do not commit credentials to the repository. Public deployments also
need the `app_owner` environment variable and access to the configured pins
board.

These API credential names replace `AQSAPI_user` and `AQSAPI_key`. Update
existing local and hosted settings to `AQS_USER` and `AQS_API_KEY`.

For local use, copy `.Renviron.example` to `.Renviron` in the repository root
and fill in the settings required for your workflow. The template contains
blank values only. The app's required API settings are:

```text
AQS_USER=your_api_username
AQS_API_KEY=your_api_key
```

Restart R after creating or editing `.Renviron` so the values are loaded.
Keep this file out of Git and deployment bundles; `.Renviron` is listed in
`.gitignore`. Do not select it in RStudio's Publish dialog.
The deployment script excludes `.Renviron` and `.env` files from its copy.
Configure the AQS API variables separately in the hosted app's Connect
environment; a local `.Renviron` is not transferred by `deploy.R`.

The reference refresh report, `EE_DVcalc_update.Rmd`, uses `AQS_userid` and
`AQS_passwd` for direct AQS database access. These are separate from the app's
API credentials and are not needed to run or publish the Shiny app. Their
existing names remain unchanged. If the report runs on Posit Connect, configure
them in the refresh report's environment, separately from the Shiny app.

# How to get the application running locally

1) Clone this repository to your local machine.
2) You will need an AQS API key. Instructions on how to register for an API key are here: https://aqs.epa.gov/aqsweb/documents/data_api.html#signup
3) Set `AQS_USER` and `AQS_API_KEY` in your local `.Renviron` file.
4) In `global.R`, set `public.server <- FALSE` to use the bundled data.
5) In RStudio, open the repository folder, then run the app from `ui.R`, or run `shiny::runApp()` from the R console.
6) Restore `public.server <- TRUE` before committing or pushing changes.

# Using the application

Choose a pollutant, standard, state, county, site ID, and design value period
from the drop-down menus in the left-hand panel. You may choose to exclude
days with Request Exclusion flags, Informational flags, and/or NAAQS exceedances.
Click **Get Selections** to retrieve concentration data from AQS and calculate
the design value. Initial AQS data retrieval and design value calculations
may take up to a minute to complete.

Select days for exclusion from the daily menu. For ozone, also select the
hours to exclude from the hourly menu. You can use Ctrl+click to select
multiple values, and Shift+click to select a range of values. Click
**Re-Calculate DV** to calculate the design value with the selected values
excluded.

Use **Download Site Design Value Data (xlsx)** to download the results and
daily data. The spreadsheet includes formulas to calculate the design value
statistics, so that you can continue to exclude days from the design value
calculations in Excel by clearing the concentrations on those days in the
daily data tabs.

It is strongly recommended that you click **Clear Selections** before
selecting a new pollutant, monitoring site, or design value period.


# Test and deploy to staging

Staging deployments use the bundled `aqsdata.Rdata` file.

## Option 1: Publish to staging from RStudio

1) Check out the feature or review branch you want to test.
2) In `global.R`, temporarily set `public.server <- FALSE`.
3) Run the app locally and confirm it uses the bundled data.
4) Use RStudio's **Publish** button and select the staging Connect server and
   account. Choose a branch-specific app name so the staging deployment does
   not replace the public app.
5) After publishing, restore `public.server <- TRUE` in `global.R`. Confirm
   that the setting is `TRUE` before committing or pushing.

## Option 2: Deploy to staging with `deploy.R`

The script is for staging only. It always packages the app with
`public.server <- FALSE` so it uses the bundled local Rdata file, regardless
of the current branch or the tracked setting in `global.R`. It never selects
the public pins board or the public app name.

Configure the staging server URL and, if needed, staging credentials in your
local `.Renviron` file (or in the deployment environment):

```text
CONNECT_STAGING_SERVER=https://your-staging-connect-server
CONNECT_STAGING_ACCOUNT=dmap
CONNECT_STAGING_API_KEY=your_api_key
```

`CONNECT_STAGING_SERVER` is required; there is no fallback to a generic or
public-server setting. `CONNECT_STAGING_ACCOUNT` defaults to `dmap`, and the
API key can be omitted if `rsconnect` is already configured for that staging
server and account. Set the URL to the staging Connect server. The script
creates a branch-specific app name prefixed with `ee_dvcalc_staging_`. It can
be run from any branch from the repository root, directly in the RStudio
console:

```r
source("deploy.R")
```

Or from a shell:

```bash
Rscript deploy.R
```

The script packages a temporary copy with `public.server <- FALSE` and records
the branch, commit, and deployment time in that package. It does not change
the tracked `global.R` file.

# Public deployment

`deploy.R` does not deploy to the public server. Public deployment must use a
separate, explicitly reviewed workflow; confirm the target, app name, data
source, and hosted credentials with the developer before publishing public
content. Public deployments need `AQS_USER`, `AQS_API_KEY`, `app_owner`, and
access to the supporting pin.

# Contact
Ben Wells (Wells.Benjamin@epa.gov)
