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

export MALLOC_PATH="${TIME}"
mkdir -p results/$MALLOC_PATH
cp $0 results/$MALLOC_PATH

export CACHE_MALLOC_THRESHOLD=$(expr 4294967296 \* 32)
for threads in 240
do
    export CACHE_NUM_CLIENTS=$threads
    export OMP_NUM_THREADS=$threads

    for i in 512
    do
        echo $(expr \( $i - 360 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( 360 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

        set_schedule "dynamic,256"
 	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
             stdbuf -oL /usr/bin/time -v ./BFS -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

        set_schedule "guided"
        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
             stdbuf -oL /usr/bin/time -v ./PageRankDelta -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRank_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

 	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
             stdbuf -oL /usr/bin/time -v ./Components -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

    done
done

export CACHE_MALLOC_THRESHOLD=$(expr 4294967296 \* 32)
for threads in 240
do
    export CACHE_NUM_CLIENTS=$threads
    export OMP_NUM_THREADS=$threads

    for i in 256
    do
        echo $(expr \( $i - 185 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( 185 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

        set_schedule "dynamic,256"
 	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
             stdbuf -oL /usr/bin/time -v ./BFS -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

    done
done

export CACHE_MALLOC_THRESHOLD=$(expr 4294967296 \* 32)
for threads in 480
do
    export CACHE_NUM_CLIENTS=$threads
    export OMP_NUM_THREADS=$threads

    for i in 256
    do
        echo $(expr \( $i \/ 8 + 80 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( $i - $i \/ 8 - 80 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

        set_schedule "static,64"
        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRank_uk-2014_${i}G_${threads}_${SCHEDULE}.txt


        set_schedule "dynamic,64"
	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./Components -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

    done
done

export CACHE_MALLOC_THRESHOLD=$(expr 4294967296 \* 4)
set_schedule "dynamic,128"
for threads in 960
do
    export CACHE_NUM_CLIENTS=$threads
    export OMP_NUM_THREADS=$threads

    for i in 128
    do
        echo $(expr \( $i \/ 8 + 48 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( $i - $i \/ 8 - 48 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./BFS -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRank_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./Components -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

    done
done

export CACHE_MALLOC_THRESHOLD=$(expr 4294967296 \* 2)
set_schedule "dynamic,64"
for threads in 960
do
    export CACHE_NUM_CLIENTS=$threads
    export OMP_NUM_THREADS=$threads

    for i in 64
    do
        echo $(expr \( $i \/ 8 + 26 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( $i - $i \/ 8 - 26 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./BFS -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRank_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./Components -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

    done
done

export CACHE_MALLOC_THRESHOLD=$(expr 4294967296 \* 2)
set_schedule "dynamic,64"
for threads in 960
do
    export CACHE_NUM_CLIENTS=$threads
    export OMP_NUM_THREADS=$threads

    for i in 32
    do
        echo $(expr \( $i \/ 8 + 24 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( $i - $i \/ 8 - 24 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./BFS -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./Components -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

        echo $(expr \( $i \/ 8 + 27 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( $i - $i \/ 8 - 27 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRank_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

    done
done

export CACHE_MALLOC_THRESHOLD=1073741824
set_schedule "static,64"
for threads in 960
do
    export CACHE_NUM_CLIENTS=$threads
    export OMP_NUM_THREADS=$threads

    for i in 16
    do
        echo $(expr \( $i \/ 8 + 10 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( $i - $i \/ 8 - 10 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./BFS -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

	    sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./PageRankDelta -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRank_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

        echo $(expr \( $i \/ 8 + 11 \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        export CACHE_PHY_SIZE=$(expr \( $i - $i \/ 8 - 11 \) \* 1024 \* 1024 \* 1024 )
        echo $CACHE_PHY_SIZE $CACHE_VIRT_SIZE

        sudo -E LD_LIBRARY_PATH="$LD_LIBRARY_PATH" numactl -i all -C !0,128,16,144,32,160,48,176,64,192,80,208,96,224,112,240 \
            stdbuf -oL /usr/bin/time -v ./Components -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}_${SCHEDULE}.txt

    done
done
