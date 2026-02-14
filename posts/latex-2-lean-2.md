This is a project about converting a subset of LaTeX definitions of Lean 4
definitions.

At first I tried writing it in Rust, but as we want to do some fancy
data-flow-analysis things, we are switching to writing it in a niche language
called *Soufflé*. Soufflé is a Datalog engine, which notably supports Lattices
and infinite domains.

## Preprocessing

Because of some choices, we need better syntax than Soufflé. Specifically, I am
representing proof definitions as a linked list. For example:
```latex
{ x + 10 | x ∈ N }
```
is represented as:
```souffle
[ "map", [ [ "+", [ "x", [ "10", nil ] ] ], [ [ "in", [ "x", [ "N", nil ] ] ], nil ] ] ]
```

A python script I wrote let's me write this instead as:
```souffle
`"map"(`"+"(`"x", `"10"), `"in"(`"x", `"N"))
```

Much simpler!

## The Analysis

The analysis, for now, is mostly to decide what to represent as Mathlib `Set`
and what to represent as Mathlib `Finset`.

For now I am trying to implement rules to decide whether a term is a finite set,
and rules to decide which expressions are used as a finite set.
