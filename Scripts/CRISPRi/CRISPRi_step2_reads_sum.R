# Adjut the ProjectDIR to where the output was saved from running 
ProjectDIR<-"Documents/Demo_CRISPRi_data/"

packs_required<-c("BiocManager","pacman")
if_insta_packs<-packs_required %in% rownames(installed.packages())
if (any(if_insta_packs == FALSE)) {
  install.packages(packs_required[!if_insta_packs])
}

# load CRAN and Bioconductor packages
pacman::p_load(tidyverse,readxl)


# load guide data
guide_sum<-read_csv("Documents/summary_guide_data.csv")

Proj_IDs<-c("5767a")

wd<-getwd()

for (p in Proj_IDs) {
  # load library metadata
  # load sample meta data
  sample_meta<-read_xlsx(paste0(wd,"/Documents/sample_meta_data/sample_metadata_seqcent-",p,".xlsx"))
  
  # load matched counts 
  matched_counts<-read.delim(paste0(ProjectDIR,"all_matched_reads-",p, ".tsv"), header = FALSE,col.names = c("Sequence","sample.ID", "type","reads")) %>% separate(col = Sequence,into = c("ref.sequence", "guide.sequence"), sep = "\\s+",fill = "right")
  matched_counts_split<-split.data.frame(matched_counts,f = matched_counts$sample.ID)
  # identify reads that match 100% with no mismatches and summarise data
  matched_counts_reshaped<-NULL
  for (sam_df in 1:length(matched_counts_split)) {
    temp_df<- matched_counts_split[[sam_df]] %>% 
      mutate(guide.length=nchar(ref.sequence),
             extra_seq="GTTTTTGTACTCG",
             refseq.full=paste0(ref.sequence,substr(extra_seq,1,(34-guide.length)))) %>% 
      filter(guide.sequence==refseq.full) %>% 
      select(ref.sequence,refseq.full,sample.ID,reads) %>% 
      group_by(ref.sequence,refseq.full,sample.ID) %>% summarise(reads=sum(reads)) %>% 
      full_join(guide_sum, by = c("ref.sequence"="guide.sequence")) %>% 
      mutate(sample.ID=ifelse(is.na(sample.ID),names(matched_counts_split)[sam_df],sample.ID),
             reads=ifelse(is.na(reads),0,reads)) %>% 
      left_join(sample_meta, by = c("sample.ID"="sample")) %>% 
      relocate(any_of(c("refseq.full","sample.ID","reads")), .after = "guide.id") %>% 
      relocate("target.gene", .before = "ref.sequence") %>% 
      rename("ref.sequence"="guide.sequence",
             "refseq.full"="guide.tag",
             "sample.ID"="sample") %>% 
      arrange(guide.id)
    matched_counts_reshaped<-rbind(matched_counts_reshaped,temp_df)
    
  }
  
  
  write_tsv(matched_counts_reshaped,file = paste0(wd,"/Results/data_long_",p,".tsv"))
}
