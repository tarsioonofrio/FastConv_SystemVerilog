# Fast Convolution
## Generator

Toom Cook is a method for linear convolution that garanties the minimal number
of multiplications by the Winograd theorem but rapdly increase the number of sums.

## Bind

Nesting is a method that bind two fast convolution matrices by multipling the input data
twice: one time in normal form, and other time by transposed form.

## Operations
Total multiplications: 36
Sums:
A: 36
C: 48
Total: 84
