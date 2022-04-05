// This code is part of the project "Ligra: A Lightweight Graph Processing
// Framework for Shared Memory", presented at Principles and Practice of 
// Parallel Programming, 2013.
// Copyright (c) 2013 Julian Shun and Guy Blelloch
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights (to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#include "ligra.h"

struct CC_F {
  uintE* IDs, *prevIDs;
  CC_F(uintE* _IDs, uintE* _prevIDs) : 
    IDs(_IDs), prevIDs(_prevIDs) {}
  inline bool update(uintE s, uintE d){ //Update function writes min ID
    uintE origID = IDs[d];
    if(IDs[s] < origID) {
      IDs[d] = min(origID,IDs[s]);
      if(origID == prevIDs[d]) return 1;
    } return 0; }
  inline bool updateAtomic (uintE s, uintE d) { //atomic Update
    uintE origID = IDs[d];
    return (writeMin(&IDs[d],IDs[s]) && origID == prevIDs[d]);
  }
  inline bool cond (uintE d) { return cond_true(d); } //does nothing
};

inline bool IDupdate(uintE *u, uintE new_value) {
  uintE cur = *u;
  bool r;
  do cur = *u; 
  while (cur / 2 > new_value / 2 && !(r = CAS(u, cur, new_value)));
  return r && (cur % 2 == 1);
}

struct CC2_F {
  uintE* IDs;
  CC2_F(uintE* _IDs) : IDs(_IDs) {}
  inline bool update(uintE s, uintE d) {
    uintE origID = IDs[d];
    if (IDs[s] / 2 < origID / 2) {
      uintE previous = IDs[d];
      IDs[d] = IDs[s] / 2 * 2;
      return previous & 1;
    }
    return 0;
  }
  inline bool updateAtomic(uintE s, uintE d) {
    return IDupdate(&IDs[d], IDs[s] / 2 * 2);
  }
  inline bool cond(uintE d) { return cond_true(d); }
};

//function used by vertex map to sync prevIDs with IDs
struct CC_Vertex_F {
  uintE* IDs, *prevIDs;
  CC_Vertex_F(uintE* _IDs, uintE* _prevIDs) :
    IDs(_IDs), prevIDs(_prevIDs) {}
  inline bool operator () (uintE i) {
    prevIDs[i] = IDs[i];
    return 1; }};

struct CC2_Vertex_F{
  uintE* IDs;
  CC2_Vertex_F(uintE *_IDs) : IDs(_IDs) {}
  inline bool operator() (uintE i) {
    IDs[i] |= 1;
    return 1;
  }
};

template <class vertex>
void Compute(graph<vertex>& GA, commandLine P) {
  long n = GA.n;
  uintE* IDs = newA(uintE,n); //, *prevIDs = newA(uintE,n);
  {parallel_for(long i=0;i<n;i++) IDs[i] = i * 2 + 1;} //initialize unique IDs

  bool* frontier = newA(bool,n);
  {parallel_for(long i=0;i<n;i++) frontier[i] = 1;} 
  vertexSubset Frontier(n,n,frontier); //initial frontier contains all vertices

  while(!Frontier.isEmpty() && Frontier.numNonzeros() != 0){ //iterate until IDS converge
    vertexMap(Frontier,CC2_Vertex_F(IDs));
    vertexSubset output = edgeMap(GA, Frontier, CC2_F(IDs), INT_MAX);
    Frontier.del();
    Frontier = output;
  }
  {parallel_for(long i = 0;i < n; i++) IDs[i] = IDs[i] / 2; }

  // long num_components = 0;
  // #pragma omp parallel for schedule(runtime) reduction(+:num_components)
  // for(long i=0;i<n;i++) num_components += IDs[i] == i;
  // printf("number of communities: %lu\n", num_components);

  Frontier.del(); free(IDs); //free(prevIDs);
}
