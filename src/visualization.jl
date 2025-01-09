# using GraphvizDotLang: GraphvizDotLang, Graph, digraph, edge, attr, subgraph

import GraphViz

#@todo: add module inside and setup pretty printing
struct NameShortener
    values::IdDict
    function NameShortener(mod::Module = Main)
        if VERSION >= v"1.12"
            all_names = names(mod, all = true, imported = true, usings = true)
        else
            all_names = names(mod, all = true, imported = true)
        end

        return new(IdDict(getproperty(mod, name) => name for name in all_names))
    end
end

function short_name(ctx::NameShortener, @nospecialize(x))
    postfix = ""
    while true
        # @warn "?" name name in all_names
        if haskey(ctx.values, x)
            return "$(ctx.values[x])$postfix"
        end
        postfix = ".$(nameof(x))$postfix"
        y = parentmodule(x)
        if y === x
            error("Unreachable symbol $x")
        end
    end
end

mutable struct GraphBuilder
    connections::Vector{String}
    added_entities::IdDict{Any,Symbol}
    shortener::NameShortener
    clusters::Vector{String}
    current_place::Int
    id_incr::Int

    GraphBuilder(; mod = Main) = new([], IdDict(), NameShortener(mod), [], 1, 0)
end

function as_dot(ctx::GraphBuilder)
    return """
    digraph { compound=true;
    $(join(ctx.clusters, '\n'))

    $(join(ctx.connections, '\n'))
    }
    """
end

function add_to_cluster!(ctx::GraphBuilder, s::String)
    insert!(ctx.clusters, ctx.current_place, s)
    ctx.current_place += 1
    return ctx.current_place
end

function create_cluster!(f, ctx::GraphBuilder, name; props...)
    str_props = ["$name=\"$(escape_string(value))\"" for (name, value) in props]
    add_to_cluster!(ctx, "subgraph cluster_$name {")
    add_to_cluster!(ctx, join(str_props, ";"))
    f()
    add_to_cluster!(ctx, "} // cluster_$name")
end

function connect!(ctx::GraphBuilder, left, right; props...)
    local edge = node("$left -> $right"; props...)
    push!(ctx.connections, edge)
    return ctx
end

function node(name; props...)
    str_props = ["$name=\"$(escape_string(value,keep="\\"))\"" for (name, value) in props]

    if length(str_props) > 0
        return "$name [$(join(str_props, ','))]"
    else
        return "$name"
    end
end

function new_id(ctx::GraphBuilder, prefix::Symbol)
    return Symbol(prefix, "_", ctx.id_incr += 1)
end

function render!(ctx::GraphBuilder, a::Type{T}) where {T<:Artifact}
    if !haskey(ctx.added_entities, a)
        id = new_id(ctx, :artifact)
        name = short_name(ctx.shortener, a)
        label = "$name\n$(artifact_type(a))"
        add_to_cluster!(
            ctx,
            node(
                id;
                label,
                shape = "ellipse",
                style = "filled",
                color = "#4a7c59",
                fillcolor = "#8fc0a9",
            ),
        )
        ctx.added_entities[a] = id
    end
    return ctx.added_entities[a]
end

function render!(ctx::GraphBuilder, x)
    render!(ctx, describe_provider(x))
end


function render!(ctx::GraphBuilder, p::AlgorithmProvider)
    if !haskey(ctx.added_entities, p)
        id = new_id(ctx, :algorithm)
        ctx.added_entities[p] = id
        name = short_name(ctx.shortener, p.call)


        create_cluster!(ctx, id, label = "Algorithm $name") do
            create_cluster!(ctx, "$(id)_inputs", label = "Inputs") do
                for a in p.inputs
                    render!(ctx, a)
                end
            end
            create_cluster!(ctx, "$(id)_outputs", label = "Outputs") do
                # for a in p.output
                render!(ctx, p.output)
                # end
            end
            for x in p.plan.providers
                render!(ctx, x)
            end
        end
    end
    return ctx.added_entities[p]
end

function render!(ctx::GraphBuilder, p::CallableProvider)
    if !haskey(ctx.added_entities, p)
        id = new_id(ctx, :provider)
        ctx.added_entities[p] = id
        name = short_name(ctx.shortener, p.call)

        descr = short_description(p)
        if isnothing(descr)
            descr = ""
        else
            descr = "\n$descr"
        end
        add_to_cluster!(
            ctx,
            node(
                id;
                shape = "rectangle",
                label = "$name$descr",
                style = "filled",
                color = "#ff8c61",
                fillcolor = "#faa275",
            ),
        )
        # for a in p.output
        other = render!(ctx, p.output)
        connect!(ctx, id, other)
        # end
        for a in p.inputs
            other = render!(ctx, a)
            connect!(ctx, other, id)
        end
    end
    return ctx.added_entities[p]
