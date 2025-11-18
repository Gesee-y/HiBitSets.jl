Base.@propagate_inbounds function Base.iterate(hb::HiBitSet{T}, state=(0,1)) where T
    
    layer::Vector{T} = hb.layers[begin]
    bitpos, bitset = state
    bitset > length(layer) && return nothing
    
    bits = layer[bitset] >> bitpos
    usize = sizeof(T)*8

    while bitset <= length(layer) && iszero(bits)
    	bits = layer[bitset] >> bitpos
    	bitset += 1
    	bitpos = 0
    end

    bitset > length(layer) && return nothing
    bits = layer[bitset] >> bitpos

    gap = trailing_zeros(bits)
    return ((bitset-1)*usize + bitpos+gap, (bitpos+gap+1, bitset))
end

function Base.collect(hb::HiBitSet)
	res = Int[]
	for e in hb
		push!(res, e)
	end

	return res
end