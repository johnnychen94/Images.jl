@testset "NonlocalMean" begin
    @info "Test: NonlocalMean"

    @testset "API" begin
        img_gray = imresize(testimage("lena_gray_256"); ratio=0.25)
        n = AdditiveWhiteGaussianNoise(0.05)
        noisy_img = apply_noise(img_gray, n; rng=MersenneTwister(0))

        # NonlocalMean
        @test NonlocalMean(0.1) == NonlocalMean(0.1, 2)
        @test NonlocalMean(0.1, 2) == NonlocalMean(0.1, 2, 5)
        @test NonlocalMean(0.1, noisy_img) == NonlocalMean(0.1, 1) # estimate r_p = 1
        @test NonlocalMean(0.1, 3) == NonlocalMean(0.1, 3, 7)
        @test_throws ArgumentError NonlocalMean(0.1, -1)
        @test_throws ArgumentError NonlocalMean(0.1, 1, -1)

        # reduce_noise
        f = NonlocalMean(0.05, 2)
        denoised_img_1 = reduce_noise(noisy_img, f)
        denoised_img_2 = similar(noisy_img)
        reduce_noise!(denoised_img_2, noisy_img, f)
        denoised_img_3 = copy(noisy_img)
        reduce_noise!(denoised_img_3, f)
        denoised_img_4 = reduce_noise(Gray{Float64}, noisy_img, f)

        @test eltype(denoised_img_1) == Gray{N0f8}
        @test eltype(denoised_img_2) == Gray{N0f8}
        @test eltype(denoised_img_3) == Gray{N0f8}
        @test eltype(denoised_img_4) == Gray{Float64}
        @test denoised_img_1 == denoised_img_2
        @test denoised_img_1 == denoised_img_3
        @test assess(PSNR(), denoised_img_1, denoised_img_4) >= 50
        @test assess(SSIM(), denoised_img_1, denoised_img_4) >= 0.999
    end

    @testset "Types" begin
        # Gray
        img_gray = n0f8.(imresize(testimage("lena_gray_256"); ratio=0.25))
        n = AdditiveWhiteGaussianNoise(0.05)
        noisy_img = apply_noise(img_gray, n; rng=MersenneTwister(0))

        f = NonlocalMean(0.05, 2)
        type_list = generate_test_types([Float32, N0f8], [Gray])
        for T in type_list
            img = T.(noisy_img)
            @test_reference "References/NonlocalMean_Gray.png" Gray{N0f8}.(reduce_noise(img, f))
        end

        # Color3
        img_color = n0f8.(imresize(testimage("lena_color_256"); ratio=0.25))
        n = AdditiveWhiteGaussianNoise(0.05)
        noisy_img = apply_noise(img_color, n; rng=MersenneTwister(0))

        f = NonlocalMean(0.05, 2)
        type_list = generate_test_types([Float32, N0f8], [RGB, Lab])
        for T in type_list
            img = T.(noisy_img)
            @test_reference "References/NonlocalMean_Color3.png" RGB{N0f8}.(reduce_noise(img, f)) by=psnr_equality(24)
        end
    end

    @testset "Numeric" begin
        img_gray = n0f8.(imresize(testimage("lena_gray_256"); ratio=0.25))
        n = AdditiveWhiteGaussianNoise(0.05)
        noisy_img = apply_noise(img_gray, n; rng=MersenneTwister(0))

        f = NonlocalMean(0.05, 2)
        denoised_img = reduce_noise(noisy_img, f)
        # further modification shall not decrease psnr and ssim
        assess(PSNR(), denoised_img, img_gray) >= 28.46
        assess(SSIM(), denoised_img, img_gray) >= 0.918
    end
end
