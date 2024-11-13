#!/bin/bash
set -ex

export NCCL_LIB_DIR=/usr/local/nvidia/lib64
export NCCL_PLUGIN_PATH=/usr/local/nvidia/lib64
#export LD_PRELOAD=/usr/local/nvidia/lib64/libnccl.so
source /usr/local/nvidia/lib64/nccl-env-profile.sh

export CUDA_AUTOCOMPAT_VERBOSE=2
export NCCL_DEBUG=TRACE
export NCCL_TOPO_DUMP_FILE=topo.txt 
export NCCL_GRAPH_DUMP_FILE=graph.txt

vatsrun --exec universe e8af7db9d406026a8a56b39606b6c6d516bd6b49 \
ext/public/python/torch/2/0/bin/python3 -m torch.distributed.run --nproc_per_node=8 --nnodes=2 --node_rank=0 --master_addr=$(hostname -i) --master_port=1234  all-reduce-torch.py
