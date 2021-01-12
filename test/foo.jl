module Foo
    macro foo(x)
        esc(:(bar() = $x))
    end
    macro foo_y(x)
        esc(:(bar(y) = y + $x))
    end
    macro multifoo(x)
        _multifoo_impl(x)
    end
    _multifoo_impl(x) = esc(quote
        multibar() = $x
        multibar(y) = y
        multibar(z::Int, args...) = z + 1
    end)
end
