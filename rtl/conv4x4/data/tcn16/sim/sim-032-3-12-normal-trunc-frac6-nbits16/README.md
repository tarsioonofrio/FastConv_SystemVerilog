# TCN16 Cin=3, Cout=12, 16 bits, frac6

Dataset experimental truncado para comparar as variantes rowconst e pretransformed em 16 bits.

Workload: imagem 32x32, Cin=3, Cout=12, kernel 3x3, seed 0, NBITS=16, QUANT=8. Os pesos transformados mantêm seis bits fracionários (largura de peso NBITS+6) e são quantizados com floor após a escala 576.

R2 reportado pela biblioteca: 0.738611919636. O pacote foi gerado por `rtl/conv4x4/data/tcn16/generate_trunc_frac8_nbits16.py` com WEIGHT_FRAC_BITS=6. SHA-256 do pack_data.sv: `f9e6144e97e6590a05c89bd952e5c1d56ce15b0a8d57aaeb5126d90441f85c7f`.
