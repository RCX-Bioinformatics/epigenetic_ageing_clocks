suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(lumi))

# Load custom R functions
source("custom_functions/parse_named_args.r")
source("custom_functions/save_matrix_chunks_gz.r")
# Read command-line arguments and parse them
args <- commandArgs(trailingOnly = TRUE)
parsed_args <- type.convert.args(args)

# Description of arguments
cat("Usage: Rscript cheekage_input_prep.R beta_vals=my_beta_vals.rds samples_in_chunk=10 dataset_name=my_dataset output_dir=/my/output/dir\n\n")
cat("Arguments:\n\n")
cat("  beta_vals: Provide the full path to your beta values rds file.\n\n")
cat("  samples_in_chunk: default: 13. Number of samples in each chunk of gzipped csv (limit for CheekAge shiny server is 100mb).\n\n")
cat("  dataset_name: Name of the processed dataset, will be part of output filenames.\n\n")
cat("  output_dir: Directory where all outputs will be saved. (default = current working directory)\n\n")

output_dir <- ifelse(!is.null(parsed_args$output_dir), parsed_args$output_dir, getwd())
# Extract the filename from the path
filename <- basename(parsed_args$beta_vals)
# Remove the file extension (.rds)
parsed_name <- sub("\\.rds$", "", filename)
parsed_name <- sub("^beta_values_", "", parsed_name)
# create output folder
# dir.create(parsed_name)
beta_vals <- readRDS(as.character(parsed_args$beta_vals))
mvals <- beta2m(beta_vals)

# Ensure top-level output_dir exists and set working directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
setwd(output_dir)

save_matrix_chunks_gz(matrix_data = mvals, 
                      file_prefix = paste0("M_vals_chunk"),
                      output_dir = parsed_name,
                      chunk_size = as.numeric(parsed_args$samples_in_chunk))

cat("\n Beta value conversion complete.\n Compressed chunks successfully created and saved.\n")
