# Context

Context is mutable structure which stores artifacts and allows single write and multiple read throught array-like interface.

Context can be nested.

## Implementation detail

Storing nested mutable structures is not efficient for the Julia compiler optimization pass as it can't backtrack all usages of nested structures.

But the API of nested structures is very transparent and clear, so Context implement internal flattening of the nested structures.