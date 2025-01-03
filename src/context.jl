abstract type AbstractContext end

abstract type ContextStack{Prev, Curr} end

struct ContextPtr{Root, Stack}
    root::Root
end

Base.show(io::IO,::MIME"text/plain", ::Type{ContextStack{Root}}) where {Root} = print(io, "[$Root]")
function Base.show(io::IO, type::MIME"text/plain", ::Type{ContextStack{Prev, Curr}}) where{Prev, Curr} 
    show(io, type, Prev)
    print(io, "[$Curr]")
end


function key end

# Redirect to the type based keys method
Base.keys(::T) where {T<:AbstractContext} = Base.keys(T)

Base.keys(::ContextPtr{Root, ContextStack{Parent, Child}}) where {Root, Parent, Child} = Base.keys(Child)
Base.keys(::ContextPtr{Root, ContextStack{Child}}) where {Root, Child} = Base.keys(Child)

function Base.getindex(c::C, ::Type{T}) where {C<:AbstractContext,T<:Artifact}
    return getfield(c, key(c, T))
end

function Base.getindex(c::C, ::Type{T}) where {C<:AbstractContext, T<:AbstractContext}
    return ContextPtr{C, ContextStack{T}}(c)
end

function Base.getindex(c::ContextPtr{Root, Prev}, ::Type{T}) where{Root, Prev, T<:Artifact}
    return getfield(c.root, key(c.root, ContextStack{Prev, T}))
end

function Base.getindex(c::ContextPtr{Root, Prev}, ::Type{T}) where{Root, Prev, T<:AbstractContext}
    return ContextPtr{Root, ContextStack{Prev, T}}(c.root)
end

function Base.getindex(c::ContextPtr{Root, Stack}) where{Root, Parent, Child, Stack<:ContextStack{Parent, Child}}
    return getfield(c.root, key(c.root, Stack))
end

function Base.getindex(c::ContextPtr{Root, Stack}) where{Root, Child, Stack<:ContextStack{ Child}}
    return getfield(c.root, key(c.root, Child))
end


function Base.setindex!(c::C, v, ::Type{T}) where {C<:AbstractContext, T<:Artifact}
    if !isnothing(getfield(c, key(c, T)))
        error("Artifact [$T] is already set")
    end
    return setfield!(c, key(c, T), Some(v))
end

function Base.setindex!(c::ContextPtr{Root, Prev}, v, ::Type{T}) where{Root, Prev, T<:Artifact}
    if !isnothing(getfield(c.root, key(c.root, ContextStack{Prev, T})))
        error("Artifact $Prev[$T] is already set")
    end
    return setfield!(c.root, key(c.root, ContextStack{Prev, T}), Some(v))
end


Base.haskey(::AbstractContext, _) = false

function define_context(context_name, artifacts...)
    # Each context shall define:
    # struct with fields
    # method `keys`
    # method `key`
    # method `show` for "text/plain"

    function enum_fields(x::Type{T}) where {T<:Artifact}
        return [T => Union{Nothing,Some{artifact_type(x)}}]
    end

    function enum_fields(x::Type{T}, ::Type{Parent}) where {T<:Artifact, Parent}
        return [ContextStack{Parent,T} => Union{Nothing,Some{artifact_type(x)}}]
    end

    function enum_fields(context::Type{C}) where {C <: AbstractContext}
        return mapreduce((x) -> enum_fields(x, ContextStack{C}), append!, keys(context), init=[])
    end

    function enum_fields(context::Type{C}, ::Type{Parent}) where {C<:AbstractContext, Parent}
        return mapreduce((x)->enum_fields(x, ContextStack{Parent,C}), append!, keys(context), init=[])
    end

    fields = mapreduce(enum_fields, append!, artifacts, init=[])


    fields_expr = map(enumerate(fields)) do (i,(_,type))
        local name = Symbol(:f,i)
        :($name::$type)
    end

    key_expr = map(enumerate(fields)) do (i, (name, _))
        local sym_name = Symbol(:f,i)
        :($FunctionFusion.key(::$context_name, ::Type{$name})=$(QuoteNode(sym_name)))
    end

    return quote
        mutable struct $context_name <: $AbstractContext
            $(fields_expr...)

            $context_name() = new($([nothing for _ in fields]...))
        end

        function Base.keys(::Type{$context_name})
            return $(Tuple([name for name in artifacts]))
        end

        $(key_expr...)
        
    end
end

"""
    @context(name, artifacts_or_contexts...)

Creates structure `name` which contains set of artifacts and contexts.
This structure implements single write, so it's elements can be stored only once.
Access to elements of the structure is done via index operator `[]` where key is the `Artifact` or `Context` types

Example:
```
@artifact A,B Int
@context Ctx A B

ctx = Ctx()
isnothing(ctx[A]) == true

ctx[A] = 1
isnothing(ctx[A]) == false
```

"""
macro context(name, artifacts...)
    return quote 
        Base.eval($__module__, $define_context($(QuoteNode(name)), $([esc(a) for a in artifacts]...)))
    end    
end

function show_artifact(io, ptr, name, spaces)
    value = ptr[]
    if isnothing(value)
        println(io, "$spaces[ ] $name")
    else
        println(io, "$spaces[✔] $name => $(something(value))")
    end
end

stack_pop(::Type{ContextStack{Last}}) where {Last} = Last
stack_pop(::Type{ContextStack{Prev, Last}}) where {Prev, Last} = Last

function Base.show(io::IO, type::MIME"text/plain", ptr::ContextPtr{Root, ContextStack{Parent, A}}) where {Root<:AbstractContext, Parent, A <:Artifact }
    spaces = get(io, :spaces, "")
    show_artifact(io, ptr, A, spaces)
end

function Base.show(io::IO, type::MIME"text/plain", ptr::ContextPtr{Root, ContextStack{A}}) where {Root<:AbstractContext, A <:Artifact }
    spaces = get(io, :spaces, "")
    show_artifact(io, ptr, A, spaces)
end

function Base.show(io::IO, type::MIME"text/plain", ptr::ContextPtr{Root, Stack}) where {Root, Stack<:ContextStack}
    spaces = get(io, :spaces, "")
    if spaces==""
        print(io, "In context $Root")
        show(io, type, Stack)
        println(io)
        nio = IOContext(io, :spaces=>"  ")
        for name in keys(ptr)
            show(nio, type, ContextPtr{Root,ContextStack{Stack,name}}(ptr.root))
        end
    else
        println(io, "$spaces[+] $(stack_pop(Stack))")
        nio = IOContext(io, :spaces=>"$spaces    ")
        for name in keys(ptr)
            show(nio, type, ContextPtr{Root,ContextStack{Stack,name}}(ptr.root))
        end
    end
end

function Base.show(io::IO, type::MIME"text/plain", ctx::T) where {T<:AbstractContext}
    println(io, "Context $T")
    nio = IOContext(io, :spaces => "  ")
    for name in keys(ctx)
        show(nio, type, ContextPtr{T,ContextStack{name}}(ctx))
    end
end

function Base.propertynames(::AbstractContext, ::Bool)
    return ()
end

function Base.getproperty(::AbstractContext, ::Symbol)
    error("no properties in AbstractContext, use array indexing instead")
end

function Base.setproperty!(::AbstractContext, ::Symbol, ::Any)
    error("no properties in AbstractContext, use array indexing instead")
end
