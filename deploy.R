## Run from the repository root with source("deploy.R") or Rscript deploy.R.
## Configure CONNECT_STAGING_SERVER locally and verify that its URL is staging.
## local() keeps deployment variables out of the calling R session.
local({
library(rsconnect)

app_dir <- normalizePath(".", winslash = "/", mustWork = TRUE)

## Read metadata from this checkout; stop rather than deploy with unknown identity.
get_git_value <- function(args) {
  value <- system2("git", c("-C", shQuote(app_dir), args),
    stdout = TRUE, stderr = TRUE)
  status <- attr(value, "status")
  if (!is.null(status) && status != 0) {
    stop("Unable to read Git deployment metadata: ", paste(value, collapse = "\n"))
  }
  trimws(paste(value, collapse = "\n"))
}

## Keep one stable target per branch; detached HEAD uses a target per full commit.
get_app_name <- function(branch, commit) {
  detached <- identical(branch, "HEAD")
  ref <- if (detached) paste0("commit:", commit) else paste0("branch:", branch)
  ## Hash the original ref, so feature/foo and feature_foo have different names.
  ## Base R hashes a temporary file, avoiding an additional package dependency.
  ref_file <- tempfile("ee_dvcalc_ref_")
  on.exit(unlink(ref_file), add = TRUE)
  writeBin(charToRaw(enc2utf8(ref)), ref_file)
  ref_hash <- unname(tools::md5sum(ref_file))
  if (is.na(ref_hash)) {
    stop("Unable to hash Git deployment ref.")
  }
  label <- if (detached) paste0("detached_", substr(commit, 1, 7)) else branch
  label <- gsub("[^A-Za-z0-9_-]", "_", label)
  prefix <- "ee_dvcalc_staging_"
  ## Shorten only the readable label to fit Connect's 64-character name limit.
  label <- substr(label, 1, 64 - nchar(prefix) - nchar(ref_hash) - 1)
  paste0(prefix, label, "_", ref_hash)
}

## Keep the full commit for detached-HEAD naming and a short version for metadata.
current_branch <- get_git_value(c("rev-parse", "--abbrev-ref", "HEAD"))
git_commit <- get_git_value(c("rev-parse", "HEAD"))
current_commit <- substr(git_commit, 1, 7)

## These settings belong to the local deployment process, not the hosted app.
## No generic/public server fallback is allowed; the URL itself is not validated.
connect_server_url <- trimws(Sys.getenv("CONNECT_STAGING_SERVER"))
if (!nzchar(connect_server_url)) {
  stop("Set CONNECT_STAGING_SERVER to the staging Posit Connect URL.")
}
connect_account <- trimws(Sys.getenv("CONNECT_STAGING_ACCOUNT"))
if (!nzchar(connect_account)) {
  connect_account <- "dmap"
}
connect_api_key <- Sys.getenv("CONNECT_STAGING_API_KEY")
connect_server_name <- "ee_dvcalc_staging"

## Register the staging URL locally. Without a supplied key, use saved credentials.
## Configure hosted AQS credentials separately in the Connect app environment.
rsconnect::addServer(url = connect_server_url, name = connect_server_name)
if (nzchar(connect_api_key)) {
  rsconnect::connectApiUser(
    account = connect_account,
    server = connect_server_name,
    apiKey = connect_api_key
  )
}

## Build a disposable copy; tracked app files stay unchanged, even on failure.
## Remove that copy when this local block exits, including after an error.
deployment_dir <- tempfile("ee_dvcalc_deploy_")
dir.create(deployment_dir)
on.exit(unlink(deployment_dir, recursive = TRUE), add = TRUE)

## Apply exclusions at every directory level while preserving runtime assets.
copy_app_files <- function(source_dir, target_dir) {
  entries <- list.files(source_dir, all.files = TRUE, no.. = TRUE)
  ## Never copy local environment/credential files, including example variants.
  entries <- entries[!grepl("^\\.Renviron($|\\.)|^\\.env($|\\.)", entries)]
  ## rsconnect scans bundled R/Rmd files for dependencies. Exclude deployment and
  ## database-refresh scripts so their non-runtime packages are not inferred.
  entries <- setdiff(entries, c(
    ".git", ".Rproj.user", "local_files", "rsconnect", "git_info.txt",
    "deploy.R", "EE_DVcalc_update.Rmd"
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

## Change only the copied global.R to load aqsdata.Rdata instead of public pins.
## Require exactly one recognized setting so unexpected source changes fail early.
## Concentration retrieval still uses the live AQS API in this mode.
global_file <- file.path(deployment_dir, "global.R")
global_lines <- readLines(global_file, warn = FALSE)
data_source_line <- grep("^public\\.server\\s*<-\\s*(TRUE|FALSE)\\s*$", global_lines)
if (length(data_source_line) != 1) {
  stop("Expected exactly one `public.server` TRUE/FALSE setting in global.R.")
}
global_lines[data_source_line] <- "public.server <- FALSE"
writeLines(global_lines, global_file)

## Include checkout identity and packaging time in the bundle for traceability.
deployed_at <- format(Sys.time(), "%Y-%m-%d %H:%M")
writeLines(c(
  paste0("branch: ", current_branch),
  paste0("commit: ", current_commit),
  paste0("deployed: ", deployed_at)
), file.path(deployment_dir, "git_info.txt"))

app_name <- get_app_name(current_branch, git_commit)

message(
  "Deploying ", app_name, " with ",
  "local Rdata data to the staging Connect server."
)

## Upload immediately, without a confirmation prompt or opening a browser.
## forceUpdate replaces this ref's existing staging app; other refs have hashed names.
## Hashed names differ from the old naming scheme and can create new staging apps.
rsconnect::deployApp(
  appDir = deployment_dir,
  appName = app_name,
  account = connect_account,
  server = connect_server_name,
  launch.browser = FALSE,
  forceUpdate = TRUE
)
})
