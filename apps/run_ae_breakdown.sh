#!/bin/bash
echo max | sudo tee /sys/fs/cgroup/limit/memory.max
echo $$ | sudo tee /sys/fs/cgroup/limit/cgroup.procs

export OMP_PROC_BIND=true
export CACHE_VIRT_SIZE=$(expr 32 \* 1024 \* 1024 \* 1024 \* 1024  )
export CACHE_CONFIG="0,87:00.0,1,0 128,88:00.0,1,0 16,27:00.0,1,0 144,28:00.0,1,0 32,23:00.0,1,0 160,24:00.0,1,0 48,03:00.0,1,0 176,04:00.0,1,0 64,c7:00.0,1,0 192,c8:00.0,1,0 80,c3:00.0,1,0 208,c4:00.0,1,0 96,a3:00.0,1,0 224,a4:00.0,1,0 112,83:00.0,1,0 240,84:00.0,1,0"
# export CACHE_CONFIG="0,/dev/nvme0n1 128,/dev/nvme1n1 16,/dev/nvme2n1 144,/dev/nvme3n1 32,/dev/nvme4n1 160,/dev/nvme5n1 48,/dev/nvme6n1 176,/dev/nvme7n1 64,/dev/nvme8n1 192,/dev/nvme9n1 80,/dev/nvme10n1 208,/dev/nvme11n1 96,/dev/nvme12n1 224,/dev/nvme13n1 112,/dev/nvme14n1 240,/dev/nvme15n1"
export CACHE_DISABLE_PARALLEL_READ_WRITE=true


TIME=$(date +"%Y%m%d:%H%M%S")

function set_schedule {
	SCHEDULE=$1
	export OMP_SCHEDULE="${SCHEDULE}"
}

mkdir -p results_ligra_breakdown

export CACHE_MALLOC_THRESHOLD=$(expr 4294967296 \* 2)
set_schedule "dynamic,64"
for threads in 960
do
    export CACHE_NUM_CLIENTS=$threads
    export OMP_NUM_THREADS=$threads

    for i in 64
    do
        echo $(expr \( $i \/ 8 + 27 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( $i - $i \/ 8 - 27 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta-cache -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results_ligra_breakdown/PageRank_uk-2014.txt

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta-cache-profile -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results_ligra_breakdown/PageRank_uk-2014_profile.txt

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta-cache-disable-direct -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results_ligra_breakdown/PageRank_uk-2014_disable_direct.txt

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta-cache-disable-private -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results_ligra_breakdown/PageRank_uk-2014_disable_private.txt

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta-cache-disable-direct-private -maxiters 20 -rounds 1 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results_ligra_breakdown/PageRank_uk-2014_disable_direct_private.txt

    done
done

