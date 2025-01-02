# Nesting of providers


```plantuml
skinparam componentStyle rectangle

[P1]
A1 -> P1
P1 -> A2
component N1 {
    portout A3
    [P2]
    A2 --> P2
    P2 -> A3
}

[P3]
A3 --> P3
P3 -> A4
```

`P1`, `P3` and `N1` are top - level providers
`P2` belongs to the `N1`


```julia
begin # provide(Root, A4 , :ctx)
    if ! ctx[A4]  # A4 is the output, the first thing that we request
        ctx[A4] = P3(begin # provide(Root, A3 , :ctx)
            if ! ctx[A3]  # A3 is the input to P3
                ctx[A3] = begin 
                    if ! ctx[N1][A3]  # A3 source is N1 so we ask N1 to provide it, and N1 is aware that he is sub-context so it adds `[N1]` to the context
                        ctx[N1][A3] = P2(begin
                            if ! ctx[N1][A2]
                                ctx[N1][A2] = begin
                                    if ! ctx[A2]
                                        ctx[A2] = P1(ctx[A1]) # A1 is top level input and have to be ready from the begining
                                    end
                                    ctx[A2]
                                end
                            end
                            ctx[N1][A2]
                        end)
                    end
                    ctx[N1][A3]
                end

            end
            ctx[A3]
        end)
    end
    ctx[A4]
end
```


Top level plan:
```
artifacts = [A1, A2, A3, A4]
providers = [P1, P3, N1]
inputs = [A1]
outputs = [A4]
```

Nested plan:
```
artifacts = [A2, A3]
providers = [P2]
inputs = [A2]
outputs = [A3]
```