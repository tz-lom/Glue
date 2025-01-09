```graphviz
digraph G {
  
//      compound=true;

// b 
// a1
// a2

 //{
 //  rank=same
 //  b a1 a2
 //}

  "##foo#232" [label="kek"] 
  "##foo#233" [label="kek2"] 

  "##foo#233" -> "##foo#232"

  subgraph cluster_3 {
      label="Algorithm A"
      subgraph cluster_i {
          label="input"
        a
      }
      subgraph  {
          label=""
        b
        c
        d
        
        
        subgraph cluster_2 {
            label="Group 1"
            g
            h [shape="record", label="inp1|My na\{\}me|{outp|outp2}}"]
        }
        
      }
      
      subgraph cluster_o {
          label="output"
        e
      }
  }
  
  
  subgraph cluster_1 {
      label="Algorithm B"
      subgraph cluster_i {
          label="input"
        a1
      }
      subgraph cluser_0 {
          label=""
        b1
        c1
        d1
      }
      
      subgraph cluster_o {
          label="output"
        e1
      }
  }

  subgraph cluster_2 {
      label="Algorithm C"
      subgraph cluster_i1 {
          label="input"
        a2
      }
      subgraph cluser_01 {
          label=""
        b2
        c2
        d2
      }
      
      subgraph cluster_o1 {
          label="output"
        e2
      }
    
  }
  
  //edge [style=invis]
 // {b a1 a2} -> {c}


edge[style=vis]

  a->b
  b->c
  c->d
  d->e
  b -> g
  g -> h
  c->h
  h->d
  
  h->a1
  
  ///
  
  
  a1->b1
  b1->c1
  c1->d1
  d1->e1
  b1 -> d1


  a2->b2
  b2->c2
  c2->d2
  d2->e2
  b2 -> d2

//   [constraint=false;]
  
  
  //edge [style=invis]
 // {b a1 a2} -> {c}

      

}

```

## Provider

```graphviz
digraph { compound=true;
provider_1 [shape="rectangle",label="P1",style="filled",color="#ff8c61",fillcolor="#faa275"]
artifact_2 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_3 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_4 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]

provider_1 -> artifact_2 []
provider_1 -> artifact_3 []
provider_1 -> artifact_4 []
}
```

## Algorithm 1

```graphviz
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
```

## Algorithm 3
```graphviz
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
provider_5 [shape="rectangle",label="P3",style="filled",color="#ff8c61",fillcolor="#faa275"]
artifact_6 [label="A4\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
provider_7 [shape="rectangle",label="P1",style="filled",color="#ff8c61",fillcolor="#faa275"]
artifact_8 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
provider_9 [shape="rectangle",label="P2",style="filled",color="#ff8c61",fillcolor="#faa275"]
} // cluster_algorithm_1

provider_5 -> artifact_4
artifact_6 -> provider_5
artifact_3 -> provider_5
provider_7 -> artifact_8
artifact_2 -> provider_7
artifact_3 -> provider_7
provider_9 -> artifact_6
artifact_8 -> provider_9
}
```

## Conditional
```graphviz
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
```

## Promote
```graphviz
digraph { compound=true;
promote_1 [shape="rpromoter",label="P4",style="filled",color="#ff8c61",fillcolor="#faa275"]
artifact_2 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_3 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]

promote_1 -> artifact_2
artifact_3 -> promote_1
}
```

## Group
```graphviz
digraph { compound=true;
subgraph cluster_conditional_1 {
label="Group G1"
provider_2 [shape="rectangle",label="P1",style="filled",color="#ff8c61",fillcolor="#faa275"]
artifact_3 [label="A3\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_4 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_5 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
provider_6 [shape="rectangle",label="P5",style="filled",color="#ff8c61",fillcolor="#faa275"]
artifact_7 [label="A5\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
} // cluster_conditional_1

provider_2 -> artifact_3
artifact_4 -> provider_2
artifact_5 -> provider_2
provider_6 -> artifact_7
artifact_4 -> provider_6
}
```

