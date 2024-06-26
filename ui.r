##########################################################################
## UI function for the Exceptional Events Design Value R shiny application
##########################################################################

## Main UI function
shinyUI(fluidPage(title="Exceptional Events Design Value Tool",
  
  ## Apply HTML styles to various parts of the page
  tags$head(tags$style(HTML("#control-panel { background-color:#E0E0E0; padding:10px; }"))),
  tags$head(tags$style(HTML("#display-panel { background-color:#FFFFFF; }"))),
  tags$head(tags$style(HTML("#select-daily { background-color:#E0FFE0; padding:10px; }"))),
  tags$head(tags$style(HTML("#select-hourly { background-color:#E0FFE0; padding:10px; }"))),
  tags$head(tags$style(HTML("#intro-panel { padding:10px; }"))),
  tags$head(tags$style(HTML(".shiny-text-output { font-size:18px; }"))),
  
  ## Control panel with menus, buttons, and download links (left side)
  absolutePanel(id="control-panel",
    
    ## Drop down menu inputs
    selectInput(inputId="poll.select",label="Select a Pollutant:",
      choices=c("Ozone","PM2.5"),selected="PM2.5"),
    uiOutput(outputId="ui.naaqs"),
    selectInput(inputId="region.select",label="Select an EPA Region:",
      choices=c("National",paste("EPA Region",c(1:10))),selected="National"),
    uiOutput(outputId="ui.state"),
    uiOutput(outputId="ui.county"),
    uiOutput(outputId="ui.site"),
    selectInput(inputId="year.select",label="Select a Design Value Period:",
      choices=paste((curr.year-2):(curr.year-4),curr.year:(curr.year-2),sep="-"),
      selected=paste(curr.year-2,curr.year,sep="-")),
    checkboxGroupInput(inputId="type.select",label="Selections include:",
      choices=c("Request Exclusion Flags","Informational Flags","NAAQS Exceedance Days"),
      selected="Request Exclusion Flags"),
    ## Action buttons and download links
    actionButton(inputId="go.button",label="Get Selections",width="135px"),
    actionButton(inputId="reset.button",label="Clear Selections",width="135px"), br(), br(),
    conditionalPanel(condition="!output.getResetValue & input['poll.select'] == 'Ozone' & output.showLink",
      downloadLink(outputId="download.ozone",label="Download Site Design Value Data (xlsx)")),
    conditionalPanel(condition="!output.getResetValue & input['poll.select'] == 'PM2.5' & output.showLink",
      downloadLink(outputId="download.pm25",label="Download Site Design Value Data (xlsx)")), 
  top="0px",left="0px",height="760px",width="300px"),
  
  ## Main panel displaying DV information
  absolutePanel(id="display-panel",
    conditionalPanel(id="intro-panel",condition="output.getResetValue",
      p("This tool allows users to determine the regulatory significance of submitted or anticipated 
         Exceptional Events demonstrations pursuant to 40 CFR \u00a750.14 by re-calculating the design
         values for Ozone or PM2.5 monitoring sites with reported concentrations potentially affected by 
         exceptional events excluded from the calculation."),
      p("To use this tool, start by choosing a pollutant, standard, state, county, site ID, and design value
         period from the drop-down menus in the left-hand panel. You may choose to exclude days with Request
         Exclusion flags, Informational flags, and/or NAAQS exceedances. Once these selections have been made,
         click on the 'Get Selections' button below to retrieve concentration data from AQS and calculate the
         design value. NOTE: Initial AQS data retrieval and design value calculations may take up to a minute
         to complete."),
      p("Once the data retrieval and design value calculations have completed, this window should populate with
         the relevant design value statistics based on the menu selections, and a list of days available for
         exclusion should appear in a new menu at the bottom of the screen. At this point, you may select days
         to exclude from the design value calculation. If Ozone is selected, a second menu should also appear
         to the right allowing you to select hourly concentrations for exclusion. You can use Ctrl+click to
         select multiple values, and Shift+click to select a range of values."),
      p("Once you have finished selecting values for exclusion, click on the button that appears beneath the
         selection menu to re-calculate the design value. The text window above should re-populate with the
         design value statistics calculated with the selected values excluded. This should take no more than
         a few seconds to complete."),
      p("At any time after the initial design value calculation is complete, you may click the 'Download Site
         Design Value Data' link which should appear in the bottom left of the screen to download the design
         values and daily data in an Excel spreadsheet. The spreadsheet includes formulas to calculate the
         design value statistics, so that you can continue to exclude days from the design value calculations
         in Excel by clearing the concentrations on those days in the daily data tabs. NOTE: The spreadsheet
         may open in protected mode, in which case the formulas will not work. Clicking the 'Enable Editing'
         button at the top of the screen in Excel should enable the formulas."),
      p("Finally, clicking the 'Clear Selections' button will reset all current selections to their initial
         values. NOTE: It is strongly recommended that you click this button before selecting a new pollutant,
         monitoring site, or design value period.")),
    conditionalPanel(id="ozone-panel",
      condition="!output.getResetValue & input['poll.select'] == 'Ozone'",
      verbatimTextOutput(outputId="ozone.dvtext")),
    conditionalPanel(id="pm25annual-panel",
      condition="!output.getResetValue & input['poll.select'] == 'PM2.5' & !output.pm25daily",
      verbatimTextOutput(outputId="pm25.annual.dvtext")),
    conditionalPanel(id="pm25daily-panel",
      condition="!output.getResetValue & input['poll.select'] == 'PM2.5' & output.pm25daily",
      verbatimTextOutput(outputId="pm25.daily.dvtext")),
    conditionalPanel(id="select-panel",condition="!output.getResetValue",
      ## Panels with additional menus allowing the user to select which values to exclude
      absolutePanel(id="select-daily",
        uiOutput(outputId="ui.daily"),
        uiOutput(outputId="pmdv.button"),
      top="480px",left="0px",height="280px",width="353px"),
      absolutePanel(id="select-hourly",
        uiOutput(outputId="ui.hourly"),
        uiOutput(outputId="o3dv.button"),
      top="480px",left="353px",height="280px",width="353px")),
    top="0px",left="300px",height="760px",width="706px")
))