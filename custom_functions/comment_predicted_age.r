comment_predicted_age <- function(predictedAge, meanMethBySample, minMethBySample, maxMethBySample, selectCpGsClock, datClock0, noMissingPerSample){
    # Initialize comment: flag negative or extremely high predicted ages
    Comment <- ifelse (predictedAge <0, "Negative DNAm age.", ifelse ( predictedAge >100, "Old DNAm age.", rep("", length(predictedAge))))
    # Handle NA predicted ages
    Comment[is.na(predictedAge)] <- "Age prediction was not possible. "
    # Check if CpGs required for the clock are missing or duplicated
    if (sum(selectCpGsClock) < dim(datClock0)[[1]]-1) {
    Comment <- rep("ERROR: The CpGs listed in column 1 of the input data did not contain the CpGs needed for calculating DNAm age. Make sure to input cg numbers such as cg00075967.", length(predictedAge) )}
    if (sum(selectCpGsClock) > dim(datClock0)[[1]]-1) {
    Comment <- rep("ERROR: The CpGs listed in column 1 of the input data contain duplicate CpGs. Each row should report only one unique CpG marker (cg number).", length(predictedAge) )}
    # Flag samples with invalid beta ranges (<0 or >1)
    restSamples <- -minMethBySample>0.05 | maxMethBySample>1.05;
    restSamples[is.na(restSamples)] <- FALSE
    lab1 <- "MAJOR WARNING: Probably you did not input beta values since either minMethBySample<-0.05 or maxMethBySample>1.05."
    Comment[restSamples] <- paste(Comment[restSamples],lab1)
    # Warn about missing values
    restSamples <- noMissingPerSample >0 & noMissingPerSample <=100
    lab1 <- "WARNING: Some beta values were missing, see noMissingPerSample."
    Comment[restSamples] <- paste(Comment[restSamples],lab1)
    restSamples <- noMissingPerSample >3000
    lab1 <- "MAJOR WARNING: More than 3k missing values!!"
    Comment[restSamples] <- paste(Comment[restSamples],lab1)
    restSamples <- noMissingPerSample >100 & noMissingPerSample <=3000 
    lab1 <- "MAJOR WARNING: noMissingPerSample>100"
    Comment[restSamples] <- paste(Comment[restSamples],lab1)
    restSamples <- meanMethBySample>.35
    restSamples[is.na(restSamples)] <- FALSE
    # Warn if mean methylation values are outside the expected range
    lab1 <- "Warning: meanMethBySample is >0.35"
    Comment[restSamples] <- paste(Comment[restSamples],lab1)
    restSamples <- meanMethBySample<.25
    restSamples[is.na(restSamples)] <- FALSE
    lab1 <- "Warning: meanMethBySample is <0.25"
    Comment[restSamples] <- paste(Comment[restSamples],lab1)
    return(Comment)
}