dnamage_estimate <- function(dat1, normalizeData=TRUE, probeAnnotation21kdatMethUsed, logfile, meanXchromosome, datClock){
    set.seed(1)
    nSamples = ncol(dat1)
    fastImputation <- FALSE

    # --------------------------------------
    # INPUT STRUCTURE: dat1 should have CpGs as rows, first column = CpG ID, other columns = samples
    # --------------------------------------

    #STEP 1: DEFINE QUALITY METRICS
    meanMethBySample <- as.numeric(apply(as.matrix(dat1[,-1]),2,mean,na.rm=TRUE))
    minMethBySample <- as.numeric(apply(as.matrix(dat1[,-1]),2,min,na.rm=TRUE))
    maxMethBySample  <- as.numeric(apply(as.matrix(dat1[,-1]),2,max,na.rm=TRUE))
    
    datMethUsed <- t(dat1[,-1])
    colnames(datMethUsed) <- as.character(dat1[,1])
    # Count missing values per sample
    noMissingPerSample <- apply(as.matrix(is.na(datMethUsed)),1,sum)
    table(noMissingPerSample)

    #STEP 2: Imputing 
    # Use kNN imputation if fewer than 3000 missing per sample and more than 1 sample
    if (!fastImputation & nSamples>1 & max(noMissingPerSample,na.rm=TRUE)<3000){
        if (max(noMissingPerSample,na.rm=TRUE)>0 ){
            dimnames1 <- dimnames(datMethUsed)
            datMethUsed <- data.frame(t(impute.knn(t(datMethUsed))$data))
            dimnames(datMethUsed) <- dimnames1
        } # end of if
    } # end of if (!fastImputation)

    # Fallback: use "fast" imputation logic if too many missing values or only 1 sample
    if (max(noMissingPerSample,na.rm=TRUE)>=3000){fastImputation <- TRUE}

    if (fastImputation | nSamples==1){
        noMissingPerSample <- apply(as.matrix(is.na(datMethUsed)),1,sum)
        table(noMissingPerSample)
        # Skip normalization if too many missing values
        if (max(noMissingPerSample,na.rm=TRUE)>0 & max(noMissingPerSample,na.rm=TRUE) >= 3000){normalizeData=FALSE}
        # Fill in missing values from goldstandard if < 3000 missing
        if (max(noMissingPerSample,na.rm=TRUE)>0 & max(noMissingPerSample,na.rm=TRUE) < 3000){
            dimnames1 <- dimnames(datMethUsed)
            for (i in which(noMissingPerSample>0) ){
                selectMissing1 <- is.na(datMethUsed[i,])
                datMethUsed[i,selectMissing1] <- as.numeric(probeAnnotation21kdatMethUsed$goldstandard2[selectMissing1])
            } # end of for loop
            dimnames(datMethUsed) <- dimnames1
        } # end of if
    } # end of if (fastImputation)

    # STEP 3: Data normalization (each sample requires about 8 seconds). It would be straightforward to parallelize this operation.
    if (normalizeData){
        datMethUsedNormalized <- BMIQcalibration(datM=datMethUsed, goldstandard.beta= probeAnnotation21kdatMethUsed$goldstandard2, plots=FALSE)
    }
    if (!normalizeData){datMethUsedNormalized = datMethUsed}
    # Free memory
    rm(datMethUsed)
    gc()

    #STEP 4: Predict age and create a data frame for the output (referred to as datout)
    # Identify CpGs used in the Horvath clock
    selectCpGsClock <- is.element(dimnames(datMethUsedNormalized)[[2]], as.character(datClock$CpGmarker[-1]))
    # Check for missing or duplicated CpGs in clock input
    if (sum(selectCpGsClock) < dim(datClock)[[1]]-1){print("The CpGs listed in column 1 of the input data did not contain the CpGs needed for calculating DNAm age. Make sure to input cg numbers such as cg00075967.")}
    print(paste(length(setdiff(datClock$CpGmarker[-1],colnames(datMethUsedNormalized))),"probes are missing from 353",sep=" "))
    if (sum(selectCpGsClock) > dim(datClock)[[1]]-1){stop("ERROR: The CpGs listed in column 1 of the input data contain duplicate CpGs. Each row should report only one unique CpG marker (cg number).")}
    # Predict age for multiple samples
    if (nSamples>1){
        ptch <- intersect(colnames(datMethUsedNormalized),datClock$CpGmarker)
        datMethClock0 <- data.frame(datMethUsedNormalized[,ptch])
        datClock0 <- datClock[c(1,match(ptch,datClock$CpGmarker)),]
        predictedAge <- as.numeric(anti.trafo(datClock0$CoefficientTraining[1]+as.matrix(datMethClock0)%*% as.numeric(datClock0$CoefficientTraining[-1])))
    } # end of if

    # Predict age for a single sample (requires duplicating input to run matrix operations)
    if (nSamples==1) {
        datMethUsedNormalized2 <- data.frame(rbind(datMethUsedNormalized,datMethUsedNormalized))
        datMethClock0 <- data.frame(datMethUsedNormalized2[,selectCpGsClock])
        ptch <- intersect(as.character(datClock$CpGmarker[-1]),colnames(datMethClock0))
        # datMethClock <- data.frame(datMethClock0[,as.character(datClock$CpGmarker[-1])])
        datMethClock <- data.frame(datMethClock0[,ptch])
        dim(datMethClock)
        sub_probes <- intersect(datClock$CpGmarker,colnames(datMethClock))
        datClock_sub <- datClock[c(1,match(sub_probes,datClock$CpGmarker)),]
        datClock$CoefficientTraining[1]+as.matrix(datMethClock) %*% as.numeric(datClock_sub$CoefficientTraining[-1])
        predictedAge <- as.numeric(anti.trafo(datClock$CoefficientTraining[1]+as.matrix(datMethClock) %*% as.numeric(datClock_sub$CoefficientTraining[-1])))
        # predictedAge_one <- predictedAge[1]
    } # end of if

    # STEP 5: Add quality and diagnostic comments
    comment <- comment_predicted_age(predictedAge, 
                                    meanMethBySample, 
                                    minMethBySample, 
                                    maxMethBySample,
                                    selectCpGsClock, 
                                    datClock0, 
                                    noMissingPerSample)
    # Assemble final output dataframe
    datout <- data.frame(SampleID=colnames(dat1)[-1],
                        DNAmAge=predictedAge,
                        comment,
                        noMissingPerSample,
                        meanMethBySample,
                        minMethBySample,
                        maxMethBySample)
    # STEP 6: Predict gender using X-chromosome methylation
    if (!is.null(meanXchromosome)){  
        if (length(meanXchromosome)==dim(datout)[[1]]){
        predictedGender <- ifelse(meanXchromosome>.4, "female", ifelse(meanXchromosome<.38,"male","Unsure"))
        datout <- data.frame(datout, predictedGender=predictedGender, meanXchromosome=meanXchromosome)
        } # end of if 
    } # end of if
    # STEP 7: Log summary messages
    if (sum(datout$Comment != "") ==0){cat(paste( "\n The individual samples appear to be fine. "), file=logfile, append=TRUE)} 
    if (sum(datout$Comment != "") >0){cat(paste( "\n Warnings were generated for the following samples.\n", datout[,1][datout$Comment != ""], "\n Hint: Check the output file for more details."), file=logfile, append=TRUE)} 
    return(datout)
}