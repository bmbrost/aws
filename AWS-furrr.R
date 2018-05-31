# https://gist.github.com/DavisVaughan/865d95cf0101c24df27b37f4047dd2e5
# DavisVaughan / AWS-furrr.R

# This example demonstrates running furrr code distributed on 2 AWS instances ("nodes").

# The instances have already been created.

library(future)
library(furrr)

# Two t2.micro AWS instances
# Created from http://www.louisaslett.com/RStudio_AMI/
public_ip <- c("34.205.155.182", "34.201.26.217")

# This is where my pem file lives (password to connect essentially).
ssh_private_key_file <- "~/Desktop/programming/AWS/key-pair/dvaughan.pem"

# Connect!
cl <- makeClusterPSOCK(
  
  ## Public IP number of EC2 instance
  public_ip,
  
  ## User name (always 'ubuntu')
  user = "ubuntu",
  
  ## Use private SSH key registered with AWS
  rshopts = c(
    "-o", "StrictHostKeyChecking=no",
    "-o", "IdentitiesOnly=yes",
    "-i", ssh_private_key_file
  ),
  
  ## Set up .libPaths() for the 'ubuntu' user and
  ## install future/purrr/furrr packages
  rscript_args = c(
    "-e", shQuote("local({p <- Sys.getenv('R_LIBS_USER'); dir.create(p, recursive = TRUE, showWarnings = FALSE); .libPaths(p)})"),
    "-e", shQuote("install.packages(c('future', 'purrr', 'furrr'))")
  ),
  
  dryrun = FALSE
)

# Set the plan to use the cluster workers!
plan(cluster, workers = cl)

# Run some code distributed evenly on the two workers!
x <- 1
future_map(1:5, ~{.x + x})
#> [[1]]
#> [1] 2
#> 
#> [[2]]
#> [1] 3
#> 
#> [[3]]
#> [1] 4
#> 
#> [[4]]
#> [1] 5
#> 
#> [[5]]
#> [1] 6

# Are we reaallllly running in parallel?
library(tictoc)
tic()
future_map(1:2, ~{ Sys.sleep(10) })
#> [[1]]
#> NULL
#> 
#> [[2]]
#> NULL
toc()
#> 13.158 sec elapsed

# Shut down
parallel::stopCluster(cl)