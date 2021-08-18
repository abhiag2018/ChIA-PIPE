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

step2a.sh -c ${conf}
step2b.sh -c ${conf}
step2c.sh -c ${conf}
step2d.sh -c ${conf}
step2e.sh -c ${conf}
step2f.sh -c ${conf}
step2g.sh -c ${conf}

step3.sh -c ${conf}
step4.sh -c ${conf}
step5.sh -c ${conf}


####### Debugging Commands

# run stepNN in sbatch 
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 stepNN.sh -c mouse_config_test.sh

# move output of steps 
# mkdir stepNN
# mv *.* stepNN/

# remove symboliv links
# find -type l -delete

# create links for all files inside stepNN directory  
# ln -s stepNN/* .

# find all files at depth 1 
# find -maxdepth 1 -type f

# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step1.sh -c mouse_config_test.sh

# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2a.sh -c mouse_config_test.sh
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2b.sh -c mouse_config_test.sh
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2c.sh -c mouse_config_test.sh
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2d.sh -c mouse_config_test.sh
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2e.sh -c mouse_config_test.sh
# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step2f.sh -c mouse_config_test.sh

# sbatch -q batch -N 1 -n 8 --mem 40G -t 0-10:00 step3.sh -c mouse_config_test.sh
