# Script to create reference values from gold standard datasets

source("custom_functions/parse_named_args.r")
source("custom_functions/generate_gs_reference_values.r")
args <- commandArgs(trailingOnly = TRUE)
parsed_args <- type.convert.args(args)

cat("Usage: Rscript gs_ref_vals.R dataset_name=my_dataset output_dir=/my/output/dir/\n\n")
  cat("Note:\n")
  cat(" - Folder 'available_beta_vals/' must exist and contain beta_values_*.rds files.\n")
  cat(" - Each RDS file must contain a matrix or data frame with probes in rows and samples in columns.\n")

output_dir <- ifelse(!is.null(parsed_args$output_dir), parsed_args$output_dir, getwd())
# Define output suffix
available_files <- list.files("available_beta_vals", full.names = T)
base_names <- gsub("^available_beta_vals/beta_values_(.*)\\.rds$", "\\1", available_files)
# Check which files have _BMIQ before .rds
has_BMIQ <- grepl("_BMIQ$", base_names)
# Error if not all or none have _BMIQ
if (!all(has_BMIQ) && any(has_BMIQ)) {
  stop("Inconsistent BMIQ suffix: some files have '_BMIQ' and others do not.")
}
base_names <- gsub("_BMIQ$", "", base_names)  # remove _BMIQ if present
# Collapse to single suffix
inputs_suffix <- paste(base_names, collapse = "_")
# Append _BMIQ if all files had it
if (all(has_BMIQ)) {
  inputs_suffix <- paste0(inputs_suffix, "_BMIQ")
}
suffix <- paste0(parsed_args$dataset_name, "_" ,inputs_suffix)

gold_standard <- generate_gs_reference_values("available_beta_vals")

# Ensure top-level output_dir exists and set working directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
setwd(output_dir)
# Save outputs
saveRDS(gold_standard, paste0("ref_vals_", suffix, ".rds"))
cat("Reference values from gold standard datasets created successfully!\n")