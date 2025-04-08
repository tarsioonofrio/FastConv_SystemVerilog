# $1=path/to/project
# $2=output_size
# $3=fast_conv
# $4=bind
# $5=shifts

cd $1
# init fast-conv repository with 2d convolution and output of size (3,3)
fast-conv init 2d -o $2

# build a fast conv 2d using toom cook method
fast-conv build 2d $3

# bind 2d fast convolution with nested method
fast-conv build 2d bind $4
# quantizate with 4 shifs
fast-conv quant shift -b $5

fast-conv sim rand -s 032 -n 032 -d 032
fast-conv sim rand -s 064 -n 064 -d 064
fast-conv sim rand -s 128 -n 128 -d 128
fast-conv sim rand -s 256 -n 256 -d 256
fast-conv sim rand -s 512 -n 512 -d 512

rm -rf build
rm -rf clib
