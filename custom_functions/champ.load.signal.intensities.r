champ.load.signal.intensities <- function(signal_matrix, methValue = "B", detPcut = 0.01, method = "minfi",
                                     SampleCutoff = 0.1, ProbeCutoff = 0.0, filterDetP = TRUE,
                                     autoimpute = TRUE, filterBeads = FALSE, beadCutoff = 0.05,
                                     filterNoCG = TRUE, filterSNPs = TRUE, population = NULL,
                                     filterMultiHit = TRUE, filterXY = TRUE, arraytype = "450K",
                                     samplesSubset = NA) {

  message("\n[ Loading Data from Signal Intensity Matrix ]")
  message("----------------------------------------------")
  
  if(method=="minfi")
  {
    message("\n[ Loading Data with Minfi Method ]")
    message("----------------------------------")
    
    # Extract sample names
    col_names <- colnames(signal_matrix)
    samples <- unique(gsub("\\.(Signal_A|Signal_B|Detection.Pval)", "", col_names))
    
    # Extract matrices
    SignalA <- as.matrix(signal_matrix[, grep("Signal_A", col_names)])
    SignalB <- as.matrix(signal_matrix[, grep("Signal_B", col_names)])
    detP <- as.matrix(signal_matrix[, grep("Detection.Pval", col_names)])
    colnames(SignalA) <- samples
    colnames(SignalB) <- samples
    colnames(detP) <- samples
    
    # Create MethylSet
    mset <- MethylSet(Meth = SignalA, Unmeth = SignalB)
    if (arraytype == "450K") {
      annotation(mset) <- c(array = "IlluminaHumanMethylation450k", annotation = "ilmn12.hg19")
    } else if (arraytype == "EPIC") {
      annotation(mset) <- c(array = "IlluminaHumanMethylationEPIC", annotation = "ilm10b4.hg19")
    } else {
      stop("Unsupported array type. Please specify either '450K' or 'EPIC'.")
    }
    
    # Select subset of samples if requred
    if(!(length(samplesSubset) == 1 && is.na(samplesSubset))){
      mset <- mset[, samplesSubset]
      detP <- detP[, samplesSubset, drop = FALSE]
    }
    pd <- pData(mset)

    message("<< Read DataSet Success. >>\n")
    
    if(methValue=="B") tmp = getBeta(mset, "Illumina") else tmp = getM(mset)
    tmp[detP >= detPcut] <- NA
    message("The fraction of failed positions per sample\n 
            (You may need to delete samples with high proportion of failed probes\n): ")
    
    numfail <- matrix(colMeans(is.na(tmp)))
    rownames(numfail) <- colnames(detP)
    colnames(numfail) <- "Failed CpG Fraction."
    print(numfail)
    RemainSample <- which(numfail < SampleCutoff)
    
    if(any(numfail >= SampleCutoff)){
      message("The detSamplecut parameter is : ",SampleCutoff, "\nSamples : ",
              paste(rownames(numfail)[which(numfail >= SampleCutoff)],collapse=",")," will be deleted.\n",
              "There are ",length(RemainSample)," samples left for analysis.\n")
    }
    
    detP <- detP[,RemainSample, drop = FALSE]
    mset <- mset[,RemainSample]
    pd <- pd[RemainSample, , drop = FALSE]
    tmp <- tmp[,RemainSample, drop = FALSE]
    
    if(filterDetP)
    {
      mset.f = mset[rowSums(is.na(tmp)) <= ProbeCutoff*ncol(detP),]
      
      if(ProbeCutoff==0)
      {
        message("Filtering probes with a detection p-value above ",detPcut," in one or more samples has removed ",dim(mset)[1]-dim(mset.f)[1]," probes from the analysis. If a large number of probes have been removed, ChAMP suggests you to identify potentially bad samples.")
      }else{
        message("Filtering probes with a detection p-value above ",detPcut," in at least ",ProbeCutoff*100,"% of samples has removed ",dim(mset)[1]-dim(mset.f)[1]," probes from the analysis. If a large number of probes have been removed, ChAMP suggests you look at the failedSample file to identify potentially bad samples.")
      }
      mset=mset.f
      tmp <- tmp[rowSums(is.na(tmp)) <= ProbeCutoff*ncol(detP),]
      message("<< Filter DetP Done. >>\n")
    }
    
    if(sum(is.na(tmp))==0){
      message("\nThere is no NA values in your matrix, there is no need to imputation.\n")
    }else
    {
      message("\nThere are ",sum(is.na(tmp))," NA remain in filtered Data Set. Impute can be done for remain NAs, but not suitable for small number samples. For small Data Set (like only 20 samples), we suggest you set parameter ProbeCutoff as 0 in champ.load() here, which would remove all NA involved probe no matter how many samples of those probes are NA.\n")
    }
    
    if(autoimpute & sum(is.na(tmp)) > 0){
      message("Impute will be conducted here for remain ",sum(is.na(tmp)),"  NAs. Note that if you don't do this, NA values would be kept in your data set. You may use champ.impute() function to do more complex imputation as well.")
      # Open a file to send messages to save lot's of information from impute.knn
      message("\nImpute function is working now, it may need couple minutes...")
      zz <- file("ImputeMessage.Rout", open="wt")
      sink(zz)
      sink(zz, type="message")
      tmp <- impute.knn(tmp,k=5)$data
      sink(type="message")
      sink()
      message("<< Imputation Done. >>\n")
    }
    
    if(filterBeads)
    {
      message("Error: 'champ.load.signal.intensities' cannot be used with filterBeads = TRUE. Signal intensity matrix does NOT contain bead count information.")
    }
    
    if(filterNoCG)
    {
      mset.f2=dropMethylationLoci(mset,dropCH=T)
      tmp <- tmp[rownames(tmp) %in% featureNames(mset.f2),]
      message("Filtering non-cg probes, has removed ",dim(mset)[1]-dim(mset.f2)[1]," from the analysis.")
      mset <- mset.f2
      message("<< Filter NoCG Done. >>\n")
    }
    
    if(filterSNPs)
    {
      if(arraytype=="450K")
      {
        if(is.null(population))
        {
          message("Using general 450K SNP list for filtering.")
          data(hm450.manifest.hg19)
          maskname <- rownames(hm450.manifest.hg19)[which(hm450.manifest.hg19$MASK_general==TRUE)]
        }else if(!population %in% c("AFR","EAS","EUR","SAS","AMR","GWD","YRI","TSI",
                                    "IBS","CHS","PUR","JPT","GIH","CHB","STU","ITU",
                                    "LWK","KHV","FIN","ESN","CEU","PJL","ACB","CLM",
                                    "CDX","GBR","BEB","PEL","MSL","MXL","ASW"))
        {
          message("Using general 450K SNP list for filtering.")
          data(hm450.manifest.hg19)
          maskname <- rownames(hm450.manifest.hg19)[which(hm450.manifest.hg19$MASK_general==TRUE)]
        }else
        {
          message("Using ",population," specific 450K SNP list for filtering.")
          data(hm450.manifest.pop.hg19)
          maskname <- rownames(hm450.manifest.pop.hg19)[which(hm450.manifest.pop.hg19[,paste("MASK_general_",population,sep="")]==TRUE)]
        }
      }else if(arraytype == "EPIC")
      {
        if(is.null(population))
        {
          message("Using general EPIC SNP list for filtering.")
          data(EPIC.manifest.hg19)
          maskname <- rownames(EPIC.manifest.hg19)[which(EPIC.manifest.hg19$MASK_general==TRUE)]
        }else if(!population %in% c("AFR","EAS","EUR","SAS","AMR","GWD","YRI","TSI",
                                    "IBS","CHS","PUR","JPT","GIH","CHB","STU","ITU",
                                    "LWK","KHV","FIN","ESN","CEU","PJL","ACB","CLM",
                                    "CDX","GBR","BEB","PEL","MSL","MXL","ASW"))
        {
          message("Using general EPIC SNP list for filtering.")
          data(EPIC.manifest.hg19)
          maskname <- rownames(EPIC.manifest.hg19)[which(EPIC.manifest.hg19$MASK_general==TRUE)]
        }else
        {
          message("Using ",population," specific EPIC SNP list for filtering.")
          data(EPIC.manifest.pop.hg19)
          maskname <- rownames(EPIC.manifest.pop.hg19)[which(EPIC.manifest.pop.hg19[,paste("MASK_general_",population,sep="")]==TRUE)]
        }
      } else if(arraytype == "Mouse") {
        message("Sorry, currently SNP filtering does not support mouse.")
      }
      mset.f2=mset[!featureNames(mset) %in% maskname,]
      tmp <- tmp[!rownames(tmp) %in% maskname,]
      message("Filtering probes with SNPs as identified in Zhou's Nucleic Acids Research Paper, 2016, has removed ",dim(mset)[1]-dim(mset.f2)[1]," from the analysis.")
      mset=mset.f2
      message("<< Filter SNP Done. >>\n")
    }
    
    if(filterMultiHit)
    {
      data(multi.hit)
      mset.f2=mset[!featureNames(mset) %in% multi.hit$TargetID,]
      tmp <- tmp[!rownames(tmp) %in% multi.hit$TargetID,]
      message("Filtering probes that align to multiple locations as identified in Nordlund et al, has removed ",dim(mset)[1]-dim(mset.f2)[1]," from the analysis.")
      mset=mset.f2
      message("<< Filter MultiHit Done. >>\n")
    }
    
    if(filterXY)
    {
      if(arraytype=="EPIC") { 
        data(probe.features.epic) 
      } else if (arraytype == "450K") {
        data(probe.features)
      } else if (arraytype == "Mouse") {
        data(probe.features.mouse)
      } else {
        stop("ArrayType parameter is wrong, it must be 450K, EPIC or Mouse.")
      }
      
      autosomes=probe.features[!probe.features$CHR %in% c("X","Y"), ]
      mset.f2=mset[featureNames(mset) %in% row.names(autosomes),]
      tmp <- tmp[rownames(tmp) %in% row.names(autosomes),]
      message("Filtering probes on the X or Y chromosome has removed ",dim(mset)[1]-dim(mset.f2)[1]," from the analysis.")
      mset=mset.f2
      message("<< Filter XY chromosome Done. >>\n")
    }
    
    
    message(paste(if(methValue=="B") "[Beta" else "[M","value is selected as output.]\n"))
    beta.raw <- tmp
    
    intensity <-  minfi::getMeth(mset) + minfi::getUnmeth(mset)
    detP <- detP[which(row.names(detP) %in% row.names(beta.raw)),]
    
    if(min(beta.raw, na.rm=TRUE)<=0) beta.raw[beta.raw<=0] <- min(beta.raw[beta.raw > 0])
    message("Zeros in your dataset have been replaced with smallest positive value.\n")
    
    if(max(beta.raw, na.rm=TRUE)>=0) beta.raw[beta.raw>=1] <- max(beta.raw[beta.raw < 1])
    message("One in your dataset have been replaced with largest value below 1.\n")
    
    message("The analysis will be proceed with ", dim(beta.raw)[1], " probes and ",dim(beta.raw)[2], " samples.\n")
    message("Current Data Set contains ",sum(is.na(beta.raw))," NA in ", if(methValue=="B") "[Beta]" else "[M]"," Matrix.\n")
    
    message("[<<<<< ChAMP.LOAD.SIGNAL.MATRIX END >>>>>>]")
    message("[===========================]")
    return(list(mset = mset, pd = pd, intensity = intensity, beta = beta.raw, detP = detP))
  } else {
    message("Error: 'champ.load.signal.intensities' only supports method = 'minfi'.")
  }
}