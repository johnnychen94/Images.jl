using FactCheck, Images, ImageFeatures, TestImages, Distributions, ColorTypes, TestImages

facts("FREAK") do 
    
    freak_params = FREAK(pattern_scale = 20.0)
    @fact freak_params.pattern_scale --> 20.0
    pt, st = ImageFeatures._freak_tables(20.0)
    @fact freak_params.pattern_table --> pt
    @fact freak_params.smoothing_table --> st

    context("Testing with Standard Images - Lighthouse (Rotation 45)") do
        img = testimage("lighthouse")
        img_array_1 = convert(Array{Gray}, img)
        img_array_2 = _warp(img_array_1, pi / 4)

        keypoints_1 = Keypoints(fastcorners(img_array_1, 12, 0.35))
        keypoints_2 = Keypoints(fastcorners(img_array_2, 12, 0.35))
        freak_params = FREAK()

        desc_1, ret_keypoints_1 = create_descriptor(img_array_1, keypoints_1, freak_params)
        desc_2, ret_keypoints_2 = create_descriptor(img_array_2, keypoints_2, freak_params)
        matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.1)
        reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 384)) for m in matches]
        @fact all(isapprox(rk[1], m[2][1], atol = 4) && isapprox(rk[2], m[2][2], atol = 4) for (rk, m) in zip(reverse_keypoints_1, matches)) --> true
    end

    context("Testing with Standard Images - Lighthouse (Rotation 45, Translation (50, 40))") do
        img = testimage("lighthouse")
        img_array_1 = convert(Array{Gray}, img)
        img_temp_2 = _warp(img_array_1, pi / 4)
        img_array_2 = _warp(img_temp_2, 50, 40)

        keypoints_1 = Keypoints(fastcorners(img_array_1, 12, 0.35))
        keypoints_2 = Keypoints(fastcorners(img_array_2, 12, 0.35))
        freak_params = FREAK()

        desc_1, ret_keypoints_1 = create_descriptor(img_array_1, keypoints_1, freak_params)
        desc_2, ret_keypoints_2 = create_descriptor(img_array_2, keypoints_2, freak_params)
        matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.1)
        reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 384)) + CartesianIndex(50, 40) for m in matches]
        @fact all(isapprox(rk[1], m[2][1], atol = 3) && isapprox(rk[2], m[2][2], atol = 3) for (rk, m) in zip(reverse_keypoints_1, matches)) --> true
end

    context("Testing with Standard Images - Lighthouse (Rotation 75, Translation (50, 40))") do
        img = testimage("lighthouse")
        img_array_1 = convert(Array{Gray}, img)
        img_temp_2 = _warp(img_array_1, 5 * pi / 6)
        img_array_2 = _warp(img_temp_2, 50, 40)

        keypoints_1 = Keypoints(fastcorners(img_array_1, 12, 0.35))
        keypoints_2 = Keypoints(fastcorners(img_array_2, 12, 0.35))
        freak_params = FREAK()

        desc_1, ret_keypoints_1 = create_descriptor(img_array_1, keypoints_1, freak_params)
        desc_2, ret_keypoints_2 = create_descriptor(img_array_2, keypoints_2, freak_params)
        matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.1)
        reverse_keypoints_1 = [_reverserotate(m[1], 5 * pi / 6, (256, 384)) + CartesianIndex(50, 40) for m in matches]
        @fact all(isapprox(rk[1], m[2][1], atol = 4) && isapprox(rk[2], m[2][2], atol = 4) for (rk, m) in zip(reverse_keypoints_1, matches)) --> true
    end

    context("Testing with Standard Images - Lena (Rotation 45, Translation (10, 20))") do
        img = testimage("lena_gray_512")
        img_array_1 = convert(Array{Gray}, img)
        img_temp_2 = _warp(img_array_1, pi / 4)
        img_array_2 = _warp(img_temp_2, 10, 20)

        keypoints_1 = Keypoints(fastcorners(img_array_1, 12, 0.2))
        keypoints_2 = Keypoints(fastcorners(img_array_2, 12, 0.2))
        freak_params = FREAK()

        desc_1, ret_keypoints_1 = create_descriptor(img_array_1, keypoints_1, freak_params)
        desc_2, ret_keypoints_2 = create_descriptor(img_array_2, keypoints_2, freak_params)
        matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.1)
        reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 256)) + CartesianIndex(10, 20) for m in matches]
        @fact sum(isapprox(rk[1], m[2][1], atol = 4) && isapprox(rk[2], m[2][2], atol = 4) for (rk, m) in zip(reverse_keypoints_1, matches)) + 1 --> length(matches)
    end
end