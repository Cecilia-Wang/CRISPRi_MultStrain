#!/bin/bash
#SBATCH -J CRISPRi_counts
#SBATCH -A 
#SBATCH --time=4:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --profile=task

# List all experiments and samples to run.
# Note, leading zeros for samples. Some are formatted %02d and others %03d!

# Dependencies:
# seqkit
# gnu parallel

module load SeqKit/2.4.0
module load Parallel/20220922
# Note, some operations require a lot of memory

# identify the list of experiments to run, new runs can be added as new lines inside the EXPLIST list
# add additional experiment list where applicable (e.g. 5767b:061:120)
EXPLIST='
seqcent:5440b:061:120
'

THREADS=8

# read QC - depreciated as read quality is always high

# main analysis - run all samples in experiment list

## Each item is assigned to the variable PARAMS in turn.
for PARAMS in $EXPLIST;do

## This line extracts the first/second/third/fourth field (delimited by colons) from the PARAMS string and assigns it to the variable TYPE. 
TYPE=$(echo $PARAMS | cut -d ":" -f 1)
RUN=$(echo $PARAMS | cut -d ":" -f 2)
SAMPLE_MIN=$(echo $PARAMS | cut -d ":" -f 3)
SAMPLE_MAX=$(echo $PARAMS | cut -d ":" -f 4)

## This line generates a sequence of numbers from SAMPLE_MIN to SAMPLE_MAX and assigns it to the variable SAMPLE_RUN. For example, if the EXPLIST='seqcent:4320a2:061:120', then SAMPLE_RUN would be '061 062 063 ... 118 119 120'
SAMPLE_RUN=$(eval echo {$SAMPLE_MIN..$SAMPLE_MAX})

# identify the project directory
PROJDIR=<path/to/fastq/files>/$RUN/

