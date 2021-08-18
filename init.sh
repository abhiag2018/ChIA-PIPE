#!/bin/bash

## The help message:
function usage
{
    echo -e "usage: bash 0.chia_pipe_shell.sh -c CONF
    " 
}


## The help message:
function usage
{
    echo -e "usage: bash 0.chia_pipe_shell.sh -c CONF [-t tag-name -m map_qual -s suffix] [-p]
    " 
}

pairing="false"
## Parse the command-line argument (i.e., get the name of the config file)
while [ "$1" != "" ]; do
    case $1 in
        -c | --conf )           shift
                                conf=$1
                                ;;
        -t | --tag )            shift
                                tag_name=$1
                                ;;
        -m | --mapq )           shift
                                map_qual=$1
                                ;;
        -s | --suffix )         shift
                                suffix=$1
                                ;;
        -p | --pairing )        shift
                                pairing="true"
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
source ${conf}

## Add dependency dir to path
#workdir=$( pwd)
#dep_dir=$( cd ${dep_dir} && pwd )
#export PATH=${dep_dir}:${PATH}
#cd ${workdir}

# Set the output directory for writing files
out_dir="${run}"
mkdir -p ${out_dir}
cd ${out_dir}

# Print values
echo ${conf}
echo ${out_dir}

# Set the resource parameters for the computing cluster
# depending on the run type (miseq or hiseq)
n_thread=1
mem=8
    