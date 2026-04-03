#
# Select.jl
#
# This file contains base functions for the 'Select' concept in the model which mimics the Promula "Select Set" concept.


const SetElType = Any

struct SelectSetKeyNotFoundException{T<:SetElType} <: Exception
  set::Vector{T}
  key::Any
end

function Base.showerror(io::IO, e::SelectSetKeyNotFoundException)
  name = e.key
  set = e.set
  n_matches = 3
  printstyled(last(split("$(typeof(e)): ", ".")); color = :red, bold = true)
  print(io, "Unable to find ")
  printstyled(io, name isa String ? '"' * name * '"' : name; bold = true)
  print(io, " in ")
  if length(set) > 3
    printstyled(io, "[\"$(first(set))\", ..., \"$(last(set))\"]."; bold = true)
  else
    printstyled(io, set; bold = true)
  end
  println(io)
  println(io, "Top $n_matches fuzzy matches for $(name isa String ? '"' * name * '"' : name) are:")
  candidates = string.(set)
  matches = reverse.(Utils.fuzzysort(reverse(basename(string(name))), reverse.(candidates)))
  matches = set[[findfirst(==(m), candidates) for m in matches]]
  for c in first(matches, n_matches)
    print(io, "  Select(..., ")
    printstyled(io, c isa String ? '"' * lstrip(c, '/') * '"' : c; color = :red)
    println(io, ")")
  end
end

"""
    Select(set) -> 1:N
    Select(set, k) -> k_i
    Select(set, [k1, k2, k3, ...]) -> [k1_i, k2_i, k3_i, ...]
    Select(set, (from = k1, to = k2)) -> [k1_i, ..., k2_i]

The `Select` functions provide a way to select elements from a `Vector` based on the provided criteria.

  - `Select(set)`: Returns the indices of all elements in `set`.
  - `Select(set, keys::Vector)`: Returns the indices of elements in `set` corresponding to the given `keys` where `keys` is a `Vector`.
  - `Select(set, key::String)`: Returns the index of the single element in `set` equal to `key`. Throws `SelectSetKeyNotFoundException` if `key` is not found.
  - `Select(set, predicate::Function)`: Returns the indices of elements in `set` for which `predicate` is true. Throws `SelectSetKeyNotFoundException` if no elements satisfy the `predicate`.
  - `Select(set, key::NamedTuple)`: Returns a range of indices for elements in `set` between `key.from` and `key.to`. Throws `SelectSetKeyNotFoundException` if either of the keys is not found.

# Examples

```julia
julia> set = ["A", "B", "C", "D", "E"];

julia> Select(set, "A")
1

julia> Select(set, ["A", "C"])
2-element Vector{Int}:
 1
 3

julia> Select(set, (from = "A", to = "D"))
1:4

julia> Select(set, ==("A"))
1-element Vector{Int}:
 1
```
"""
Select(set::Vector{T}) where {T<:SetElType} = eachindex(set)
Select(set::Vector{T}, keys::Vector{T}) where {T<:SetElType} = Select.(Ref(set), keys)
function Select(set::Vector{T}, key::T) where {T<:SetElType}
  key ∉ set && throw(SelectSetKeyNotFoundException(map(string, set), string(key)))
  only(findall(==(key), set))
end

function Select(set::Vector{T}, predicate::Base.Fix2) where {T<:SetElType}
  isnothing(findfirst(predicate, set)) && throw(SelectSetKeyNotFoundException(set, "$(predicate.f)($(predicate.x))"))
  idx = findall(predicate, set)
  isempty(idx) && throw(SelectSetKeyNotFoundException(map(string, set), string(predicate.x))) # error if nothing matches
  # length(idx) == length(set) && throw(SelectSetKeyNotFoundException(map(string, set), string(predicate.x))) # error if everything matches
  idx
end

function Select(set::Vector{T}, key::NamedTuple{(:from, :to),Tuple{T,T}}) where {T<:SetElType}
  (from, to) = key
  idx1 = Select(set, from)
  idx2 = Select(set, to)
  idx1:idx2
end
Select(set::Vector{T}, names::T...) where {T<:SetElType} =
  error("Cannot use Select(key, $(join(names, ", "))). Use Select(key, [$(join(names, ", "))]) instead.")
