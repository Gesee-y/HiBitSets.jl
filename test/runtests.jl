using HiBitSets
using Test

@testset "HiBitSet – Construction" begin
    hb = HiBitSet(1000)
    @test isempty(hb)
    @test length(hb) == 0
end

@testset "HiBitSet – Insert & Delete" begin
    hb = HiBitSet(100)
    push!(hb, 10)
    push!(hb, 20)
    @test 10 in hb
    @test 20 in hb

    delete!(hb, 10)
    @test !(10 in hb)
    @test 20 in hb
end

@testset "HiBitSet – Membership" begin
    vals = [3, 7, 50, 99]
    hb = HiBitSet(vals, 100)
    for v in vals
        @test v in hb
    end
    @test !(1 in hb)
    @test !(98 in hb)
end

@testset "HiBitSet – Intersection" begin
    A = [1, 3, 5, 7, 9]
    B = [2, 3, 6, 7, 10]
    hbA = HiBitSet(A, 100)
    hbB = HiBitSet(B, 100)
    out = HiBitSet(100)
    inter = intersect_to_vector(hbA, hbB)
    @test sort(inter) == [3,7]

    # Coherence with Set
    @test sort(inter) == sort(collect(intersect(Set(A), Set(B))))

    intersect!(out, hbA, hbB)
    @test sort(collect(out)) == sort(collect(intersect(Set(A), Set(B))))

    u = intersect(hbA, hbB)
    @test sort(collect(u)) == sort(collect(intersect(Set(A), Set(B))))

    intersect!(hbA, hbB)
    @test sort(collect(out)) == sort(collect(intersect(Set(A), Set(B))))
end

@testset "HiBitSet – Union" begin
    A = [1,4,6]
    B = [2,4,8]
    hbA = HiBitSet(A, 50)
    hbB = HiBitSet(B, 50)
    out = HiBitSet(50)

    union!(out, hbA, hbB)
    @test sort(collect(out)) == sort(collect(union(Set(A), Set(B))))

    u = union(hbA, hbB)
    @test sort(collect(u)) == sort(collect(union(Set(A), Set(B))))

    union!(hbA, hbB)
    @test sort(collect(out)) == sort(collect(union(Set(A), Set(B))))
end

@testset "HiBitSet – Difference" begin
    A = [1,3,5,7]
    B = [3,7]
    hbA = HiBitSet(A, 50)
    hbB = HiBitSet(B, 50)
    out = HiBitSet(50)

    setdiff!(out, hbA, hbB)
    @test sort(collect(out)) == sort(collect(setdiff(Set(A), Set(B))))

    u = setdiff(hbA, hbB)
    @test sort(collect(u)) == sort(collect(setdiff(Set(A), Set(B))))

    setdiff!(hbA, hbB)
    @test sort(collect(out)) == sort(collect(setdiff(Set(A), Set(B))))
end

@testset "HiBitSet – Inclusion" begin
    A = [1,2,3]
    B = [1,2,3,4,5]
    hbA = HiBitSet(A, 100)
    hbB = HiBitSet(B, 100)

    @test issubset(hbA, hbB)
    @test !issubset(hbB, hbA)
end

@testset "HiBitSet – Cardinality" begin
    A = [1,5,7,20,30]
    hb = HiBitSet(A, 100)
    @test length(hb) == length(A)

    empty = HiBitSet(500)
    @test length(empty) == 0
end

@testset "HiBitSet – Iteration" begin
    A = sort(unique(rand(1:1000-1, 50)))
    hb = HiBitSet(A, 1000)
    @test sort(collect(hb)) == A

    empty = HiBitSet(1000)
    @test collect(empty) == []
end

@testset "HiBitSet – Min/Max (if implemented)" begin
    A = [10, 50, 3, 99, 42]
    hb = HiBitSet(A, 200)

    if hasmethod(minimum, Tuple{HiBitSet})
        @test minimum(hb) == minimum(A)
    end
    
    if hasmethod(maximum, Tuple{HiBitSet})
        @test maximum(hb) == maximum(A)
    end
end

@testset "HiBitSet – Stress & Randomized" begin
    for _ in 1:200
        cap = 1000
        A = unique(rand(1:cap-1, rand(1:50)))
        B = unique(rand(1:cap-1, rand(1:50)))

        hbA = HiBitSet(A, cap)
        hbB = HiBitSet(B, cap)
        out = HiBitSet(cap)

        # intersection
        out_inter = intersect_to_vector(hbA, hbB)
        @test sort(out_inter) == sort(collect(intersect(Set(A), Set(B))))

        # union
        union!(out, hbA, hbB)
        @test sort(collect(out)) == sort(collect(union(Set(A), Set(B))))

        # difference
        setdiff!(out, hbA, hbB)
        @test sort(collect(out)) == sort(collect(setdiff(Set(A), Set(B))))
    end
end
