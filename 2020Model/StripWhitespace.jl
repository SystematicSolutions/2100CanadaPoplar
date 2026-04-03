#!/usr/bin/env julia

# Define a regular expression pattern to match trailing whitespace
const TRAILING_WS_PATTERN = r"[ \t]+\n"

# Define the directory to search for files
DIRECTORY = length(ARGS) > 1 ? abspath(only(ARGS[1])) : abspath(joinpath(@__DIR__, ".."))

@info "Stripping whitespace for $DIRECTORY"

# Loop over all files in the directory
for (root, dirs, files) in walkdir(DIRECTORY)
  for file in files
    if endswith(file, ".jl")
      # Read the contents of the file
      filepath = joinpath(root, file)
      contents = read(filepath, String)
      lines = split(contents, '\n')
      lines = rstrip.(lines)
      new_contents = join(lines, '\n')
      if new_contents != contents
        @info "Stripping whitespace for $filepath"
        write(filepath, new_contents)
      end
    end
  end
end
