local({
library(rsconnect)

app_dir <- normalizePath(".", winslash = "/", mustWork = TRUE)

get_git_value <- function(args) {
  value <- system2("git", c("-C", shQuote(app_dir), args),
    stdout = TRUE, stderr = TRUE)
  status <- attr(value, "status")
  if (!is.null(status) && status != 0) {
    stop("Unable to read Git deployment metadata: ", paste(value, collapse = "\n"))
  }
  trimws(paste(value, collapse = "\n"))
}

current_branch <- get_git_value(c("rev-parse", "--abbrev-ref", "HEAD"))
current_commit <- substr(get_git_value(c("rev-parse", "HEAD")), 1, 7)
is_public_deployment <- identical(current_branch, "main")

connect_server_url <- trimws(Sys.getenv("CONNECT_SERVER"))
connect_account <- trimws(Sys.getenv("CONNECT_ACCOUNT"))
if (!nzchar(connect_account)) {
  connect_account <- "dmap"
}
connect_api_key <- Sys.getenv("CONNECT_API_KEY")
connect_server_name <- "ee_dvcalc"

if (nzchar(connect_server_url)) {
  rsconnect::addServer(url = connect_server_url, name = connect_server_name)
}
if (nzchar(connect_api_key)) {
  if (!nzchar(connect_server_url)) {
    stop("Set CONNECT_SERVER when using CONNECT_API_KEY.")
  }
  rsconnect::connectApiUser(
    account = connect_account,
    server = connect_server_name,
    apiKey = connect_api_key
  )
}

deployment_dir <- tempfile("ee_dvcalc_deploy_")
dir.create(deployment_dir)
on.exit(unlink(deployment_dir, recursive = TRUE), add = TRUE)

copy_app_files <- function(source_dir, target_dir) {
  entries <- list.files(source_dir, all.files = TRUE, no.. = TRUE)
  entries <- entries[!grepl("^\\.Renviron($|\\.)|^\\.env($|\\.)", entries)]
  entries <- setdiff(entries, c(
    ".git", ".Rproj.user", "local_files", "rsconnect", "git_info.txt"
  ))
  for (entry in entries) {
    source <- file.path(source_dir, entry)
    target <- file.path(target_dir, entry)
    if (dir.exists(source)) {
      dir.create(target)
      copy_app_files(source, target)
    } else if (!file.copy(source, target, overwrite = TRUE)) {
      stop("Unable to package deployment file: ", source)
    }
  }
}

copy_app_files(app_dir, deployment_dir)

global_file <- file.path(deployment_dir, "global.R")
global_lines <- readLines(global_file, warn = FALSE)
data_source_line <- grep("^public\\.server\\s*<-\\s*TRUE\\s*$", global_lines)
if (length(data_source_line) != 1) {
  stop("Expected exactly one `public.server <- TRUE` setting in global.R.")
}
if (!is_public_deployment) {
  global_lines[data_source_line] <- "public.server <- FALSE"
  writeLines(global_lines, global_file)
}

deployed_at <- format(Sys.time(), "%Y-%m-%d %H:%M")
writeLines(c(
  paste0("branch: ", current_branch),
  paste0("commit: ", current_commit),
  paste0("deployed: ", deployed_at)
), file.path(deployment_dir, "git_info.txt"))

app_name <- if (is_public_deployment) {
  "ee_dvcalc"
} else {
  paste0("ee_dvcalc_", gsub("[^A-Za-z0-9_-]", "_", current_branch))
}

message(
  "Deploying ", app_name, " with ",
  if (is_public_deployment) "pins-board" else "local Rdata",
  " data."
)

rsconnect::deployApp(
  appDir = deployment_dir,
  appName = app_name,
  account = connect_account,
  server = if (nzchar(connect_server_url)) connect_server_name else NULL,
  launch.browser = FALSE,
  forceUpdate = TRUE
)
})
