"""
SUMMARY

This script generates a summary of the changes between two git commits.
It outputs a graph of the commit history and a summary of the changes in
the modified files between the specified commits.

Usage:
  julia Summary.jl [new_commit] [old_commit]

Arguments:
  new_commit: (optional) commit hash or branch name to compare against old_commit. Defaults to "HEAD".
  old_commit: (optional) commit hash or branch name to use as the base commit. Defaults to most recent merge commit.

Output:
  - A graph of the commit history between old_commit and new_commit.
  - A summary of the changes in the modified files between old_commit and new_commit.
  - The summary is saved to ../log/MODIFIED_FILES.log.

Examples:

  julia bin/Summary.jl               # compare HEAD against most recent merge commit
  julia bin/Summary.jl abc123        # compare abc123 against most recent merge commit
  julia bin/Summary.jl abc123 2      # compare abc123 against second most recent merge commit
  julia bin/Summary.jl abc123 def456 # compare abc123 against def456
"""

function main()
  # Set default values for new_commit and old_commit
  new_commit = "HEAD"
  old_commit = "1"

  # Override default values if specified as command-line arguments
  if length(ARGS) == 1
    new_commit = ARGS[1]
  elseif length(ARGS) == 2
    old_commit = ARGS[2]
  end

  # If old_commit is an integer, find the corresponding merge commit hash
  old_commit_n = tryparse(Int, old_commit)
  if !isnothing(old_commit_n)
    merge_commits = readlines(`git log --pretty=format:%H --merges`)
    old_commit = first(merge_commits[old_commit_n], 6)
    old_commit = first(strip(read(`git merge-base --octopus $old_commit`, String)), 6)
    old_commit = "$old_commit^1"
  end

  # Print the comparison range and commit history graph
  println("Comparing $old_commit..$new_commit:")
  graph = read(`git log --graph --oneline --boundary $old_commit..$new_commit`, String)
  println(graph)

  # Print the summary of the changes and save to file
  summary = read(`git diff --stat $old_commit $new_commit`, String)
  println("Summary:")
  println(summary)
  write(joinpath(@__DIR__, "../log/MODIFIED_FILES.log"), summary)
end

main()
