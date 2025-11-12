# ChAMP-like preprocessing script for custom signal intensities matrix input (no IDATs)

suppressPackageStartupMessages(library(minfi))
suppressPackageStartupMessages(library(ChAMP))
suppressPackageStartupMessages(library(sva))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(dendextend))
suppressPackageStartupMessages(library(lumi))

source("custom_functions/parse_named_args.r")
source("custom_functions/champ.load.signal.intensities.r")

args <- commandArgs(trailingOnly = TRUE)
parsed_args <- type.convert.args(args)

cat("Usage: Rscript champ_preprocessing_GS_signal_intensities.R input_file=signal_intensities.txt.gz samples_to_process=samples_to_process.rds dataset_name=my_dataset arraytype=450K output_dir=/my/output/dir\n\n")
cat("Arguments:\n\n")
cat("  input_file: Path to the input .csv.gz file containing signal intensities. The file must be tab-delimited.\n\n")
cat("  arraytype: Choose microarray type 450K or EPIC.(default = 450K)\n\n")
cat("  dataset_name: Name of the processed dataset, will be part of output filenames.\n\n")
cat("  samples_to_process: RDS file with set of samples that should be processed.\n\n")
cat("  output_dir: Directory where all outputs will be saved. (default = current working directory)\n\n")

array <- ifelse(!is.null(parsed_args$arraytype), as.character(parsed_args$arraytype), "450K")
output_dir <- ifelse(!is.null(parsed_args$output_dir), parsed_args$output_dir, getwd())

# Ensure top-level output_dir exists and set working directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
setwd(output_dir)

samples_to_process <- NA
if (!is.null(parsed_args$samples_to_process)) {
    message("Reading samples_to_process from file: ", parsed_args$samples_to_process)
    samples_to_process <- readRDS(parsed_args$samples_to_process)
    message("Loaded ", length(samples_to_process), " samples.")
}
suffix <- paste0(parsed_args$dataset_name, "_BMIQ")

# Load the signal matrix
signal_intensities <- read.table(parsed_args$input_file, 
                                sep = "\t", 
                                header = TRUE, 
                                row.names = 1, 
                                check.names = FALSE)

# Load signal intensities using modified champ.load() from ChAMP package
signal_int_load <- champ.load.signal.intensities(signal_matrix = signal_intensities,
                          arraytype = array, method = "minfi",
                          filterNoCG = FALSE, filterXY = FALSE, filterBeads = FALSE,
                          SampleCutoff = 1.1, filterDetP = FALSE, detPcut = 1.1, 
                          filterSNPs = FALSE, samplesSubset = samples_to_process,
                          filterMultiHit = FALSE)

# Normalize using BMIQ
norm.beta <- champ.norm(beta = signal_int_load$beta, method = "BMIQ", arraytype = array, plotBMIQ = TRUE, resultsDir = "./CHAMP_Normalization/")

# Create dummy pheno only if needed
if (length(signal_int_load$pd) != ncol(signal_int_load$beta)) {
    sample_names <- colnames(signal_int_load$beta)
    dummy_pheno <- rep("Unknown", length(sample_names))
    names(dummy_pheno) <- sample_names
    message("WARNING: No phenotype data detected. Using dummy phenotype.")
} else {
    dummy_pheno <- signal_int_load$pd
}
# QC reports
champ.QC(beta = signal_int_load$beta, pheno = dummy_pheno, resultsDir = "./raw_data")
champ.QC(beta = norm.beta, pheno = dummy_pheno, resultsDir = "./normalised")

# Save outputs
Mvals_bmiq <- beta2m(norm.beta)
saveRDS(Mvals_bmiq, paste0("M_values_", suffix, ".rds"))
saveRDS(norm.beta, paste0("beta_values_", suffix, ".rds"))
saveRDS(signal_int_load$beta, paste0("beta_values_", parsed_args$dataset_name, ".rds"))

cat("Processing completed successfully!\n")