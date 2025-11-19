# HiBitSet.jl

[![Test workflow status](https://github.com/Gesee-y/HiBitSets.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/Gesee-y/HiBitSets.jl/actions/workflows/coverage.yml?query=branch%3Amain)
[![Coverage Status](https://coveralls.io/repos/github/Gesee-y/HiBitSets.jl/badge.svg)](https://coveralls.io/github/Gesee-y/HiBitSets.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()

[Hierarchical Bitset](https://github.com/amethyst/hibitset) HiBitSet is a hierarchical bitset inspired by the structure used in the ECS ecosystem, particularly in Amethyst’s hibitset.
It implements a multi-layer bitset that accelerates set operations by skipping empty regions efficiently. They can only store positive integers.


---

## Why a Hierarchical Bitset?

A classical bitset scans blocks linearly.
A hierarchical bitset keeps summaries (“layers”) that tell you which blocks contain at least one bit set.

### Structure (simplified):

- Layer 0: raw bits

- Layer 1: one bit per n-bit chunk of Layer 0

- Layer 2: one bit per n-bit chunk of Layer 1

… and so on


This allows:

- Fast intersection
- Fast union
- Fast filtering of sparse sets
-Predictable performance even with large ranges

---

## Use case

- ECS queries (matching components fast)

- High-frequency set operations


Not ideal for:

- Iteration-heavy workloads

- Frequent deep copies


---

## Basic Usage

```julia
using HiBitSets

bs = HiBitSet([1,3,4], 10000)
push!(bs, 42)
push!(bs, 9000)

if 42 in bs
    println("found")
end

delete!(bs, 42)
```

---

## Benchmarks

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
