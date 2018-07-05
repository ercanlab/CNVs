#!/bin/bash
#
#BATCH --verbose
#SBATCH --job-name=bamCompare
#SBATCH --time=10:00:00
#SBATCH --nodes=1
#SBATCH --mem=50GB
#SBATCH --mail-type=ALL
#SBATCH --output=/scratch/dam740/reports/slurm_bamcompare_%j.out
#SBATCH --mail-user=dam740@nyu.edu
  
module load samtools/intel/1.6

mutants=(bc4289 sp117 sp1981 sp219 ty1909 ty1916 vc100)
f_control=dnaseq_controls/single/BAM/control_single.sorted.bam
bin_size=500
echo "Printing control index stats..."
samtools idxstats $f_control

echo ${mutants[*]}

for mut in ${mutants[*]}; do
    echo "---- $mut ----"
    dir=$mut/dnaseq/BAM

    if [ ! -a $dir/$mut.sorted.bam ]; then
        echo 'Sorting...'
        samtools sort $dir/$mut.bam -o $dir/$mut.sorted.bam
    fi

    if [ ! -a $dir/$mut.sorted.bam.bai ]; then
        echo "Indexing..."
        samtools index $dir/$mut.sorted.bam
    fi

    echo "Printing mutant index stats..."
    samtools idxstats $dir/$mut.sorted.bam

    echo "Running bamcompare..."
    ~/.local/bin/bamCompare\
        --bamfile1 $dir/$mut.sorted.bam\
        --bamfile2 $f_control\
        -o $dir/$mut.sorted.ignore.bedgraph\
        --binSize $bin_size\
        --scaleFactorsMethod None\
        --operation log2\
        --minMappingQuality 30\
        --outFileFormat bedgraph\
        --ignoreDuplicates

    ~/.local/bin/bamCompare\
        --bamfile1 $dir/$mut.sorted.bam\
        --bamfile2 $f_control\
        -o $dir/$mut.sorted.bedgraph\
        --binSize $bin_size\
        --scaleFactorsMethod None\
        --operation log2\
        --minMappingQuality 30\
        --outFileFormat bedgraph
done
