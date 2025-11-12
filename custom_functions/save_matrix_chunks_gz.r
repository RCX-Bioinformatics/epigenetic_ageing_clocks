# Function to save matrix into gzipped csv chunks
save_matrix_chunks_gz <- function(matrix_data, chunk_size = 20, output_dir = ".", file_prefix = "matrix_chunk") {
  # Ensure the output directory exists
  if (!dir.exists(output_dir)) {
    dir.create(output_dir)
  }
  
  # Determine the number of chunks based on the number of columns
  num_chunks <- ceiling(ncol(matrix_data) / chunk_size)
  
  # Iterate over the number of chunks
  for (i in 1:num_chunks) {
    # Determine the range of columns for this chunk
    start_col <- (i - 1) * chunk_size + 1
    end_col <- min(i * chunk_size, ncol(matrix_data))
    
    # Extract the chunk of the matrix
    chunk <- matrix_data[, start_col:end_col, drop = FALSE]  # Ensure it's a data frame/matrix
    
    # Create the filename for this chunk using the custom prefix
    file_name <- file.path(output_dir, paste0(file_prefix, "_", i, ".csv.gz"))
    
    # Write the chunk to a gzipped CSV file with tab separator, preserving row and column names
    fwrite(chunk, file = file_name, sep = "\t", row.names = TRUE, col.names = TRUE)
    
    cat("Saved chunk ", i, " to ", file_name, "\n")  # Optional: print progress
  }
}