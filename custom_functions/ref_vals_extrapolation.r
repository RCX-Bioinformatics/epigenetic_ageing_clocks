ref_vals_extrapolation <- function(beta_vals, ref_vals, epiclocks, suffix)
{
  n_samples <- ncol(beta_vals)
  original_probes <- rownames(beta_vals)

  log_df <- data.frame(Clock = character(),
                       Total_Probes = integer(),
                       Missing_Probes = integer(),
                       Missing_Percent = numeric(),
                       stringsAsFactors = FALSE)

  # Collect all probes needed by all clocks
  all_clock_probes <- unique(unlist(epiclocks))
  missing_probes <- setdiff(all_clock_probes, original_probes)

  # Check all missing probes are in ref_vals
  unavailable_probes <- setdiff(missing_probes, rownames(ref_vals))
  if (length(unavailable_probes) > 0) {
    stop(paste0("Missing probes not found in reference values: ",
                paste(head(unavailable_probes), collapse = ", "),
                if (length(unavailable_probes) > 5) ", ..." else ""))
  }

  # Create missing probe matrix from ref_vals
  if (length(missing_probes) > 0) {
    missing_vals <- ref_vals[missing_probes, , drop = FALSE]
    missing_matrix <- matrix(rep(missing_vals[, 1], times = n_samples),
                             nrow = length(missing_probes),
                             ncol = n_samples,
                             dimnames = list(missing_probes, colnames(beta_vals)))
    full_matrix <- rbind(beta_vals, missing_matrix)
  } else {
    full_matrix <- beta_vals
  }

  # Prepare log for each clock
  for (clock_name in names(epiclocks)) {
    clock_probes <- epiclocks[[clock_name]]
    total_probes <- length(clock_probes)
    n_missing <- sum(!(clock_probes %in% original_probes))
    percent_missing <- (n_missing / total_probes) * 100
    log_df <- rbind(log_df, data.frame(Clock = clock_name,
                                       Total_Probes = total_probes,
                                       Missing_Probes = n_missing,
                                       Missing_Percent = round(percent_missing, 2),
                                       stringsAsFactors = FALSE))
  }

  log_file <- paste0("epiclock_probes_summary_", suffix, ".log")
  write.table(log_df, file = log_file, sep = "\t", row.names = FALSE, quote = FALSE)

  return(full_matrix)
}