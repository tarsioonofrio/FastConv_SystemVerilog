cd $1

# init fast-conv repository with 2d convolution and output of size (3,3)
fast-conv init 2d -o $2
# build a fast conv 2d using toom cook method
fast-conv build 2d toom-cook
# bind 2d fast convolution with nested method
fast-conv build 2d bind $3
# quantizate with 4 shifs
fast-conv quant shift -b $4

