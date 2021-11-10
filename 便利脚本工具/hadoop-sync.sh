#!/bin/bash

if [ $# -lt 1 ]
then
    echo Not Enough Arguement
    exit;
fi

for host in master slave1 slave2
do
    echo ========== $host ==========
    for file in $@
    do
        if [ -e $file ]
        then
            pdir=$(cd -P $(dirname $file); pwd)
            
            fname=$(basename $file)
            ssh $host "mkdir -p $pdir"
            rsync -av $pdir/$fname $host:$pdir
        else
            echo $file does not exists!
        fi
    done
done