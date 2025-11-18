# 🧬 Epigenetic Ageing Clock Pipeline

This pipeline estimates multiple **epigenetic ageing clocks** from DNA methylation data:

- **DNAmAge (Horvath clock)** Horvath S. (2013). DNA methylation age of human tissues and cell types. Genome Biology.
- **AltumAge** Lee Y. et al. (2022). AltumAge: A Pan-Tissue DNA Methylation Epigenetic Clock. Frontiers in Aging.
- **CheekAge** Shokhirev M. N. et al. (2024). CheekAge: a next-generation buccal epigenetic aging clock associated with lifestyle and health. GeroScience.

All scripts run inside prebuilt **Singularity containers**, ensuring a reproducible environment without manual package installation.

It consists of two main parts:

1. **Gold Standard (GS) dataset generation** — creates a comprehensive reference methylation dataset covering all probes required by various epigenetic ageing clocks.
2. **Epigenetic clocks estimation** — processes a new dataset, completes missing probes using the GS reference, and estimates multiple epigenetic ageing clocks.

---

## 📁 Directory Structure

```
epigenetic_ageing_clocks/
├── config/
│   ├── gold_standard_config.yaml
│   └── epiclocks_config.yaml
├── scripts/
│   ├── gold_standard/
│   └── epiclocks/
├── singularity/
└── run_gold_standard.sh
└── run_epiclocks.sh
```

---

## ⚙️ Prerequisites

- **Linux environment** with:
  - `bash`, `yq`, `make`, and `singularity` installed
- **Required Singularity images** (can be built using `make`):
  - `ubuntu22.04_R4.4.1.sif` → base environment
  - `champ.sif` → ChAMP-based preprocessing
  - `horvath.sif` → Horvath’s DNAmAge estimation
  - `pyaging.sif` → PyAging-based deep learning clocks

Make sure these Singularity images are correctly defined in the config YAML files.

---

### 🔧 Build Singularity Images

A single Makefile is provided in the `singularity/` folder to build all containers in the correct order.

1. Navigate to the `singularity/` folder:

```bash
cd singularity/
```
2. Build all containers:
```bash
make all
```
Tip: If you encounter permission denied errors, rerun with sudo
```bash
sudo make all
```
3. To build individual containers, you can run:
```bash
make ubuntu22.04_R4.4.1   # Build only the base container (must be created first)
make champ                 # Build only the champ container
make pyaging               # Build only the pyaging container
make horvath               # Build only the horvath container
```
4.To clean all built `.sif` images:
```bash
make clean
```

---

## 🧩 Step 1: Create Gold Standard (GS) Reference Dataset

This step preprocesses multiple methylation datasets and merges them to create **reference beta value matrix** that cover all probes needed by downstream epigenetic ageing clocks.

### Configuration

Edit `config/gold_standard_config.yaml` to define (details provided in the config file):

```yaml
paths:
  workdir: "/path/to/workdir"

workflow:
  run_preprocessing: true
  run_reference_creation: true

datasets:
  - name: "REF1"
    input_type: "signal_intensity"
    signal_file: "/path/to/REF1_signals.txt.gz"
    array_type: "EPIC"
  - name: "REF1"
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
└── ref_vals_*.rds            # Final combined reference matrix
```

Each dataset is processed only once (a `.done` file prevents re-processing).

---

## 🧠 Step 2: Estimate Epigenetic Ageing Clocks

Once GS reference dataset is ready, use them to estimate clocks for a new dataset.

### Configuration

Edit `config/epiclocks_config.yaml` (details provided in the config file):

```yaml
paths:
  workdir: "/path/to/workdir"

dataset:
  name: "MyDataset"
  idat_dir: "/path/to/idats/"

gold_standard_BMIQ: "/path/to/epigenetic_ageing_clocks/GS_results/ref_vals_buccal_REF1_REF2_REF3_BMIQ.rds"
gold_standard_raw: "/path/to/epigenetic_ageing_clocks/GS_results/ref_vals_buccal_REF1_REF2_REF3.rds"
```

### Run

```bash
bash run_epiclocks.sh
```

This will:

1. **Preprocess** the input dataset using ChAMP (`champ_preprocessing.R`). This step creates the following files inside the `preprocessing` folder:
  - Beta-values
    - `beta_values_*.rds`
    - `beta_values_*_BMIQ.rds` and `beta_values_*_BMIQ.csv`
  - M-values
    - `M_values_*_BMIQ.rds`
  - Metadata
    - `champ_metadata_*.rds`
  - Cell type estimates
    - `cell_proportions_epidish_*_BMIQ.rds`
    - `cell_proportions_hepidish_*_BMIQ.rds`
  - Quality control
    - Raw vs normalised QC plots
    - BMIQ diagnostic plots
    - SVD plots (batch effect assessment)

2. **Complete missing probes** using the GS reference (`ref_vals_completion.R`). This step creates the following files inside the `complete_betas` folder:
  - Complete beta-values
    - `beta_values_*_BMIQ.rds` and `beta_values_*_BMIQ.csv`
    - `beta_values_*.rds` and `beta_values_*.csv`
  - Summary of missing probes per each epigenetic ageing clock
    - `epiclock_probes_summary_*.log`

3. **Compute ageing clock estimates**:
  - **Prepare inputs for CheekAge Shiny server** (`cheekage_input_prep.R`). This step creates the following files inside the `cheekage` folder:
    - M-values divided into smaller chunks suitable for upload to the CheekAge Shiny server
      - `M_vals_chunk_*.csv.gz`
  - **AltumAge estimate** (via PyAging) (`pyaging_clocks.py`). This step creates the following file inside the `altumage` folder:
    - AltumAge estimate
      - `pyaging_estimate_MyDataset.csv`
  - **Horvath DNAmAge** using R script based on original publication from dr. Horvath (`horvath_dnamage.R`). This step creates the following file inside the `dnamage` folder:
    - DNAmAge estimate
      - `beta_values_MyDataset_*_DNAmAge.csv`

Results are stored under:

```
$WORKDIR/EPICLOCKS_results/MyDataset/
├── preprocessing/
├── complete_betas/
├── cheekage/
├── altumage/
└── dnamage/
```


## 🧹 Tips

- If a dataset has already been processed, delete its `.done` file to re-run that step.
- If you have already processed methylation data and want to create GS reference directly, set the `run_preprocessing` argument to `false` in the YAML configuration file.
- Intermediate files and temporary cache are cleaned automatically at the end of each run.
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
- **PyAging / AltumAge:** de Lima Camillo L.P., pyaging: a Python-based compendium of GPU-optimized aging clocks. Bioinformatics. 2024
- **CheekAge** Shokhirev M. N. et al. (2024). CheekAge: a next-generation buccal epigenetic aging clock associated with lifestyle and health. GeroScience.