end

function render!(ctx::GraphBuilder, p::PromoteProvider)
    if !haskey(ctx.added_entities, p)
        id = new_id(ctx, :promote)
        ctx.added_entities[p] = id

        name = short_name(ctx.shortener, p.call)

        add_to_cluster!(
            ctx,
            node(
                id;
                shape = "rpromoter",
                label = name,
                style = "filled",
                color = "#ff8c61",
                fillcolor = "#faa275",
            ),
        )

        connect!(ctx, id, render!(ctx, p.output))
        connect!(ctx, render!(ctx, p.input), id)
    end
    return ctx.added_entities[p]
end

function render!(ctx::GraphBuilder, p::ConditionalProvider)
    if !haskey(ctx.added_entities, p)
        id = new_id(ctx, :conditional)
        ctx.added_entities[p] = id
        name = short_name(ctx.shortener, p.call)

        add_to_cluster!(
            ctx,
            node(
                id;
                shape = "diamond",
                label = name,
                style = "filled",
                color = "#b23a48",
                fillcolor = "#fcb902",
            ),
        )

        connect!(ctx, render!(ctx, p.condition), id; label = "?")
        connect!(ctx, render!(ctx, p.if_true), id; label = "true")
        connect!(ctx, render!(ctx, p.if_false), id; label = "false")
        connect!(ctx, id, render!(ctx, p.output))
    end
    return ctx.added_entities[p]
end

function render!(ctx::GraphBuilder, p::GroupProvider)
    if !haskey(ctx.added_entities, p)
        id = new_id(ctx, :group)
        ctx.added_entities[p] = id
        name = short_name(ctx.shortener, p.call)

        create_cluster!(ctx, id, label = "Group $name") do
            for p in p.plan.providers
                render!(ctx, p)
            end
        end
    end
    return ctx.added_entities[p]
end


function render!(ctx::GraphBuilder, p::UnimplementedProvider)
    if !haskey(ctx.added_entities, p)
        id = new_id(ctx, :unimplemented)
        ctx.added_entities[p] = id
        name = short_name(ctx.shortener, p.call)

        descr = short_description(p)
        if isnothing(descr)
            descr = ""
        else
            descr = "\n$descr"
        end
        add_to_cluster!(
            ctx,
            node(
                id;
                shape = "rectangle",
                label = "Unimplemented $name$descr",
                # style = "filled",
                color = "#ff8c61",
                # fillcolor = "#faa275",
            ),
        )
        # for a in p.output
        other = render!(ctx, p.output)
        connect!(ctx, id, other)
        # end
        for a in p.inputs
            other = render!(ctx, a)
            connect!(ctx, other, id)
        end
    end
    return ctx.added_entities[p]
end

function render!(ctx::GraphBuilder, p::InvokeProvider)
    if !haskey(ctx.added_entities, p)
        id = new_id(ctx, :invoke)
        ctx.added_entities[p] = id
        name = short_name(ctx.shortener, p.call)

        descr = short_description(p)
        if isnothing(descr)
            descr = name
        else
            descr = "$name\n$descr"
        end

        descr = replace(
            descr,
            "{" => "\\{",
            "}" => "\\}",
            ">" => "\\>",
            "<" => "\\<",
            "|" => "\\|",
        )

        inputs_label = []
        inputs_maps = []
        for a in inputs(p.algorithm)
            a_id = new_id(ctx, Symbol(id, :_input))
            a_replace = get(p.backward_substitutions, a, a)
            push!(inputs_maps, (a_id, a, a_replace))
            if a !== a_replace
                push!(
                    inputs_label,
                    "<$a_id>$(short_name(ctx.shortener, a_replace))⇥$(short_name(ctx.shortener, a))",
                )
            else
                push!(inputs_label, "<$a_id>$(short_name(ctx.shortener, a))")
            end
        end

        outputs_label = []
        outputs_maps = []
        for a in outputs(p.algorithm)
            a_id = new_id(ctx, Symbol(id, :_output))
            a_replace = get(p.backward_substitutions, a, a)
            push!(outputs_maps, (a_id, a, a_replace))
            if a !== a_replace
                push!(
                    outputs_label,
                    "<$a_id>$(short_name(ctx.shortener, a_replace))⇥$(short_name(ctx.shortener, a))",
                )
            else
                push!(outputs_label, "<$a_id>$(short_name(ctx.shortener, a))")
            end
        end

        add_to_cluster!(
            ctx,
            node(
                id;
                shape = "record",
                label = "{{$(join(inputs_label, "|"))}|$descr|{$(join(outputs_label,"|"))}}",
                # style = "filled",
                # color = "#ff8c61",
                # fillcolor = "#faa275",
            ),
        )

        render!(ctx, p.algorithm)

        for (gate_id, a, a_replace) in outputs_maps
            other = render!(ctx, a)
            connect!(ctx, other, "$id:$gate_id")
            if a !== a_replace
                other = render!(ctx, a_replace)
                connect!(ctx, "$id:$gate_id", other)
            end
        end
        for (gate_id, a, a_replace) in inputs_maps
            other = render!(ctx, a)
            connect!(ctx, "$id:$gate_id", other)
            if a !== a_replace
                other = render!(ctx, a_replace)
                connect!(ctx, other, "$id:$gate_id")
            end
        end
    end
    return ctx.added_entities[p]
