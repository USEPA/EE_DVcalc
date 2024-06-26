###############################################################
## Server function for the Exceptional Events Design Value Tool
###############################################################
shinyServer(function(input,output,session) {
  
  #######################################################################
  ## Logic controlling reactive drop-down menus in the left-hand UI panel
  #######################################################################
  
  ## Get AQS monitor metadata based on pollutant selection
  get.monitors <- reactive({
    if (is.null(input$poll.select)) { return() }
    if (is.null(input$year.select)) { return() }
    if (input$poll.select == "Ozone") { monitors <- o3.monitors }
    if (input$poll.select == "PM2.5") { monitors <- pm.monitors }
    monitors <- subset(monitors,
      as.Date(monitor_begin_date) <= as.Date(paste(substr(input$year.select,1,4),"12-31",sep="-")) &
      as.Date(last_sample_date) >= as.Date(paste(substr(input$year.select,6,9),"01-01",sep="-")))
    return(monitors)
  })
  
  ## Pull site info from monitor metadata
  get.sites <- reactive({
    if (is.null(input$poll.select)) { return() }
    monitors <- get.monitors()
    monitors$site <- substr(monitors$id,1,9) 
    return(subset(monitors,!duplicated(site),c("site","site_name",
      "address","epa_region","state_name","county_name")))
  })
  
  ## Create a NAAQS selection input
  output$ui.naaqs <- renderUI({
    if (is.null(input$poll.select)) { return() }
    if (input$poll.select == "Ozone") {
      naaqs.choices <- c("2015 8-hour NAAQS (70 ppb)","2008 8-hour NAAQS (75 ppb)",
        "1997 8-hour NAAQS (84 ppb)")
      naaqs.selected <- "2015 8-hour NAAQS (70 ppb)"
    }
    if (input$poll.select == "PM2.5") {
      naaqs.choices <- c("2024 Annual NAAQS (9 ug/m^3)","2012 Annual NAAQS (12 ug/m^3)",
        "2006 24-hour NAAQS (35 ug/m^3)","1997 Annual NAAQS (15 ug/m^3)")
      naaqs.selected <- "2024 Annual NAAQS (9 ug/m^3)"
    }
    selectInput(inputId="naaqs.select",label="Select a NAAQS:",
      choices=naaqs.choices,selected=naaqs.selected)
  })
  
  ## Set NAAQS level based on NAAQS selection input
  naaqs.level <- reactive({
    if (is.null(input$poll.select)) { return() }
    if (is.null(input$naaqs.select)) { return() }
    naaqs <- substr(input$naaqs.select,1,4)
    if (input$poll.select == "Ozone") {
      level <- ifelse(naaqs == "2015",70,ifelse(naaqs == "2008",75,84))
    }
    if (input$poll.select == "PM2.5") {
      level <- ifelse(naaqs == "2024",9,ifelse(naaqs == "2012",12,
        ifelse(naaqs == "2006",35,15)))
    }
    return(level)
  })
  
  ## Create a state selection input
  output$ui.state <- renderUI({
    if (is.null(get.sites())) { return() }
    if (is.null(input$region.select)) { return() }
    sites <- get.sites()
    if (input$region.select != "National") {
      sites <- subset(sites,epa_region == substr(input$region.select,12,13))
    }
    sites <- subset(sites,!duplicated(substr(site,1,2)))
    state.choices <- substr(sites$site,1,2)
    names(state.choices) <- paste(state.choices,sites$state_name,sep=" - ")
    selectInput(inputId="state.select",label="Select a State:",
      choices=c(" ",state.choices),selected=" ")
  })
  
  ## Create a county selection input
  output$ui.county <- renderUI({
    if (is.null(get.sites())) { return() }
    if (is.null(input$state.select)) { return() }
    if (input$state.select == " ") { return() }
    sites <- subset(get.sites(),substr(site,1,2) == input$state.select &
      !duplicated(substr(site,1,5)))
    county.choices <- substr(sites$site,3,5)
    names(county.choices) <- paste(county.choices,sites$county_name,sep=" - ")
    selectInput(inputId="county.select",label="Select a County:",
      choices=c(" ",county.choices),selected=" ")
  })
  
  ## Create a site selection input 
  output$ui.site <- renderUI({
    if (is.null(get.sites())) { return() }
    if (is.null(input$state.select)) { return() }
    if (is.null(input$county.select)) { return() }
    if (input$state.select == " ") { return() }
    if (input$county.select == " ") { return() }
    sites <- subset(get.sites(),substr(site,1,2) == input$state.select & 
      substr(site,3,5) == input$county.select)
    site.choices <- substr(unique(sites$site),6,9)
    site.names <- mapply(function(x,y) ifelse(x == " ",y,x),x=sites$site_name,y=sites$address)
    names(site.choices) <- paste(site.choices,substr(site.names,1,25),sep=" - ")
    selectInput(inputId="site.select",label="Select a Site",
      choices=c(" ",site.choices),selected=" ")
  })
  
  ## Set reactive values based on which action buttons are clicked
  vals <- reactiveValues(counter=0,last.clicked=NULL,reset=TRUE)
  observeEvent({ c(input$go.button,input$calc.o3dv,input$calc.pmdv) },
    { vals$counter <- sum(input$go.button,input$calc.o3dv,input$calc.pmdv) })
  observeEvent(input$go.button, {
    if (input$go.button > 0) { vals$last.clicked <- "go.button"; vals$reset <- FALSE; }
  })
  observeEvent(input$calc.o3dv, {
    if (input$calc.o3dv > 0) { vals$last.clicked <- "calc.o3dv" }
  })
  observeEvent(input$calc.pmdv, {
    if (input$calc.pmdv > 0) { vals$last.clicked <- "calc.pmdv" }
  })
  
  ## Logic controlling the "Reset App" button
  observeEvent(input$reset.button,{
    updateSelectInput(session,inputId="daily.select",choices=NULL,selected=NULL)
    updateSelectInput(session,inputId="hourly.select",choices=NULL,selected=NULL)
    updateCheckboxGroupInput(session,inputId="type.select",selected="Request Exclusion Flags")
    updateSelectInput(session,inputId="year.select",selected=paste(curr.year-2,curr.year,sep="-"))
    updateSelectInput(session,inputId="state.select",selected=" ")
    updateSelectInput(session,inputId="region.select",selected="National")
    updateSelectInput(session,inputId="poll.select",selected="PM2.5")
    updateSelectInput(session,inputId="naaqs.select",selected="2024 Annual NAAQS (9 ug/m^3)")
    vals$counter <- 0
    vals$last.clicked <- NULL
    vals$reset <- TRUE
  })
  
  ## Allows reset value to be used in ui.r conditionalPanel statements
  output$getResetValue <- reactive({ return(vals$reset) })
  outputOptions(output,"getResetValue",suspendWhenHidden=FALSE)
  
  ## Allows conditioning on PM2.5 NAAQS in ui.r conditionalPanel statements
  output$pm25daily <- reactive({ return(ifelse(naaqs.level() == 35,TRUE,FALSE)) })
  outputOptions(output,"pm25daily",suspendWhenHidden=FALSE)
  
  ##########################################################################
  ## Get hourly or daily data for identifying exclusions and calculating DVs
  ##########################################################################
  
  ## Get AQS Site ID based on state, county, site selections
  aqs.site.id <- reactive({
    if (is.null(input$site.select)) { return() }
    if (input$site.select == " ") { return() }
    return(paste(input$state.select,input$county.select,input$site.select,sep=""))
  })
  
  ## Get vector of years based on DV period input
  dv.years <- reactive({
    if (is.null(input$year.select)) { return() }
    return(c(as.numeric(substr(input$year.select,1,4)):
      as.numeric(substr(input$year.select,6,9))))
  })
  
  ## Get vector of dates associated with selected DV period
  dv.dates <- reactive({
    if (is.null(dv.years())) { return() }
    return(seq(as.Date(paste(dv.years()[1],"01-01",sep="-")),
        as.Date(paste(dv.years()[3],"12-31",sep="-")),1))
  })
  
  ## Retrieve initial dataset for selected site using the AQS API
  get.site.data <- eventReactive(input$go.button, {
    if (is.null(get.sites())) { return() }
    if (is.null(naaqs.level())) { return() }
    if (is.null(aqs.site.id())) { return() }
    if (is.null(dv.dates())) { return() }
    ## Download hourly ozone data from AQS API, subset and format
    if (input$poll.select == "Ozone") { withProgress({
      dates <- c(dv.dates(),as.Date(paste(dv.years()[3]+1,"01-01",sep="-")))
      monitor.info <- subset(get.monitors(),substr(id,1,9) == aqs.site.id())
      api.data <- as.data.frame(aqs_sampledata_by_site(parameter="44201",
        bdate=dates[1],edate=dates[length(dates)],stateFIPS=input$state.select,
        countycode=input$county.select,sitenum=input$site.select))
    },message="Retrieving data from AQS...",value=NULL,detail=NULL)
    withProgress({
      temp <- data.frame(poc=api.data$poc,
        date=as.Date(api.data$date_local),
        hour=as.integer(substr(api.data$time_local,1,2)),
        method=api.data$method_code,
        conc=floor(1000*api.data$sample_measurement),
        flag=sapply(api.data$qualifier,function(x) 
          ifelse(is.na(x)," ",ifelse(substr(x,1,1) == "V"," ",
          ifelse(substr(x,2,2) == " ",substr(x,1,1),substr(x,1,2))))),
        concur=" ")
      ## Add existing regional concurrence flags, if any
      concur <- subset(o3.concurrences,substr(id,1,9) == aqs.site.id() & 
        as.integer(substr(dt,1,4)) %in% dv.years())
      if (nrow(concur) > 0) {
        concur$poc <- substr(concur$id,10,11)
        concur$date <- as.Date(substr(concur$dt,1,10))
        concur$hour <- as.integer(substr(concur$dt,12,13))
        conc.ind <- match(paste(concur$poc,concur$date,concur$hour),
          paste(temp$poc,temp$date,temp$hour))
        temp$concur[conc.ind] <- "Y"
      }
      ## Create dataset with a full hourly record
      npocs <- length(unique(temp$poc)); ndays <- length(dates);
      all.hrs <- data.frame(poc=rep(unique(temp$poc),each=24*ndays),
        date=rep(dates,each=24,times=npocs),hour=rep(c(0:23),times=ndays*npocs))
      data <- merge(all.hrs,temp,by=c("poc","date","hour"),all.x=TRUE,all.y=FALSE,sort=FALSE)
      data <- data[order(data$poc,data$date,data$hour),]
      ## Remove missing days assumed less than the standard
      bg <- which(data$flag == "BG" & data$concur == "Y")
      if (length(bg) > 0) { data$conc[bg] <- -99 }
      ## Remove concurred exceptional events
      ee <- which(substr(data$flag,1,1) == "R" & data$concur == "Y")
      if (length(ee) > 0) { data$conc[ee] <- -99 }
      ## Remove data with non-FEM/FRM method codes
      non.ref <- o3.methods$method_code[which(o3.methods$frm_fem_id == " ")]
      if (length(non.ref) > 0) {
        drop <- which(data$method %in% non.ref)
        if (length(drop) > 0) { data$conc[drop] <- NA }
      }
      ## Remove data with concurred NAAQS exclusions
      if (any(monitor.info$nonreg_concur == "Y")) {
        nonreg <- which(monitor.info$nonreg_concur == "Y")
        for (i in nonreg) {
          bd <- as.Date(monitor.info$nonreg_begin_date[i])
          ed <- as.Date(ifelse(monitor.info$nonreg_end_date[i] == " ",as.character(Sys.Date()),
            monitor.info$nonreg_end_date[i]))
          drop <- which(data$poc == substr(monitor.info$id[i],10,11) & 
            data$date >= bd & data$date <= ed)
          if (length(drop) > 0) { data$conc[drop] <- NA }
        }
      }
      ## If only one POC operating, return data
      if (npocs == 1) {
        site.data <- data[,c("date","hour","conc","flag","concur")]
      }
      ## 2008 and 1997 O3 NAAQS: Return data from monitor with lowest POC
      if (naaqs.level() > 70 & npocs > 1) { 
        site.data <- subset(data,poc == min(data$poc),c("date","hour","conc","flag","concur"))
      }
      ## 2015 O3 NAAQS: Combine POCs at sites with multiple monitors
      if (naaqs.level() == 70 & npocs > 1) {
        m <- subset(monitor.info,primary_begin_date != " ",
          c("id","primary_begin_date","primary_end_date"))
        m <- m[which(!duplicated(m)),]; m <- m[order(m$primary_begin_date),];
        m$bd <- as.Date(m$primary_begin_date)
        m$ed <- sapply(m$primary_end_date,function(x) as.Date(ifelse(x == " ",
          paste(dv.years()[3]+1,"01-01",sep="-"),x)))
        m <- subset(m,bd < as.Date(paste(dv.years()[3],"12-31",sep="-")) &
          ed >= as.Date(paste(dv.years()[1],"01-01",sep="-")))
        n.dts <- length(unique(paste(data$date,data$hour)))
        site.data <- data.frame(date=data$date[1:n.dts],hour=data$hour[1:n.dts],conc=NA)
        for (j in 1:nrow(m)) {
          site.ind <- which(site.data$date >= m$bd[j] & site.data$date <= m$ed[j])
          pri.ind <- which(data$poc == substr(m$id[j],10,11) &
            data$date >= m$bd[j] & data$date <= m$ed[j])
          if (length(pri.ind) == 0) { next }
          site.data$conc[site.ind] <- data$conc[pri.ind]
          site.sub <- site.ind[which(is.na(site.data$conc[site.ind]))]
          if (length(site.sub)== 0) { next }
          t <- subset(data,poc != substr(m$id[j],10,11) & date >= m$bd[j] & date <= m$ed[j])
          vals <- floor(apply(matrix(t$conc,ncol=(npocs-1)),1,mean.na))
          site.data$conc[site.sub] <- vals[(site.sub-site.ind[1]+1)]
        }
        site.data$flag <- c(tapply(data$flag,list(data$date,data$hour),function(x)
          paste(unique(x[which(substr(x,1,1) %in% c("I","R"))]),collapse=",")))
        site.data$concur <- c(tapply(data$concur,list(data$date,data$hour),function(x)
          paste(unique(x[which(substr(x,1,1) == "Y")]),collapse=",")))
      }
    },message="Calculating Design Value...",value=NULL,detail=NULL) }
    ## Download raw PM2.5 data from AQS API, subset and format
    if (input$poll.select == "PM2.5") { withProgress({
      dates <- dv.dates()
      monitor.info <- subset(get.monitors(),substr(id,1,9) == aqs.site.id())
      api.data <- as.data.frame(aqs_sampledata_by_site(parameter="88101",
        bdate=dates[1],edate=dates[length(dates)],stateFIPS=input$state.select,
        countycode=input$county.select,sitenum=input$site.select))
    },message="Retrieving data from AQS...",value=NULL,detail=NULL)
    withProgress({
      temp <- data.frame(poc=api.data$poc,
        date=as.Date(api.data$date_local),
        hour=as.integer(substr(api.data$time_local,1,2)),
        duration=api.data$sample_duration_code,
        conc=round(api.data$sample_measurement,1),
        flag=sapply(api.data$qualifier,function(x) 
          ifelse(is.na(x)," ",ifelse(substr(x,1,1) == "V"," ",
          ifelse(substr(x,2,2) == " ",substr(x,1,1),substr(x,1,2))))),
        concur=" ")
      ## Get FRM data, add existing regional concurrence flags, if any
      frm <- subset(temp,duration == 7)
      concur <- subset(pm.concurrences.daily,substr(id,1,9) == aqs.site.id() & 
        as.integer(substr(dt,1,4)) %in% dv.years())
      if (nrow(concur) > 0) {
        concur$poc <- substr(concur$id,10,11)
        concur$date <- as.Date(substr(concur$dt,1,10))
        conc.ind <- match(paste(concur$poc,concur$date),paste(frm$poc,frm$date))
        frm$concur[conc.ind] <- "Y"
      }
      ## Get FEM data, calculate 24-hour averages
      fem <- subset(temp,duration == 1)
      if (nrow(fem) > 0) {
        ## Add existing regional concurrence flags, if any
        concur <- subset(pm.concurrences.hourly,substr(id,1,9) == aqs.site.id() & 
          as.integer(substr(dt,1,4)) %in% dv.years())
        if (nrow(concur) > 0) {
          concur$poc <- substr(concur$id,10,11)
          concur$date <- as.Date(substr(concur$dt,1,10))
          concur$hour <- as.integer(substr(concur$dt,12,13))
          conc.ind <- match(paste(concur$poc,concur$date,concur$hour),
            paste(fem$poc,fem$date,fem$hour))
          fem$concur[conc.ind] <- "Y"
        }
        npocs <- length(unique(fem$poc)); ndays <- length(dates);
        all.hrs <- data.frame(poc=rep(unique(fem$poc),each=24*ndays),
          date=rep(dates,each=24,times=npocs),hour=rep(c(0:23),times=ndays*npocs))
        vals <- merge(all.hrs,fem,by=c("poc","date","hour"),all.x=TRUE,all.y=FALSE,sort=FALSE)
        vals <- vals[order(vals$poc,vals$date,vals$hour),]
        fem <- data.frame(poc=rep(unique(vals$poc),each=ndays),
          date=rep(dates,times=npocs),hour=rep(0,ndays*npocs),duration=rep("X",ndays*npocs),
          conc=apply(matrix(vals$conc,nrow=24),2,avg24,sub=0,lvl=35),
          flag=apply(matrix(vals$flag,nrow=24),2,function(x)
            paste(unique(x[which(substr(x,1,1) %in% c("I","R"))]),collapse=",")),
          concur=apply(matrix(vals$concur,nrow=24),2,function(x)
            ifelse(any(x == "Y",na.rm=TRUE),"Y"," ")))
      }
      temp <- rbind(frm,fem)
      ## Create a dataset with a full daily record
      npocs <- length(unique(temp$poc)); ndays <- length(dates);
      all.days <- data.frame(poc=rep(unique(temp$poc),each=ndays),date=rep(dates,times=npocs))
      data <- merge(all.days,temp,all.x=TRUE,all.y=FALSE)
      if (nrow(data) > (npocs*ndays)) {
        data <- data[order(data$poc,data$date,data$conc,decreasing=TRUE),]
        data <- data[!duplicated(data[,c("poc","date")]),]
        data <- data[order(data$poc,data$date),]
      }
      ## Remove concurred exceptional events
      ee <- which(substr(data$flag,1,1) == "R" & data$concur == "Y")
      if (length(ee) > 0) { data$conc[ee] <- -99 }
      ## Remove data with concurred NAAQS exclusions
      if (any(monitor.info$nonreg_concur == "Y")) {
        nonreg <- which(monitor.info$nonreg_concur == "Y")
        for (i in nonreg) {
          bd <- as.Date(monitor.info$nonreg_begin_date[i])
          ed <- as.Date(ifelse(monitor.info$nonreg_end_date[i] == " ",as.character(Sys.Date()),
            monitor.info$nonreg_end_date[i]))
          drop <- which(data$poc == substr(monitor.info$id[i],10,11) &
            data$date >= bd & data$date <= ed)
          if (length(drop) > 0) { data$conc[drop] <- NA }
        }
      }
      ## If only one POC operating, return data
      if (npocs == 1) {
        site.data <- data[,c("date","conc","flag","concur")]
      }
      ## Combine POCs at sites with multiple monitors
      if (npocs > 1) {
        m <- subset(monitor.info,primary_begin_date != " ",
          c("id","primary_begin_date","primary_end_date"))
        m <- m[which(!duplicated(m)),]; m <- m[order(m$primary_begin_date),];
        m$bd <- as.Date(m$primary_begin_date)
        m$ed <- sapply(m$primary_end_date,function(x) as.Date(ifelse(x == " ",
          paste(dv.years()[3],"12-31",sep="-"),x)))
        m <- subset(m,bd < as.Date(paste(dv.years()[3],"12-31",sep="-")) &
          ed >= as.Date(paste(dv.years()[1],"01-01",sep="-")))
        n.days <- length(unique(data$date))
        site.data <- data.frame(date=data$date[1:n.days],conc=NA)
        for (j in 1:nrow(m)) {
          site.ind <- which(site.data$date >= m$bd[j] & site.data$date <= m$ed[j])
          pri.ind <- which(data$poc == substr(m$id[j],10,11) &
            data$date >= m$bd[j] & data$date <= m$ed[j])
          if (length(pri.ind) == 0) { next }
          site.data$conc[site.ind] <- data$conc[pri.ind]
          site.sub <- site.ind[which(is.na(site.data$conc[site.ind]))]
          if (length(site.sub) == 0) { next }
          t <- subset(data,poc != substr(m$id[j],10,11) & date >= m$bd[j] & date <= m$ed[j])
          vals <- floor(10*apply(matrix(t$conc,ncol=(npocs-1)),1,mean.na))/10
          site.data$conc[site.sub] <- vals[(site.sub-site.ind[1]+1)]
        }
        site.data$flag <- c(tapply(data$flag,list(data$date),function(x)
          paste(unique(x[which(substr(x,1,1) %in% c("I","R"))]),collapse=",")))
        site.data$concur <- c(tapply(data$concur,list(data$date),function(x)
          paste(unique(x[which(substr(x,1,1) == "Y")]),collapse=",")))
      }
    },message="Calculating Design Value...",value=NULL,detail=NULL) }
    return(site.data)
  })
  
  ## Get site-level data for DV calculation, exclude EE selections
  site.data <- reactive({
    if (vals$reset) { return() }
    vals$counter
    isolate({
      if (is.null(get.site.data())) { return() }
      site.data <- get.site.data()
      if (vals$last.clicked == "go.button") { return(site.data) }
      if (vals$last.clicked == "calc.o3dv") { withProgress({
        if (is.null(input$hourly.select)) { return(site.data) }
        selected.vals <- substr(input$hourly.select,1,13)
        index <- which(paste(as.character(site.data$date),
          sprintf("%02d",site.data$hour)) %in% selected.vals)
      },message="Calculating Design Value...",value=NULL,detail=NULL) }
      if (vals$last.clicked == "calc.pmdv") { withProgress({
        if (is.null(input$daily.select)) { return(site.data) }
        selected.vals <- substr(input$daily.select,1,10)
        index <- which(as.character(site.data$date) %in% selected.vals)
      },message="Calculating Design Value...",value=NULL,detail=NULL) }
      site.data$conc[index] <- -99
      site.data$flag[index] <- "RX"
      site.data$concur[index] <- "Y"
      return(site.data)
    })
  })
  
  #######################################
  ## Calculate ozone DVs from hourly data
  #######################################
  
  ## Calculate daily max 8-hour averages for ozone
  site.mda8 <- reactive({
    if (input$poll.select != "Ozone") { return() }
    if (is.null(site.data())) { return() }
    isolate({ withProgress({
      level <- naaqs.level(); data <- site.data();
      n <- nrow(data)-17; t <- data[1:n,]; 
      t8 <- matrix(c(t$conc[1:(n-7)],t$conc[2:(n-6)],t$conc[3:(n-5)],t$conc[4:(n-4)],
        t$conc[5:(n-3)],t$conc[6:(n-2)],t$conc[7:(n-1)],t$conc[8:n]),nrow=n-7,ncol=8)
      ## Calculate daily obs BEFORE removing exceptional events
      if (level == 70) {
        ma8 <- matrix(apply(t8,1,avg8,sub=0,lvl=level),nrow=24)
        obs <- apply(ma8[8:24,],2,count)
      }
      if (level > 70) {
        ma8 <- matrix(apply(t8,1,avg8,sub=2,lvl=level),nrow=24)
        obs <- apply(ma8,2,count)
      }
      ## Set concurred EE and BG values to missing, re-calculate 8-hr averages
      if (any(t$conc < 0,na.rm=TRUE)) {
        t$conc[which(t$conc < 0)] <- NA
        t8 <- matrix(c(t$conc[1:(n-7)],t$conc[2:(n-6)],t$conc[3:(n-5)],t$conc[4:(n-4)],
          t$conc[5:(n-3)],t$conc[6:(n-2)],t$conc[7:(n-1)],t$conc[8:n]),nrow=n-7,ncol=8)
        ma8 <- matrix(apply(t8,1,avg8,sub=ifelse(level == 70,0,2),lvl=level),nrow=24)
      }
      ## Calculate daily max values
      if (level == 70) { dmax <- apply(matrix(ma8,nrow=24)[8:24,],2,max.na) }
      if (level > 70) { dmax <- apply(matrix(ma8,nrow=24),2,max.na) }
      mda8 <- data.frame(date=dv.dates(),obs,dmax)
      mda8$flag <- as.character(tapply(t$flag[1:(n-7)],list(t$date[1:(n-7)]),function(x)
        paste(unique(x[which(substr(x,1,1) %in% c("I","R"))]),collapse=",")))
      return(mda8)
    },message="Calculating Design Value...",value=NULL,detail=NULL) })
  })
  
  ## Calculate ozone design value
  ozone.dv <- reactive({
    if (is.null(site.mda8())) { return() }
    isolate({ withProgress({
      years <- dv.years(); level <- naaqs.level(); mda8 <- site.mda8();
      ann <- data.frame(year=years,matrix(NA,nrow=3,ncol=23))
      colnames(ann)[2:24] <- c("valid","req","pct",
        paste(rep(c("max","date"),each=10),rep(c(1:10),times=2),sep=""))
      req.obs <- ifelse(level == 70,13,18)
      for (i in 1:3) {
        seasons <- subset(o3.seasons,begin_year <= years[i] & end_year >= years[i])
        t <- subset(mda8,substr(date,1,4) == years[i])
        s <- seasons[tail(intersect(which(seasons$state == input$state.select),
          intersect(which(seasons$county %in% c(" ",input$county.select)),
            which(seasons$site_id %in% c(" ",input$site.select)))),n=1),]
        bd <- as.Date(paste(years[i],s$begin_month,s$begin_day,sep="-"))
        ed <- as.Date(paste(years[i],s$end_month,s$end_day,sep="-"))
        season <- which(t$date >= bd & t$date <= ed)
        valid <- t$obs >= req.obs | floor(t$dmax) > level
        t$dmax[!valid] <- NA
        max.ind <- order(t$dmax,decreasing=TRUE)
        ann$req[i] <- ed - bd + 1
        ann$valid[i] <- length(intersect(season,which(valid)))
        ann$pct[i] <- floor(100*ann$valid[i]/ann$req[i]+0.5)
        for (j in 1:10) {
          ann[i,paste("max",j,sep="")] <- floor(t$dmax[max.ind][j])
          ann[i,paste("date",j,sep="")] <- as.character(t$date[max.ind][j])
        }
      }
      dv <- list(dv=floor(mean(ann$max4)),pct=floor(mean(ann$pct)+0.5))
      return(list(dv=dv,ann=ann))
    },message="Calculating Design Value...",value=NULL,detail=NULL) })
  })
  
  #######################################
  ## Calculate PM2.5 DVs from daily data
  #######################################
  
  ## Get PM2.5 scheduled sample dates for selected site
  sample.dates <- reactive({
    if (input$poll.select != "PM2.5") { return() }
    if (is.null(aqs.site.id())) { return() }
    if (is.null(dv.dates())) { return() }
    return(c(subset(pm.schedules,site == aqs.site.id() & 
      sample_date %in% as.character(dv.dates()))$sample_date))
  })
  
  ## Get PM2.5 makeup sample dates for selected site
  makeup.samples <- reactive({
    if (input$poll.select != "PM2.5") { return() }
    if (is.null(aqs.site.id())) { return() }
    if (is.null(dv.dates())) { return() }
    return(c(subset(pm.makeup.samples,site == aqs.site.id() &
      sample_date %in% as.character(dv.dates()))$sample_date))
  })
  
  ## Calculate PM2.5 annual design value (1997, 2012, 2024 NAAQS)
  pm25.annual.dv <- reactive({
    if (is.null(sample.dates())) { return() }
    if (is.null(site.data())) { return() }
    isolate({ withProgress({
      level <- naaqs.level(); data <- site.data();
      dates <- dv.dates(); sched <- sample.dates(); makeup <- makeup.samples();
      years <- as.numeric(substr(dates,1,4)); sched.years <- as.numeric(substr(sched,1,4));
      months <- as.numeric(substr(dates,6,7)); sched.months <- as.numeric(substr(sched,6,7));
      quarters <- (months-1) %/% 3 + 1; sched.quarters <- (sched.months-1) %/% 3 + 1;
      index <- intersect(which(!is.na(data$conc)),which(as.character(dates) %in% c(sched,makeup)))
      ## Calculate quarterly data capture
      qtr <- data.frame(year=rep(dv.years(),each=4),quarter=rep(1:4,times=3))
      qtr$obs <- c(table(quarters[index],years[index]))
      qtr$req <- c(table(sched.quarters,sched.years))
      qtr$pct <- pmin(floor(100*qtr$obs/qtr$req+0.5),100)
      ## Remove concurred exceptional events, calculate quarterly means
      if (any(data$conc == -99,na.rm=TRUE)) { data$conc[which(data$conc == -99)] <- NA }
      qtr$mean <- c(tapply(data$conc,list(quarters,years),mean.na))
      ## Calculate annual means
      ann <- data.frame(year=dv.years(),
        obs=tapply(qtr$obs,list(qtr$year),sum,na.rm=TRUE),
        mean=tapply(qtr$mean,list(qtr$year),mean.na),
        complete.qtrs=tapply(qtr$pct,list(qtr$year),function(x) sum(x >= 75)),
        min.qtr.obs=tapply(qtr$obs,list(qtr$year),min))
      ann$valid <- sapply(ann$complete.qtrs,function(x) x == 4)
      ## Calculate design value, test for validity
      dv <- list(dv=floor(10*mean(ann$mean)+0.5)/10,valid=all(ann$valid))
      if (!is.na(dv$dv) & !dv$valid) {
        ## If annual mean or DV > NAAQS level, check for >= 11 obs in each quarter
        inv <- which(!ann$valid)
        check1 <- ann$min.qtr.obs >= 11
        check2 <- ann$mean > level
        check3 <- !is.na(dv$dv) & dv$dv > level
        ann$valid[inv] <- check1[inv] & (check2[inv] | check3)
        dv$valid <- all(ann$valid)
        ## Substitution test 1: sites with DV > NAAQS level
        qtr.obs <- tapply(qtr$obs,list(qtr$quarter),sum)
        if (dv$dv > level & min(qtr$obs) < 11 & all(qtr.obs > 30)) {
          qtr.min <- tapply(data$conc,list(quarters),min.na)
          inv.qtrs <- subset(qtr,obs < 11)
          test.qtr <- qtr; test.ann <- ann;
          concs <- data$conc
          for (i in 1:nrow(inv.qtrs)) {
            q <- inv.qtrs$quarter[i]; y <- inv.qtrs$year[i];
            rep.ind <- which(years == y & quarters == q & as.character(dates) %in% sched & is.na(concs))
            N <- 11 - inv.qtrs$obs[i]
            concs[rep.ind][1:N] <- qtr.min[q]
          }
          test.qtr$mean <- c(tapply(concs,list(quarters,years),mean.na))
          test.ann$mean <- tapply(test.qtr$mean,list(test.qtr$year),mean.na)
          test.dv <- floor(10*mean(test.ann$mean)+0.5)/10
          if (test.dv > level) { dv$valid <- TRUE }  
        }
      }
      ## Substitution test 2: sites with DV <= NAAQS level, all quarters >= 50% complete
      if (!is.na(dv$dv) & !dv$valid & all(qtr$pct >= 50)) {
        test.qtr <- qtr; test.ann <- ann; concs <- data$conc;
        qtr.max <- tapply(data$conc,list(quarters),max.na)
        inv.qtrs <- subset(qtr,pct < 75)
        for (i in 1:nrow(inv.qtrs)) {
          q <- inv.qtrs$quarter[i]; y <- inv.qtrs$year[i];
          rep.ind <- which(years == y & quarters == q & as.character(dates) %in% sched & is.na(concs))
          if (length(rep.ind) > 0) { concs[rep.ind] <- qtr.max[q] }
        }
        test.qtr$mean <- c(tapply(concs,list(quarters,years),mean.na))
        test.ann$mean <- tapply(test.qtr$mean,list(test.qtr$year),mean.na)
        test.dv <- floor(10*mean(test.ann$mean)+0.5)/10
        if (test.dv <= level) { dv$valid <- TRUE }
      }
      return(list(dv=dv,ann=ann,qtr=qtr))
    },message="Calculating Design Value...",value=NULL,detail=NULL) })
  })
  
  ## Calculate PM2.5 daily design values (2006 NAAQS)
  pm25.daily.dv <- reactive({
    if (is.null(sample.dates())) { return() }
    if (is.null(site.data())) { return() }
    isolate({ withProgress({
      level <- naaqs.level(); data <- site.data();
      dates <- dv.dates(); sched <- sample.dates(); makeup <- makeup.samples();
      years <- as.numeric(substr(dates,1,4)); sched.years <- as.numeric(substr(sched,1,4));
      months <- as.numeric(substr(dates,6,7)); sched.months <- as.numeric(substr(sched,6,7));
      quarters <- (months-1) %/% 3 + 1; sched.quarters <- (sched.months-1) %/% 3 + 1;
      index <- intersect(which(!is.na(data$conc)),which(as.character(dates) %in% c(sched,makeup)))
      ## Calculate quarterly data capture
      qtr <- data.frame(year=rep(dv.years(),each=4),quarter=rep(1:4,times=3))
      qtr$obs <- c(table(quarters[index],years[index]))
      qtr$req <- c(table(sched.quarters,sched.years))
      qtr$pct <- pmin(floor(100*qtr$obs/qtr$req+0.5),100)
      ## Calculate annual data capture
      ann <- data.frame(year=dv.years(),matrix(NA,nrow=3,ncol=25))
      colnames(ann)[2:26] <- c("obs","Nmax","p98","complete.qtrs","valid",
        paste(rep(c("max","date"),each=10),rep(c(1:10),times=2),sep=""))
      ann$obs <- c(table(years[index])); ann$Nmax <- ann$obs %/% 50 + 1;
      ann$complete.qtrs <- tapply(qtr$pct,list(qtr$year),function(x) sum(x >= 75))
      ann$valid <- sapply(ann$complete.qtrs,function(x) x == 4)
      ## Remove concurred exceptional events, calculate annual 98th percentiles
      if (any(data$conc == -99,na.rm=TRUE)) { data$conc[which(data$conc == -99)] <- NA }
      ## Calculate 98th percentile, get 10 highest days for each year
      for (i in 1:3) {
        year.ind <- which(years == dv.years()[i])
        t <- data$conc[year.ind]
        if (sum(!is.na(t)) == 0) { next }
        d <- data$date[year.ind]
        max.ind <- order(t,decreasing=TRUE)
        ann$p98[i] <- t[max.ind][ann$Nmax[i]]
        if (ann$p98[i] > naaqs.level()) { ann$valid[i] <- TRUE }
        for (j in 1:10) {
          ann[i,paste("max",j,sep="")] <- t[max.ind][j]
          ann[i,paste("date",j,sep="")] <- as.character(d[max.ind][j])
        }
      }
      ## Calculate design value and test for validity
      dv <- list(dv=floor(mean(ann$p98)+0.5),valid=all(ann$valid))
      if (all(ann$obs > 0) & dv$dv > level) { dv$valid <- TRUE }
      ## Apply substitution test if all quarters >= 50% complete
      if (!is.na(dv$dv) & !dv$valid & all(qtr$pct >= 50)) {
        test <- ann[,c(1:4)]; concs <- data$conc;
        qtr.max <- tapply(data$conc,list(quarters),max.na)
        inv.qtrs <- subset(qtr,pct < 75)
        for (i in 1:nrow(inv.qtrs)) {
          q <- inv.qtrs$quarter[i]; y <- inv.qtrs$year[i];
          rep.ind <- which(years == y & quarters == q & as.character(dates) %in% sched & is.na(concs))
          if (length(rep.ind) > 0) { concs[rep.ind] <- qtr.max[q] }
        }
        for (i in 1:3) {
          t <- concs[which(years == dv.years()[i])]
          test$obs[i] <- sum(!is.na(t)); test$Nmax[i] <- test$obs[i] %/% 50 + 1;
          test$p98[i] <- t[order(t,decreasing=TRUE)][test$Nmax[i]]
        }
        test.dv <- floor(mean(test$p98)+0.5)
        if (test.dv < level) { dv$valid <- TRUE }
      }
      return(list(dv=dv,ann=ann,qtr=qtr))
    },message="Calculating Design Value...",value=NULL,detail=NULL) })
  })
  
  ##################################################################
  ## Logic controlling selections displayed in the lower right panel
  ##################################################################
  
  ## Menu allowing user to select days for exclusion
  output$ui.daily <- renderUI({
    if (vals$reset) { return() }
    if (is.null(input$type.select)) { return() }
    isolate({
      if (is.null(naaqs.level())) { return() }
      choices <- NULL; level <- naaqs.level();
      if (input$poll.select == "Ozone") {
        if (is.null(site.mda8())) { return() }
        temp <- site.mda8()
        req.obs <- ifelse(level == 70,13,18)
        temp$conc <- mapply(function(obs,conc) ifelse(obs >= req.obs | conc > level,
          floor(conc),NA),obs=temp$obs,conc=temp$dmax)
      }
      if (input$poll.select == "PM2.5") {
        if (is.null(site.data())) { return() }
        temp <- subset(site.data(),concur != "Y")
      }
      data <- subset(temp,!is.na(conc),c("date","conc","flag"))
      data$date <- as.character(data$date)
      if ("Request Exclusion Flags" %in% input$type.select) {
        vals <- subset(data,substr(flag,1,1) == "R")
        if (nrow(vals) > 0) { choices <- rbind(choices,vals) }
      }
      if ("Informational Flags" %in% input$type.select) {
        vals <- subset(data,substr(flag,1,1) == "I")
        if (nrow(vals) > 0) { choices <- rbind(choices,vals) }
      }
      if ("NAAQS Exceedance Days" %in% input$type.select) {
        vals <- subset(data,conc > level)
        if (nrow(vals) > 0) { choices <- rbind(choices,vals) }
      }
      if (is.null(choices)) { return("No values found meeting selected conditions.") }
      choices <- choices[order(choices$date),]
      selectInput(inputId="daily.select",label="Select days to exclude:",
        choices=c(paste(colnames(choices),collapse=" "),apply(choices,1,paste,collapse=" "),
          use.names=FALSE),selectize=FALSE,multiple=TRUE,size=10)
    })
  })
  
  ## Menu allowing user to select hours for exclusion (ozone only)
  output$ui.hourly <- renderUI({
    if (vals$reset) { return() }
    if (input$poll.select == "PM2.5") { return() }
    if (is.null(input$daily.select)) { return() }
    isolate({
      data <- subset(get.site.data(),!is.na(conc) & concur != "Y",c("date","hour","conc","flag"))
      data$date <- as.character(data$date)
      choices <- subset(data,date %in% substr(input$daily.select,1,10))
      choices$hour <- sprintf("%02d",choices$hour)
      if (length(choices) == 0) { return() }
      selectInput(inputId="hourly.select",label="Select hours to exclude:",
        choices=c(paste(colnames(choices),collapse=" "),apply(choices,1,paste,collapse=" "),
          use.names=FALSE),selectize=FALSE,multiple=TRUE,size=10)
    })
  })
  
  ## Make hourly selections persist when daily selections change
  observeEvent(input$daily.select,{
    if (vals$reset) { return() }
    if (input$poll.select == "PM2.5") { return() }
    index <- which(substr(input$hourly.select,1,10) %in% substr(input$daily.select,1,10))
    hrs.selected <- input$hourly.select[index]
    if (length(hrs.selected) > 0) {
      updateSelectInput(session,inputId="hourly.select",selected=hrs.selected)
    }
  })
  
  ## Action button to re-calculate ozone DV with selected hours removed
  output$o3dv.button <- renderUI({
    if (vals$reset) { return() }
    if (is.null(input$daily.select)) { return() }
    if (length(input$daily.select) == 0) { return() }
    if (input$poll.select == "PM2.5") { return("Ctrl+click to select multiple") }
    if (is.null(input$hourly.select)) { return() }
    if (length(input$hourly.select) == 0) { return() }
    actionButton(inputId="calc.o3dv",label="Re-Calculate DV",width="150px")
  })
  
  ## Action button to re-calculate PM2.5 DV with selected days removed
  output$pmdv.button <- renderUI({
    if (vals$reset) { return() }
    if (is.null(input$daily.select)) { return() }
    if (length(input$daily.select) == 0) { return() }
    if (input$poll.select == "Ozone") { return("Ctrl+click to select multiple") }
    actionButton(inputId="calc.pmdv",label="Re-Calculate DV",width="150px")    
  })
  
  ##############################################################
  ## Logic controlling values displayed in the upper right panel
  ##############################################################
  
  ## Ozone design value text output
  output$ozone.dvtext <- renderText({
    if (is.null(ozone.dv())) { return() }
    c(input$year.select," Design Value: ",ozone.dv()$dv$dv," ppb   ",
      input$year.select," Percent Complete: ",ozone.dv()$dv$pct,"\n\n",
      dv.years()[1]," 4th Highest Value: ",ozone.dv()$ann$max4[1]," ppb   ",
      dv.years()[1]," Percent Complete: ",ozone.dv()$ann$pct[1],"\n",
      dv.years()[2]," 4th highest Value: ",ozone.dv()$ann$max4[2]," ppb   ",
      dv.years()[2]," Percent Complete: ",ozone.dv()$ann$pct[2],"\n",
      dv.years()[3]," 4th highest Value: ",ozone.dv()$ann$max4[3]," ppb   ",
      dv.years()[3]," Percent Complete: ",ozone.dv()$ann$pct[3],"\n\n",
      " 1st Highest: ",ozone.dv()$ann$max1[1]," ppb ",ozone.dv()$ann$date1[1],"  ",
                       ozone.dv()$ann$max1[2]," ppb ",ozone.dv()$ann$date1[2],"  ",
                       ozone.dv()$ann$max1[3]," ppb ",ozone.dv()$ann$date1[3],"\n",
      " 2nd Highest: ",ozone.dv()$ann$max2[1]," ppb ",ozone.dv()$ann$date2[1],"  ",
                       ozone.dv()$ann$max2[2]," ppb ",ozone.dv()$ann$date2[2],"  ",
                       ozone.dv()$ann$max2[3]," ppb ",ozone.dv()$ann$date2[3],"\n",
      " 3rd Highest: ",ozone.dv()$ann$max3[1]," ppb ",ozone.dv()$ann$date3[1],"  ",
                       ozone.dv()$ann$max3[2]," ppb ",ozone.dv()$ann$date3[2],"  ",
                       ozone.dv()$ann$max3[3]," ppb ",ozone.dv()$ann$date3[3],"\n",
      " 4th Highest: ",ozone.dv()$ann$max4[1]," ppb ",ozone.dv()$ann$date4[1],"  ",
                       ozone.dv()$ann$max4[2]," ppb ",ozone.dv()$ann$date4[2],"  ",
                       ozone.dv()$ann$max4[3]," ppb ",ozone.dv()$ann$date4[3],"\n",
      " 5th Highest: ",ozone.dv()$ann$max5[1]," ppb ",ozone.dv()$ann$date5[1],"  ",
                       ozone.dv()$ann$max5[2]," ppb ",ozone.dv()$ann$date5[2],"  ",
                       ozone.dv()$ann$max5[3]," ppb ",ozone.dv()$ann$date5[3],"\n",
      " 6th Highest: ",ozone.dv()$ann$max6[1]," ppb ",ozone.dv()$ann$date6[1],"  ",
                       ozone.dv()$ann$max6[2]," ppb ",ozone.dv()$ann$date6[2],"  ",
                       ozone.dv()$ann$max6[3]," ppb ",ozone.dv()$ann$date6[3],"\n",
      " 7th Highest: ",ozone.dv()$ann$max7[1]," ppb ",ozone.dv()$ann$date7[1],"  ",
                       ozone.dv()$ann$max7[2]," ppb ",ozone.dv()$ann$date7[2],"  ",
                       ozone.dv()$ann$max7[3]," ppb ",ozone.dv()$ann$date7[3],"\n",
      " 8th Highest: ",ozone.dv()$ann$max8[1]," ppb ",ozone.dv()$ann$date8[1],"  ",
                       ozone.dv()$ann$max8[2]," ppb ",ozone.dv()$ann$date8[2],"  ",
                       ozone.dv()$ann$max8[3]," ppb ",ozone.dv()$ann$date8[3],"\n",
      " 9th Highest: ",ozone.dv()$ann$max9[1]," ppb ",ozone.dv()$ann$date9[1],"  ",
                       ozone.dv()$ann$max9[2]," ppb ",ozone.dv()$ann$date9[2],"  ",
                       ozone.dv()$ann$max9[3]," ppb ",ozone.dv()$ann$date9[3],"\n",
      "10th Highest: ",ozone.dv()$ann$max10[1]," ppb ",ozone.dv()$ann$date10[1],"  ",
                       ozone.dv()$ann$max10[2]," ppb ",ozone.dv()$ann$date10[2],"  ",
                       ozone.dv()$ann$max10[3]," ppb ",ozone.dv()$ann$date10[3],"\n")
  },sep="")
  
  ## PM2.5 annual design value text output
  output$pm25.annual.dvtext <- renderText({
    if (is.null(pm25.annual.dv())) { return() }
    if (naaqs.level() == 35) { return() }
    c(input$year.select," Design Value: ",sprintf("%4.1f",pm25.annual.dv()$dv$dv)," ug/m^3   ",
      input$year.select," DV Validity: ",pm25.annual.dv()$dv$valid,"\n\n",
      dv.years()[1]," Annual Mean: ",sprintf("%5.2f",pm25.annual.dv()$ann$mean[1])," ug/m^3   ",
      dv.years()[1]," Complete Quarters: ",pm25.annual.dv()$ann$complete.qtrs[1],"\n",
      dv.years()[2]," Annual Mean: ",sprintf("%5.2f",pm25.annual.dv()$ann$mean[2])," ug/m^3   ",
      dv.years()[2]," Complete Quarters: ",pm25.annual.dv()$ann$complete.qtrs[2],"\n",
      dv.years()[3]," Annual Mean: ",sprintf("%5.2f",pm25.annual.dv()$ann$mean[3])," ug/m^3   ",
      dv.years()[3]," Complete Quarters: ",pm25.annual.dv()$ann$complete.qtrs[3],"\n\n",
      dv.years()[1]," Q1 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[1])," ug/m^3   ",
      dv.years()[1]," Q1 Percent Complete: ",pm25.annual.dv()$qtr$pct[1],"\n",
      dv.years()[1]," Q2 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[2])," ug/m^3   ",
      dv.years()[1]," Q2 Percent Complete: ",pm25.annual.dv()$qtr$pct[2],"\n",
      dv.years()[1]," Q3 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[3])," ug/m^3   ",
      dv.years()[1]," Q3 Percent Complete: ",pm25.annual.dv()$qtr$pct[3],"\n",
      dv.years()[1]," Q4 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[4])," ug/m^3   ",
      dv.years()[1]," Q4 Percent Complete: ",pm25.annual.dv()$qtr$pct[4],"\n",
      dv.years()[2]," Q1 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[5])," ug/m^3   ",
      dv.years()[2]," Q1 Percent Complete: ",pm25.annual.dv()$qtr$pct[5],"\n",
      dv.years()[2]," Q2 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[6])," ug/m^3   ",
      dv.years()[2]," Q2 Percent Complete: ",pm25.annual.dv()$qtr$pct[6],"\n",
      dv.years()[2]," Q3 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[7])," ug/m^3   ",
      dv.years()[2]," Q3 Percent Complete: ",pm25.annual.dv()$qtr$pct[7],"\n",
      dv.years()[2]," Q4 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[8])," ug/m^3   ",
      dv.years()[2]," Q4 Percent Complete: ",pm25.annual.dv()$qtr$pct[8],"\n",
      dv.years()[3]," Q1 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[9])," ug/m^3   ",
      dv.years()[3]," Q1 Percent Complete: ",pm25.annual.dv()$qtr$pct[9],"\n",
      dv.years()[3]," Q2 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[10])," ug/m^3   ",
      dv.years()[3]," Q2 Percent Complete: ",pm25.annual.dv()$qtr$pct[10],"\n",
      dv.years()[3]," Q3 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[11])," ug/m^3   ",
      dv.years()[3]," Q3 Percent Complete: ",pm25.annual.dv()$qtr$pct[11],"\n",
      dv.years()[3]," Q4 Mean: ",sprintf("%5.2f",pm25.annual.dv()$qtr$mean[12])," ug/m^3   ",
      dv.years()[3]," Q4 Percent Complete: ",pm25.annual.dv()$qtr$pct[12],"\n")
  },sep="")
  
  ## PM2.5 daily design value text output
  output$pm25.daily.dvtext <- renderText({
    if (is.null(pm25.daily.dv())) { return() }
    if (naaqs.level() != 35) { return() }
    c(input$year.select," Design Value: ",pm25.daily.dv()$dv$dv," ug/m^3   ",
      input$year.select," DV Validity: ",pm25.daily.dv()$dv$valid,"\n\n",
      dv.years()[1]," 98th Percentile: ",sprintf("%4.1f",pm25.daily.dv()$ann$p98[1])," ug/m^3   ",
      dv.years()[1]," Complete Quarters: ",pm25.daily.dv()$ann$complete.qtrs[1],"\n",
      dv.years()[2]," 98th Percentile: ",sprintf("%4.1f",pm25.daily.dv()$ann$p98[2])," ug/m^3   ",
      dv.years()[2]," Complete Quarters: ",pm25.daily.dv()$ann$complete.qtrs[2],"\n",
      dv.years()[3]," 98th Percentile: ",sprintf("%4.1f",pm25.daily.dv()$ann$p98[3])," ug/m^3   ",
      dv.years()[3]," Complete Quarters: ",pm25.daily.dv()$ann$complete.qtrs[3],"\n\n",
      " 1st Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max1[1])," ug/m^3 ",pm25.daily.dv()$ann$date1[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max1[2])," ug/m^3 ",pm25.daily.dv()$ann$date1[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max1[3])," ug/m^3 ",pm25.daily.dv()$ann$date1[3],"\n",
      " 2nd Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max2[1])," ug/m^3 ",pm25.daily.dv()$ann$date2[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max2[2])," ug/m^3 ",pm25.daily.dv()$ann$date2[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max2[3])," ug/m^3 ",pm25.daily.dv()$ann$date2[3],"\n",
      " 3rd Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max3[1])," ug/m^3 ",pm25.daily.dv()$ann$date3[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max3[2])," ug/m^3 ",pm25.daily.dv()$ann$date3[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max3[3])," ug/m^3 ",pm25.daily.dv()$ann$date3[3],"\n",
      " 4th Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max4[1])," ug/m^3 ",pm25.daily.dv()$ann$date4[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max4[2])," ug/m^3 ",pm25.daily.dv()$ann$date4[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max4[3])," ug/m^3 ",pm25.daily.dv()$ann$date4[3],"\n",
      " 5th Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max5[1])," ug/m^3 ",pm25.daily.dv()$ann$date5[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max5[2])," ug/m^3 ",pm25.daily.dv()$ann$date5[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max5[3])," ug/m^3 ",pm25.daily.dv()$ann$date5[3],"\n",
      " 6th Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max6[1])," ug/m^3 ",pm25.daily.dv()$ann$date6[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max6[2])," ug/m^3 ",pm25.daily.dv()$ann$date6[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max6[3])," ug/m^3 ",pm25.daily.dv()$ann$date6[3],"\n",
      " 7th Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max7[1])," ug/m^3 ",pm25.daily.dv()$ann$date7[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max7[2])," ug/m^3 ",pm25.daily.dv()$ann$date7[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max7[3])," ug/m^3 ",pm25.daily.dv()$ann$date7[3],"\n",
      " 8th Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max8[1])," ug/m^3 ",pm25.daily.dv()$ann$date8[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max8[2])," ug/m^3 ",pm25.daily.dv()$ann$date8[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max8[3])," ug/m^3 ",pm25.daily.dv()$ann$date8[3],"\n",
      " 9th Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max9[1])," ug/m^3 ",pm25.daily.dv()$ann$date9[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max9[2])," ug/m^3 ",pm25.daily.dv()$ann$date9[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max9[3])," ug/m^3 ",pm25.daily.dv()$ann$date9[3],"\n",
      "10th Highest: ",sprintf("%4.1f",pm25.daily.dv()$ann$max10[1])," ug/m^3 ",pm25.daily.dv()$ann$date10[1],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max10[2])," ug/m^3 ",pm25.daily.dv()$ann$date10[2],"  ",
                       sprintf("%4.1f",pm25.daily.dv()$ann$max10[3])," ug/m^3 ",pm25.daily.dv()$ann$date10[3],"\n")
  },sep="")
  
  ################################################################
  ## Logic controlling download link in the lower left-hand corner
  ################################################################
  
  ## Trigger to prevent download button from displaying before data retrieval finishes
  output$showLink <- reactive({
    if (vals$reset) { return(FALSE) }
    return(ifelse(is.null(site.data()),FALSE,TRUE)) 
  })
  outputOptions(output,"showLink",suspendWhenHidden=FALSE)
  
  ## Download Ozone DV data to Excel spreadsheet
  output$download.ozone <- downloadHandler(
    filename=function() { return(gsub("-","",paste("Ozone","_",aqs.site.id(),"_",
      input$year.select,"_",Sys.Date(),".xlsx",sep=""))) },
    content=function(file) {
      wb <- loadWorkbook("xlsx/OzoneDVtemplate.xlsx")
      site <- subset(get.sites(),site == aqs.site.id()); level <- naaqs.level();
      data <- site.mda8(); dv <- ozone.dv(); req.obs <- ifelse(level == 70,13,18);
      data$date <- as.character(data$date); data$dmax <- round(data$dmax,3);
      valid <- data$obs >= req.obs | floor(data$dmax) > level; data$dmax[!valid] <- NA;
      if (any(data$conc == -99,na.rm=TRUE)) { data$conc[which(data$conc == -99)] <- NA }
      daily <- split(data,substr(data$date,1,4))
      for (i in 1:3) {
        writeData(wb,sheet=i+1,x=daily[[i]],startCol=1,startRow=2,
          colNames=FALSE,rowNames=FALSE,na.string="")
      }
      writeData(wb,sheet=1,x=unlist(c(input$naaqs.select,site)),startCol=2,startRow=2,
        colNames=FALSE,rowNames=FALSE,na.string="")
      writeData(wb,sheet=1,x=dv$ann$pct,startCol=3,startRow=15,
        colNames=FALSE,rowNames=FALSE,na.string="")
      saveWorkbook(wb,file)
      invisible(NULL)
  })
  
  ## Download PM2.5 DV data to Excel spreadsheet
  output$download.pm25 <- downloadHandler(
    filename=function() { return(gsub("-","",paste("PM25","_",aqs.site.id(),"_",
      input$year.select,"_",Sys.Date(),".xlsx",sep=""))) },
    content=function(file) {
      wb <- loadWorkbook("xlsx/PM25DVtemplate.xlsx")
      site <- subset(get.sites(),site == aqs.site.id())
      data <- site.data(); ann.dv <- pm25.annual.dv(); daily.dv <- pm25.daily.dv();
      data$date <- as.character(data$date);
      data$quarter <- (as.numeric(substr(data$date,6,7))-1) %/% 3 + 1
      if (any(data$conc == -99,na.rm=TRUE)) { data$conc[which(data$conc == -99)] <- NA }
      daily <- split(data[,c("date","quarter","conc","flag")],substr(data$date,1,4))
      for (i in 1:3) {
        writeData(wb,sheet=i+1,x=daily[[i]],startCol=1,startRow=2,
          colNames=FALSE,rowNames=FALSE,na.string="")
      }
      writeData(wb,sheet=1,x=unlist(site),startCol=2,startRow=2,
        colNames=FALSE,rowNames=FALSE,na.string="")
      writeData(wb,sheet=1,x=ifelse(ann.dv$dv$valid,"Yes","No"),startCol=3,startRow=10,
        colNames=FALSE,rowNames=FALSE,na.string="")
      writeData(wb,sheet=1,x=ifelse(daily.dv$dv$valid,"Yes","No"),startCol=3,startRow=12,
        colNames=FALSE,rowNames=FALSE,na.string="")
      writeData(wb,sheet=1,x=ann.dv$qtr[,c("obs","pct")],startCol=10,startRow=15,
        colNames=FALSE,rowNames=FALSE,na.string="")
      saveWorkbook(wb,file)
      invisible(NULL)
  })
})
