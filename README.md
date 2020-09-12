# Score calc: a program to calculate scores of each methods to mock data imitating a real situation

- Author: BanshoMasutani<banmasutani@gmail.com>
- Data: 2020-09-12


## Reproduce

0. Install python3 and Rust language. If you have not installed Rust yet, just type:`curl https://sh.rustup.rs -sSf | sh`.
1. Clone and build [Dyss](https://bitbucket.org/ban-m/dyss/src/default/):
```bash
mkdir dyss_build
git clone git@github.com:ban-m/dyss.git
cd dyss
bash setup.sh
python3 ./src/dyss_debug.py --reference ./data/lambda.fa --model ./kmer_models/r9.4_180mv_450bps_6mer/template_median68pA.model --param ./data/parameters.csv --test ./data/test_reads/
```
2. In the `dyss_build` directly, clone this repository:
```bash
cd ../
git clone git@github.com:ban-m/score_calculate.git
cd score_calculate
cargo build --release
bash score_calc_only_needed.job
```

It takes several days to complete, as naive implementation of DTW is (by far) slower than the proposed method.

