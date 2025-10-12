#### CRISPRi analyses

All necessary intermediate files including metadata and output from CRISPRi_step2_reads_sum.R are provided to allow downstream tests in R

**Instructions:**

 - Download the zipped R project file to a preferred location and unzip the file
 - Open the CRISPRi_related_data_analyses_CW.Rproj in Rstudio, you should see the name appear on the top right corner. Loading the project will allow relative path to work, without doing so will cause issues when loading files. The system platform information is provided down the bottom of this readme file. Note that first time setting up the project might require installation of R packages and Rstudio reset 
 - (Optional) Exact tests. 
   - In Rstudio, open up the CRISPRi_step3_exact_test.Rmd (in Scripts/CRISPRi) to run the exact tests. Input files for this step are available at Results/CRISPRi/data_long/,whcih is preset using the R project settings so no need to change path or anything. The results of this step are also provided for this step so feel free to skip
 - Gene vulnerability tests and figure generation
   - Within the same R project Rstudio window, open the script 2025_Muti_strain_CRISPRi.Rmd (in Scripts/CRISPRi)
   - Install and load the required libraries via running the first chunk of code (ie. "packman load libraries") provided in the file, which will perpare the environment for the following analyses
   - After the environment has been prepared, make sure to run the code chunks in order (DONOT skip chunks) as some code chunks would build variables for downstream analyses
  

For each screen, raw gRNA reads from sequencing data was extracted and calculated using high-performance computing service provided by New Zealand eScience Infrastructure (NeSI)  using the scripts CRISPRi_step1-preprocess_2025_v2.sl.sh and CRISPRi_step2_reads_sum.R 




**System information for running the scripts**

sessionInfo()

R version 4.5.1 (2025-06-13)

Platform: aarch64-apple-darwin20

Running under: macOS Sonoma 14.5

Matrix products: default
BLAS:   /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib 

LAPACK: /Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

time zone: Pacific/Auckland
tzcode source: internal

attached base packages:
[1] stats4    stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:

 [1] ggvenn_0.1.16               ggsankey_0.0.99999          ggpattern_1.1.4             UpSetR_1.4.0               
 [5] ggh4x_0.3.1                 patchwork_1.3.1             rstatix_0.7.2               ggExtra_0.10.1             
 [9] ggtext_0.1.2                ggupset_0.4.1               RColorBrewer_1.1-3          viridis_0.6.5              
[13] viridisLite_0.4.2           DESeq2_1.48.2               SummarizedExperiment_1.38.1 Biobase_2.68.0             
[17] MatrixGenerics_1.20.0       matrixStats_1.5.0           GenomicRanges_1.60.0        GenomeInfoDb_1.44.2        
[21] IRanges_2.42.0              S4Vectors_0.46.0            BiocGenerics_0.54.0         generics_0.1.4             
[25] ggpubr_0.6.1                ggrepel_0.9.6               edgeR_4.6.3                 limma_3.64.3               
[29] data.table_1.17.8           writexl_1.5.4               readxl_1.4.5                lubridate_1.9.4            
[33] forcats_1.0.0               stringr_1.5.2               dplyr_1.1.4                 purrr_1.1.0                
[37] readr_2.1.5                 tidyr_1.3.1                 tibble_3.3.0                ggplot2_4.0.0              
[41] tidyverse_2.0.0            

loaded via a namespace (and not attached):

 [1] gridExtra_2.3           rlang_1.1.6             magrittr_2.0.4          compiler_4.5.1          vctrs_0.6.5            
 [6] pkgconfig_2.0.3         crayon_1.5.3            fastmap_1.2.0           backports_1.5.0         XVector_0.48.0         
[11] utf8_1.2.6              promises_1.3.3          rmarkdown_2.29          tzdb_0.5.0              UCSC.utils_1.4.0       
[16] bit_4.6.0               xfun_0.52               jsonlite_2.0.0          later_1.4.2             DelayedArray_0.34.1    
[21] BiocParallel_1.42.1     broom_1.0.9             parallel_4.5.1          R6_2.6.1                stringi_1.8.7          
[26] car_3.1-3               cellranger_1.1.0        Rcpp_1.1.0              knitr_1.50              pacman_0.5.1           
[31] httpuv_1.6.16           Matrix_1.7-3            timechange_0.3.0        tidyselect_1.2.1        rstudioapi_0.17.1      
[36] abind_1.4-8             yaml_2.3.10             codetools_0.2-20        miniUI_0.1.2            plyr_1.8.9             
[41] lattice_0.22-7          shiny_1.11.1            withr_3.0.2             S7_0.2.0                evaluate_1.0.5         
[46] xml2_1.3.8              pillar_1.11.1           carData_3.0-5           vroom_1.6.5             hms_1.1.3              
[51] scales_1.4.0            xtable_1.8-4            glue_1.8.0              tools_4.5.1             locfit_1.5-9.12        
[56] ggsignif_0.6.4          grid_4.5.1              GenomeInfoDbData_1.2.14 Formula_1.2-5           cli_3.6.5              
[61] S4Arrays_1.8.1          gtable_0.3.6            digest_0.6.37           SparseArray_1.8.1       farver_2.1.2           
[66] htmltools_0.5.8.1       lifecycle_1.0.4         httr_1.4.7              mime_0.13               statmod_1.5.0          
[71] gridtext_0.1.5          bit64_4.6.0-1          
