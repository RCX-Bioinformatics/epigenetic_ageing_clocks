suppressPackageStartupMessages(library("RPMM"))
suppressPackageStartupMessages(library("sqldf"))
suppressPackageStartupMessages(library("WGCNA"))
suppressPackageStartupMessages(library("impute"))

options(digits=14)

# Load custom R functions and inputs
source("custom_functions/parse_named_args.r")
source("custom_functions/dnamage_input_prep.r")
source("custom_functions/dnamage_estimate.r")
source("custom_functions/comment_predicted_age.r")
source("/opt/13059_2013_3156_MOESM24_ESM.txt")
probeAnnotation21kdatMethUsed <- read.csv("/opt/13059_2013_3156_MOESM22_ESM.csv")
probeAnnotation27k <- read.csv("/opt/13059_2013_3156_MOESM21_ESM.csv")
datClock <- read.csv("/opt/13059_2013_3156_MOESM23_ESM.csv")

# Read command-line arguments and parse them
args <- commandArgs(trailingOnly = TRUE)
parsed_args <- type.convert.args(args)

# Description of arguments
cat("Usage: Rscript horvath_dnamage.R beta_vals=/full/path/my_beta_vals.rds output_dir=/my/output/dir\n\n")
cat("Arguments:\n\n")
cat("  beta_vals: Provide the full file path to the .rds file containing the beta values.\n\n")
cat("  output_dir: Directory where all outputs will be saved. (default = current working directory)\n\n")

output_dir <- ifelse(!is.null(parsed_args$output_dir), parsed_args$output_dir, getwd())
betas <- readRDS(as.character(parsed_args$beta_vals))
# Extract the filename from the path
filename <- basename(parsed_args$beta_vals)
parsed_beta_name <- sub("\\.rds$", "", filename)

# Define basic functions
trafo <- function(x,adult.age=20) { x=(x+1)/(1+adult.age); y=ifelse(x<=1, log( x),x-1);y }
anti.trafo <- function(x,adult.age=20) { ifelse(x<0, (1+adult.age)*exp(x)-1, (1+adult.age)*x+adult.age) }

# Create a log file which will be output into your directory
file.create(paste0(output_dir,"LogFile.txt"))

dnamage_prep <- dnamage_input_prep(betas = betas,
                                    logfile = paste0(output_dir,"LogFile.txt"),
                                    probeAnnotation27k = probeAnnotation27k,
                                    probeAnnotation21kdatMethUsed = probeAnnotation21kdatMethUsed)

dnamage_out <- dnamage_estimate(dat1 = dnamage_prep$betas, 
                                normalizeData=TRUE, 
                                probeAnnotation21kdatMethUsed = probeAnnotation21kdatMethUsed, 
                                logfile = paste0(output_dir,"LogFile.txt"), 
                                meanXchromosome = dnamage_prep$mean_X_chromosome, 
                                datClock = datClock)

# Ensure top-level output_dir exists and set working directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
setwd(output_dir)

# Save DNAmAge estimate
write.table(dnamage_out, file=paste0(parsed_beta_name, "_DNAmAge", ".csv"), col.names = T, row.names = F, sep=",")
cat("Horvath's DNAmAge estimate completed successfully!\n")
