#!/bin/bash
#$ -S /bin/bash
#$ -N score
#$ -cwd
#$ -pe smp 24
#$ -e ./result/scoreerr
#$ -o ./result/scoreout
#$ -V
## This is a cluster mode script for calculating scores.
set -ue
## You may consider modifying the variables below:

## The directly containing .fast5 file.
QUERIES=/glusterfs/ban-m/E_coli_K12_1D_R9.2_SpotON_2/downloads/pass

## Reference file
ECOLIREF=/glusterfs/ban-m/references/ecoli/ecolik12.fa

## Molde file.
MODEL=${PWD}/../kmer_models/r9.2_180mv_250bps_6mer/template_median68pA.model

## Reference size
REFSIZE=100

## SAM file (this should be created by mapping .fastq file from $QUERIES/*.fast5 to $ECOLIREF so that
## the script can know where the "correct" alignemnts begin).
SAM=/glusterfs/ban-m/bwamap/mapped.sam

## The amount of events this script can see to map a event sequence to reference.
QUERY_SIZE=250

echo "refsize,querysize,num_scouts,num_packs,true_positive,false_positive,positive_num,test_num,method,metric,power" >> test.csv # result/score_proposed.csv
packs=1
scouts=16
power=35
cargo run --release $MODEL $REFSIZE $ECOLIREF $QUERIES $SAM Scouting,${scouts},${packs} $QUERY_SIZE PC Hill ${power} >> test.csv
exit 0;
for packs in $(seq 2 1 3)
do
    for scouts in $(seq 14 2 20)
    do
	    for power in $(seq 35 1 38)
	    do
	        cargo run --release $MODEL $REFSIZE $ECOLIREF $QUERIES $SAM Scouting,${scouts},${packs} $QUERY_SIZE PC Hill ${power} >> result/score_proposed.csv
	    done
    done
done
