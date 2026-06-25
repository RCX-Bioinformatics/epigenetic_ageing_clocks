suppressPackageStartupMessages(library("methylCIPHER"))
suppressPackageStartupMessages(library("dplyr"))

# Load custom R functions
source("custom_functions/parse_named_args.r")
source("custom_functions/calcGrimAgeV1.r")
source("custom_functions/check_common_inputs.r")
source("custom_functions/align_meth_pheno.r")

# Read command-line arguments and parse them
args <- commandArgs(trailingOnly = TRUE)
parsed_args <- type.convert.args(args)

# Description of arguments
cat("Usage: Rscript grimage.R beta_vals=my_beta_vals.rds pheno_data=my_pheno_data.csv dataset_name=my_dataset output_dir=/my/output/dir\n\n")
cat("Arguments:\n\n")
cat("  beta_vals: Provide the full path to your beta values rds file.\n\n")
cat("  pheno_data: Provide the full path to a CSV file containing phenotype data.\n",
    "              The file must include the following columns:\n",
    "              - \"SampleID\" : Unique sample identifiers (must match methylation data row names)\n",
    "              - \"Age\"      : Numeric age values\n",
    "              - \"Female\"   : Sex indicator (1 = female, 0 = male)\n\n")
cat("  dataset_name: Name of the processed dataset, will be part of output filenames.\n\n")
cat("  output_dir: Directory where the output files will be saved.\n\n")

# Load beta values
# row names (sample Identifiers) and column names (CpG identities)
datMeth <- readRDS(as.character(parsed_args$beta_vals))
datMeth <- t(datMeth)
datMeth[1:5, 1:5]

# Load pheno data
pheno <- read.csv(as.character(parsed_args$pheno_data))
head(pheno)

# Align data
align_res <- align_meth_pheno(datMeth, pheno)
datMeth <- align_res$datMeth
pheno   <- align_res$datPheno
message("Number of samples with available methylation and phenotype data: ",
        nrow(datMeth))

cat("Calculating GrimAge...\n")
grimage_res <- calcGrimAgeV1(datMeth, pheno)

# Ensure top-level output_dir exists and set working directory
output_dir <- ifelse(!is.null(parsed_args$output_dir), parsed_args$output_dir, getwd())
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
setwd(output_dir)

# Save GrimAge estimate
write.table(grimage_res,
            file = paste0(parsed_args$dataset_name,
                "_GrimAge.csv"),
            col.names = TRUE, row.names = FALSE, sep = ",")
cat("GrimAge estimate completed successfully!\n")