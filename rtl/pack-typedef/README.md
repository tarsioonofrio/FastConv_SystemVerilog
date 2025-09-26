# Shared type aliases

`pack_typedef.sv` imports `pack_def` and the selected `pack_param` package to define the reusable vector types listed below.

| Typedef | Base type | Description |
|---------|-----------|-------------|
| `logic_vector` | `logic [NBITS-1:0]` | Convenience alias for a single data element. |
| `type_input` | `logic_vector [C1_SIZE*C1_SIZE-1:0]` | Flattened input tile presented to the forward Winograd transform. |
| `type_output` | `logic_vector [A1_SIZE*A1_SIZE-1:0]` | Flattened spatial output tile returned by the inverse transform. |
| `type_weight` | `logic_vector [M1_SIZE*M1_SIZE-1:0]` | Winograd-domain tile consumed by the multiplier bank. |
| `type_matrix_c` | `logic_vector [C1_SIZE*M1_SIZE-1:0]` | Intermediate matrix between the two stages of the forward transform. |
| `type_matrix_a` | `logic_vector [C1_SIZE*M1_SIZE-1:0]` | Intermediate matrix between the two stages of the inverse transform. |
| `two_words` | `logic_vector [1:0]` | Bundle of two words used in the CSA library. |
| `four_words` | `logic_vector [3:0]` | Bundle of four words for CSA staging. |
| `six_words` | `logic_vector [5:0]` | Bundle of six words for CSA staging. |
| `eight_words` | `logic_vector [7:0]` | Bundle of eight words for CSA staging. |
| `ten_words` | `logic_vector [9:0]` | Bundle of ten words for CSA staging. |

Import this package after selecting the appropriate `pack_param` variant so each typedef expands to the correct dimensions for the target kernel.