## Unimplemented
```graphviz
digraph { compound=true;
unimplemented_1 [shape="rectangle",label="Unimplemented U1",color="#ff8c61"]
artifact_2 [label="A2\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_3 [label="A1\nInt64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]

unimplemented_1 -> artifact_2
artifact_3 -> unimplemented_1
}
```

## Invoke with
```graphviz
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
```


## Example 9
```graphviz
digraph { compound=true;
subgraph cluster_algorithm_1 {
label="Algorithm compute_in_metric"
subgraph cluster_algorithm_1_inputs {
label="Inputs"
artifact_2 [label="TrainALocation\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_3 [label="TrainASpeed\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_4 [label="TrainBLocation\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_5 [label="TrainBSpeed\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_6 [label="Time\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
} // cluster_algorithm_1_inputs
subgraph cluster_algorithm_1_outputs {
label="Outputs"
artifact_7 [label="FinalDistance\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
} // cluster_algorithm_1_outputs
invoke_8 [shape="record",label="{{<invoke_8_input_9>TrainASpeed⇥C_Speed|<invoke_8_input_10>TrainALocation⇥C_Start}|new_location_A|{<invoke_8_output_11>TrainANewLocation⇥C_End}}"]
subgraph cluster_algorithm_12 {
label="Algorithm new_location"
subgraph cluster_algorithm_12_inputs {
label="Inputs"
artifact_13 [label="C_Speed\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_14 [label="C_Start\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
} // cluster_algorithm_12_inputs
subgraph cluster_algorithm_12_outputs {
label="Outputs"
artifact_15 [label="C_End\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
} // cluster_algorithm_12_outputs
provider_16 [shape="rectangle",label="x",style="filled",color="#ff8c61",fillcolor="#faa275"]
artifact_17 [label="C_Start_Normalized\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_18 [label="C_Speed_Normalized\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
artifact_19 [label="C_Time\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
provider_20 [shape="rectangle",label="normalize_speed_metric",style="filled",color="#ff8c61",fillcolor="#faa275"]
provider_21 [shape="rectangle",label="normalize_start_metric",style="filled",color="#ff8c61",fillcolor="#faa275"]
} // cluster_algorithm_12
artifact_22 [label="TrainANewLocation\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
invoke_23 [shape="record",label="{{<invoke_23_input_24>TrainBSpeed⇥C_Speed|<invoke_23_input_25>TrainBLocation⇥C_Start}|new_location_B|{<invoke_23_output_26>TrainBNewLocation⇥C_End}}"]
subgraph cluster_algorithm_27 {
label="Algorithm new_location"
subgraph cluster_algorithm_27_inputs {
label="Inputs"
} // cluster_algorithm_27_inputs
subgraph cluster_algorithm_27_outputs {
label="Outputs"
} // cluster_algorithm_27_outputs
} // cluster_algorithm_27
artifact_28 [label="TrainBNewLocation\nFloat64",shape="ellipse",style="filled",color="#4a7c59",fillcolor="#8fc0a9"]
provider_29 [shape="rectangle",label="compute_final_distance",style="filled",color="#ff8c61",fillcolor="#faa275"]
} // cluster_algorithm_1

provider_16 -> artifact_15
artifact_17 -> provider_16
artifact_18 -> provider_16
artifact_19 -> provider_16
provider_20 -> artifact_18
artifact_13 -> provider_20
provider_21 -> artifact_17
artifact_14 -> provider_21
artifact_15 -> invoke_8:invoke_8_output_11
invoke_8:invoke_8_output_11 -> artifact_22
invoke_8:invoke_8_input_9 -> artifact_13
artifact_3 -> invoke_8:invoke_8_input_9
invoke_8:invoke_8_input_10 -> artifact_14
artifact_2 -> invoke_8:invoke_8_input_10
artifact_15 -> invoke_23:invoke_23_output_26
invoke_23:invoke_23_output_26 -> artifact_28
invoke_23:invoke_23_input_24 -> artifact_13
artifact_5 -> invoke_23:invoke_23_input_24
invoke_23:invoke_23_input_25 -> artifact_14
artifact_4 -> invoke_23:invoke_23_input_25
provider_29 -> artifact_7
artifact_22 -> provider_29
artifact_28 -> provider_29
}
```