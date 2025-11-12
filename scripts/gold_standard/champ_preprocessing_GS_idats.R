# ChAMP-like preprocessing script for custom signal intensities matrix input (no IDATs)

suppressPackageStartupMessages(library(minfi))
suppressPackageStartupMessages(library(ChAMP))
suppressPackageStartupMessages(library(sva))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(dendextend))
suppressPackageStartupMessages(library(EpiDISH))
suppressPackageStartupMessages(library(lumi))

source("custom_functions/parse_named_args.r")
args <- commandArgs(trailingOnly = TRUE)
parsed_args <- type.convert.args(args)

cat("Usage: Rscript champ_preprocessing_GS_idats.R idat_dir=/my/idat/dir/ dataset_name=my_dataset arraytype=450K output_dir=/my/output/dir/\n\n")
cat("Arguments:\n\n")
cat("  idat_dir: Provide the full path to your IDAT directory.\n\n")
cat("  arraytype: Choose microarray type 450K or EPIC.(default = 450K)\n\n")
cat("  dataset_name: Name of the processed dataset, will be part of output filenames.\n\n")
cat("  output_dir: Directory where all outputs will be saved. (default = current working directory)\n\n")

array <- ifelse(!is.null(parsed_args$arraytype), as.character(parsed_args$arraytype), "450K")
suffix <- paste0(parsed_args$dataset_name, "_BMIQ")
output_dir <- ifelse(!is.null(parsed_args$output_dir), parsed_args$output_dir, getwd())

# Ensure top-level output_dir exists and set working directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
setwd(output_dir)

# Load signal intensities using champ.load() from ChAMP package
idat_load <- champ.load(directory = as.character(parsed_args$idat_dir),
                          arraytype = array, method = "minfi",
                          filterNoCG = FALSE, filterXY = FALSE, filterBeads = FALSE,
                          SampleCutoff = 1.1, filterDetP = FALSE, detPcut = 1.1, 
                          filterSNPs = FALSE, filterMultiHit = FALSE)

# Normalize using BMIQ
norm.beta <- champ.norm(beta = idat_load$beta, 
                        method = "BMIQ", arraytype = array, 
                        plotBMIQ = TRUE, 
                        resultsDir = "./CHAMP_Normalization/")

# Create dummy pheno only if needed
if (length(idat_load$pd) != ncol(idat_load$beta)) {
    sample_names <- colnames(idat_load$beta)
    dummy_pheno <- rep("Unknown", length(sample_names))
    names(dummy_pheno) <- sample_names
    message("WARNING: No phenotype data detected. Using dummy phenotype.")
} else {
    dummy_pheno <- idat_load$pd
}
# QC reports
champ.QC(beta = idat_load$beta, pheno = dummy_pheno, 
        resultsDir = "./raw_data")
champ.QC(beta = norm.beta, pheno = dummy_pheno, 
        resultsDir = "./normalised")

# Save outputs
Mvals_bmiq <- beta2m(norm.beta)
saveRDS(Mvals_bmiq, paste0("M_values_", suffix, ".rds"))
saveRDS(norm.beta, paste0("beta_values_", suffix, ".rds"))
saveRDS(idat_load$beta, paste0("beta_values_", parsed_args$dataset_name, ".rds"))

cat("Processing completed successfully!\n")