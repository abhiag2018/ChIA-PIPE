#!/bin/bash

# ChIA-PIPE
#         Starting point for launching ChIA-PIPE
# 2018
# The Jackson Laboratory for Genomic Medicine

## The help message:
function usage
{
    echo -e "usage: bash 0.chia_pipe_shell.sh -c CONF
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

step1.sh -c ${conf}

step2.sh -c ${conf} -t none -m 30 -s UU
step2.sh -c ${conf} -t singlelinker.single -m 10 -s UxxU
step2.sh -c ${conf} -t halflinker -m 30 -s UxxU
step2.sh -c ${conf} -t singlelinker.paired -m 30 -s UU
step2.sh -c ${conf} -t fulllinker.chimeric.single -m 30 -s UxxU
step2.sh -c ${conf} -t fulllinker.chimeric.paired -m 30 -s UxxU
step2.sh -c ${conf} -t FullLinker.NonChimeric.single -m 30 -s xx
step2.sh -c ${conf} -t FullLinker.NonChimeric.paired -m 30 -s UxxU -p

step3.sh -c ${conf}

step4.sh -c ${conf}

step5.sh -c ${conf}


####### Debugging Commands


## move output of steps 
# mkdir stepNN
# mv *.* stepNN/

## remove symbolic links
# find -type l -delete

## create links for all files inside stepNN directory  
# ln -s stepNN/* .

## find all files at depth 1 
# find -maxdepth 1 -type f

## run stepNN in sbatch 
## sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 stepNN.sh -c mouse_config_test.sh
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step1.sh -c mouse_config_test.sh

# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2.sh -c mouse_config_test.sh -t none -m 30 -s UU 
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2.sh -c mouse_config_test.sh -t singlelinker.single -m 10 -s UxxU 
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2.sh -c mouse_config_test.sh -t singlelinker.paired -m 30 -s UU 
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2.sh -c mouse_config_test.sh -t fulllinker.chimeric.single -m 30 -s UxxU 
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2.sh -c mouse_config_test.sh -t fulllinker.chimeric.paired -m 30 -s UxxU 
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2.sh -c mouse_config_test.sh -t FullLinker.NonChimeric.single -m 30 -s xx 
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2.sh -c mouse_config_test.sh -t FullLinker.NonChimeric.paired -m 30 -s UxxU -p 

# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step3.sh -c mouse_config_test.sh
