align_meth_pheno <- function(datMeth, pheno) {

    common_ids <- intersect(rownames(datMeth), pheno$SampleID)
    missing_in_pheno <- setdiff(rownames(datMeth), pheno$SampleID)
    missing_in_meth  <- setdiff(pheno$SampleID, rownames(datMeth))

    # Message for samples missing phenotype data
    if (length(missing_in_pheno) > 0) {
    message("The following samples do NOT have phenotype data and will be removed:")
    message(paste(missing_in_pheno, collapse = ", "))
    }
    # Message for phenotype samples missing methylation data
    if (length(missing_in_meth) > 0) {
    message("The following phenotype samples do NOT have methylation data and will be removed:")
    message(paste(missing_in_meth, collapse = ", "))
    }
    # Stop if no overlap
    if (length(common_ids) == 0) {
    stop("No overlapping Sample IDs between rownames(datMeth) and pheno$SampleID.")
    }
    datMeth  <- datMeth[common_ids, , drop = FALSE]
    datPheno <- pheno[match(common_ids, pheno$SampleID), , drop = FALSE]
    # Final alignment check
    if (!all(rownames(datMeth) == datPheno$SampleID)) {
    stop("Sample alignment failed: rownames(datMeth) do not match datPheno$SampleID.")
    }
    return(list(datMeth = datMeth, datPheno = datPheno))
}