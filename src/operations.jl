########################################################################################################################
###################################################### OPERATIONS ######################################################
########################################################################################################################

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
function Base.push!(hb::HiBitSet{T}, x::Integer) where T
    @assert 0 <= x < hb.capacity "index out of bounds"
    usize = sizeof(T)*8
    word_idx = x ÷ usize + 1       # 1-based word index
    bitpos = x % usize

    # if already present, still fine (idempotent)
    _set_bit!(hb.layers, 1, word_idx, bitpos)

    # propagate upwards: for each level, set the bit corresponding to word_idx
    cur_word = word_idx
    for lvl in 2:length(hb.layers)
        parent_word = (cur_word - 1) ÷ usize + 1
        parent_bit  = (cur_word - 1) % usize
        _set_bit!(hb.layers, lvl, parent_word, parent_bit)
        cur_word = parent_word
    end
    return hb
end
function Base.delete!(hb::HiBitSet{T}, x::Integer) where T
    @assert 0 <= x < hb.capacity "index out of bounds"
    usize = sizeof(T)*8
    word_idx = x ÷ usize + 1       # 1-based word index
    bitpos = x % usize

    _disable_bit!(hb.layers, 1, word_idx, bitpos)

    # propagate upwards: for each level, set the bit corresponding to word_idx
    cur_word = word_idx
    @inbounds for lvl in 2:length(hb.layers)
        parent_word = (cur_word - 1) ÷ usize + 1
        parent_bit  = (cur_word - 1) % usize
        _disable_bit!(hb.layers, lvl, parent_word, parent_bit)
        cur_word = parent_word
    end
    return hb
end

# check membership
function Base.in(x::Integer, hb::HiBitSet{T}) where T
    0 <= x < hb.capacity || return false
    usize = sizeof(T)*8
    word_idx = x ÷ usize + 1
    bitpos = x % usize
    return !iszero(_get_bit(hb.layers, 1, word_idx, bitpos))
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
Base.issubset(hbA::HiBitSet, hbB::HiBitSet) = (hbA in hbB)

function Base.length(hb::HiBitSet{T}) where T
    layer = hb.layers[begin]
    res = 0

    @inbounds for bits in layer
        res += count_ones(bits)
    end

    return res
end 

function Base.maximum(hb::HiBitSet{T}) where T
    layer = hb.layers[begin]
    usize = sizeof(T)*8
    L = length(layer)

    @inbounds for i in L:-1:1
        bits = layer[i]
        iszero(bits) && continue

        bpos = 1
        while !iszero(bits)
            npos = trailing_zeros(bits)
            bits >>= bpos + npos
            bpos += npos
        end

        return (i-1)*usize + bpos
    end

    return 0
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

    return result
end

# An in-place intersection that returns a new HiBitSet (hb_out = hb1 ∩ hb2)
Base.intersect!(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T = intersect!(HiBitSet{T}(hb1.capacity), hb1, hb2)
function Base.intersect!(hb_out::HiBitSet{T}, hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T
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
Base.intersect(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T = intersect!(HiBitSet{T}(hb1.capacity), hb1, hb2)
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

# An in-place intersection that returns a new HiBitSet (hb_out = hb1 ∩ hb2)
Base.setdiff!(hb1::HiBitSet{T}, hbs::HiBitSet{T}...) where T = setdiff!(HiBitSet{T}(hb1.capacity), hb1, hbs...)
function Base.setdiff!(hb_out::HiBitSet{T}, hb1::HiBitSet{T}, hbs::HiBitSet{T}...) where T
    @assert hb_out.capacity == hb1.capacity "capacities must match"
    @assert length(hb_out.layers) == length(hb1.layers) "layer counts must match"
    @inbounds for lvl in 1:length(hb_out.layers)
        L = length(hb_out.layers[lvl])
        for i in 1:L
            a = hb1.layers[lvl][i]
            for hb in hbs
                a &= ~hb.layers[lvl][i]
            end

            hb_out.layers[lvl][i] = a
        end
    end
    return hb_out
end
Base.setdiff(hb1::HiBitSet{T}, hbs::HiBitSet{T}...) where T = setdiff!(HiBitSet{T}(hb1.capacity), hb1, hbs...)
function Base.setdiff!(hb1::HiBitSet{T}, hbs::HiBitSet{T}...) where T
    @inbounds for lvl in 1:length(hb2.layers)
        L = length(hb2.layers[lvl])
        for i in 1:L
            a = hb1.layers[lvl][i]
            for hb in hbs
                a &= ~hb.layers[lvl][i]
            end

            hb1.layers[lvl][i] = a
        end
    end
    return hb1
end


Base.union!(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T = union!(HiBitSet{T}(hb1.capacity), hb1, hb2)
function Base.union!(hb_out::HiBitSet{T}, hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T
    @assert hb_out.capacity == hb1.capacity == hb2.capacity "capacities must match"
    @assert length(hb_out.layers) == length(hb1.layers) == length(hb2.layers) "layer counts must match"
    @inbounds for lvl in 1:length(hb_out.layers)
        L = length(hb_out.layers[lvl])
        for i in 1:L
            hb_out.layers[lvl][i] = hb1.layers[lvl][i] | hb2.layers[lvl][i]
        end
    end
    return hb_out
end
Base.union(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T = union!(HiBitSet{T}(hb1.capacity), hb1, hb2)
function Base.union!(hb1::HiBitSet{T}, hb2::HiBitSet{T}) where T
    @assert hb1.capacity == hb2.capacity "capacities must match"
    @assert length(hb1.layers) == length(hb2.layers) "layer counts must match"
    @inbounds for lvl in 1:length(hb2.layers)
        L = length(hb2.layers[lvl])
        for i in 1:L
            hb1.layers[lvl][i] = hb1.layers[lvl][i] | hb2.layers[lvl][i]
        end
    end
    return hb1
end

function Base.empty!(hb::HiBitSet)
    @inbounds for layer in hb.layers
        layer .= 0
    end
end

function Base.copy(hb::HiBitSet{T}) where T
    nhb = HiBitSet{T}(hb.capacity)
    nhb.layers = deepcopy(hb.layers)
end

function Base.copy!(hb1::HiBitSet, hb2::HiBitSet)
    @assert hb1.capacity == hb2.capacity "capacities must match"
    hb1.layers = deepcopy(hb2.layers)
end

# convenience: build empty HiBitSet with same structure
function empty_like(hb::HiBitSet)
    layers = [zeros(WORD, length(l)) for l in hb.layers]
    return HiBitSet(layers, hb.capacity, hb.words_level1)
end
Base.isempty(hb::HiBitSet) = all(iszero, hb.layers[1])

_nbits(::Type{T}) where T= sizeof(T)*8
_nbits(n) = _nbits(typeof(n))
