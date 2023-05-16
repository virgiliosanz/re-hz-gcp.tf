#!/bin/bash

# -d: data size
# -c -t : client and thread per client


# for quick data loading
# --ratio=4:0 --pipeline=40


# optional for OSS cluster API
# --cluster-mode

HOST=redis-12000.cluster.vsanz-default.demo.redislabs.com 
PORT=12000

memtier_benchmark --ratio=1:4 --test-time=3600 \
 -d 150 \
 -t 12 -c 10 \
 --key-pattern=P:P \
 --key-maximum=20000000 \
 --hide-histogram -x 1000 \
 -a adminRL123 \
 --pipeline=1  \
 -s $HOST -p $PORT 
