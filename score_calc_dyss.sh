#!/bin/bash
#$ -S /bin/bash
#$ -N score
#$ -cwd
#$ -pe smp 24
#$ -V
set -ue
DATA=${PWD}/data
mkdir -p ${DATA}


#### ====== Prepare dataset ==================


## These are events extracted by Python script named `${PWD}/scripts/extract.py`.
## It is obtained by
## ```bash
## wget https://s3.climb.ac.uk/nanopore/E_coli_K12_1D_R9.2_SpotON_2.tgz
## tar -xvf E_coli_K12_1D_R9.2_SpotON_2.tgz
## python3 ${PWD}/scripts/extract.py ${PWD}/E_coli_K12_1D_R9.2_SpotON_2/downloads/pass/ 1200 ${QUERIES}/events.json
## ```
## It requires ONT's fast5 API packages.
QUERY=${DATA}/events.json
if ! [ -e ${QUERY} ]
then
    wget https://mlab.cb.k.u-tokyo.ac.jp/~ban-m/read_until_paper/events.json.gz -O ${QUERY}.gz
    gunzip ${QUERY}.gz
fi
## Reference file
ECOLIREF=${DATA}/EColi_k12.fasta
if ! [ -e ${ECOLIREF} ]
then
    wget http://togows.dbcls.jp/entry/nucleotide/U00096.3.fasta -O ${ECOLIREF}
fi

## Molde file.
MODEL=${PWD}/kmer_models/r9.2_180mv_250bps_6mer/template_median68pA.model
if ! [ -d ${PWD}/kmer_models ]
then
    git clone https://github.com/nanoporetech/kmer_models.git
fi

## Reference size
REFSIZE=100

## SAM File. Mapping from query reads -> ECOLIREF.
READS=${DATA}/query.fasta
SAM=${DATA}/mapping.sam
if ! [ -e ${READS} ]
then
    wget https://s3.climb.ac.uk/nanopore/E_coli_K12_1D_R9.2_SpotON_2.pass.fasta -O ${READS}
fi

if ! [ -e ${SAM} ]
then
    minimap2 -a -x map-ont ${ECOLIREF} ${READS} > ${SAM}
fi


## The amount of events this script can see to map a event sequence to reference.
QUERY_SIZE=250

### =================== RUN ===========================

echo "refsize,querysize,num_scouts,num_packs,true_positive,false_positive,positive_num,test_num,method,metric,power" >> result/score_proposed.csv
packs=1
scouts=16
power=35
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
