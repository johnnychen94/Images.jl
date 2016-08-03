using ImagesFiltering, OffsetArrays
using Base.Test

A = reshape(1:25, 5, 5)
@test @inferred(padarray(A, Fill(0,(2,2),(2,2)))) == OffsetArray(
    [0  0  0   0   0   0   0  0  0;
     0  0  0   0   0   0   0  0  0;
     0  0  1   6  11  16  21  0  0;
     0  0  2   7  12  17  22  0  0;
     0  0  3   8  13  18  23  0  0;
     0  0  4   9  14  19  24  0  0;
     0  0  5  10  15  20  25  0  0;
     0  0  0   0   0   0   0  0  0;
     0  0  0   0   0   0   0  0  0], (-2,-2))
@test @inferred(padarray(A, Pad{:replicate}((2,2),(2,2)))) == OffsetArray(
    [ 1  1  1   6  11  16  21  21  21;
      1  1  1   6  11  16  21  21  21;
      1  1  1   6  11  16  21  21  21;
      2  2  2   7  12  17  22  22  22;
      3  3  3   8  13  18  23  23  23;
      4  4  4   9  14  19  24  24  24;
      5  5  5  10  15  20  25  25  25;
      5  5  5  10  15  20  25  25  25;
      5  5  5  10  15  20  25  25  25], (-2,-2))
@test @inferred(padarray(A, Pad{:circular}((2,2),(2,2)))) == OffsetArray(
    [19  24  4   9  14  19  24  4   9;
     20  25  5  10  15  20  25  5  10;
     16  21  1   6  11  16  21  1   6;
     17  22  2   7  12  17  22  2   7;
     18  23  3   8  13  18  23  3   8;
     19  24  4   9  14  19  24  4   9;
     20  25  5  10  15  20  25  5  10;
     16  21  1   6  11  16  21  1   6;
     17  22  2   7  12  17  22  2   7], (-2,-2))
@test @inferred(padarray(A, Pad{:symmetric}((2,2),(2,2)))) == OffsetArray(
    [ 7  2  2   7  12  17  22  22  17;
      6  1  1   6  11  16  21  21  16;
      6  1  1   6  11  16  21  21  16;
      7  2  2   7  12  17  22  22  17;
      8  3  3   8  13  18  23  23  18;
      9  4  4   9  14  19  24  24  19;
     10  5  5  10  15  20  25  25  20;
     10  5  5  10  15  20  25  25  20;
      9  4  4   9  14  19  24  24  19], (-2,-2))
@test @inferred(padarray(A, Pad{:reflect}((2,2),(2,2)))) == OffsetArray(
    [13   8  3   8  13  18  23  18  13;
     12   7  2   7  12  17  22  17  12;
     11   6  1   6  11  16  21  16  11;
     12   7  2   7  12  17  22  17  12;
     13   8  3   8  13  18  23  18  13;
     14   9  4   9  14  19  24  19  14;
     15  10  5  10  15  20  25  20  15;
     14   9  4   9  14  19  24  19  14;
     13   8  3   8  13  18  23  18  13], (-2,-2))
ret = @test_throws ArgumentError padarray(A, Fill(0))
@test contains(ret.value.msg, "lacks the proper padding")
for Style in (:replicate, :circular, :symmetric, :reflect)
    ret = @test_throws ArgumentError padarray(A, Pad{Style}((1,),(1,)))
    @test contains(ret.value.msg, "lacks the proper padding")
    ret = @test_throws ArgumentError padarray(A, Pad{Style}((1,1,1),(1,1,1)))
    @test contains(ret.value.msg, "lacks the proper padding")
    ret = @test_throws ArgumentError padarray(A, Pad{Style})
    @test contains(ret.value.msg, "must supply padding")
end
# arrays smaller than the padding
A = [1 2; 3 4]
@test @inferred(padarray(A, Pad{:replicate}((3,3),(3,3)))) == OffsetArray(
    [ 1  1  1  1  2  2  2  2;
      1  1  1  1  2  2  2  2;
      1  1  1  1  2  2  2  2;
      1  1  1  1  2  2  2  2;
      3  3  3  3  4  4  4  4;
      3  3  3  3  4  4  4  4;
      3  3  3  3  4  4  4  4;
      3  3  3  3  4  4  4  4], (-3,-3))
