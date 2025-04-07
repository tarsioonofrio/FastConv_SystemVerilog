# $1=path/to/project 
# $2=output_size
# $3=bind
# $4=shifts

cd $1
# init fast-conv repository with 2d convolution and output of size (3,3)
fast-conv init 2d -o $2
# build a fast conv 2d using toom cook method
# fast-conv build 2d toom-cook
# bind 2d fast convolution with nested method
fast-conv build 2d bind $3
# quantizate with 4 shifs
fast-conv quant shift -b $4

sim rand -s 032 -n 032 -d 032
sim rand -s 064 -n 064 -d 064
sim rand -s 128 -n 128 -d 128
sim rand -s 256 -n 256 -d 256
sim rand -s 512 -n 512 -d 512
