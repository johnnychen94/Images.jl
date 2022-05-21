@testset "AdditiveWhiteGaussianNoise" begin
    @info "Test: AdditiveWhiteGaussianNoise"

    @testset "API" begin
        @test_throws MethodError AdditiveWhiteGaussianNoise()
        @test_throws ArgumentError AdditiveWhiteGaussianNoise(0.0, -0.1)
        @test AdditiveWhiteGaussianNoise(0.1) == AdditiveWhiteGaussianNoise(0.0, 0.1)

        n = AdditiveWhiteGaussianNoise(0.1)
        A = rand(Gray, 255, 255)
        B1 = similar(A)
        B2 = copy(A)
        out_B1 = apply_noise!(B1, A, n)
        out_B2 = apply_noise!(B2, n)
        # issue #7
        @test out_B2 == B2
        @test out_B1 == B1

        B3 = apply_noise(A, n)

        B1 = similar(A)
        B2 = copy(A)
        apply_noise!(B1, A, n; rng = MersenneTwister(0))
        apply_noise!(B2, n; rng = MersenneTwister(0))
        B3 = apply_noise(A, n; rng = MersenneTwister(0))
        B4 = apply_noise(Float64, A, n; rng = MersenneTwister(0))
        @test B1 == B2 == B3 == B4
    end

    @testset "types" begin
        n = AdditiveWhiteGaussianNoise(0.1)

        # Gray
        type_list = generate_test_types([Bool, Float32, N0f8], [Gray])
        A = [1.0 1.0 1.0; 1.0 1.0 1.0; 0.0 0.0 0.0]
        for T in type_list
            a = T.(A)
            apply_noise(a, n)

            b1 = similar(A, floattype(eltype(A)))
            b2 = copy(A)
            apply_noise!(b1, A, n; rng = MersenneTwister(0))
            apply_noise!(b2, n; rng = MersenneTwister(0))
            b3 = apply_noise(A, n; rng = MersenneTwister(0))
            b4 = apply_noise(floattype(eltype(A)), A, n; rng = MersenneTwister(0))
            @test b1 == b2 == b3 == b4
        end

        # RGB
        type_list = generate_test_types([Float32, N0f8], [RGB])
        A = [RGB(0.0, 0.0, 0.0) RGB(0.0, 1.0, 0.0) RGB(0.0, 1.0, 1.0)
            RGB(0.0, 0.0, 1.0) RGB(1.0, 0.0, 0.0) RGB(1.0, 1.0, 0.0)
            RGB(1.0, 1.0, 1.0) RGB(1.0, 0.0, 1.0) RGB(0.0, 0.0, 0.0)]
        for T in type_list
            a = T.(A)
            apply_noise(a, n)

            b1 = similar(A, floattype(eltype(A)))
            b2 = copy(A)
            apply_noise!(b1, A, n; rng = MersenneTwister(0))
            apply_noise!(b2, n; rng = MersenneTwister(0))
            b3 = apply_noise(A, n; rng = MersenneTwister(0))
            b4 = apply_noise(floattype(eltype(A)), A, n; rng = MersenneTwister(0))
            @test b1 == b2 == b3 == b4
        end
    end
end
