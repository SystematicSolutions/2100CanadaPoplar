module Utils

# Utils

# based on LupoLb/Luna.jl

using Dates
using Printf
import LibGit2

srcdir() = dirname(@__FILE__)

e2020dir() = dirname(srcdir())

datadir() = joinpath(srcdir(), "data")

cachedir() = joinpath(homedir(), ".e2020")

function git_commit()
  try
    repo = LibGit2.GitRepo(e2020dir())
    commit = string(LibGit2.GitHash(LibGit2.head(repo)))
    LibGit2.isdirty(repo) && (commit *= " (dirty)")
    return commit
  catch
    "git commit unavailable"
  end
end

function git_branch()
  try
    repo = LibGit2.GitRepo(e2020dir())
    n = string(LibGit2.name(LibGit2.head(repo)))
    branch = split(n, "/")[end]
    return branch
  catch
    "git branch unavailable"
  end
end

function format_elapsed(ms::Dates.Millisecond)
  stot = Dates.value(ms) / 1000 # total seconds
  seconds = stot % 60
  stot -= seconds
  mtot = stot ÷ 60
  minutes = mtot % 60
  mtot -= minutes
  hours = mtot ÷ 60
  out = @sprintf("%.3f seconds", seconds)
  minstr = abs(minutes) == 1 ? "minute" : "minutes"
  hrstr = abs(hours) == 1 ? "hour" : "hours"
  if abs(hours) > 0
    out = @sprintf("%d %s, ", minutes, minstr) * out
    out = @sprintf("%d %s, ", hours, hrstr) * out
  elseif abs(minutes) > 0
    out = @sprintf("%d %s, ", minutes, minstr) * out
  end
  out
end

# Fuzzy Search Algorithm
# From julia/stdlib/REPL/src/docview.jl

function matchinds(needle, haystack; acronym::Bool = false)
  chars = collect(needle)
  is = Int[]
  lastc = '\0'
  for (i, char) in enumerate(haystack)
    while !isempty(chars) && isspace(first(chars))
      popfirst!(chars) # skip spaces
    end
    isempty(chars) && break
    if lowercase(char) == lowercase(chars[1]) && (!acronym || !isletter(lastc))
      push!(is, i)
      popfirst!(chars)
    end
    lastc = char
  end
  return is
end

longer(x, y) = length(x) >= length(y) ? (x, true) : (y, false)

bestmatch(needle, haystack) = longer(matchinds(needle, haystack; acronym = true), matchinds(needle, haystack))

avgdistance(xs) = isempty(xs) ? 0 : (xs[end] - xs[1] - length(xs) + 1) / length(xs)

function fuzzyscore(needle, haystack)
  score = 0.0
  is, acro = bestmatch(needle, haystack)
  score += (acro ? 2 : 1) * length(is) # Matched characters
  score -= 2(length(needle) - length(is)) # Missing characters
  !acro && (score -= avgdistance(is) / 10) # Contiguous
  !isempty(is) && (score -= sum(is) / length(is) / 100) # Closer to beginning
  return score
end

function fuzzysort(search::String, candidates::Vector{String})
  scores = map(cand -> (fuzzyscore(search, cand), -Float32(levenshtein(search, cand))), candidates)
  reverse(candidates[sortperm(scores)])
end

# Levenshtein Distance

function levenshtein(s1, s2)
  a, b = collect(s1), collect(s2)
  m = length(a)
  n = length(b)
  d = Matrix{Int}(undef, m + 1, n + 1)

  d[1:m+1, 1] = 0:m
  d[1, 1:n+1] = 0:n

  for i in 1:m, j in 1:n
    d[i+1, j+1] = min(d[i, j+1] + 1, d[i+1, j] + 1, d[i, j] + (a[i] != b[j]))
  end

  return d[m+1, n+1]
end

function levsort(search::String, candidates::Vector{String})
  scores = map(cand -> (Float32(levenshtein(search, cand)), -fuzzyscore(search, cand)), candidates)
  candidates = candidates[sortperm(scores)]
  i = 0
  for outer i in 1:length(candidates)
    levenshtein(search, candidates[i]) > 3 && break
  end
  return candidates[1:i]
end

end
