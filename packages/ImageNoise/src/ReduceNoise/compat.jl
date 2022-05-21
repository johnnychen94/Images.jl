"""
    _colon(I:J)

`_colon(I, J)` works equivelently to `I:J`, it's used to backward support julia v"1.0".
"""
_colon(I, J) = I:J
if v"1.0" <= VERSION < v"1.1"
    _colon(I::CartesianIndex{N}, J::CartesianIndex{N}) where N =
        CartesianIndices(map((i,j) -> i:j, Tuple(I), Tuple(J)))
end

# patch for ColorVectorSpace 0.9
# for CVS < 0.9, we can just use the fallback solution in Distances
if isdefined(ImageCore.ColorVectorSpace, :⊙)
    # Because how abs2 calculated in color vector space is ambiguious, abs2(::RGB) is un-defined
    # since ColorVectorSpace 0.9
    # https://github.com/JuliaGraphics/ColorVectorSpace.jl/pull/131
    @inline _abs2(c::Colorant) = mapreducec(v->float(v)^2, +, 0, c)
    @inline _abs2(x) = abs2(x)
    @inline _abs(c::Colorant) = mapreducec(v->abs(float(v)), +, 0, c)
    @inline _abs(x) = abs(x)
else
    const _abs2 = abs2
    const _abs = abs
end
