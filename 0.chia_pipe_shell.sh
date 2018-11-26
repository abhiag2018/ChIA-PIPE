#!/bin/bash
#PBS -l nodes=1:ppn=1
#PBS -l walltime=1:00:00
#PBS -l mem=2GB
#PBS -l vmem=2GB
#PBS -j oe


# ChIA-PET Tool 2
#         Starting point for launching ChIA-PET Tool 2
# 2017
# The Jackson Laboratory for Genomic Medicine

## The help message:
function usage
{
    echo -e "usage: bash 0.chia_pet_tool_2.pbs -c CONF
    " 
}

## Parse the command-line argument (i.e., get the name of the config file)
while [ "$1" != "" ]; do
    case $1 in
        -c | --conf )           shift
                                conf=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done


# Source the config file to get the parameter values
conf="${PBS_O_WORKDIR}/${conf}"
source ${conf}

# Add dependency dir to path
export PATH=${PATH}:${dep_dir}

# Set the output directory for writing files
out_dir="${PBS_O_WORKDIR}/${run}"
mkdir -p ${out_dir}

# Print values
echo ${conf}
echo ${out_dir}

# Set the resource parameters for the computing cluster
# depending on the run type (miseq or hiseq)
n_thread=20
mem=60
    
if [ ${run_type} == "miseq" ]
then
    wall_time=5
elif [ ${run_type} == "hiseq" ] || [ ${run_type} == "nextseq" ]
then
    wall_time=10
else
    wall_time=20
fi


### 1. Linker filtering
# Submit the job
job_1=$( qsub -F "--conf ${conf} --out_dir ${out_dir}" \
-l nodes=1:ppn=${n_thread},mem=${mem}gb,vmem=${mem}gb,walltime=${wall_time}:00:00 \
-j oe -o ${out_dir}/1.${run}.filter_linker.o \
${bin_dir}/1.filter_linker.pbs )

