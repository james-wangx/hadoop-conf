#!/bin/bash

for host in master slave1 slave2
do
        echo ========== $host ==========
        ssh $host jps
done