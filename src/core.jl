# HiBitSet.jl
# Hierarchical bitset (hi-bitset) implementation in Julia
# - Stores a set of non-negative integer indices
# - Layers are vectors of UInt64 "words"; each upper layer indexes the presence of words in the layer below
# - Automatically computes number of layers needed (top layer length == 1)
# - Functions: HiBitSet(capacity), add!, contains, intersect, intersect_to_vector, iterate, pop!

export HiBitSet, add!, contains, intersect_to_vector, intersect!

const WORD = UInt64
const WORD_BITS = 64

mutable struct HiBitSet{T} <: AbstractHiBitSet{T}
    layers::Vector{Vector{T}}
    capacity::Int
    words_level1::Int

    # Constructor

	function HiBitSet{T}(capacity::Integer) where T<:Unsigned
	    @assert capacity > 0 "capacity must be > 0"
	    layers = _build_layers(T, capacity)
	    return new{T}(layers, capacity, length(layers[1]))
	end
	function HiBitSet{T}(A, capacity::Integer) where T<:Unsigned
	    hb = HiBitSet{T}(capacity)

	    for a in A
	    	push!(hb, a)
	    end

	    return hb
	end
	HiBitSet(capacity::Integer) = HiBitSet{WORD}(capacity)
	HiBitSet(A, capacity::Integer) = HiBitSet{WORD}(A, capacity)
end

struct Frame{T}
    lvl::Int
    widx::Int
    mask::T

    ## Constructor

    Frame{T}(l,w,m) where T= new{T}(l,w,m)
    Frame(l,w,m) = Frame{WORD}(l,w,m)
end

# helper: number of words to cover n bits
_words_for_bits(n::Integer) = Int(n ÷ _nbits(n)) + 1

# Build layers from capacity. Keep dividing by WORD_BITS until top layer length == 1
function _build_layers(::Type{T}, capacity::Integer) where T
    words = _words_for_bits(capacity)
    layers = Vector{Vector{T}}()
    push!(layers, zeros(T, words))
    while length(layers[end]) > 1
        parent_words = _words_for_bits(length(layers[end]))
        push!(layers, zeros(T, parent_words))
    end
    return layers
end