ifdef LONG
INTT = -DLONG
endif

ifdef EDGELONG
INTE = -DEDGELONG
endif

#compilers
ifdef CILK
PCC = g++
PCFLAGS = -std=c++14 -fcilkplus -lcilkrts -O3 -DCILK $(INTT) $(INTE)
PLFLAGS = -fcilkplus -lcilkrts

else ifdef MKLROOT
PCC = icpc
PCFLAGS = -std=c++14 -O3 -DCILKP $(INTT) $(INTE)

else ifdef OPENMP
PCC = clang++-13
PCFLAGS = -std=c++14 -fopenmp -march=native -O3 -DOPENMP $(INTT) $(INTE)
#PCFLAGS = -std=c++14 -fopenmp -march=native -O3 -DOPENMP $(INTT) $(INTE) -fpass-plugin=/home/jiguanglizipao/ScalableCache/build-libcache/llvm-plugin/ScalableCacheInstrument/ScalableCacheInstrument.so -fpass-plugin=/home/jiguanglizipao/ScalableCache/build-libcache/llvm-plugin/ScalableCacheAlloc/ScalableCacheAlloc.so -I/home/jiguanglizipao/cache_bind/ -L/home/jiguanglizipao/cache_bind/ -L/usr/lib/llvm-13/lib /home/jiguanglizipao/cache_bind/libcache.a -pthread -lboost_fiber -lboost_context -lboost_thread -lnuma -pthread -ldl -fopenmp $(shell pkg-config --libs spdk_nvme spdk_env_dpdk spdk_syslibs) -flto=thin 

else
PCC = g++
PCFLAGS = -std=c++14 -O3 $(INTT) $(INTE)
endif

COMMON = utils.h parseCommandLine.h parallel.h quickSort.h blockRadixSort.h transpose.h
LOCAL_COMMON = graphIO.h
GENERATORS = rMatGraph gridGraph randLocalGraph SNAPtoAdj wghSNAPtoAdj adjGraphAddWeights adjToBinary communityToHyperAdj hyperAdjToBinary adjHypergraphAddWeights randHypergraph KONECTtoHyperAdj KONECTtoClique communityToClique communityToMESH KONECTtoMESH adjToDualBinary

.PHONY: all clean
all: $(GENERATORS)

$(COMMON):
	ln -s ../ligra/$@ .

% : %.C $(COMMON) $(LOCAL_COMMON)
	$(PCC) $< $(PCFLAGS) -o $@

clean :
	rm -f *.o $(GENERATORS)

cleansrc :
	make -s clean
	rm -f $(COMMON)
