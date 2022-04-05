ifdef LONG
INTT = -DLONG
endif

ifdef EDGELONG
INTE = -DEDGELONG
endif

ifdef PD
PD = -DPD
endif

ifdef BYTE
CODE = -DBYTE
else ifdef NIBBLE
CODE = -DNIBBLE
else
CODE = -DBYTERLE
endif

ifdef LOWMEM
MEM = -DLOWMEM
endif

#compilers
ifdef CILK
PCC = g++
PCFLAGS = -std=c++14 -fcilkplus -lcilkrts -O3 -DCILK $(INTT) $(INTE) $(CODE) $(PD) $(MEM)
PLFLAGS = -fcilkplus -lcilkrts

else ifdef MKLROOT
PCC = icpc
PCFLAGS = -std=c++14 -O3 -DCILKP $(INTT) $(INTE) $(CODE) $(PD) $(MEM)

else ifdef OPENMP
# PCC = g++
# PCFLAGS = -std=c++14 -fopenmp -march=native -O3 -DOPENMP $(INTT) $(INTE) $(CODE) $(PD) $(MEM)
PCC = clang++-13
# PCFLAGS = -std=c++14 -fopenmp -march=native -O3 -DOPENMP $(INTT) $(INTE) $(CODE) $(PD) $(MEM)
PCFLAGS = -std=c++14 -fopenmp -march=native -O3 -DOPENMP $(INTT) $(INTE) $(CODE) $(PD) $(MEM) -DWITH_CACHE -fpass-plugin=/home/jiguanglizipao/ScalableCache/build-new/llvm-plugin/ScalableCacheInstrument/ScalableCacheInstrument.so -fpass-plugin=/home/jiguanglizipao/ScalableCache/build-new/llvm-plugin/ScalableCacheAlloc/ScalableCacheAlloc.so -L/home/jiguanglizipao/ScalableCache/build-new -flto=thin -lcache -pthread -lboost_fiber -lboost_context -lboost_thread -lnuma -pthread -ldl -fopenmp $(shell pkg-config --libs spdk_nvme spdk_env_dpdk spdk_syslibs) -L/home/blealtancao/mimalloc/install/lib -lmimalloc

else
PCC = g++
PCFLAGS = -std=c++14 -O3 $(INTT) $(INTE) $(CODE) $(PD) $(MEM)
endif

COMMON= ligra.h graph.h compressedVertex.h vertex.h utils.h IO.h parallel.h gettime.h index_map.h maybe.h sequence.h edgeMap_utils.h binary_search.h quickSort.h blockRadixSort.h transpose.h parseCommandLine.h byte.h byteRLE.h nibble.h byte-pd.h byteRLE-pd.h nibble-pd.h vertexSubset.h encoder.C decoder.C

ALL= encoder decoder BFS BC BellmanFord Components Components-Shortcut Radii PageRank PageRankDelta BFSCC BFS-Bitvector KCore MIS Triangle CF

all: $(ALL)

% : %.C $(COMMON)
	$(PCC) $< -o $@ $(PCFLAGS) 

$(COMMON):
	ln -s ../ligra/$@ .

.PHONY : clean

clean :
	rm -f *.o $(ALL)

cleansrc :
	rm -f *.o $(ALL)
	rm $(COMMON)
