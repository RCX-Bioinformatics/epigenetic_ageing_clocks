generate_gs_reference_values <- function(folder_path) {
  # List all .rds files
  rds_files <- list.files(folder_path, pattern = "\\.rds$", full.names = TRUE)

  # Read all matrices and convert to data frames with rownames as a column
  data_list <- lapply(rds_files, function(file) {
    mat <- readRDS(file)
    if (!is.matrix(mat) && !is.data.frame(mat)) {
      warning("Skipping file (not a matrix/data.frame): ", file)
      return(NULL)
    }
    df <- as.data.frame(mat)
    df$probe <- rownames(df)
    return(df)
  })

  # Remove any NULLs
  data_list <- data_list[!sapply(data_list, is.null)]

  # Merge all data frames by probe (full outer join)
  merged <- Reduce(function(x, y) merge(x, y, by = "probe", all = TRUE), data_list)

  # Set probe as rownames and drop the probe column
  rownames(merged) <- merged$probe
  merged$probe <- NULL

  # Compute rowMeans across all samples (ignoring NA)
  mean_beta <- rowMeans(merged, na.rm = TRUE)

  # Return as single-column matrix
  result <- matrix(mean_beta, ncol = 1)
  rownames(result) <- names(mean_beta)
  colnames(result) <- "refeence_value"

  return(result)
}