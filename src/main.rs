extern crate bio;
extern crate dtw;
extern crate fast5wrapper;
extern crate irabu;
extern crate rand;
extern crate rayon;
extern crate squiggler;
extern crate utility;
use rayon::prelude::*;
use std::path::Path;
use utility::utilities;
const FRACTION:usize =1000;// means 0.1 percent.
const TRAINING_NUM: usize = 4_000;
fn main() {
    let args: Vec<_> = std::env::args().collect();
    let model = squiggler::Squiggler::new(&Path::new(&args[1])).expect("model");
    let refsize: usize = args[2].parse::<usize>().expect("refsize") * 1_000;
    let (temp, rev) = utilities::setup_template_complement(&Path::new(&args[3])).expect("ref");
    // convert to squiggle, normalize.
    let temp = utilities::convert_to_squiggle(&temp, &model);
    let rev = utilities::convert_to_squiggle(&rev, &model);
    let queries = utilities::get_queries(&args[4],1000,100_000).expect("queries");
    let sam = utilities::get_sam(&args[5]).expect("sam");
    let mode = utilities::get_mode(&args[6]).expect("mode");
    let querysize: usize = args[7].parse().expect("querysize");
    let method = &args[8];
    let metric = &args[9];
    let power: usize = args[10].parse::<usize>().expect("power");
    let queries = utilities::merge_queries_and_sam(&queries, &sam)
        .into_iter()
        .collect();
    let data = utilities::get_dataset(
        &queries,
        &temp,
        &rev,
        refsize,
        querysize,
        &mode,
        power as f32 / 100.,
        &metric,
    );
    let (true_positive, false_positive, positive_num, test_num) =
        utilities::compute_k_folds(&data, data.len() / TRAINING_NUM)
            .par_iter()
            .map(|&(ref test,ref train)| {
                let takenum = test.len() / FRACTION;
                let train: Vec<_> = train.iter().fold(vec![], |mut acc, &(pos, neg)| {
                    acc.push((pos, true));
                    acc.push((neg, false));
                    acc
                });
                // take first takenum number as positive, the rest as negative
                let test = test.iter()
                    .fold((0, vec![]), |(cum, mut acc), &(pos, neg)| {
                        if cum < takenum {
                            acc.push((pos, true));
                            (cum + 1, acc)
                        } else {
                            acc.push((neg, false));
                            (cum + 1, acc)
                        }
                    })
                    .1;
                utilities::validate_for_single_pack(&train, &test, method)
            })
        .reduce(||(0, 0, 0, 0), |acc, x| {
                (acc.0 + x.0, acc.1 + x.1, acc.2 + x.2, acc.3 + x.3)
            });
    use dtw::Mode;
    match mode {
        Mode::Sub => println!(
            "{},{},{},{},{},{},{},{},{}",
            refsize,
            querysize,
            true_positive,
            false_positive,
            positive_num,
            test_num,
            method,
            metric,
            power
        ),
        Mode::SakoeChiba(b) => println!(
            "{},{},{},{},{},{},{},{},{},{}",
            refsize,
            querysize,
            b,
            true_positive,
            false_positive,
            positive_num,
            test_num,
            method,
            metric,
            power
        ),
        Mode::Scouting(scouts, packs) => println!(
            "{},{},{},{},{},{},{},{},{},{},{}",
            refsize,
            querysize,
            scouts,
            packs,
            true_positive,
            false_positive,
            positive_num,
            test_num,
            method,
            metric,
            power
        ),
        _ => eprintln!("error"),
    };
}
