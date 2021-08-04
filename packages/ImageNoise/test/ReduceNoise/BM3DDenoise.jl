@testset "BM3DDenoise" begin
    @info "Test: BM3DDenoise"
    @testset "Numeric" begin
        img_gray = n0f8.(imresize(testimage("lena_gray_256"); ratio=0.25))
        n = AdditiveWhiteGaussianNoise(0.05)
        noisy_img = apply_noise(img_gray, n; rng=MersenneTwister(0))

        f = BM3D(0.05)
        denoised_img = reduce_noise(noisy_img, f)
        # further modification shall not decrease psnr and ssim
        @test assess(PSNR(), denoised_img, img_gray) >= 28.
        @test assess(SSIM(), denoised_img, img_gray) >= 0.9
    end
end
