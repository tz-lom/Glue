# Macros syntax agreements

Macros of FunctionFusion follow the syntax convention that helps to memoize and write them.
Here are those conventions:

## Function-like

If macro defines callable entity then it will follow function like syntax.
Most of the time it is a function call syntax `function_name(arguments)::Output = implementation`

* `@algorithm name(inputs...)::Outputs = [Providers]`
* `@provider name(arg::Artifact...)::Artifact = implementation`
* `@provider function name(arg::Artifact...)::Artifact  implementation end`
* `@provider alias = name(Artifact...)::Artifact` alias may look like an exception
* `@promote name(Input)::Output`
* `@unimplemented name(Artifact, ...)::Artifact`

Keep a note - if implementation may have access to the arguments the arguments are specified by name and type `(name1::Type1, name2::Type2)`, otherwithe they are just types `(Type1, Type2)`

## Assignment-like

If macro defines something then it is using assignment syntax

* `@artifact A1, A2 = Int`
* `@context Context = [A1, A2]`
* `@group name = [P1, P2]`
* `@provider alias = name(Artifact...)::Artifact` alias provider is just definition of the existing function as a provider.

## Vector-like

If macro requires list of entities this list is written as array

* List of entries for `@context`
* List of providers for `@artifact` and `@group`

## @todo

To decide:

* `@conditional conditional::D = C ? A : B` or `@conditional cond(A ? B : C)::D` or `@conditional cond()::D = C ? A : B`
* `@invoke_with Name = Algorithm{Substitutions}` or `@invoke_with name(Was=>Become, ...)::(Was=>Become) = Algorithm`or use curly braces iso round ones
