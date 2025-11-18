# HiBitSet.jl

![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()

[Hierarchical Bitset](https://github.com/amethyst/hibitset) is a data structure formerly introduced in the ECS domain.

It's a bitset with multiples layers which allows for fast sets operations.

Here are some benchmarks:

```
--- Intersect ---
HiBitSet:  18.947 ns (0 allocations: 0 bytes)
Set:  313.378 ns (0 allocations: 0 bytes)
BitSet:  20.921 ns (0 allocations: 0 bytes)
--- Inclusion ---
HiBitSet:  1.578 ns (0 allocations: 0 bytes)
Set:  1.578 ns (0 allocations: 0 bytes)
BitSet:  1.973 ns (0 allocations: 0 bytes)
--- Pushing an element ---
HiBitSet:  9.473 ns (0 allocations: 0 bytes)
Set:  13.026 ns (0 allocations: 0 bytes)
BitSet:  6.710 ns (0 allocations: 0 bytes)
--- Deleting an element ---
HiBitSet:  9.078 ns (0 allocations: 0 bytes)
Set:  9.079 ns (0 allocations: 0 bytes)
BitSet:  3.157 ns (0 allocations: 0 bytes)
--- Set Inclusion ---
HiBitSet:  23.289 ns (0 allocations: 0 bytes)
Set:  212.552 ns (0 allocations: 0 bytes)
BitSet:  69.399 ns (0 allocations: 0 bytes)
--- Set Union ---
HiBitSet:  18.947 ns (0 allocations: 0 bytes)
Set:  1.381 μs (0 allocations: 0 bytes)
BitSet:  28.421 ns (0 allocations: 0 bytes)
--- Set Difference ---
HiBitSet:  16.579 ns (0 allocations: 0 bytes)
Set:  331.858 ns (0 allocations: 0 bytes)
BitSet:  20.921 ns (0 allocations: 0 bytes)
--- Set Cardinality ---
HiBitSet:  12.631 ns (0 allocations: 0 bytes)
Set:  2.763 ns (0 allocations: 0 bytes)
BitSet:  9.868 ns (0 allocations: 0 bytes)
--- Set Copy ---
HiBitSet:  738.440 ns (9 allocations: 1.02 KiB)
Set:  742.888 ns (4 allocations: 4.81 KiB)
BitSet:  109.697 ns (3 allocations: 272 bytes)
--- Set Iteration ---
HiBitSet:  576.273 ns (0 allocations: 0 bytes)
Set:  410.448 ns (0 allocations: 0 bytes)
BitSet:  13.421 ns (0 allocations: 0 bytes)
```