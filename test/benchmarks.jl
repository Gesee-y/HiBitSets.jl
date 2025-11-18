include("..\\src\\HiBitSet.jl")

using .HiBitSets
using BenchmarkTools

A, B = rand(1:999, 100), rand(1:999, 100)

# Example usage (uncomment to test):

out = HiBitSets.HiBitSet(1000)
hb = HiBitSets.HiBitSet(A,1000)
#delete!(hb, 10); push!(hb, 12); push!(hb, 99)
hb2 = HiBitSets.HiBitSet(B,1000)
#push!(hb2, 12); push!(hb2, 50)
println(HiBitSets.intersect_to_vector(hb, hb2))

a,b = BitSet(A), BitSet(B)
c = Set(A)
d = Set(B)

println(intersect!(a, b))
println(intersect!(c, d))

println("--- Intersect ---")
print("HiBitSet:")
@btime intersect!($hb,$hb2)
print("Set:")
@btime intersect!($c,$d)
print("BitSet:")
@btime intersect!($a,$b)

println("--- Inclusion ---")
print("HiBitSet:")
@btime in($hb, 1)
print("Set:")
@btime in($c, 1)
print("BitSet:")
@btime in($a, 1)

println("--- Pushing an element ---")
print("HiBitSet:")
@btime push!($hb, 1)
print("Set:")
@btime push!($c, 1)
print("BitSet:")
@btime push!($a, 1)

println("--- Deleting an element ---")
print("HiBitSet:")
@btime delete!($hb, 1)
print("Set:")
@btime delete!($c, 1)
print("BitSet:")
@btime delete!($a, 1)

println("--- Set Inclusion ---")
print("HiBitSet:")
@btime in($hb, $hb2)
print("Set:")
@btime in($c, $d)
print("BitSet:")
@btime in($a, $b)

println("--- Set Union ---")
print("HiBitSet:")
@btime union!($hb, $hb2)
print("Set:")
@btime union!($c, $d)
print("BitSet:")
@btime union!($a, $b)

println("--- Set Difference ---")
print("HiBitSet:")
@btime setdiff!($hb, $hb2)
print("Set:")
@btime setdiff!($c, $d)
print("BitSet:")
@btime setdiff!($a, $b)

println("--- Set Cardinality ---")
print("HiBitSet:")
@btime length($hb)
print("Set:")
@btime length($c)
print("BitSet:")
@btime length($a)

println("--- Set Copy ---")
print("HiBitSet:")
@btime copy($hb)
print("Set:")
@btime copy($c)
print("BitSet:")
@btime copy($a)

s = 0
println("--- Set Iteration ---")
print("HiBitSet:")
@btime @inbounds for e in $hb2
	$s += e
end
print("Set:")
@btime for e in $c
	$s += e
end
print("BitSet:")
@btime for e in $a
	$s += e
end
s += 1

#println(intersect!(a,b))
#println(intersect!(c,d))