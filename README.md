# EE_DVcalc
Exceptional Events Design Value Calculator

R shiny application developed by Ben Wells, US EPA/OAQPS
Latest Update: November 27, 2023
--------------------------------------------------------

Instructions for getting the app running locally
1) Clone this Github repository to your local machine
2) Make sure you have the latest version of R with the following packages installed: RAQSAPI, shiny, xlsx
   - R can be downloaded for free from https://cran.r-project.org/
   - To install packages, enter "install.packages(c("RAQSAPI","shiny","xlsx"))" in the R console window
4) Register for access to the EPA's AQS API here: https://aqs.epa.gov/aqsweb/documents/data_api.html#signup
5) In the downloaded repository, make the following changes in the file called 'global.r':
   - On line 1, change "C:/Your/Local/Directory/" to the path to your cloned repository
   - On line 5, change "Your.Name@epa.gov" to your email address and "Your_AQS_API_key" to your AQS API key
     (you should receive your AQS API key by email when you sign up)
6) In the R console window, enter the following commands:
   - source("C:/Your/App/Directory/global.r") where /Your/App/Directory/ is the path to the app folder.
   - runApp()
7) The app should open in a new internet browser window
   - Be sure to read the instructions on the opening screen before you start using the app!
