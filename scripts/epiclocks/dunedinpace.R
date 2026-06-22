suppressPackageStartupMessages(library("DunedinPACE"))
suppressPackageStartupMessages(library("data.table"))

# Load custom R functions
source("custom_functions/parse_named_args.r")
# Read command-line arguments and parse them
args <- commandArgs(trailingOnly = TRUE)
parsed_args <- type.convert.args(args)

# Description of arguments
cat("Usage: Rscript dunedinpace.R beta_vals=my_beta_vals.rds dataset_name=my_dataset output_dir=/my/output/dir\n\n")
cat("Arguments:\n\n")
cat("  beta_vals: Provide the full path to your beta values rds file.\n\n")
cat("  dataset_name: Name of the processed dataset, will be part of output filenames.\n\n")
cat("  output_dir: Directory where the output files will be saved.\n\n")

# Load beta values
# row names (sample Identifiers) and column names (CpG identities)
datMeth <- readRDS(as.character(parsed_args$beta_vals))
datMeth[1:5, 1:5]

# Calculate DunedinPACE
cat("Calculating DunedinPACE...\n")
res <- PACEProjector(datMeth)
DunedinPACE <- as.data.frame(res$DunedinPACE)

# Ensure top-level output_dir exists and set working directory
output_dir <- ifelse(!is.null(parsed_args$output_dir), parsed_args$output_dir, getwd())
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
setwd(output_dir)

# Save DunedinPACE estimate
write.table(DunedinPACE,
            file=paste0(parsed_args$dataset_name,
            "_DunedinPACE", ".csv"),
            col.names = TRUE, row.names = TRUE, sep=",")
cat("DunedinPACE estimate completed successfully!\n")