## the -p option stands for parents, so that mkdir will create any necessary parent directories as well
mkdir -p $PROJDIR/reads/
mkdir -p $PROJDIR/processed_reads/
mkdir -p $PROJDIR/passed_reads/
mkdir -p $PROJDIR/trimmed_reads/
mkdir -p $PROJDIR/collapsed_reads/
mkdir -p $PROJDIR/final_reads/
mkdir -p $PROJDIR/failed_reads/
mkdir -p $PROJDIR/tmp/
# convert fastq to fasta ## should be fastq to tab-delimited table
## this is how to make a function in shell
function fastq_to_table() {

# use 10# format to prevent octal errors

## This line formats the first argument passed to the function ($1) as a three-digit number with leading zeros (if necessary) and prefixes it with an "S". The 10# format is used to ensure that the number is treated as a decimal, avoiding errors if the number starts with a zero (which would otherwise be interpreted as an octal number). For example, if $1 (first field/column) is 5, SAMPLENAME will be set to S005
SAMPLENAME=S$(printf "%03d" $(( 10#$1 )) ) # convert all samplenames to three digit.... need to update sample sheets accordingly...
echo "Converting fastq to read table for $3/S$1....fastq"


## This command uses the seqkit function(program) for processing sequence data. The fx2tab subcommand converts FASTQ files to a tab-delimited format, with the --no-qual option omitting the quality scores. The input FASTQ files are located in the $3/fastq directory and have names matching the pattern S$1*.fastq.gz. 
## the '|' symbol in shell is called 'pipe', which pipes the output from the current process to the next process, kind of similar to "%>%" in R
## The awk command is used for pattern scanning and processing, here it processes the output from seqkit, adding the sample name (stored in the SAMPLENAME variable) as a second column. The -F '\t' option specifies that the input is tab-delimited, -v means variable, and OFS='\t' sets the output field separator to a tab.
## The sort command sorts the output from awk, using up to 10 GB of memory (-S10G). The -T /mnt/e/tmp/ option specifies a temporary directory for storing intermediate files during the sorting process.
## 'uniq -c'  collapses consecutive identical lines into a single line, prefixing each line with a count of the number of occurrences. This is useful for counting the number of reads for each unique sequence in the sample.
## The "sed" stands for "stream editor", the commands replace sequences of one or more spaces with a single tab and remove any leading tabs from the lines. This is to make sure the data of each field will be put into the correct columns, as sometimes spaces could affect the table (some software will convert 4 spaces as a tab, some others will not convert any)
## The final output is redirected to a file in the $3/reads directory, with a filename based on the SAMPLENAME variable and a .reads extension.

seqkit fx2tab --no-qual $3/S$1*.fastq.gz | 
awk -F '\t' -v sample="$SAMPLENAME" '{print $2, sample}' OFS='\t' | sort -S10G -T $PROJDIR/tmp/ | uniq -c | \
sed 's/[ ]\+/\t/g' | sed 's/^\t//g' > $3/reads/$SAMPLENAME.reads

}

# export the function
export -f fastq_to_table

## run the function in parallel, threads=32,  The command template to execute for each sample. The {} placeholder is replaced by each value from SAMPLE_RUN in turn. '::: $SAMPLE_RUN' specifies the input values for the parallel execution, with each value in SAMPLE_RUN being passed to a separate instance of the fastq_to_table function.
parallel --bar -j $THREADS "fastq_to_table {} $RUN $PROJDIR" ::: $SAMPLE_RUN


# replace promoter at beginning of reads with QC tag

# edit to assign each sequence a unique code (so we can check promoter mutants later)??

## the multiple sed functions search for DNA sequences (that is 10 to 30 nucleotides long) matching certain patterns in the input file ($2/reads/$SAMPLENAME.reads) and replace them with corresponding labels. Generally "sed 's/\t[ACGT]\{10,30\}PATTERN/\tLABEL\t_base-f_/g'". The labels were used to categorize the based on their promoter regions
function replace_promoter () {
# use 10# format to prevent octal errors
SAMPLENAME=S$(printf "%03d" $(( 10#$1 )) ) # convert all samplenames to three digit.... need to update sample sheets accordingly...

sed 's/\t[ACGT]\{10,30\}AGATATAATCTGGGA/\tcanonical\t_base-f_/g' $2/reads/$SAMPLENAME.reads | # expected tag
sed 's/\t[ACGT]\{10,30\}TATCA[ACGT]\{6,8\}TATAATCTGGGA/\tmutant-preprom\t_base-f_/g' |
sed 's/\t[ACGT]\{10,30\}AGA[ACGT]\{5,6\}CTGGGA/\tmutant-prom1\t_base-f_/g' |
sed 's/\t[ACGT]\{10,30\}TATCA[ACGT]\{11,13\}TCTGGGA/\tmutant-prom2\t_base-f_/g' |
sed 's/\t[ACGT]\{10,30\}AGATATAATCTGGGGA/\tmutant-postprom\t_base-f_/g' |
sed 's/\t[ACGT]\{10,30\}AGATATAATCTGGTA/\tmutant-postprom\t_base-f_/g' |
sed 's/\t[ACGT]\{10,30\}AGATATAATCTTGGA/\tmutant-postprom\t_base-f_/g' |
sed 's/\t[ACGT]\{0,10\}GATCCC[ACGT]\{17,20\}TCT[ACGT]\{2,4\}GA/\tmutant-mixed\t_base-f_/g' > $2/processed_reads/$SAMPLENAME.processed.reads
}

export -f replace_promoter

echo "Replacing promoter sequences"

parallel --bar -j $THREADS "replace_promoter {} $PROJDIR" ::: $SAMPLE_RUN


function collapse_reads () {

# use 10# format to prevent octal errors
SAMPLENAME=S$(printf "%03d" $(( 10#$1 )) ) # convert all samplenames to three digit.... need to update sample sheets accordingly...

echo "Collapsing reads for $SAMPLENAME"

# split into complete (contain "base-f") and incomplete reads
sed -n '/base-f/p' $2/processed_reads/$SAMPLENAME.processed.reads > $2/passed_reads/$SAMPLENAME.processed.passed.reads

# incomplete reads
sed '/base-f/d' $2/processed_reads/$SAMPLENAME.processed.reads | 
sort -S10G -T $PROJDIR/tmp/ -r -k1 -n > $2/failed_reads/$SAMPLENAME.processed.failed.reads


sed 's/_base-f_/passed\t/g' $2/passed_reads/$SAMPLENAME.processed.passed.reads |
awk -F'\t' '{print $1,substr($4,1,34),$5,$2}' | sort -r -k1 -n > $2/trimmed_reads/$SAMPLENAME.processed.passed.trimmed.reads

# collapse and sum reads per gRNA
awk '{grna[$2"\t"$3"\t"$4] += $1} END {for (i in grna) print i,grna[i] }' $2/trimmed_reads/$SAMPLENAME.processed.passed.trimmed.reads | 
sort -S10G -T $PROJDIR/tmp/ -r -k4 -n > $2/collapsed_reads/$SAMPLENAME.processed.passed.trimmed.collapsed.reads

}

export -f collapse_reads


parallel --bar -j 32 "collapse_reads {} $PROJDIR" ::: $SAMPLE_RUN



cat $PROJDIR/collapsed_reads/S*.processed.passed.trimmed.collapsed.reads > $PROJDIR/final_reads/all_processed-$RUN.reads

sed -i 's/ /\t/g' $PROJDIR/final_reads/all_processed-$RUN.reads


# identify reads that match to any guide
awk -F'\t' '
    # First file: prefix table
    NR==FNR {
      prefixes[$2] = $0 ; next        # $2 = guide.sequence
    }

    # Second file: sample with gRNA
    {
      gRNA = $1
      for (p in prefixes) {
        if (substr(gRNA, 1, length(p)) == p)
          print p, '\t', $0
      }
    }
  ' $PROJDIR/no_header_summmary_guide_data.tsv $PROJDIR/final_reads/all_processed-$RUN.reads >> $PROJDIR/final_reads/all_matched_reads-$RUN.tsv

## read QC reporting

awk '{Total=Total+$1} END{print "Total reads raw: " Total}' $PROJDIR/reads/*.reads > $PROJDIR/final_reads/stats_$RUN.table
awk '{Total=Total+$4} END{print "Total reads passing QC: " Total}' $PROJDIR/final_reads/all_processed-$RUN.reads >> $PROJDIR/final_reads/stats_$RUN.table


# summarise promoter mutant information...
awk '{grna[$2"\t"$3] += $4} END {for (i in grna) print i,grna[i] }' $PROJDIR/final_reads/all_processed-$RUN.reads |
sort -k1,1 -k2,2 > $PROJDIR/final_reads/all_mutants-$RUN.reads

sed -i 's/ /\t/g' $PROJDIR/final_reads/all_mutants-$RUN.reads

done



# summarise all read table stats

grep "Total" $PROJDIR/final_reads/stats_*.table | sed 's/.table:/\t/g' | sed 's/.*stats_//g'   > $PROJDIR/final_reads/stats.all.table



















