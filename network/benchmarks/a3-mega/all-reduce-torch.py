import os

import argparse
import socket
import torch
import torch.distributed as dist


def timed_allreduce(local_rank, mat, start_event, end_event, N, M):
    dist.barrier()
    start_event.record()
    dist.all_reduce(mat)
    end_event.record()

    torch.cuda.synchronize()
    duration = start_event.elapsed_time(end_event) / 1000

    n = dist.get_world_size()
    size = M * N * 4  # 4 is 4 bytes in fp32
    # note that this is following the same math as NVIDIA/nccl-tests
    algbw = torch.tensor([size / duration]).cuda(local_rank)

    # calculate mean across all ranks
    dist.reduce(algbw, dst=0, op=dist.ReduceOp.SUM)
    algbw /= n

    return algbw


def run(local_rank, N, M, trials):
    hostname = socket.gethostname()
    is_global_rank_0 = dist.get_rank() == 0

    mat = torch.rand(N, M, dtype=torch.float32).cuda(local_rank)

    start_event = torch.cuda.Event(enable_timing=True)
    end_event = torch.cuda.Event(enable_timing=True)

    # do a few warm up iterations
    for i in range(2):
        timed_allreduce(local_rank, mat, start_event, end_event, N, M)

    # real benchmark
    algbw_gather = []
    for i in range(trials):
        if is_global_rank_0:
            print(i + 1)
        algbw_gather += timed_allreduce(
            local_rank, mat, start_event, end_event, N, M
        )

    algbw = torch.mean(torch.stack(algbw_gather))

    # the 2*(n-1)/n busbw correction factor specific to all-reduce is explained here:
    # https://github.com/NVIDIA/nccl-tests/blob/master/doc/PERFORMANCE.md#allreduce
    # busbw reflects how optimally the hardware is used
    n = dist.get_world_size()
    busbw = algbw * (2 * (n - 1) / n)

    if is_global_rank_0:
        print(
            f"The average bandwidth of all_reduce with a {M*N*4/1e9}GB payload ({trials} trials, {n} ranks):\n",
            f"algbw: {algbw/1e9:.3f} GBps ({algbw*8/1e9:.1f} Gbps)\n",
            f"busbw: {busbw/1e9:.3f} GBps ({busbw*8/1e9:.1f} Gbps)\n",
        )


def init_processes(local_rank, fn, N, M, trials, backend="nccl"):
    torch.cuda.set_device(local_rank)
    dist.init_process_group(backend)
    fn(local_rank, N, M, trials)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-n",
        type=int,
        default=500000,
    )
    parser.add_argument(
        "-m",
        type=int,
        default=2000,
    )
    parser.add_argument(
        "-t",
        type=int,
        default=5,
    )
    args = parser.parse_args()

    rank = int(os.environ["LOCAL_RANK"])
    init_processes(local_rank=rank, fn=run, N=args.n, M=args.m, trials=args.t)