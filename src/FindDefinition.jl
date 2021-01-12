module FindDefinition

export finddef, finddefs

import MacroTools

ismacrocall(_) = false
ismacrocall(expr::Expr) = expr.head == :macrocall

ismoduledef(_) = false
ismoduledef(e::Expr) = e.head == :module

isinclude(_) = false
isinclude(e::Expr) = e.head == :call && e.args[1] == :include

args(_) = []
args(e::Expr) = e.args

function collect_nodes(f, _module, ast)
    init = f(ast) ? [(from_module = _module, ex = ast)] : []
    if ismoduledef(ast)
        modulename = ast.args[2]
        _module = getproperty(_module, modulename)
    end
    reduce( ∪, collect_nodes(f, _module, arg) for arg in args(ast); init )
end

collect_includefiles(_module, ast) = [(; from_module = mod, file = ex.args[2]::String)
                                            for (mod, ex) in collect_nodes(isinclude, _module, ast)]

function parsefile(path, fromline = 1; greedy=true)
    str = read(path, String)
    newlines = only.(findall("\n", str))
    res = Expr[]
    pos = fromline == 1 ? 1 : newlines[fromline-1]+1
    while pos < length(str)
        lineshift = searchsortedfirst(newlines, pos) - 1
        fix_lnn(e) = e
        fix_lnn(lnn::LineNumberNode) = LineNumberNode(lnn.line + lineshift, path)

        expr, pos = Meta.parse(str, pos)
        isnothing(expr) && continue ## why can this happen?
        expr = MacroTools.postwalk(fix_lnn, expr)
        push!(res, expr)
        greedy || break
    end
    res
end

function rec_find_expr(f, _module, ast, includepath)
    res = collect_nodes(f, _module, ast)
    includes = collect_includefiles(_module, ast)
    for (mod, inc) in includes
        inc = joinpath(includepath, inc)
        for expr in parsefile(inc)
            append!(res, rec_find_expr(f, mod, expr, dirname(inc)))
        end
    end
    res
end

trysplitdef(ex) = try
    MacroTools.splitdef(ex)
catch
    nothing
end
# MacroTools.isdef is broken. See MacroTools issue #154
isfunctiondef(ex) = trysplitdef(ex) != nothing

argtypes(method) = Base.tail(tuple(method.sig.types...))
function defines_this_method(_module, ex, method)
    d = trysplitdef(ex)
    isnothing(d) && return false
    get(d,:name,nothing) != method.name && return false
    # TODO should be possible without `eval`, using `Meta.lower`
    newname = gensym()
    d[:name] = newname
    newexp = MacroTools.combinedef(d)
    f = _module.eval(newexp)
    exmethod = only(methods(f))
    return argtypes(exmethod) == argtypes(method) &&
           Base.kwarg_decl(exmethod) == Base.kwarg_decl(method)
end

macrocall_linenumnode(macrocall) = macrocall.args[2]
function find_definitions(method::Method)
    _module = method.module
    eval_method = only(methods(_module.eval))
    file, line = string(eval_method.file), eval_method.line
    module_def = only(parsefile(file, line; greedy=false))
    res = LineNumberNode[]
    mcls = rec_find_expr(ismacrocall, _module, module_def, dirname(file))
    for (_module, macrocall) in mcls
        lnn = macrocall_linenumnode(macrocall)
        expanded = macroexpand(_module, macrocall)
        funcdefs = collect_nodes(isfunctiondef, _module, expanded)
        for (_module, funcdef) in funcdefs
            if defines_this_method(_module, funcdef, method)
                #push!(res, (lnn, funcdef))
                push!(res, lnn)
            end
        end
    end
    res
end

find_definitions(f::Function) = reduce( ∪, find_definitions(m) for m in methods(f) )

finddef(m::Method) = last(find_definitions(m))
finddefs(f::Function) = map(finddef, methods(f))

end
