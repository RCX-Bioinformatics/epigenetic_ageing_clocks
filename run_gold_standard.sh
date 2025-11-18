#!/usr/bin/env bash

set -e
set -o pipefail

# -----------------------------
# CONFIG
# -----------------------------
CONFIG="/$HOME/epigenetic_ageing_clocks/config/gold_standard_config.yaml"

# Read top-level workdir from YAML
WORKDIR=$(yq e '.paths.workdir' "$CONFIG")
SING_IMAGE="$WORKDIR/singularity/champ/champ.sif"
RESULTS_DIR="$WORKDIR/GS_results"
DATASET_OUTPUTS="$RESULTS_DIR/GS_preprocessing"
AVAILABLE_BETA="$WORKDIR/available_beta_vals"

# Create necessary folders
mkdir -p "$DATASET_OUTPUTS"
mkdir -p "$AVAILABLE_BETA"


# -------------------------------------
# Run preprocessing of methylation data
# -------------------------------------
run_preprocessing=$(yq e '.workflow.run_preprocessing' "$CONFIG")

if [ "$run_preprocessing" = "true" ]; then
    echo "=============================================="
    echo " Preprocessing methylation data for GS dataset"
    echo "=============================================="

    # -----------------------------
    # Loop over datasets
    # -----------------------------
    dataset_count=$(yq e '.datasets | length' "$CONFIG")
    if [[ "$dataset_count" -eq 0 ]]; then
        echo "No datasets found in $CONFIG"
    else
        for i in $(seq 0 $((dataset_count - 1))); do
            name=$(yq e ".datasets[$i].name // \"\"" "$CONFIG")
            input_type=$(yq e ".datasets[$i].input_type // \"\"" "$CONFIG")
            array_type=$(yq e ".datasets[$i].array_type // \"\"" "$CONFIG")
            idat_dir=$(yq e ".datasets[$i].idat_dir // \"\"" "$CONFIG")
            signal_file=$(yq e ".datasets[$i].signal_file // \"\"" "$CONFIG")
            samples_to_process=$(yq e ".datasets[$i].samples_to_process // \"\"" "$CONFIG")

            if [[ -z "$name" ]]; then
                echo "Skipping dataset at index $i (no name found)."
                continue
            fi

            echo "----------------------------------------"
            echo "Processing dataset: $name ($input_type)"
            DATASET_DIR="$DATASET_OUTPUTS/$name"
            DONE_FILE="$DATASET_DIR/.done"
            mkdir -p "$DATASET_DIR"

            if [[ -f "$DONE_FILE" ]]; then
                echo "Dataset '$name' already processed. Skipping."
                continue
            fi

            # Run processing depending on type
            if [[ "$input_type" == "idat" ]]; then
                echo "Running IDAT preprocessing..."

                singularity exec "$SING_IMAGE" Rscript "$WORKDIR/scripts/gold_standard/champ_preprocessing_GS_idats.R" \
                    dataset_name="$name" \
                    idat_dir="$idat_dir" \
                    arraytype="$array_type" \
                    output_dir="$DATASET_DIR"

            elif [[ "$input_type" == "signal_intensity" ]]; then
                echo "Running signal intensities preprocessing..."

                singularity exec "$SING_IMAGE" Rscript "$WORKDIR/scripts/gold_standard/champ_preprocessing_GS_signal_intensities.R" \
                    dataset_name="$name" \
                    input_file="$signal_file" \
                    samples_to_process="$samples_to_process" \
                    arraytype="$array_type" \
                    output_dir="$DATASET_DIR"

            else
                echo "Unknown input_type '$input_type' for dataset $name. Skipping."
                continue
            fi

            touch "$DONE_FILE"
            echo "Dataset '$name' successfully processed."
        done
    fi
else
    echo "Skipping preprocessing workflow"
fi


# -----------------------------
# Run GS dataset creation
# -----------------------------
run_ref=$(yq e '.workflow.run_reference_creation' "$CONFIG")
if [[ "$run_ref" == "true" ]]; then
    echo "================================="
    echo " Generating gold standard dataset"
    echo "================================="

    echo "----------------------------------------"
    echo " Collecting BMIQ beta values"
    echo "----------------------------------------"

    # Copy ONLY BMIQ-normalized beta values from dataset outputs
    find "$DATASET_OUTPUTS" -type f -name "beta_values_*_BMIQ.rds" | while read file; do
        echo "Copying: $file → $AVAILABLE_BETA/"
        cp "$file" "$AVAILABLE_BETA/"
    done

    singularity exec "$SING_IMAGE" Rscript $WORKDIR/scripts/gold_standard/gs_ref_vals.R \
        dataset_name="buccal" \
        output_dir="$RESULTS_DIR"
    rm $AVAILABLE_BETA/*

    echo "----------------------------------------"
    echo " Collecting RAW beta values"
    echo "----------------------------------------"
    # Copy ONLY raw beta values from dataset outputs
    find "$DATASET_OUTPUTS" -type f -name "beta_values_*.rds" ! -name "*_BMIQ.rds" | while read file; do
        echo "Copying: $file → $AVAILABLE_BETA/"
        cp "$file" "$AVAILABLE_BETA/"
    done

    singularity exec "$SING_IMAGE" Rscript $WORKDIR/scripts/gold_standard/gs_ref_vals.R \
        dataset_name="buccal" \
        output_dir="$RESULTS_DIR"
    rm $AVAILABLE_BETA/*
fi

rm -r $AVAILABLE_BETA

echo "----------------------------------------"
echo "All datasets processed. Results saved in $RESULTS_DIR"