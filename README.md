# FindDefinition
*Locate methods defined through macros*

Methods defined through macros unhelpfully report their file and line numbers as those inside the macro definition. For example, this
```julia
# contents of foo.jl:
module Foo
  macro foo()
      :(bar() = x)  # line 3
  end

  @foo() # line 6
end

# somewhere else:
bar()
```
gives an `UndefVarError` with the stack trace pointing to line 3, rather than 6.

This module provides functions `finddef(method)` and `finddefs(f::Function)` returning `LineNumberNode`s for the macro call sites:
```julia
julia> using FindDefinition

julia> finddef(first(methods(Foo.bar)))
:(#= [...]/foo.jl:6 =#)

julia> finddefs(Foo.bar)
1-element Array{LineNumberNode,1}:
 :(#= [...]/foo.jl:6 =#)
 ```
 
 __Warning__: The current implementation uses `eval` inside loaded modules to match method signatures. This is probably harmless, but does produce new `gensym`ed symbols inside your loaded modules.
