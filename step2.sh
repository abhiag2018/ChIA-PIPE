#!/bin/bash


source init.sh

###############
############### 2.

# tag_name="none"
# map_qual=30
# suffix="UU"

## Create name of the log file
log_file=2.${run}.map_${tag_name}.log

## Print arguments to ensure correct parsing
echo "
Arguments:
    main_prog=${main_prog}
    run=${run}
    tag_name=${tag_name}
    genome=${genome}
    ctrl_genome=${ctrl_genome}
    fasta=${fasta}
    juicer=${juicer}
    out_dir=${out_dir}
" >> ${log_file}


#-- perform hybrid bwa-mem and bwa-aln mapping, 
# de-duplication, span computation, and tag clustering --#

## Perform mapping using memaln (hybrid of bwa-mem and bwa-aln)
# Report mapping start
echo "
`date` --- Mapping started for: ---
    ${run} ${tag_name}
" >> ${log_file}


${main_prog} memaln -T ${map_qual} -t ${n_thread} ${fasta} \
    ${run}.${tag_name}.fastq.gz 1> ${run}.${tag_name}.sam 2>> ${log_file}

# Compress files
pigz -p ${n_thread} ${run}.${tag_name}.sam >> ${log_file}

# Report mapping completion
echo -e "`date` --- Mapping completed ---\n" >> ${log_file}

## Pair the tags
# Report pairing start
echo -e "`date` --- Pairing paired tags ---\n" >> ${log_file}

# Pairing
${main_prog} pair -S -q ${map_qual} -t ${n_thread} -s ${self_bp} \
    ${run}.${tag_name}.sam.gz \
    1>${run}.${tag_name}.stat.xls 2>> ${log_file}

# Report pairing completion
echo -e "`date` --- ENDED ${run} cpu pair ---\n" >> ${log_file}

## Compute the span of the paired tags
# Report span computation start
echo -e "`date` --- Computing span of paired tags ---\n" >> ${log_file}

# Span computation
${main_prog} span -g -t ${n_thread} -s ${self_bp} \
    ${run}.${tag_name}.${suffix}.bam 2>> ${log_file} \
    1>${run}.${tag_name}.${suffix}.span.xls

# Report span computation completion
echo -e "`date` --- ENDED ${run} span pair --\n" >> ${log_file}


## Deduplicate the paired tags
# Report tag deduplication start
echo -e "`date` --- De-duplicating paired tags ${suffix} ---\n" >> ${log_file}

# Tag deduplication
${main_prog} dedup -g -t ${n_thread} -s ${self_bp} \
    ${run}.${tag_name}.${suffix}.bam \
    1> ${run}.${tag_name}.${suffix}.dedup.lc 2>> ${log_file}

# Remove intermediary file
rm ${run}.${tag_name}.${suffix}.cpu.dedup 2>> ${log_file}

# Report tag deduplication completion
echo -e "`date` --- ENDED ${run} cpu dedup ---" >> ${log_file}

## Compute the span of the non-redundant tags
# Report non-redundant span computation start
echo -e "`date` --- Computing span of paired tags ${suffix} nr ---\n" \
    >> ${log_file}

# Non-redundant span computation
${main_prog} span -t ${n_thread} -s ${self_bp} \
    ${run}.${tag_name}.${suffix}.nr.bam \
    2>> ${log_file} 1>${run}.${tag_name}.${suffix}.nr.span.xls

# Report non-redundant span computation completion
echo -e "`date` --- ENDED ${run} cpu dedup span ---\n" >> ${log_file}



if [[ "$pairing" == "true" ]]; then
    # Cluster tags using 500bp extension 
    echo -e "`date` --- STARTED ${run} clustering with ${extbp} bp"\
        "extension from each side --- \n" >> ${log_file}

    ${main_prog} cluster -m -s ${self_bp} -B 1000 -5 5,0 -3 3,${exten_bp} \
        -t ${n_thread} -j -x -v 1 -g  -O ${run}.e500 \
        ${run}.${tag_name}.${suffix}.nr.bam 1>> ${log_file} 2>> ${log_file}

    echo -e "`date` --- ENDED ${run} cpu clustering --- \n" >> ${log_file}


    # Rename loop files appropriately
    mv ${run}.e500.clusters.cis.chiasig.gz ${run}.e500.clusters.cis.gz
    mv ${run}.e500.clusters.trans.chiasig.gz ${run}.e500.clusters.trans.gz

    # Make subset file with intrachrom loops with PET_count >= 2
    # for browsing in Excel
    cis_file="${run}.e500.clusters.cis.gz"
    be3_file="${run}.e500.clusters.cis.BE3"
    zcat ${cis_file} | awk '{ if ( $7 >= 3 ) print }' > ${be3_file}


    ### Make .hic file for Juicebox
    ### BAM --> pairs --> hic
    # BAM to pairs
    paired_tag_bam="${run}.${tag_name}.${suffix}.nr.bam"
    ${bin_dir}/util/pairix_src/util/bam2pairs/bam2pairs -c ${chrom_sizes} \
        ${paired_tag_bam} ${run}

    # Pairs to .hic
    juicer="${bin_dir}/util/juicer_tools.1.7.5_linux_x64_jcuda.0.8.jar"
    hic_file="ChIA-PET_${genome}_${cell_type}_${ip_factor}_${run}_${run_type}_pairs.hic"

    java -Xmx2g -jar ${juicer} pre -r \
        2500000,1000000,500000,250000,100000,50000,25000,10000,5000,1000 \
        ${run}.bsorted.pairs.gz ${hic_file} ${chrom_sizes}
fi
