#!/bin/bash
echo max | sudo tee /sys/fs/cgroup/limit/memory.max
echo $$ | sudo tee /sys/fs/cgroup/limit/cgroup.procs
export OMP_PROC_BIND=true

TIME=$(date +"%Y%m%d:%H%M%S")
function set_schedule {
	SCHEDULE=$1
	export OMP_SCHEDULE="${SCHEDULE}"
}

export MALLOC_PATH="${TIME}"

mkdir -p results/$MALLOC_PATH
cp $0 results/$MALLOC_PATH

sudo ~/setvm.sh

for threads in 256
do
    export OMP_NUM_THREADS=$threads

    for i in 512
    do
        echo $(expr \( $i \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        set_schedule "dynamic,256"
        stdbuf -oL /usr/bin/time -v numactl -i all ./BFS -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}.txt
        set_schedule "guided"
        stdbuf -oL /usr/bin/time -v numactl -i all ./PageRankDelta -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRankDelta_uk-2014_${i}G_${threads}.txt
        stdbuf -oL /usr/bin/time -v numactl -i all ./Components -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}.txt
    done
done

echo 1 | sudo tee /proc/sys/vm/swappiness

for threads in 256
do
    export OMP_NUM_THREADS=$threads

    for i in 256
    do
        echo $(expr \( $i \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        set_schedule "dynamic,64"
        stdbuf -oL /usr/bin/time -v numactl -i all ./BFS -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}.txt
        set_schedule "static,64"
        stdbuf -oL /usr/bin/time -v numactl -i all ./PageRankDelta -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRankDelta_uk-2014_${i}G_${threads}.txt
        set_schedule "dynamic,64"
        stdbuf -oL /usr/bin/time -v numactl -i all ./Components -rounds 1 -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}.txt
    done
done

set_schedule "dynamic,64"
for threads in 256
do
    export OMP_NUM_THREADS=$threads

    for i in 128 64 32 16
    do
        echo $(expr \( $i \) \* 1024 \* 1024 \* 1024) | sudo tee /sys/fs/cgroup/limit/memory.max
        stdbuf -oL /usr/bin/time -v numactl -i all ./BFS -rounds 1 -r 5 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/BFS_uk-2014_${i}G_${threads}.txt
        stdbuf -oL /usr/bin/time -v numactl -i all ./PageRankDelta -rounds 1 -maxiters 20 -b /mnt/data/TriCache/ligra/uk-2014 2>&1 | tee results/$MALLOC_PATH/PageRankDelta_uk-2014_${i}G_${threads}.txt
        stdbuf -oL /usr/bin/time -v numactl -i all ./Components -rounds 1 -s -b /mnt/data/TriCache/ligra/uk-2014-sym 2>&1 | tee results/$MALLOC_PATH/CC_uk-2014_${i}G_${threads}.txt
    done
done
