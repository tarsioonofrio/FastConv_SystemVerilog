# WPN16 m32 vs TCN16 m18: power by hierarchy

## Scope

- Both runs use NBITS=16, Genus 21.12, TSMC28 TT 0.90 V / 25 C, and PLE interconnect.
- Reused the existing gate-level SHM and mapped DB; RTL and testbench were not changed.
- Re-read each SHM only over the accepted job window: 101 ns to 10875 ns (10.774 us, 5387 cycles at 2 ns).
- Reports are diagnostic additions. The original full-simulation power reports were not overwritten.
- Paxos scratch checkout: `7c23728fd44d02a52c3357eaea125da14afc2117`.

## Top-level result in the active window

| Metric | TCN16 m18 | WPN16 m32 | WPN16 delta |
| --- | ---: | ---: | ---: |
| Cell count | 51,148 | 29,049 | -43.2% |
| Total area (um2) | 77,963.252 | 50,771.518 | -34.9% |
| Leakage (mW) | 0.265635 | 0.161098 | -0.104537 |
| Internal dynamic (mW) | 4.67577 | 5.76531 | +1.08954 |
| Switching dynamic (mW) | 3.39186 | 3.71489 | +0.32303 |
| Dynamic total (mW) | 8.06763 | 9.48020 | +17.5% |
| Total power (mW) | 8.33326 | 9.64130 | +15.7% |

The reported area is about 35% lower for WPN16, not 50% lower. Its lower leakage is outweighed by higher dynamic power.

## Hierarchical evidence

Dynamic power below is internal plus switching. The hierarchy reports use the same active window.

| Hierarchy | TCN16 m18: cells / dynamic (mW) | WPN16 m32: cells / dynamic (mW) | Difference |
| --- | ---: | ---: | ---: |
| `MAC_LANES[].multip` aggregate | 7,488 / 1.498629 | 13,196 / 2.800912 | +1.302283 mW |
| Average per MAC lane | 416 average / 0.083257 | 412 average / 0.087528 | +5.1% per lane |
| `WEIGHT_TRANSFORM_ROWS[].weight_trf_row` aggregate | 27,257 / 0.318814 | 2,804 / 0.116554 | -0.202260 mW |
| `trf` | 3,757 / 1.144226 | 3,634 / 0.857351 | -0.286875 mW |
| `inverse_row_acc` | 1,692 / 0.884470 | 1,532 / 0.958823 | +0.074353 mW |

The extra 14 WPN MAC lanes account for most of the net increase: the aggregate MAC-lane dynamic power rises by 1.302 mW, while the average per lane rises only about 5%. TCN, meanwhile, has roughly 9.7 times as many cells in its weight-transform-row hierarchy, but those rows consume less dynamic power than the WPN rows in aggregate. This is why cell area/count alone does not predict dynamic power here.

At top level, the dynamic-power increase splits almost evenly between register power (+0.690286 mW) and logic power (+0.702460 mW); clock power changes by only +0.019827 mW. The clock category is about 2% of total power in both runs, so the clock tree is not the main explanation.

## Activity coverage and limitation

- WPN annotation: 3,213 flop outputs and all 37,337 driver nets asserted.
- TCN annotation: 2,677 flop outputs asserted; 59,688 of 59,710 driver nets asserted, with 22 unconnected.
- `report_activity -by_hierarchy` could not be run because the Paxos license checkout for `Joules_RTL_Power` failed. Therefore this result contains power by hierarchy and activity-annotation coverage, but not toggle counts/duty by hierarchy.
- The original top-level power reports used the complete 0-10881 ns SHM. Their full-window dynamic totals were 8.00482 mW (TCN) and 9.39809 mW (WPN), preserving the same direction and similar gap. The active-window report is used above to exclude idle/reset margins.

## Conclusion

The evidence supports this explanation: WPN16 m32 has lower area because its weight-transform hierarchy is much smaller, but it has 32 switching MAC lanes versus TCN16 m18's 18. The MAC-lane aggregate alone adds about 1.30 mW of dynamic power; reductions in the WPN transform blocks partially offset that increase. The remaining dynamic difference is consistent with higher register and logic power. Exact hierarchical toggle rates remain unavailable until the `Joules_RTL_Power` license is accessible.
