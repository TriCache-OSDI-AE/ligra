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
PCFLAGS = -std=c++14 -fopenmp -march=native -O3 -DOPENMP $(INTT) $(INTE) $(CODE) $(PD) $(MEM)

CACHE_PATH=/home/jiguanglizipao/ScalableCache/build-new
CACHE_PCFLAGS = -std=c++14 -fopenmp -march=native -O3 -DOPENMP $(INTT) $(INTE) $(CODE) $(PD) $(MEM) -DWITH_CACHE -fpass-plugin=$(CACHE_PATH)/llvm-plugin/ScalableCacheInstrument/ScalableCacheInstrument.so -fpass-plugin=$(CACHE_PATH)/llvm-plugin/ScalableCacheAlloc/ScalableCacheAlloc.so -L$(CACHE_PATH) -flto=thin
CACHE_LDFLAGS = -pthread -lboost_fiber -lboost_context -lboost_thread -lnuma -pthread -ldl -fopenmp $(shell pkg-config --libs spdk_nvme spdk_env_dpdk spdk_syslibs)

else
PCC = g++
PCFLAGS = -std=c++14 -O3 $(INTT) $(INTE) $(CODE) $(PD) $(MEM)
endif

COMMON= ligra.h graph.h compressedVertex.h vertex.h utils.h IO.h parallel.h gettime.h index_map.h maybe.h sequence.h edgeMap_utils.h binary_search.h quickSort.h blockRadixSort.h transpose.h parseCommandLine.h byte.h byteRLE.h nibble.h byte-pd.h byteRLE-pd.h nibble-pd.h vertexSubset.h encoder.C decoder.C

ALL= encoder decoder BFS BC BellmanFord Components Components-Shortcut Radii PageRank PageRankDelta BFSCC BFS-Bitvector KCore MIS Triangle CF

ALL_CACHE= BFS-cache Components-cache PageRankDelta-cache
ALL_CACHE_PROFILE= BFS-cache-profile Components-cache-profile PageRankDelta-cache-profile
ALL_CACHE_DISABLE_DIRECT= BFS-cache-disable-direct Components-cache-disable-direct PageRankDelta-cache-disable-direct
ALL_CACHE_DISABLE_PRIVATE= BFS-cache-disable-private Components-cache-disable-private PageRankDelta-cache-disable-private
ALL_CACHE_DISABLE_DIRECT_PRIVATE= BFS-cache-disable-direct-private Components-cache-disable-direct-private PageRankDelta-cache-disable-direct-private

all: $(ALL) $(ALL_CACHE) $(ALL_CACHE_PROFILE) $(ALL_CACHE_DISABLE_DIRECT) $(ALL_CACHE_DISABLE_PRIVATE) $(ALL_CACHE_DISABLE_DIRECT_PRIVATE)

% : %.C $(COMMON)
	$(PCC) $< -o $@ $(PCFLAGS) 

%-cache : %.C $(COMMON)
	$(PCC) $< -o $@ $(CACHE_PCFLAGS) -lcache $(CACHE_LDFLAGS)

%-cache-profile : %.C $(COMMON)
	$(PCC) $< -o $@ $(CACHE_PCFLAGS) -lcache-profile $(CACHE_LDFLAGS)

%-cache-disable-direct : %.C $(COMMON)
	$(PCC) $< -o $@ $(CACHE_PCFLAGS) -lcache-disable-direct $(CACHE_LDFLAGS)

%-cache-disable-private : %.C $(COMMON)
	$(PCC) $< -o $@ $(CACHE_PCFLAGS) -lcache-disable-private $(CACHE_LDFLAGS)

%-cache-disable-direct-private : %.C $(COMMON)
	$(PCC) $< -o $@ $(CACHE_PCFLAGS) -lcache-disable-direct-private $(CACHE_LDFLAGS)

$(COMMON):
	ln -s ../ligra/$@ .

.PHONY : clean

clean :
	rm -f *.o $(ALL) $(ALL_CACHE) $(ALL_CACHE_PROFILE) $(ALL_CACHE_DISABLE_DIRECT) $(ALL_CACHE_DISABLE_PRIVATE) $(ALL_CACHE_DISABLE_DIRECT_PRIVATE)

cleansrc :
	rm -f *.o $(ALL) $(ALL_CACHE) $(ALL_CACHE_PROFILE) $(ALL_CACHE_DISABLE_DIRECT) $(ALL_CACHE_DISABLE_PRIVATE) $(ALL_CACHE_DISABLE_DIRECT_PRIVATE)
	rm $(COMMON)