@test @inferred(padarray(A, Pad{:circular}((3,3),(3,3)))) == OffsetArray(
    [ 4  3  4  3  4  3  4  3;
      2  1  2  1  2  1  2  1;
      4  3  4  3  4  3  4  3;
      2  1  2  1  2  1  2  1;
      4  3  4  3  4  3  4  3;
      2  1  2  1  2  1  2  1;
      4  3  4  3  4  3  4  3;
      2  1  2  1  2  1  2  1], (-3,-3))
@test @inferred(padarray(A, Pad{:symmetric}((3,3),(3,3)))) == OffsetArray(
    [ 4  4  3  3  4  4  3  3;
      4  4  3  3  4  4  3  3;
      2  2  1  1  2  2  1  1;
      2  2  1  1  2  2  1  1;
      4  4  3  3  4  4  3  3;
      4  4  3  3  4  4  3  3;
      2  2  1  1  2  2  1  1;
      2  2  1  1  2  2  1  1], (-3,-3))
@test @inferred(padarray(A, Pad{:reflect}((3,3),(3,3)))) == OffsetArray(
    [ 4  3  4  3  4  3  4  3;
      2  1  2  1  2  1  2  1;
      4  3  4  3  4  3  4  3;
      2  1  2  1  2  1  2  1;
      4  3  4  3  4  3  4  3;
      2  1  2  1  2  1  2  1;
      4  3  4  3  4  3  4  3;
      2  1  2  1  2  1  2  1], (-3,-3))
for Style in (:replicate, :circular, :symmetric, :reflect)
    @test @inferred(padarray(A, Pad{Style}((0,0), (0,0)))) == A
end
@test @inferred(padarray(A, Fill(0, (0,0), (0,0)))) == A
@test @inferred(padarray(A, Pad{:replicate}((1,2), (2,0)))) == OffsetArray([1 1 1 2; 1 1 1 2; 3 3 3 4; 3 3 3 4; 3 3 3 4], (-1,-2))
@test @inferred(padarray(A, Pad{:circular}((2,1), (0,2)))) == OffsetArray([2 1 2 1 2; 4 3 4 3 4; 2 1 2 1 2; 4 3 4 3 4], (-2,-1))
@test @inferred(padarray(A, Pad{:symmetric}((1,2), (2,0)))) == OffsetArray([2 1 1 2; 2 1 1 2; 4 3 3 4; 4 3 3 4; 2 1 1 2], (-1,-2))
@test @inferred(padarray(A, Fill(-1,(1,2), (2,0)))) == OffsetArray([-1 -1 -1 -1; -1 -1 1 2; -1 -1 3 4; -1 -1 -1 -1; -1 -1 -1 -1], (-1,-2))
A = [1 2 3; 4 5 6]
@test @inferred(padarray(A, Pad{:reflect}((1,2), (2,0)))) == OffsetArray([6 5 4 5 6; 3 2 1 2 3; 6 5 4 5 6; 3 2 1 2 3; 6 5 4 5 6], (-1,-2))
A = [1 2; 3 4]
@test @inferred(padarray(A, Pad(1,1))) == OffsetArray([1 1 2 2; 1 1 2 2; 3 3 4 4; 3 3 4 4], (-1,-1))
@test @inferred(padarray(A, Pad{:circular}((1,1), ()))) == OffsetArray([4 3 4; 2 1 2; 4 3 4], (-1,-1))
@test @inferred(padarray(A, Pad{:symmetric}((), (1,1)))) == [1 2 2; 3 4 4; 3 4 4]
A = ["a" "b"; "c" "d"]
@test @inferred(padarray(A, Pad(1,1))) == OffsetArray(["a" "a" "b" "b"; "a" "a" "b" "b"; "c" "c" "d" "d"; "c" "c" "d" "d"], (-1,-1))
@test_throws MethodError padarray(A, Pad{:unknown}(1,1))
A = trues(3,3)
@test isa(parent(padarray(A, Pad((1,2), (2,1)))), BitArray{2})
A = falses(10,10,10)
B = view(A,1:8,1:8,1:8)
@test isa(parent(padarray(A, Pad((1,1,1)))), BitArray{3})
@test isa(parent(padarray(B, Pad((1,1,1)))), BitArray{3})

nothing
