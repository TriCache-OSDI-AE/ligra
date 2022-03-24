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

//Version of BFS that uses a bitvector to mark visited vertices. Works
//better than BFS.C when bitvector fits in cache but Parents array
//does not.
#include "ligra.h"
//atomically do bitwise-OR of *a with b and store in location a
template <class ET>
inline void writeOr(ET *a, ET b) {
  volatile ET newV, oldV; 
  do {oldV = *a; newV = oldV | b;}
  while ((oldV != newV) && !CAS(a, oldV, newV));
}

struct BFS_F {
  long* Visited;
  BFS_F(long* _Visited) 
  : Visited(_Visited) {}
  inline bool update (uintE s, uintE d) { //Update
    writeOr(&Visited[d/64], Visited[d/64] | ((long)1 << (d % 64)));
    return 1;
  }
  inline bool updateAtomic (uintE s, uintE d){ //atomic version of Update
    //writeOr(&Visited[d/64], Visited[d/64] | ((long)1 << (d % 64)));
    long cur;
    do {
	cur = Visited[d/64];
    	if (cur >> (d%64) & 1) return 0;
    } while (!CAS(&Visited[d/64], cur, cur | (1l << d%64)));
    return 1;  
  }
  //cond function checks if vertex has been visited yet
  inline bool cond (uintE d) { 
    return (!(Visited[d/64] & ((long)1 << (d % 64)))); }
};

template <class vertex>
void Compute(graph<vertex>& GA, commandLine P) {
  long start = P.getOptionLongValue("-r",0);
  long n = GA.n;
  //creates Parents array, initialized to all -1, except for start
  //create bitvector to mark visited vertices
  long numWords = (n+63)/64;
  long* Visited = newA(long,numWords);
  {parallel_for(long i=0;i<numWords;i++) Visited[i] = 0;}
  Visited[start/64] = (long)1 << (start % 64);
  vertexSubset Frontier(n,start); //creates initial frontier
  while(!Frontier.isEmpty()){ //loop until frontier is empty
    vertexSubset output = edgeMap(GA,Frontier,BFS_F(Visited));    
    Frontier.del();
    Frontier = output; //set new frontier
  } 
  Frontier.del();
  free(Visited);
}
