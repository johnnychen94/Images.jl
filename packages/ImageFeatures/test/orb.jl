using FactCheck, Images, ImageFeatures, TestImages, Distributions, ColorTypes, TestImages

facts("ORB") do 
    
    orb_params = ORB(num_keypoints = 1000, threshold = 0.2)
    @fact orb_params.num_keypoints --> 1000 
    @fact orb_params.n_fast --> 12
    @fact orb_params.threshold --> 0.2
    @fact orb_params.harris_factor --> 0.04
    @fact orb_params.downsample --> 1.3
    @fact orb_params.levels --> 8
    @fact orb_params.sigma --> 1.2

    context("Testing with Standard Images - Lighthouse (Rotation 45)") do
        img = testimage("lighthouse")
        img_array_1 = convert(Array{Gray}, img)
        img_array_2 = _warp(img_array_1, pi / 4)

        orb_params = ORB(num_keypoints = 1000)

        desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
        desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
        matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
        reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 384)) for m in matches]
        @fact all(isapprox(rk[1], m[2][1], atol = 3) && isapprox(rk[2], m[2][2], atol = 3) for (rk, m) in zip(reverse_keypoints_1, matches)) --> true
    end

    context("Testing with Standard Images - Lighthouse (Rotation 45, Translation (50, 40))") do
        img = testimage("lighthouse")
        img_array_1 = convert(Array{Gray}, img)
        img_temp_2 = _warp(img_array_1, pi / 4)
        img_array_2 = _warp(img_temp_2, 50, 40)
        
        orb_params = ORB(num_keypoints = 1000)

        desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
        desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
        matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
        reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 384)) + CartesianIndex(50, 40) for m in matches]
        @fact all(isapprox(rk[1], m[2][1], atol = 3) && isapprox(rk[2], m[2][2], atol = 3) for (rk, m) in zip(reverse_keypoints_1, matches)) --> true
    end

    context("Testing with Standard Images - Lighthouse (Rotation 75, Translation (50, 40))") do
        img = testimage("lighthouse")
        img_array_1 = convert(Array{Gray}, img)
        img_temp_2 = _warp(img_array_1, 5 * pi / 6)
        img_array_2 = _warp(img_temp_2, 50, 40)
        
        orb_params = ORB(num_keypoints = 1000)

        desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
        desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
        matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
        reverse_keypoints_1 = [_reverserotate(m[1], 5 * pi / 6, (256, 384)) + CartesianIndex(50, 40) for m in matches]
        @fact sum(isapprox(rk[1], m[2][1], atol = 4) && isapprox(rk[2], m[2][2], atol = 4) for (rk, m) in zip(reverse_keypoints_1, matches)) + 1 --> length(matches)
    end

    context("Testing with Standard Images - Lena (Rotation 45, Translation (10, 20))") do
        img = testimage("lena_gray_512")
        img_array_1 = convert(Array{Gray}, img)
        img_temp_2 = _warp(img_array_1, pi / 4)
        img_array_2 = _warp(img_temp_2, 10, 20)
        
        orb_params = ORB(num_keypoints = 1000, threshold = 0.18)

        desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
        desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
        matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
        reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 256)) + CartesianIndex(10, 20) for m in matches]
        @fact sum(isapprox(rk[1], m[2][1], atol = 4) && isapprox(rk[2], m[2][2], atol = 4) for (rk, m) in zip(reverse_keypoints_1, matches)) + 3 --> length(matches)
    end
end