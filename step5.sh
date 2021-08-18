#!/bin/bash

source init.sh

###############
############### 5. Phase loops

if [ ${all_steps} == true ] && [ ${snp_file} != "none" ]
then
    ## Create name of the log file
    log_file=5.${run}.phase_loops.log

    # Print arguments to ensure correct parsing
    echo "
    Arguments:
        run=${run}
        fasta=${fasta}
        snp_file=${snp_file}
        out_dir=${out_dir}
        bin_dir=${bin_dir}
    " >> ${log_file}
    
    # Create file names
    bam_file=${run}.for.BROWSER.bam
    loop_file=${run}.e500.clusters.cis.BE3
    pileup_file=${run}.total_snp_pileup.txt

    if [ ${peak_caller} == "spp" ] || [ ${peak_caller} == "SPP" ]
    then
        peak_file=${run}.for.BROWSER.spp.z6.broadPeak
    else
        peak_file=${run}.no_input_all_peaks.narrowPeak
    fi
    
    # Separate the SNP file into one file for each chromosome
    # (named after the chromosome)
    echo -e "`date` Splitting SNP file by chromosome..\n" >> ${log_file}

    awk '{ print >> "temp_"$1 }' ${snp_file}


    # Count the SNP alleles for each chromosome
    echo -e "`date` Counting SNP alleles on each chromosome..\n" >> ${log_file}

    ### Get chromosome names from the fasta file
    chroms=$(grep ">" ${fasta} | sed -e "s/>//g")
    echo -e "`date` Detected the following chroms in the FASTA file..\n" \
        >> ${log_file}

    for chrom in ${chroms}
    do
        echo -e "\t${chrom}" >> ${log_file}
    done


    ### Pileup chromosomes
    echo -e "`date` Performing mpileup on chromosome:\n" \
        >> ${log_file}

    job_ids=()

    for chrom in ${chroms}
    do
        # Skip chrM
        if [ ${chrom} == 'chrM' ] || [ ${chrom} == 'chrY' ]
        then
            echo -e "\t (Skipping ${chrom})" >> ${log_file}
            continue
        fi
    
        # Create a separate PBS job for each chromosome
        # to count SNP alleles with samtools
        echo -e "\t ${chrom}" >> ${log_file}
        job_name="temp_job_${chrom}"
    
        # Change to output directory and load modules
        pbs="cd ${out_dir};"
        pbs+="module load samtools/0.1.19;"
    
        # Samtools command
        # By default, samtools/0.1.19 has BAQ filtering ON
        # It is important to retain this if changing to a different version
        pbs+="samtools mpileup -f ${fasta} "
        pbs+="-l temp_${chrom} ${bam_file} "
        pbs+="> temp_counts.${chrom}.mileup"
    
        # Submit job
        jid=$( echo -e ${pbs} 2>> ${log_file} | \
            qsub -l nodes=1:ppn=20,mem=60gb,walltime=8:00:00 -N ${job_name})
        sleep 0.5
        job_ids+=" ${jid}"
    done


    # Wait for all chromosome jobs to finish
    echo -e "`date` Waiting for job completion... \n" >> ${log_file}

    for jid in ${job_ids}
    do
        echo -e "\t${jid}" >> ${log_file}
    
        while [ -n "$( qstat | grep ${jid} )" ]
        do
            sleep 1
        done
    done

    # Report completion of counting SNP alleles
    echo -e "`date` Completed counting SNP alleles..\n" >> ${log_file}


    ### Merge SNP allele counts from all chromosomes
    echo -e "`date` Merging SNP allele counts from all chroms..\n" \
        >> ${log_file}

    cat *mileup | awk 'BEGIN{FS="\t";OFS="\t"}{chrom=$1;pos=$2;ref=$3;\
    num=$4+$7+$10;bases=$5""$8""$11;qual=$6""$9""$12;\
    print chrom,pos,ref,num,bases,qual}' | awk 'NF==6{print}' \
        > ${pileup_file}

    echo -e "`date` Completed merging SNP allele counts..\n" >> ${log_file}


    # Remove temporary files
    echo -e "`date` Removing temp files..\n" >> ${log_file}

    #rm temp_*

    echo -e "`date` Completed removing temp files..\n" >> ${log_file}

    ### Count phased SNPs
    # Do binomial test to identify significantly biased SNPs
    # Output file name: phased_snp_qvalue.txt
    echo -e "`date` Counting SNP allele bias and assessing significance.." \ 
        >> ${log_file}

    # Allele-biased SNPs (R)
    Rscript ${bin_dir}/compute_phased_SNP.R \
        ${run} ${pileup_file} ${snp_file} TRUE 0.1

    # Create BED file of All SNPs
    cat ${run}.snp_qvalues.txt | grep -v biased | awk -v OFS='\t' \
        '{ print $1, $2, $2+200, $7, "+", $4, $5, $6, "153,153,153"}' \
        > ${run}.snp_qvalues.bed

    # Create BED file of Phased SNPs
    cat ${run}.snp_qvalues.txt | grep Yes | awk -v OFS='\t' \
        '{ 
        if ($4 >= $5) 
            print $1, $2, $2+200, $7, "+", $4, $5, $6, "26,152,80"
        else
            print $1, $2, $2+200, $7, "+", $4, $5, $6, "215,48,39"
        }' \
        > ${run}.snp_qvalues.phased.bed


    # Make bedgraph of Paternal allele counts
    cat phased_snp_qvalue.txt | grep -v biased | \
        awk -v OFS='\t' '{ print $1, $2, $2+100, $4 }' \
        > ${run}.snp_coverage.Paternal.100.bedgraph

    # Make bedgraph of maternal allele counts
    cat phased_snp_qvalue.txt | grep -v biased | \
        awk -v OFS='\t' '{ print $1, $2, $2+10, $5 }' \
        > ${run}.snp_coverage.Maternal.10.bedgraph


    echo -e "`date` Completed counting SNP allele bias..\n" >> ${log_file}


    #######
    cat phased_snp_qvalue.Yes.txt | grep -v biased | \
        awk -v OFS='\t' '{ print $1, $2, $2+1, $4 }' \
        > ${run}.snp_coverage.Yes.Paternal.1.bedgraph
    ########


    ### Compute phased interactions
    # phased_snp_qvalue.txx is generated by last step
    # (non-overlapping)
    echo "`date` Identifying biased loops (from raw loops and biased SNPs)..
    " >> ${log_file}
    
    perl ${bin_dir}/compute_phased_loops.pl \
        phased_snp_qvalue.txt ${peak_file} ${loop_file}
    
    # Create two subset BED files
    # BED file of only phased peaks
    cat ${peak_file}.SNP_Phased.browser.bed | grep -v Unphased \
        > ${peak_file}.SNP_Phased.Paternal_or_Maternal.bed

    # BED file of only unphased peaks
    cat ${peak_file}.SNP_Phased.browser.bed | grep Unphased \
        > ${peak_file}.SNP_Phased.Unphased.bed
    
    echo -e "`date` Completed identifying biased loops..\n" >> ${log_file}
    echo "`date` $0 done" >> ${log_file}
fi
