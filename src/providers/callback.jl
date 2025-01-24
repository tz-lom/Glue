struct CallbackProvider <: AbstractProvider
    call::Function
    result::Type{<:Artifact}
    origin::AbstractProvider
end

inputs(::CallbackProvider) = ()
outputs(p::CallbackProvider) = (p.result,)
storage(::CallbackProvider) = ()

Base.show(io::IO, p::CallbackProvider) =
    print(io, "CallbackProvider $(nameof(p.call)) = $(nameof(p.origin.call))")

function provide(p::CallbackProvider, ::Type, context, resolve)
    return quote
        @inline () -> $(provide(p.origin, outputs(p.origin)[1], context, resolve))
    end
end


function define_callback_provider(name, artifact_name, origin)
    origin_provider = describe_provider(origin)
    type = artifact_type(outputs(origin_provider)[1])
    descr = gensym(:callable_provider)

    return quote
        $FunctionFusion.@artifact $artifact_name = Any

        function $name()
            error($("Can't call Callback Provider $name directly"))
        end
        const $descr = $CallbackProvider($name, $artifact_name, $origin_provider)

        $FunctionFusion.describe_provider(::typeof($name)) = $descr
    end
end

macro callback_provider(expr)
    @match expr begin
        Expr(
            :(=),
            [
                Expr(:(::), [Expr(:call, [name::Symbol]), artifact::Symbol]),
                Expr(:block, [_, origin::Symbol]),
            ],
        ) => begin
            quote
                Base.eval(
                    $__module__,
                    define_callback_provider(
                        $(QuoteNode(name)),
                        $(QuoteNode(artifact)),
                        $(esc(origin)),
                    ),
                )
            end
        end
        _ => throw(DomainError(expr, "Unsupported syntax"))
    end
end