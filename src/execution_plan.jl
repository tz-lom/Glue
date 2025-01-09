
struct ExecutionPlan
    providers::OrderedSet{AbstractProvider}
    provider_for_artifact::Dict{Type{<:Artifact},AbstractProvider}
    artifacts::OrderedSet{Type{<:Artifact}}
    inputs::OrderedSet{Type{<:Artifact}}
    outputs::OrderedSet{Type{<:Artifact}}
    can_generate::OrderedSet{Type{<:Artifact}}

    function ExecutionPlan(providers)
        provider_for_artifact = Dict{Type{<:Artifact},AbstractProvider}()


        input_set = OrderedSet{Type{<:Artifact}}()
        output_set = OrderedSet{Type{<:Artifact}}()

        for provider in providers
            for input in FunctionFusion.inputs(provider)
                push!(input_set, input)
            end

            for output in FunctionFusion.outputs(provider)
                provider_for_artifact[output] = provider
                push!(output_set, output)
            end
        end

        artifacts = union(input_set, output_set)
        inputs = setdiff(input_set, output_set)
        outputs = setdiff(output_set, input_set)


        return new(
            OrderedSet(providers),
            provider_for_artifact,
            artifacts,
            inputs,
            outputs,
            output_set,
        )
    end
end

function Base.(==)(left::ExecutionPlan, right::ExecutionPlan)
    return left.providers == right.providers
end

Base.show(io::IO, p::ExecutionPlan) = print(
    io,
    """ExecutionPlan
  inputs = $((p.inputs...,))
  outputs = $((p.outputs...,))
  can_generate = $((p.can_generate...,))
  providers = $((p.providers...,))""",
)