
module Test_Visualization
using Test, FunctionFusion

function to_dot(x)
    g = FunctionFusion.GraphBuilder(mod = @__MODULE__)
    FunctionFusion.render!(g, x)
    return FunctionFusion.as_dot(g)
end

@artifact A1, A2, A3, A4, A5, A6 = Int
@artifact B1 = Bool

@provider P1(x::A1, y::A2)::A3 = x + y
@provider P2(x::A3)::A4 = x
@provider P3(x::A4, y::A2)::A5 = x + y

@algorithm Gen1[P1](A1, A2)::A3
@algorithm Gen3[P1, P2, P3](A1, A2)::A5

@conditional C1::A3 = B1 ? A1 : A2

@promote P4 A1 A2

@provider P5(x::A1)::A5 = x + 1

@group G1 P1 P5

@unimplemented U1(A1)::A2

@invoke_with I1 = Gen1{A2 => A4}

@invoke_with I2 = Gen1{A2 => A5,A3 => A6}
@artifact A7 = Int
@provider P5(x::A3, y::A6)::A7 = x + y

@algorithm Gen4[I1, I2, P2, P5, Gen3](A1, A2, A4)::A7

@algorithm N1[P2](A3)::A4
@algorithm N2[N1](A3)::A4

@testset "Provider" begin

    @test to_dot(P1) == raw"""
    digraph { compound=true;
    provider_1 [shape="rectangle",label="P1",style="filled",color="#ff8c61",fillcolor="#faa275"]
    artifact_2 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_3 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_4 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]

    provider_1 -> artifact_2
    artifact_3 -> provider_1
    artifact_4 -> provider_1
    }
    """
end

@testset "Algorithm1" begin

    @test to_dot(Gen1) == raw"""
    digraph { compound=true;
    subgraph cluster_algorithm_1 {
    label="Algorithm Gen1"
    subgraph cluster_algorithm_1_inputs {
    label="Inputs"
    artifact_2 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_3 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    } // cluster_algorithm_1_inputs
    subgraph cluster_algorithm_1_outputs {
    label="Outputs"
    artifact_4 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    } // cluster_algorithm_1_outputs
    provider_5 [shape="rectangle",label="P1",style="filled",color="#ff8c61",fillcolor="#faa275"]
    } // cluster_algorithm_1

    provider_5 -> artifact_4
    artifact_2 -> provider_5
    artifact_3 -> provider_5
    }
    """
end

@testset "Algorithm3" begin
    @test to_dot(Gen3) == raw"""
    digraph { compound=true;
    subgraph cluster_algorithm_1 {
    label="Algorithm Gen3"
    subgraph cluster_algorithm_1_inputs {
    label="Inputs"
    artifact_2 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_3 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    } // cluster_algorithm_1_inputs
    subgraph cluster_algorithm_1_outputs {
    label="Outputs"
    artifact_4 [label="A5\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    } // cluster_algorithm_1_outputs
    provider_5 [shape="rectangle",label="P1",style="filled",color="#ff8c61",fillcolor="#faa275"]
    artifact_6 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    provider_7 [shape="rectangle",label="P2",style="filled",color="#ff8c61",fillcolor="#faa275"]
    artifact_8 [label="A4\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    provider_9 [shape="rectangle",label="P3",style="filled",color="#ff8c61",fillcolor="#faa275"]
    } // cluster_algorithm_1

    provider_5 -> artifact_6
    artifact_2 -> provider_5
    artifact_3 -> provider_5
    provider_7 -> artifact_8
    artifact_6 -> provider_7
    provider_9 -> artifact_4
    artifact_8 -> provider_9
    artifact_3 -> provider_9
    }
    """
end


@testset "Conditional" begin
    @test to_dot(C1) == raw"""
    digraph { compound=true;
    conditional_1 [shape="diamond",label="C1",style="filled",color="#b23a48",fillcolor="#fcb902"]
    artifact_2 [label="B1\nBool",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_3 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_4 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_5 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]

    artifact_2 -> conditional_1 [label="?"]
    artifact_3 -> conditional_1 [label="true"]
    artifact_4 -> conditional_1 [label="false"]
    conditional_1 -> artifact_5
    }
    """
end



@testset "Promote" begin
    @test to_dot(P4) == raw"""
    digraph { compound=true;
    promote_1 [shape="rpromoter",label="P4",style="filled",color="#ff8c61",fillcolor="#faa275"]
    artifact_2 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_3 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]

    promote_1 -> artifact_2
    artifact_3 -> promote_1
    }
    """
end

@testset "Group" begin
    @test to_dot(G1) == raw"""
    digraph { compound=true;
    subgraph cluster_group_1 {
    label="Group G1"
    provider_2 [shape="rectangle",label="P1",style="filled",color="#ff8c61",fillcolor="#faa275"]
    artifact_3 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_4 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_5 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    provider_6 [shape="rectangle",label="P5",style="filled",color="#ff8c61",fillcolor="#faa275"]
    artifact_7 [label="A5\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    } // cluster_group_1

    provider_2 -> artifact_3
    artifact_4 -> provider_2
    artifact_5 -> provider_2
    provider_6 -> artifact_7
    artifact_4 -> provider_6
    }
    """
end

@testset "Unimplemented" begin
    @test to_dot(U1) == raw"""
    digraph { compound=true;
    unimplemented_1 [shape="rectangle",label="Unimplemented U1",color="#ff8c61"]
    artifact_2 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_3 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]

    unimplemented_1 -> artifact_2
    artifact_3 -> unimplemented_1
    }
    """
end

@testset "Invoke with" begin
    @test to_dot(I1) == raw"""
    digraph { compound=true;
    invoke_1 [shape="record",label="{{<invoke_1_input_2>A1|<invoke_1_input_3>A4⇥A2}|I1|{<invoke_1_output_4>A3}}"]
    subgraph cluster_algorithm_5 {
    label="Algorithm Gen1"
    subgraph cluster_algorithm_5_inputs {
    label="Inputs"
    artifact_6 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    artifact_7 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    } // cluster_algorithm_5_inputs
    subgraph cluster_algorithm_5_outputs {
    label="Outputs"
    artifact_8 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
    } // cluster_algorithm_5_outputs
    provider_9 [shape="rectangle",label="P1",style="filled",color="#ff8c61",fillcolor="#faa275"]
    } // cluster_algorithm_5
    artifact_10 [label="A4\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]

    provider_9 -> artifact_8
    artifact_6 -> provider_9
    artifact_7 -> provider_9
    artifact_8 -> invoke_1:invoke_1_output_4
    invoke_1:invoke_1_input_2 -> artifact_6
    invoke_1:invoke_1_input_3 -> artifact_7
    artifact_10 -> invoke_1:invoke_1_input_3
    }
    """
end

@testset "Multiple invoke" begin
    @test to_dot(Gen4) = raw"""
    """
end

end