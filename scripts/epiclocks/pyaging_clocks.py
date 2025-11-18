import argparse
import pandas as pd
import pyaging as pya
import sys
import os

def str2bool(value):
    if isinstance(value, bool):
        return value
    if value.lower() in ('true', 't', 'yes', '1'):
        return True
    elif value.lower() in ('false', 'f', 'no', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError("epicv2 must be 'true' or 'false'.")

# Define allowed clocks
ALLOWED_CLOCKS = ['AltumAge', 'DunedinPACE']

def validate_clocks(clock_input):
    clock_list = [clock.strip() for clock in clock_input.split(",")]
    invalid_clocks = [c for c in clock_list if c not in ALLOWED_CLOCKS]
    if invalid_clocks:
        print(f"Error: Invalid clock(s): {', '.join(invalid_clocks)}")
        print(f"Allowed clocks are: {', '.join(ALLOWED_CLOCKS)}")
        sys.exit(1)
    return clock_list

def main():
    parser = argparse.ArgumentParser(
        description="Predict epigenetic age using pyaging. Input must be BMIQ-normalized methylation data (CSV)."
    )
    parser.add_argument(
        "input_csv",
        type=str,
        help="Path to the BMIQ-normalized methylation CSV file; rows = samples, columns = probes."
    )
    parser.add_argument(
        "--epicv2",
        type=str2bool,
        default=False,
        help="Whether to apply EPIC v2 probe aggregation (true/false). Default: false."
    )
    parser.add_argument(
        "--clocks",
        type=str,
        default="AltumAge,DunedinPACE",
        help=f"Comma-separated list of clocks to use. Available clocks: {', '.join(ALLOWED_CLOCKS)}"
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Optional output CSV file name (e.g. predictions.csv)."
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        default=os.getcwd(),
        help="Output directory (default = current working directory)."
    )

    args = parser.parse_args()

    # Validate and parse clocks
    clock_list = validate_clocks(args.clocks)

    # Prepare output directory
    output_dir = os.path.abspath(args.output_dir)
    os.makedirs(output_dir, exist_ok=True)

    # Determine output filename and path
    if args.output:
        output_path = os.path.join(output_dir, args.output)
    else:
        input_name = os.path.splitext(os.path.basename(args.input_csv))[0]
        output_filename = f"predictions_{input_name}.csv"
        output_path = os.path.join(output_dir, output_filename)

    # Load methylation data
    df = pd.read_csv(args.input_csv, index_col=0)

    # Apply EPIC v2 aggregation if requested
    if args.epicv2:
        df = pya.pp.epicv2_probe_aggregation(df)

    # Convert to AnnData object (with k-NN imputation)
    adata = pya.pp.df_to_adata(df, imputer_strategy='knn')

    # Predict epigenetic age
    pya.pred.predict_age(adata, clock_list)

    # Save result
    adata.obs.to_csv(output_path)
    print(f"Prediction results saved to: {output_path}")

if __name__ == "__main__":
    main()
