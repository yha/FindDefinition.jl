module Bar1
    include("foo.jl")
    using .Foo: @foo
    m() = r
    q() = z
    @foo y
end

include("foo.jl")
module Bar2
    using ..Foo: @foo, @foo_y, @multifoo
    @foo u
    @foo v
    @foo_y w
    @multifoo q
end
