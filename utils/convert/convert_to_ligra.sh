#!/bin/bash
echo $$ | sudo tee /sys/fs/cgroup/limit/cgroup.procs
echo max | sudo tee /sys/fs/cgroup/limit/memory.max

export OMP_PROC_BIND=true
export CACHE_VIRT_SIZE=$(expr 32 \* 1024 \* 1024 \* 1024 \* 1024)

export CACHE_MALLOC_THRESHOLD=$(expr 32 \* 1024 \* 1024)

#export CACHE_DISABLE_PARALLEL_READ_WRITE

export CACHE_CONFIG="0,87:00.0,1,0 128,88:00.0,1,0 16,27:00.0,1,0 144,28:00.0,1,0 32,23:00.0,1,0 160,24:00.0,1,0 48,03:00.0,1,0 176,04:00.0,1,0 64,c7:00.0,1,0 192,c8:00.0,1,0 80,c3:00.0,1,0 208,c4:00.0,1,0 96,a3:00.0,1,0 224,a4:00.0,1,0 112,83:00.0,1,0 240,84:00.0,1,0"

export THREADS=240
export CACHE_NUM_CLIENTS=$(expr $THREADS \+ 16 \* 4)
export OMP_NUM_THREADS=$THREADS

export CACHE_PHY_SIZE=$(expr 250 \* 1024 \* 1024 \* 1024)

sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" stdbuf -oL /usr/bin/time -v numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
    ./convert_to_ligra /mnt/data0/jiguanglizipao/DataSet/uk-2014.bin /mnt/data1/jiguanglizipao/uk-2014
    # ./convert_to_ligra /mnt/data1/jiguanglizipao/uk-2014.txt /mnt/data1/jiguanglizipao/uk-2014

