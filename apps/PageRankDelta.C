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
#include "math.h"

template <class vertex>
struct PR_F {
  vertex* V;
  float* Delta, *nghSum;
  PR_F(vertex* _V, float* _Delta, float* _nghSum) : 
    V(_V), Delta(_Delta), nghSum(_nghSum) {}
  inline bool update(uintE s, uintE d){
    float oldVal = nghSum[d];
    nghSum[d] += Delta[s] / V[s].getOutDegree();
    return oldVal == 0;
  }
  inline bool updateAtomic (uintE s, uintE d) {
    volatile float oldV, newV; 
    do { //basically a fetch-and-add
      oldV = nghSum[d]; newV = oldV + Delta[s] / V[s].getOutDegree();
    } while(!CAS(&nghSum[d],oldV,newV));
    return oldV == 0.0;
  }
  inline bool cond (uintE d) { return cond_true(d); }};

template <typename vertex>
struct PR_Vertex_F_FirstRound {
  float damping, addedConstant, one_over_n, epsilon2;
  float* p, *Delta, *nghSum;
  PR_Vertex_F_FirstRound(float* _p, float* _Delta, float* _nghSum, float _damping, float _one_over_n,float _epsilon2) :
    p(_p),
    damping(_damping), Delta(_Delta), nghSum(_nghSum), one_over_n(_one_over_n),
    addedConstant((1-_damping)*_one_over_n),
    epsilon2(_epsilon2) {}
  inline bool operator () (uintE i) {
    Delta[i] = damping*nghSum[i]+addedConstant;
    p[i] += Delta[i];
    Delta[i]-=one_over_n; //subtract off delta from initialization
    return (fabs(Delta[i]) > epsilon2 * p[i]);
  }
};

template <typename vertex>
struct PR_Vertex_F {
  float damping, epsilon2;
  float* p, *Delta, *nghSum;
  PR_Vertex_F(float* _p, float* _Delta, float* _nghSum, float _damping, float _epsilon2) :
    p(_p),
    damping(_damping), Delta(_Delta), nghSum(_nghSum), 
    epsilon2(_epsilon2) {}
  inline bool operator () (uintE i) {
    Delta[i] = nghSum[i]*damping;
    if (fabs(Delta[i]) > epsilon2 * p[i]) { p[i]+=Delta[i]; return 1;}
    else return 0;
  }
};

struct PR_Vertex_Reset {
  float* nghSum;
  PR_Vertex_Reset(float* _nghSum) :
    nghSum(_nghSum) {}
  inline bool operator () (uintE i) {
    nghSum[i] = 0.0;
    return 1;
  }
};

template <class vertex>
void Compute(graph<vertex>& GA, commandLine P) {
  long maxIters = P.getOptionLongValue("-maxiters",100);
  const long n = GA.n;
  const float damping = 0.85;
  const float epsilon = 0.0000001;
  const float epsilon2 = 0.01;

  float one_over_n = 1/(float)n;
  float* p = newA(float,n), *Delta = newA(float,n), 
    *nghSum = newA(float,n);
  bool* frontier = newA(bool,n);
  parallel_for(long i=0;i<n;i++) {
    p[i] = 0.0;//one_over_n;
    Delta[i] = one_over_n; //initial delta propagation from each vertex
    nghSum[i] = 0.0;
    frontier[i] = 1;
  }

  vertexSubset Frontier(n,n,frontier);
  bool* all = newA(bool,n);
  {parallel_for(long i=0;i<n;i++) all[i] = 1;}
  vertexSubset All(n,n,all); //all vertices

  long round = 0;
  while(round++ < maxIters) {
    edgeMap(GA,Frontier,PR_F<vertex>(GA.V,Delta,nghSum), INT_MAX, no_output | dense_forward);
    vertexSubset active 
      = (round == 1) ? 
      vertexFilter(All,PR_Vertex_F_FirstRound<vertex>(p,Delta,nghSum,damping,one_over_n,epsilon2)) :
      vertexFilter(All,PR_Vertex_F<vertex>(p,Delta,nghSum,damping,epsilon2));
    //compute L1-norm (use nghSum as temp array)

    // printf("iter = %ld NUM active = %ld\n", round, active.numNonzeros());
    {parallel_for(long i=0;i<n;i++) {
      nghSum[i] = fabs(Delta[i]); }}
    float L1_norm = sequence::plusReduce(nghSum,n);
    if(L1_norm < epsilon) break;
    //reset	

    vertexMap(All,PR_Vertex_Reset(nghSum));
    Frontier.del();
    Frontier = active;
  }

  // float max_pr = 0;
  // long max_pr_id = 0;
  // #pragma omp parallel for schedule(runtime) reduction(max:max_pr)
  // for(long i=0;i<n;i++) max_pr = max_pr > p[i] ? max_pr : p[i];
  // parallel_for(long i=0;i<n;i++) if(p[i] == max_pr) max_pr_id = i;
  // printf("largest pr value is %f from %lu\n", max_pr, max_pr_id);

  Frontier.del(); free(p); free(Delta); free(nghSum); All.del();
}
