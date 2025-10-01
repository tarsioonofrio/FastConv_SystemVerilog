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
fast-conv build 2d bind nest
# quantizate with 4 shifs
# fast-conv quant shift -b 8

fast-conv sim normal -i 032 -n 032 -d 032
fast-conv sim normal -i 062 -n 062 -d 062
fast-conv sim normal -i 122 -n 122 -d 122
fast-conv sim normal -i 244 -n 244 -d 244
# fast-conv sim rand -i 488 -n 488 -d 488

rm -rf build clib sv