end



# const Grph = Union{GraphvizDotLang.Graph,GraphvizDotLang.Subgraph}

# # GraphViz.

# as_id(f::Function) = String(Symbol(parentmodule(f), '.', f))
# as_id(t::Type) = String(Symbol(t))
# as_id(s::Symbol) = String(s)

# function node(id::String, port::Union{String,Nothing} = nothing; kwargs...)
#     g -> begin

#         nid = GraphvizDotLang.NodeId(id, port)
#         nd = findfirst(
#             el -> typeof(el) === GraphvizDotLang.NodeStmt && el.id == nid,
#             g.stmt_list,
#         )

#         if nd === nothing
#             g |> GraphvizDotLang.node(id, port; kwargs...)
#         end
#         g
#     end
# end


# function visualize!(g::Grph, a::Type{<:Artifact}, _)
#     id = as_id(a)
#     g |> node(
#         as_id(a),
#         ;
#         shape = "ellipse",
#         label = "$id\n$(artifact_type(a))",
#         style = "filled",
#         color = "#4a7c59",
#         fillcolor = "#8fc0a9",
#     )
# end

# function visualize!(g::Grph, p::CallableProvider, root::Graph)
#     id = as_id(p.call)
#     descr = short_description(p)
#     if isnothing(descr)
#         descr = ""
#     else
#         descr = "\n$descr"
#     end
#     g |> node(
#         id;
#         shape = "rectangle",
#         label = "$id$descr",
#         style = "filled",
#         color = "#ff8c61",
#         fillcolor = "#faa275",
#     )

#     for inp in p.inputs
#         visualize!(g, inp, root)
#         g |> edge(as_id(inp), id)
#     end

#     visualize!(g, p.output, root)
#     g |> edge(id, as_id(p.output))
# end


# function visualize!(g::Grph, p::UnimplementedProvider, root::Graph)
#     id = as_id(p.call)
#     descr = short_description(p)
#     if isnothing(descr)
#         descr = ""
#     else
#         descr = "\n$descr"
#     end
#     g |> node(
#         id;
#         shape = "hexagon",
#         label = "$id$descr",
#         style = "filled",
#         color = "#ff8c61",
#         fillcolor = "#faa275",
#     )

#     for inp in p.inputs
#         visualize!(g, inp, root)
#         g |> edge(as_id(inp), id)
#     end

#     visualize!(g, p.output, root)
#     g |> edge(id, as_id(p.output))
# end

# function visualize!(g::Grph, p::ConditionalProvider, root::Graph)
#     id = as_id(p.name)
#     g |> node(
#         id;
#         shape = "diamond",
#         label = "$id",
#         style = "filled",
#         color = "#b23a48",
#         fillcolor = "#fcb902",
#     )


#     visualize!(g, p.condition, root)
#     g |> edge(as_id(p.condition), id; label = "?")

#     visualize!(g, p.if_true, root)
#     g |> edge(as_id(p.if_true), id; label = "true")

#     visualize!(g, p.if_false, root)
#     g |> edge(as_id(p.if_false), id; label = "false")

#     visualize!(g, p.output, root)
#     g |> edge(id, as_id(p.output))
# end

