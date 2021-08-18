#!/bin/bash

source init.sh

###############
############### 4. Extract summary stats

bash ${bin_dir}/util/scripts/extract_summary_stats.sh --conf ../${conf} --out_dir ${out_dir}
