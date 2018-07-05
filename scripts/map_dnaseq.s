#!/bin/bash
#
#BATCH --verbose
#SBATCH --job-name=cnv
#SBATCH --time=20:00:00
#SBATCH --nodes=1
#SBATCH --mem=50GB
#SBATCH --mail-type=ALL
#SBATCH --output=/scratch/dam740/reports/slurm_cnv_%j.out
#SBATCH --mail-user=dam740@nyu.edu
       
##
# Waits for a sbatch job to finish.
# Input: string, the message returned by the sbatch command
#        e.g: 'Submitted batch job 4424072'
##
wait_for_job(){
  # extract only the jobid from the job output
  jobout="$1"
  jobid="${jobout##* }"

  is_running=$(squeue -j $jobid | wc -l | awk '$0=$1')
  while [ $is_running -gt 1 ]
  do
    sleep 15
    is_running=$(squeue -j $jobid | wc -l | awk '$0=$1')
  done
}

BASE_DIR=/scratch/dam740/cnv
mutants=(bc4289 sp117 sp1981 sp219 ty1909 ty1916 vc100)

SBATCH_SCRIPTS=/scratch/cgsb/ercan/scripts/chip/slurm/
MAIL=dam740@nyu.edu

mkdir -p $BASE_DIR/reports
cd $BASE_DIR

for mut in ${mutants[*]}; do

  echo "Running CNV for experiment '$mut'"
  WORKING_DIR=$BASE_DIR/$mut/dnaseq
  cd $WORKING_DIR

  mv Fastq/* .
  rm -rf Fastq

  echo "Unzipping files"
  gunzip *.gz

  ls *fastq > files.txt
  n=$(wc -l files.txt | awk '$0=$1')

  echo "Running Bowtie..."
  job_out=$(sbatch --output=$BASE_DIR/reports/slurm_bowtie_%j.out\
                   --error=$BASE_DIR/reports/slurm_bowtie_%j.err\
                   --mail-type=ALL\
                   --mail-user=$MAIL\
                   --array=1-$n\
                   $SBATCH_SCRIPTS/doBowtie_Single.s)
  wait_for_job "$job_out"
  echo "Bowtie finished..."

  rm files.txt

  # Record keeping
  mkdir ReadAlignments
  mv Read_Alignment*txt ReadAlignments

  # Get organized
  mkdir Fastq
  mv *fastq Fastq

  mkdir BAM
  mv *bam BAM

  cd BAM

  module purge
  module load samtools/intel/1.6
  samtools merge $mut.bam $(ls *bam)

done