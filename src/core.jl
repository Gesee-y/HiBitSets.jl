# HiBitSet.jl
# Hierarchical bitset (hi-bitset) implementation in Julia
# - Stores a set of non-negative integer indices
# - Layers are vectors of UInt64 "words"; each upper layer indexes the presence of words in the layer below
# - Automatically computes number of layers needed (top layer length == 1)
# - Functions: HiBitSet(capacity), add!, contains, intersect, intersect_to_vector, iterate, pop!

export HiBitSet, add!, contains, intersect_to_vector, intersect!

const WORD = UInt64
const WORD_BITS = 64

mutable struct HiBitSet{T}
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



# internal: set bit in layer `lvl` at word index widx and bit position bitpos
@inline function _set_bit!(layers::Vector{Vector{T}}, lvl::Int, widx::Int, bitpos::Int) where T
    layers[lvl][widx] |= (one(T) << bitpos)
end
@inline function _disable_bit!(layers::Vector{Vector{T}}, lvl::Int, widx::Int, bitpos::Int) where T
    layers[lvl][widx] &= ~(one(T) << bitpos)
end
# internal: get bit
@inline function _get_bit(layers::Vector{Vector{T}}, lvl::Int, widx::Int, bitpos::Int) where T
    return (layers[lvl][widx] >> bitpos) & one(T)
end

# add an index to the set
function Base.push!(hb::HiBitSet, x::Integer)
    @assert 0 <= x < hb.capacity "index out of bounds"
    word_idx = x ÷ WORD_BITS + 1       # 1-based word index
    bitpos = x % WORD_BITS

    # if already present, still fine (idempotent)
    _set_bit!(hb.layers, 1, word_idx, bitpos)

    # propagate upwards: for each level, set the bit corresponding to word_idx
    cur_word = word_idx
    @inbounds for lvl in 2:length(hb.layers)
        parent_word = (cur_word - 1) ÷ WORD_BITS + 1
        parent_bit  = (cur_word - 1) % WORD_BITS
        _set_bit!(hb.layers, lvl, parent_word, parent_bit)
        cur_word = parent_word
    end
    return hb
end
function Base.delete!(hb::HiBitSet, x::Integer)
    @assert 0 <= x < hb.capacity "index out of bounds"
    word_idx = x ÷ WORD_BITS + 1       # 1-based word index
    bitpos = x % WORD_BITS

    # if already present, still fine (idempotent)
    _set_bit!(hb.layers, 1, word_idx, bitpos)

    # propagate upwards: for each level, set the bit corresponding to word_idx
    cur_word = word_idx
    @inbounds for lvl in 2:length(hb.layers)
        parent_word = (cur_word - 1) ÷ WORD_BITS + 1
        parent_bit  = (cur_word - 1) % WORD_BITS
        _disable_bit!(hb.layers, lvl, parent_word, parent_bit)
        cur_word = parent_word
    end
    return hb
end

# check membership
function Base.in(hb::HiBitSet{T}, x::Integer) where T
    0 <= x < hb.capacity || return false
    bits = _nbits(T)
    wi = x ÷ bits + 1
    bp = x % bits
    return @inbounds !iszero(_get_bit(hb.layers, 1, wi, bp))
end
function Base.in(hbA::HiBitSet, hbB::HiBitSet)
    # intersect hbA & hbB et comparer chaque couche
    @inbounds for lvl in 1:length(hbA.layers)
        L = length(hbA.layers[lvl])
        for i in 1:L
	        if (hbA.layers[lvl][i] & hbB.layers[lvl][i]) != hbA.layers[lvl][i]
	            return false
	        end
	    end
    end
    return true
end


# Efficient intersection that returns a vector of indices present in both sets
# We scan top-down: find matching words at top, then descend to find matching bits.
function intersect_to_vector(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T
    @assert hb1.capacity == hb2.capacity "capacities must match"
    L = length(hb1.layers)
    result = Int[]

    # stack entries: (level, word_index_in_level, mask)
    # We'll start from top level where we look at word positions that match
    # For top level, iterate all words (usually 1)
    

    stack = Frame{T}[]
    # initialize with top-level matches
    top_lvl = L
    @inbounds for w in 1:length(hb1.layers[top_lvl])
        m = hb1.layers[top_lvl][w] & hb2.layers[top_lvl][w]
        if m != 0
            push!(stack, Frame(top_lvl, w, m))
        end
    end

    @inbounds while !isempty(stack)
        fr = pop!(stack)
        lvl = fr.lvl
        widx = fr.widx
        mask = fr.mask

        if lvl == 1
            # convert each 1 bit in mask to absolute index
            base = (widx - 1) * WORD_BITS
            while mask != 0
                tz = trailing_zeros(mask)
                push!(result, base + tz)
                mask &= mask - 1  # clear lowest set bit
            end
        else
            # descend: each bit set in mask corresponds to a word index in the lower level
            # For each set bit at position b, the child word index is (widx-1)*WORD_BITS + b + 1
            base_child = (widx - 1) * WORD_BITS
            # iterate set bits
            m = mask
            while m != 0
                tz = trailing_zeros(m)
                child_widx = base_child + tz + 1
                # compute mask at child level
                child_mask = hb1.layers[lvl-1][child_widx] & hb2.layers[lvl-1][child_widx]
                if child_mask != 0
                    push!(stack, Frame(lvl-1, child_widx, child_mask))
                end
                m &= m - 1
            end
        end
    end

    #sort!(result)
    return result
end

# An in-place intersection that returns a new HiBitSet (hb_out = hb1 ∩ hb2)
Base.intersect!(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T = intersect!(HiBitSet{T}(hb1.capacity), hb1, hb2)
function Base.intersect(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T
    hb_out = HiBitSet{T}(hb1.capacity)
    @assert hb_out.capacity == hb1.capacity == hb2.capacity "capacities must match"
    @assert length(hb_out.layers) == length(hb1.layers) == length(hb2.layers) "layer counts must match"
    @inbounds for lvl in 1:length(hb_out.layers)
        L = length(hb_out.layers[lvl])
        for i in 1:L
            hb_out.layers[lvl][i] = hb1.layers[lvl][i] & hb2.layers[lvl][i]
        end
    end
    return hb_out
end
function Base.intersect!(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T
    @assert hb1.capacity == hb2.capacity "capacities must match"
    @assert length(hb1.layers) == length(hb2.layers) "layer counts must match"
    @inbounds for lvl in 1:length(hb2.layers)
        L = length(hb2.layers[lvl])
        for i in 1:L
            hb1.layers[lvl][i] = hb1.layers[lvl][i] & hb2.layers[lvl][i]
        end
    end
    return hb1
end

# convenience: build empty HiBitSet with same structure
function empty_like(hb::HiBitSet)
    layers = [zeros(WORD, length(l)) for l in hb.layers]
    return HiBitSet(layers, hb.capacity, hb.words_level1)
end

# iteration over set elements (ascending)
Base.iterate(hb::HiBitSet, state=nothing) = iterate(_iter_helper(hb), state)
function _iter_helper(hb::HiBitSet)
    vec = intersect_to_vector(hb, hb)  # trivial but leverages implementation
    return Iterators.Stateful(vec)
end

_nbits(::Type{T}) where T= sizeof(T)*8
_nbits(n) = _nbits(typeof(n))