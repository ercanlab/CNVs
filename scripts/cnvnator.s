#!/bin/bash
#
#BATCH --verbose
#SBATCH --job-name=cnvnator
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --mem=5GB
#SBATCH --mail-type=ALL
#SBATCH --output=/scratch/dam740/reports/slurm_cnvnator_%j.out
#SBATCH --mail-user=dam740@nyu.edu

TITLE=cnv_calling
WORKING_DIR=$(pwd)

module load root-cern/intel/6.08.06
module load cnvnator/intel/0.3.3

mkdir -p $WORKING_DIR/reports
cd $WORKING_DIR

peaks_dir=peaks
mkdir $peaks_dir

experiments=(bc4289 sp117 sp1981 sp219 ty1909 ty1916 vc100)
bin_size=1000
for exp in ${experiments[*]}; do
  froot=$exp.root
  fpeaks=$exp.peaks.txt
  echo "Running CNVnator for experiment $exp"

  echo "bam stuff"
  cnvnator -root $froot -tree bams/$exp.sorted.bam -unique

  echo "histogram"
  cnvnator -root $froot -his $bin_size -d c_elegans_genome

  echo "calling stats"
  cnvnator -root $froot -stat $bin_size

  echo "partititon"
  cnvnator -root $froot -partition $bin_size

  echo "calling peaks"
  cnvnator -root $froot -call $bin_size > $peaks_dir/$fpeaks

  #echo "visua"
  #echo CHROMOSOME_X:11396601-18436500 | cnvnator -root $froot -view $bin_size > $exp.visua

  #echo "Genotyping"
  #echo CHROMOSOME_X:11396601-18436500 | cnvnator -root $froot -genotype $bin_size
done