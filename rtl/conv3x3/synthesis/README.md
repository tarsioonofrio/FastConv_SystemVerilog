# ASIC synthesis results

The active synthesis tree contains only configurations whose Xcelium
`list-file.txt` selects a 16-bit workload and whose configuration sets
`NBITS=16`. The active 3x3 configurations are the IFN9 and TCN9 column
variants with the `-nbits16` suffix.

Earlier 20-bit configurations and their reports were moved, without deleting
their evidence, to [`../archive/synthesis/`](../archive/synthesis/). This
includes the generic `conv.sv` ASIC sweeps, the IFN9 20-bit column variants,
and the associated campaign reports. They are retained for historical
reproduction and are not part of the active 16-bit synthesis set.
