#!/bin/bash

#SBATCH -J RNAseq_alignment
#SBATCH -A ***REMOVED***
#SBATCH --time=8:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --profile=task

# Anything within the brackets "<>"" should be customised, fill in with relevant info/path, then remove the brackets and run the script 
# This file was designed to run on the sever managed by slurm, please adjust if using alternative platforms. 

##### Change this section according to your project before running #########


# Where raw sequencing files locate
Input_DIR=<your/input/dir>

# Where you want the processed data, or intermediate data to be saved
Process_DIR=<your/processed/data/to/be/saved>

mkdir -p $Process_DIR/samfiles
mkdir -p $Process_DIR/bamfiles
mkdir -p $Process_DIR/bowtie2_index

# Location of reference genome and annotation files
ref_DIR=<path/to/references>

# define output directory where you want to save the results
Output_DIR=<path/to/output>

####################################################################################

# load modules(aka tools), this is like loading apps so you can use specific features
module load Bowtie2/2.5.4-GCC-12.3.0
module load SAMtools/1.21-GCC-12.3.0


# If sequencing facility completed appropriate preprocessing, adapter-trimming and QC steps can be skipped. 


# Use bowtie2 to build reference file based on the reference genome

bowtie2-build -f $ref_DIR/<ref_genome>.fasta $Process_DIR/bowtie2_index/<ref_name>


# align the QCed RNAseq reads to the mtb genome and create .bam files

################# run this chunk if preprocessing is NOT required #################  
cd $Input_DIR

# use bowtie 2 to align reads to reference genome
for i in *_R1_001.fastq.gz
do bowtie2 --no-unal -p 8 -x $Process_DIR/bowtie2_index/<ref_name> -1 $i -2 ${i%_R1_001.fastq.gz}_R2_001.fastq.gz -S $Process_DIR/samfiles/${i%_R1_001.fastq.gz}.sam

done

# The for loop is used to go over all samples. Because paired files (ie. forward and reverse) need to be run in one go and not separate, thus for the loop I only asked it to search for the forward reads file (eg. XXXX_R1.fq)
# --no-unal is an optional argument, meaning reads that do not align to the reference genome will not be written to sam output
# -p is the number (n) of processors/threads used
# -x is the genome index
# -1 is the file(s) containing forward reads
# -2 is the file(s) containing reverse reads
# -S indicate the output alignment will be generaged as sam format

####################################################################################


################# run this chunk if preprocessing is required #################  
## To run this, remove 1 "#" from the beginning for each line after this line till the end of this chunk

# cd $Input_DIR

# mkdir -p $Process_DIR/clean_seq

## remove adapters
# for fq in *_R1_001.fastq.gz
# do bbduk.sh in1=$fq in2=${fq%_R1_001.fastq.gz}_R2_001.fastq.gz out1=$Output_DIR/clean_seq/clean_${fq%_R1_001.fastq.gz}_R1.fq out2=$Output_DIR/clean_seq/clean_${fq%_R1_001.fastq.gz}_R2.fq ref=adapters.fa ktrim=N k=23 mink=11 hdist=1 tpe tbo

# done

## remove phix
# cd $Output_DIR/clean_seq
# for fq in clean*_R1.fq
# do
# bbduk.sh in1=$fq in2=${fq%_R1.fq}_R2.fq.
# out1=$Output_DIR/clean_seq/filtered_${fq%_R1.fq}_R1.fq out2=$Output_DIR/clean_seq/filtered_${fq%_R1.fq}_R2.fq 
# ref=phix.fa k=31 hdist=1 stats=stats.txt
# done

# quality trimming
# for fq in filtered_*_R1.fq
# do
# bbduk.sh in1=$fq in2=${fq%_R1.fq}_R2_001.fastq.gz  out1=$Output_DIR/clean_seq/QC_$${fq%_R1.fq}_R1.fq out2=$Output_DIR/clean_seq/QC_${fq%_R1.fq}_R2.fq  qtrim=r trimq=10
# done

## use bowtie 2 to align reads to reference genome
# for i in QC*_R1.fq
# do bowtie2 --no-unal -p 8 -x $Process_DIR/bowtie2_index/<ref_name> -1 $i -2 ${i%_R1.fq}_R2.fq -S $Process_DIR/samfiles/${i%_R1.fq}.sam
# done

####################################################################################

# sort sam files and convert to bam files
cd $Process_DIR/samfiles

for s in *.sam
do samtools sort -O bam -@ 4 $s -o $Process_DIR/bamfiles/${s%.sam}_bowtie2.bam 
done

cd $Process_DIR/bamfiles
for b in *.bam
do samtools index $b  ${b}.bai
done



# use FeatureCounts to calculate the raw counts per gene across all strains 

module load Subread/2.0.7-GCC-12.3.0

featureCounts -t gene -g gene_id  -p -O -a $ref_DIR/<ref_genome>.gtf -o $Output_DIR/FeatureCounts_RNASeq.txt *.bam

# Proceed to differential expression analyses with R script
