dnamage_input_check <- function(dat0, nSamples, nProbes, DoNotProceed, logfile, probeAnnotation27k, probeAnnotation21kdatMethUsed){
    # Error: No samples detected
    if (nSamples==0) {DoNotProceed=TRUE; cat(paste( "\n ERROR: There must be a data input error since there seem to be no samples.\n Make sure that you input a comma delimited file (.csv file)\n that can be read using the R command read.csv.sql . Samples correspond to columns in that file  ."), file=logfile, append=TRUE)}
    # Error: No probes detected
    if (nProbes==0) {DoNotProceed=TRUE; cat(paste( "\n ERROR: There must be a data input error since there seem to be zero probes.\n Make sure that you input a comma delimited file (.csv file)\n that can be read using the R command read.csv.sql  CpGs correspond to rows."), file=logfile, append=TRUE)}
    # Warning: More samples than probes (likely transposed matrix)
    if (nSamples > nProbes) {cat(paste( "\n MAJOR WARNING: It worries me a lot that there are more samples than CpG probes.\n Make sure that probes correspond to rows and samples to columns.\n I wonder whether you want to first transpose the data and then resubmit them? In any event, I will proceed with the analysis."), file=logfile, append=TRUE)}
    # Error: First column (probe IDs) is numeric - likely wrong input format
    if (is.numeric(dat0[,1])) {DoNotProceed=TRUE; cat(paste( "\n Error: The first column does not seem to contain probe identifiers (cg numbers from Illumina) since these entries are numeric values. Make sure that the first column of the file contains probe identifiers such as cg00000292. Instead it contains ", dat0[1:3,1]), file=logfile, append=TRUE)}
    # Warning: First column is not character - still suspicious format
    if (!is.character(dat0[,1])) { cat(paste( "\n Major Warning: The first column does not seem to contain probe identifiers (cg numbers from Illumina) since these entries are numeric values. Make sure that the first column of the file contains CpG probe identifiers such as cg00000292. Instead it contains ", dat0[1:3,1]), file=logfile, append=TRUE)}
    # Continue checks only if no critical issue so far
    if (!DoNotProceed){
        # Check for non-numeric columns (excluding the first, which is ProbeID)
        nonNumericColumn <- rep(FALSE, dim(dat0)[[2]]-1)
        for (i in 2:dim(dat0)[[2]]) {nonNumericColumn[i-1]=! is.numeric(dat0[,i]) }
        # Warn if non-numeric beta values are found
        if (sum(nonNumericColumn) >0) {cat(paste( "\n MAJOR WARNING: Possible input error. The following samples contain non-numeric beta values: ", colnames(dat0)[-1][ nonNumericColumn], "\n Hint: Maybe you use the wrong symbols for missing data. Make sure to code missing values as NA in the Excel file. To proceed, I will force the entries into numeric values but make sure this makes sense.\n" ), file=logfile, append=TRUE)}
        # Extract X chromosomal probes
        XchromosomalCpGs <- as.character(probeAnnotation27k$Name[probeAnnotation27k$Chr=="X"])
        selectXchromosome <- is.element(dat0[,1], XchromosomalCpGs)
        selectXchromosome[is.na(selectXchromosome)] <- FALSE
        # Compute mean methylation for X chromosome probes per sample (only if enough probes found)
        meanXchromosome <- rep(NA, dim(dat0)[[2]]-1)
        if (sum(selectXchromosome) >=500) {
            meanXchromosome <- apply( as.matrix(dat0[selectXchromosome,-1]),2,FUN=function(x) mean(as.numeric(x),na.rm=TRUE))
        }
        # Warn if many missing values for X chromosomal probes
        if (sum(is.na(meanXchromosome)) >0) { 
            cat(paste( "\n \n Comment: There are lots of missing values for X chromosomal probes for some of the samples. This is not a problem when it comes to estimating age but I cannot predict the gender of these samples.\n " ), file=logfile, append=TRUE)
        }
        # Check that all required 21k CpGs are present in input
        match1 <- match(probeAnnotation21kdatMethUsed$Name , dat0[,1])
        if (sum(is.na(match1))>0) { 
            missingProbes <- probeAnnotation21kdatMethUsed$Name[!is.element( probeAnnotation21kdatMethUsed$Name , dat0[,1])]    
            DoNotProceed <- TRUE
            cat(paste( "\n \n Input error: You forgot to include the following ", length(missingProbes), " CpG probes (or probe names):\n ", paste( missingProbes, sep="",collapse=", ")), file=logfile, append=TRUE)
        }
    }
    # Reorder or subset the data so rows match the required 21k probes
    match1 <- match(probeAnnotation21kdatMethUsed$Name , dat0[,1])
    if (sum(is.na(match1))>0) paste(sum(is.na(match1)), "CpG probes cannot be matched in each sample.")
    dat1 <- dat0[match1,]
    return(list(betas = dat1, mean_X_chromosome = meanXchromosome))
}

dnamage_input_prep <- function(betas, logfile, probeAnnotation27k, probeAnnotation21kdatMethUsed){
    # Convert beta matrix into a data frame with probe IDs as the first column
    data <- data.frame(cbind(rownames(betas),betas),row.names = c(),stringsAsFactors = FALSE)
    # Convert all columns except the first (ProbeID) to numeric
    for(i in c(2:ncol(data)))
    {
        data[,i] <- as.numeric(as.character(data[,i]))
    }
    # Rename first two columns (for consistency with expected input format)
    colnames(data)[1:2] <- c("ProbeID","V1")
    # Calculate the number of samples (columns) and probes (rows)
    n_samples <- dim(data)[[2]]-1
    n_probes <- dim(data)[[1]]
    cat(paste( "The methylation data set contains", n_samples, "samples (e.g. arrays) and ", n_probes, " probes."), file=logfile)
    # Clean up any quotation marks in the ProbeID column (common artifact from CSV reading)
    data[,1] <- gsub(x=data [,1],pattern="\"",replacement="")
    do_not_proceed <- FALSE
    # Perform input validation and compatibility checks
    data_checked <- dnamage_input_check(dat0 = data,
                                        nSamples = n_samples,
                                        nProbes = n_probes,
                                        DoNotProceed = do_not_proceed,
                                        logfile = logfile,
                                        probeAnnotation27k = probeAnnotation27k,
                                        probeAnnotation21kdatMethUsed = probeAnnotation21kdatMethUsed)
    return(data_checked)
}