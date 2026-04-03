#
# Run.jl
#
using Logging

try
  @time include("$(only(ARGS))")
catch e
  @error "Something went wrong" exception=(e, catch_backtrace())
  throw(e)
end
