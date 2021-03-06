# README #
## Publication Details ##
* **paper**: Genome analysis and data sharing informs timing of molecular events in pancreatic neuroendocrine tumour
* **authors**: Rene Quevedo, Anna Spreafico, Jeff Bruce, Arnavaz Danesh, Amanda Giesler, Youstina Hanna, Cherry Have, Tiantian Li, S.Y. Cindy Yang Tong Zhang, Sylvia L. Asa, Benjamin Haibe-Kains, Suzanne Kamel-Reid, Monika Krzyzanowska, Adam Smith, Simron Singh, Lillian L. Siu, Trevor J. Pugh
* **publication**: Submitted to Cancer Research - January 12, 2018

## Repo Details ##
### Allelic Fraction Plots: af_plotter ###
* **afPlotter.R**: Creates rough allelic-fraction plots for each sample and maps mutations to each region
    * Used to generate Supplementary Figure 4
    * VCF files are stored in zipped tarballs in the data directory
    * All arguments are hardcoded

### CGH Metaanalysis: cgh_analysis ###
* **aggregateLoh.R**: Used to generate Figure 2, LOH plots for each sample coloured by copy-state, and to create the RData needed foer pancancer_loh.R
    * Has 3 main inputs:
    > data/otbData.aggregateLoh.medianLOH.Rdata: Contains copy-state and LOH status for PNETs and GINETs in validation cohort
    >
    > data/data.aggregateLoh.T2-1.Rdata: Contains copy-state and LOH status for PNETs and GINETs in discovery cohort
    >
    > disease.names:  Toggles the parameters between the discovery and validation cohorts for proper plotting
    
* **cghPlotter.R**:  Used to generate the figures for Supplementary Figure 5.  Clusters copy-number plots between CGH data and discovery+validation cohort as well as does a metaanalysis on features
    * Assumes that the zipped tarball, cgh_files.tar.gz, is extracted into the folder data/cgh_files
    * Assumes that the zipped tarball, net_files.tar.gz, is extracted into the folder data/net_files
    * Runs interactively with a lot of parameters hardcoded and toggled for output
    * Loads in the cgh files and net-seq files and runs a meta-analysis across all clusters

### AACR GENIE Purity Esimation: genie_analysis ###
* **estSomPurity.R**: Main code used to analyze the GENIE Data
    * genie_data/README.txt contains information of how all data was obtained and downloaded from GENIE
    * Takes 3 main inputs:
    > genie_data/GENIE_pnet_DAM_mutations.txt: contains annotated mutation data downloaded from GENIE
    >
    > genie_data/GENIE_pnet_DAM_cna.seg: contains copy-number information data downloaded from GENIE
    >
    > genie_data/GENIE_pnet_clinicalData.txt: contains metadata associated with corresponding samples (SUBJECT TO REMOVE)
    * Code executes with no further arguments.  All parameters are hardcoded within the script and should be run interactively.
    * Generates the following output
    > plots/seg_af_plots.pdf: Plots copy-number profiles with the mapped gene harboring a mutation.  Allelic fractions from targetted sequencing data is displayed for each SNV.
    >
    > ploidy_models.tsv: Simple list of all ploidy models tested
    >
    > otb_purity_estimate.tsv: Generates the raw data that underwent manual revision for best models used in "ST24. GENIE AF Estimates"
    >
    > best.fit.models: Computationally estimated "best fit models" are stored in a list.  "Complete" and "Incomplete" are used to describe models where all mutations are accounted for and explained ("complete") or not ("incomplete")
* **plotTAF.R**: Simple script to plot the expected purity compared against the predicted purity
    * Expected purity  -  de novo computed purity
    * Expected purity  -  pathologist-limited computed purity

### GTEX TPM Analysis: gtex_analysis ###
* Pre-processing tools:
    * constructFpkmMatrix.R: Constructs the sample x tracking_id FPKM matrices per tissue type
    * convertFpkmToTpmMatrix.R: Converts the tissue-specific FPKM matrices to the associated TPM matrices
* **sampleToGtexCdf.R**: Generates a Cumulative Density Function for a given gene of interest in each tissue of GTEx. An input tumor samples expression values are projected on to the GTEx Tissue/Gene-specific CDF to find whether the tumor sample has greater, equal to, or lower expression than GTEx Tissue/gene-specific expression. The 95% CI of the GTEx Tissue/gene-specific expression is plotted above to give context to the percentile.
    * Usage: Rscript sampleToGtexCdf.R /path/to/sampleTpm.Rdata /path/to/goi_list.txt outdir

### TCGA Pancan LOH: pancan_loh ###
* **pancancer_loh.R**: Orders and plots the LOH segments, coloured by copy-number as seen in Figure 1
    * All parameters are hardcoded in the script
    * Input can be described as:
    > data/PNET_segments.txt: allele-specific copy-segments for all PNETS (discovery + validation)
    >
    > data/PNET_segments.txt: allele-specific copy-segments for all GINETS (discovery + validation)
    >
    > data/seg_meta_data.csv: ABSOLUTE calcualted allele-specific copy-number segs obtained from Carter et al., (doi:10.1038/nbt.2203)

### Shallow WGS LOH: shallow_wgs ###
* First version of sWGS LOH calling, intended to run interactively with most parameters hardcoded
* **generateReferenceCdf.R**: Used to generate the reference ECDF for the number of heterozygous SNPs within each bin based on the counts in normal samples
* **physicalCoverageTCN.R**: Generates the sWGS plots seen in Supplementary Figure 3. Estimates the copy-state by depth-of-coverage based EM modelling paired with a quantile-based heterozygosity interpretation.


