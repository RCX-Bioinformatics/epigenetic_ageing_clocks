# 🧬 Epigenetic Ageing Clock Pipeline

This pipeline estimates multiple **epigenetic ageing clocks** from DNA methylation data.  
It consists of two main parts:

1. **Gold Standard (GS) dataset generation** — creates a comprehensive reference methylation dataset covering all probes required by various epigenetic ageing clocks.
2. **Epigenetic clocks estimation** — processes a new dataset, completes missing probes using the GS reference, and estimates multiple ageing clocks.

---

## 📁 Directory Structure

```
epigenetic_ageing_clocks/
├── config/
│   ├── gold_standard_config.yaml
│   └── epiclocks_config.yaml
├── scripts/
│   ├── gold_standard/
│   │   ├── champ_preprocessing_GS_idats.R
│   │   ├── champ_preprocessing_GS_signal_intensities.R
│   │   └── gs_ref_vals.R
│   └── epiclocks/
│       ├── champ_preprocessing.R
│       ├── ref_vals_completion.R
│       ├── cheekage_input_prep.R
│       ├── horvath_dnamage.R
│       └── pyaging_clocks.py
├── singularity/
│   ├── champ/champ.def
│   ├── horvath/horvath.def
│   └── pyaging/pyaging.def
└── run_gold_standard.sh
└── run_epiclocks.sh
```

---

## ⚙️ Prerequisites

- **Linux environment** with:
  - `bash`, `yq`, `make`, and `singularity` installed
- **Required Singularity images** (can be built using `make`):
  - `champ.sif` → ChAMP-based preprocessing
  - `horvath.sif` → Horvath’s DNAmAge estimation
  - `pyaging.sif` → PyAging-based deep learning clocks

Make sure these Singularity images are correctly defined in the config YAML files.

---

### 🔧 Build Singularity Images

If not yet built, navigate to the `singularity/ubuntu22.04_R4.4.1` directory and run:

```bash
make
```

This will build `.sif` container using the `Makefile`. Please build all necessary containers following the same instructions.

---

## 🧩 Step 1: Create Gold Standard (GS) Reference Dataset

This step preprocesses multiple methylation datasets and merges them to create **reference beta value matrices** that cover all probes needed by downstream ageing clocks.

### Configuration

Edit `config/gold_standard_config.yaml` to define:

```yaml
paths:
  workdir: "/path/to/workdir"

workflow:
  run_preprocessing: true
  run_reference_creation: true

datasets:
  - name: "GSE50586"
    input_type: "signal_intensity"
    signal_file: "/path/to/GSE50586_signals.txt.gz"
    array_type: "EPIC"
  - name: "GSE48472"
    input_type: "idat"
    idat_dir: "/path/to/idats/"
    array_type: "450K"
```

Each dataset can be provided as:
- `input_type: idat` → path to `.idat` files  
- `input_type: signal_intensity` → path to text file with signal A/B intensities and detection p-values

### Run

```bash
bash run_gold_standard.sh
```

This script will:

1. Preprocess each dataset (ChAMP-based normalization and QC)
2. Generate both **BMIQ-normalized** and **RAW** reference beta matrices
3. Save results to:

```
$WORKDIR/GS_results/
├── GS_preprocessing/         # Individual dataset preprocessing outputs
└── buccal_ref_values/        # Final combined reference matrices
```

Each dataset is processed only once (a `.done` file prevents re-processing).

---

## 🧠 Step 2: Estimate Epigenetic Ageing Clocks

Once GS reference datasets are ready, use them to estimate clocks for a new dataset.

### Configuration

Edit `config/epiclocks_config.yaml`:

```yaml
paths:
  workdir: "/path/to/workdir"

dataset:
  name: "MyDataset"
  idat_dir: "/path/to/idats/"

gold_standard_BMIQ: "/path/to/epigenetic_ageing_clocks/GS_results/buccal_ref_values_BMIQ.rds"
gold_standard_raw: "/path/to/epigenetic_ageing_clocks/GS_results/buccal_ref_values_RAW.rds"
```

### Run

```bash
bash run_epiclocks.sh
```

This will:

1. **Preprocess** the input dataset using ChAMP  
   → Outputs `beta_values_RAW.rds` and `beta_values_BMIQ.rds`
2. **Complete missing probes** using the GS reference (`ref_vals_completion.R`)
3. **Compute ageing clock estimates**:
   - **CheekAge** (via Shiny server input prep)
   - **AltumAge** (via PyAging)
   - **Horvath DNAmAge** (using R script based on original publication from dr. Horvath)

Results are stored under:

```
$WORKDIR/EPICLOCKS_results/MyDataset/
├── preprocessing/
├── complete_betas/
├── cheekage/
├── altumage/
└── dnamage/
```

---

## 🧹 Tips

- If a dataset has already been processed, delete its `.done` file to re-run that step.
- If you have already processed methylation data and want to create a GS reference directly, set the `run_preprocessing` argument to `false` in the YAML configuration file.
- Intermediate files from `AVAILABLE_BETA` are cleaned automatically.
- Temporary cache from PyAging is removed at the end of each run.
- Make sure that `workdir` in YAML configuration file matches the actual repository path.

---

## 💬 Example Workflow

```bash
# Step 1: Build reference GS dataset
bash run_gold_standard.sh

# Step 2: Run clocks on new dataset
bash run_epiclocks.sh
```

---

## 📚 Citation

If you use this pipeline, please cite the relevant methods and tools:

- Mareckova et al. (update once published)
- **ChAMP:** Tian Y, Morris TJ, Webster AP, et al. ChAMP: updated methylation analysis pipeline for Illumina BeadChips. Bioinformatics. 2017.  
- **BMIQ normalization:** Teschendorff AE, et al. A beta-mixture quantile normalization method for correcting probe design bias in Illumina Infinium 450k DNA methylation data. Bioinformatics. 2013.  
- **Cell type heterogeneity estimate:** Zheng SC, Breeze CE, Beck S, Teschendorff AE (2018). “Identification of differentially methylated cell-types in Epigenome-Wide Association Studies.” Nature Methods, 15(12), 1059.
- **DNAmAge:** Horvath S. (2013). DNA methylation age of human tissues and cell types. Genome Biology.
- **AltumAge:** Lee Y. et al. (2022). AltumAge: A Pan-Tissue DNA Methylation Epigenetic Clock. Frontiers in Aging.
- **PyAging / AltumAge:** de Lima Camillo et al., *bioRxiv*, 2023
- **CheekAge** Shokhirev M. N. et al. (2024). CheekAge: a next-generation buccal epigenetic aging clock associated with lifestyle and health. GeroScience.