#include <cstdio>
#include <fstream>
#include <atomic>
#include <parallel/algorithm>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

using vid_type = uint32_t;
using off_type = uint64_t;
off_type MAX_EDGES = 1lu << 40;

int main(int argc, char** argv)
{
    std::pair<vid_type, vid_type> *edges = (std::pair<vid_type, vid_type>*)mmap(nullptr, MAX_EDGES * 2 * sizeof(vid_type), PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON | MAP_NORESERVE, 0, 0);

    off_type num_edges = 0;
    vid_type max_id = 0, src, dst;

    // {
    //     auto fi = fopen(argv[1], "r");
    //     while(fscanf(fi, "%u%u", &src, &dst) != EOF)
    //     {
    //         edges[num_edges++] = std::make_pair(src, dst);
    //         max_id = std::max(max_id, src);
    //         max_id = std::max(max_id, dst);
    //     }
    //     fclose(fi);
    // }

    {
        int fd = open(argv[1], O_RDONLY, 0640);
        std::size_t size = lseek(fd, 0, SEEK_END);
        std::pair<vid_type, vid_type> *read_edges = (std::pair<vid_type, vid_type>*)mmap(nullptr, size, PROT_READ, MAP_PRIVATE, fd, 0);
        num_edges = size / sizeof(std::pair<vid_type, vid_type>);
        #pragma omp parallel for reduction(max : max_id)
        for(off_type i=0;i<num_edges;i++)
        {
            edges[i] = read_edges[i];
            max_id = max_id >= std::max(read_edges[i].first, read_edges[i].second) ? max_id : std::max(read_edges[i].first, read_edges[i].second);

        }
        close(fd);
    }

    off_type num_vertices = max_id + 1;

    printf("%lu %lu\n", num_vertices, num_edges);

    // __gnu_parallel::sort(edges, edges + num_edges, std::less<std::pair<vid_type, vid_type>>(), __gnu_parallel::multiway_mergesort_tag());

    // {
    //     auto fo = fopen((std::string(argv[2])+".config").c_str(), "w");
    //     fprintf(fo, "%lu", num_vertices);
    //     fclose(fo);
    // }
    // {
    //     auto fo = fopen((std::string(argv[2])+".idx").c_str(), "w");
    //     vid_type cur_vid = 0;
    //     for(off_type i=0;i<num_edges;i++)
    //     {
    //         while(cur_vid <= edges[i].first)
    //         {
    //             fwrite((char*)&i, sizeof(off_type), 1, fo);
    //             cur_vid++;
    //         }
    //     }
    //     while(cur_vid < num_vertices)
    //     {
    //         fwrite((char*)&num_edges, sizeof(off_type), 1, fo);
    //         cur_vid++;
    //     }
    //     fclose(fo);
    // }

    // {
    //     auto fo = fopen((std::string(argv[2])+".adj").c_str(), "w");
    //     for(off_type i=0;i<num_edges;i++)
    //     {
    //         #pragma clang optimize off
    //         vid_type dst = edges[i].second;
    //         fwrite((char*)&dst, sizeof(vid_type), 1, fo);
    //         #pragma clang optimize on
    //     }
    //     fclose(fo);
    // }

    #pragma omp parallel for
    for(off_type i=0;i<num_edges;i++)
        edges[i+num_edges] = std::make_pair(edges[i].second, edges[i].first);

    __gnu_parallel::sort(edges + num_edges, edges + 2 * num_edges, std::less<std::pair<vid_type, vid_type>>(), __gnu_parallel::multiway_mergesort_tag());

    {
        auto fo = fopen((std::string(argv[2])+".ridx").c_str(), "w");
        vid_type cur_vid = 0;
        for(off_type i=0;i<num_edges;i++)
        {
            while(cur_vid <= edges[i+num_edges].first)
            {
                fwrite((char*)&i, sizeof(off_type), 1, fo);
                cur_vid++;
            }
        }
        while(cur_vid < num_vertices)
        {
            fwrite((char*)&num_edges, sizeof(off_type), 1, fo);
            cur_vid++;
        }
        fclose(fo);
    }

    {
        auto fo = fopen((std::string(argv[2])+".radj").c_str(), "w");
        for(off_type i=0;i<num_edges;i++)
        {
            #pragma clang optimize off
            vid_type dst = edges[i+num_edges].second;
            fwrite((char*)&dst, sizeof(vid_type), 1, fo);
            #pragma clang optimize on
        }
        fclose(fo);
    }

    // __gnu_parallel::sort(edges, edges + 2 * num_edges, std::less<std::pair<vid_type, vid_type>>(), __gnu_parallel::multiway_mergesort_tag());

    // {
    //     auto fo = fopen((std::string(argv[2])+"-sym.config").c_str(), "w");
    //     fprintf(fo, "%lu", num_vertices);
    //     fclose(fo);
    // }

    // off_type unique_edges = std::unique(edges, edges + 2 * num_edges) - edges;

    // {
    //     auto fo = fopen((std::string(argv[2])+"-sym.idx").c_str(), "w");
    //     vid_type cur_vid = 0;
    //     for(off_type i=0;i<unique_edges;i++)
    //     {
    //         while(cur_vid <= edges[i].first)
    //         {
    //             fwrite((char*)&i, sizeof(off_type), 1, fo);
    //             cur_vid++;
    //         }
    //     }
    //     while(cur_vid < num_vertices)
    //     {
    //         fwrite((char*)&unique_edges, sizeof(off_type), 1, fo);
    //         cur_vid++;
    //     }
    //     fclose(fo);
    // }

    // {
    //     auto fo = fopen((std::string(argv[2])+"-sym.adj").c_str(), "w");
    //     for(off_type i=0;i<unique_edges;i++)
    //     {
    //         #pragma clang optimize off
    //         vid_type dst = edges[i].second;
    //         fwrite((char*)&dst, sizeof(vid_type), 1, fo);
    //         #pragma clang optimize on
    //     }
    //     fclose(fo);
    // }
    
}