# function visualize!(g::Grph, p::AlgorithmProvider, root::Graph)
#     id = as_id(p.call)

#     sub = g #subgraph(g, "cluster_" * id; label = id)

#     sub_inputs =
#         subgraph(sub, "cluster_" * id * "inputs"; label = "Inputs", style = "dashed")

#     for inp in p.inputs
#         visualize!(sub_inputs, inp, root)
#     end

#     sub_outputs =
#         subgraph(sub, "cluster_$(id)_outputs", label = "Outputs", style = "dashed")

#     visualize!(sub_outputs, p.output, root)

#     for provider in p.plan.providers
#         visualize!(sub, provider, root)
#     end
# end

# function visualize!(g::Grph, p::InvokeProvider, root::Graph)
#     visualize!(g, p.algorithm, root)
# end

# # function visualize!(g::Grph, p::ComposedProvider, root::Graph)
# #     id = as_id(p.call)

# #     sub_id = "cluster_composed_$(id)"

# #     nd = findfirst(
# #         el -> typeof(el) === GraphvizDotLang.NodeStmt && el.id == sub_id,
# #         root.stmt_list,
# #     )
# #     if nd === nothing

# #         sub = subgraph(root, sub_id; label = "$id implementation")

# #         for inp in p.inputs
# #             sub |> node(
# #                 as_id(inp[1]);
# #                 shape = "ellipse",
# #                 label = "$(as_id(inp[1]))\n⇤ $(as_id(inp[2]))\n$(artifact_type(inp[1]))",
# #                 style = "filled",
# #                 color = "#5c374c",
# #                 fillcolor = "#985277",
# #             )
# #         end

# #         for inp in p.outputs
# #             sub |> node(
# #                 as_id(inp[2]);
# #                 shape = "ellipse",
# #                 label = "$(as_id(inp[2]))\n⇥ $(as_id(inp[1]))\n$(artifact_type(inp[2]))",
# #                 style = "filled",
# #                 color = "#5c374c",
# #                 fillcolor = "#985277",
# #             )
# #         end

# #         for provider in p.plan.providers
# #             visualize!(sub, provider, root)
# #         end
# #     end

# #     g |> node(
# #         id;
# #         label = id,
# #         shape = "component",
# #         style = "filled",
# #         color = "#5c374c",
# #         fillcolor = "#985277",
# #     )

# #     g |> edge(
# #         id,
# #         as_id(first(p.plan.inputs)),
# #         lhead = sub_id,
# #         arrowhead = "none",
# #         style = "dotted",
# #         constraint = "false",
# #     )

# #     for inp in inputs(p)
# #         visualize!(g, inp, root)
# #         g |> edge(as_id(inp), id)
# #     end
# #     for out in outputs(p)
# #         visualize!(g, out, root)
# #         g |> edge(id, as_id(out))
# #     end
# # end

# function visualize!(g::Grph, p::PromoteProvider, root::Graph)
#     id = as_id(p.call)

#     visualize!(g, p.input, root)
#     visualize!(g, p.output, root)

#     g |> node(
#         id;
#         shape = "rpromoter",
#         label = id,
#         style = "filled",
#         color = "#e6b89c",
#         fillcolor = "#ead2ac",
#     )
#     g |> edge(as_id(p.input), id)
#     g |> edge(id, as_id(p.output))
# end

# function visualize!(g::Grph, p::GroupProvider, root::Graph)
#     id = as_id(p.call)

#     sub = subgraph(g, "cluster_group_$id#aside"; label = "Group $id")
#     for provider in p.plan.providers
#         visualize!(sub, provider, root)
#     end

#     # g |> node(id; label = id)

#     # for inp in inputs(p)
#     #     visualize!(g, inp)
#     #     g |> edge(as_id(inp), id)
#     # end
#     # for out in outputs(p)
#     #     visualize!(g, out)
#     #     g |> edge(id, as_id(out))
#     # end

# end

# function visualize(p::AbstractProvider)
#     g = digraph(compound = "true")
#     visualize!(g, p, g)
#     return g
# end

# function visualize(lst::Vector)
#     providers = collect_providers(lst)
#     g = digraph(compound = "true")
#     foreach(p -> visualize!(g, p, g), providers)
#     return g
# end

# function visualize(p)
#     visualize(describe_provider(p))
# end

# function render(g::Graph)
#     io = IOBuffer()
#     print(io, g)
#     return GraphViz.Graph(String(take!(io)))
# end

