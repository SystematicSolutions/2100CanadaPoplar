#
# Math.jl
#
# This file contains base functions for E2020 equations to handle specific ambigous calculations.
#
# Finite Math functions
# NOTE: Dheepak - April 19th, 2023
# The following `finite_math` functions define finite versions of common mathematical operations, such as division, inversion, exponentiation,
#   and logarithm to handle special cases and to make code compatible with Promula.

using MacroTools

"""
    finite_divide(x, y)

Performs division by multiplying `x` with the finite inverse of `y`.

# Arguments

  - `x`: The dividend.
  - `y`: The divisor.
"""
finite_divide(x, y) = x * finite_inverse(y)

"""
    finite_inverse(x)

Calculates the inverse of `x` while handling the special case when `x` is zero.

# Arguments

  - `x`: The number to find the inverse of.
"""
finite_inverse(x) = ifelse(isapprox(x,0;atol=3e-39), 0, 1 / x)

"""
    finite_power(x, y)

Calculates `x` raised to the power `y` while handling the special case when `x` is zero.

# Arguments

  - `x`: The base.
  - `y`: The exponent.
"""
finite_power(x, y) = ifelse(iszero(x), x, sign(x) * (abs(x)^y))

"""
    finite_exp(x)

Calculates the exponential of `x` while handling the special case when `x` is zero.

# Arguments

  - `x`: The number to find the exponential of.
"""
finite_exp(x) = exp(x)

"""
    finite_log(x)

Calculates the natural logarithm of `x` while handling the special case when `x` is less than or equal to zero.

# Arguments

  - `x`: The number to find the natural logarithm of.
"""
finite_log(x) = isapprox(x, 0.0; rtol = 1e-3, atol = 1e-6) ? x : (x <= 0.0 ? 0.0 : log(x))

"""
    @finite_math(expr)

A macro that transforms the standard mathematical operations in the input expression `expr` to their finite versions.
The macro replaces division, logarithm, exponentiation, and power operations with `finite_divide`, `finite_log`, `finite_exp`, and `finite_power` functions, respectively.

# Usage

```julia
@finite_math Y = log(Y / X^2)
```

This will convert the expression to:

```julia
Y = finite_log(finite_power(Y * finite_inverse(X), 2))
```
"""

function finite_math(expr::Expr)
  # The `@finite_math` macro transforms mathematical expressions in the input code to their finite versions.
  # It takes a single expression `expr` as input.
  # The macro traverses the input expression, and for each mathematical operation, it replaces the standard operation with its corresponding finite version.
  # This is done using the `postwalk` function and a series of anonymous functions.
  # Once all the operations are replaced, the transformed expression is returned.
  MacroTools.postwalk(expr) do ex
    if @capture(ex, op_(e__))
      if op == :/
        op = :(finite_divide)
        :($(op)($(e...)))
      elseif op == :(log)
        op = :(finite_log)
        :($(op)($(e...)))
      elseif op == :(exp)
        op = :(finite_exp)
        :($(op)($(e...)))
      elseif op == :^
        op = :(finite_power)
        :($(op)($(e...)))
      elseif op == :./
        op = :(finite_divide)
        :($(op).($(e...)))
      elseif op == :.^
        op = :(finite_power)
        :($(op).($(e...)))
      else
        :($(op)($(e...)))
      end
    elseif @capture(ex, op_.(e__))
      op = if op == :(/)
        :(finite_divide)
      elseif op == :(log)
        :(finite_log)
      elseif op == :(exp)
        :(finite_exp)
      elseif op == :(^)
        :(finite_power)
      else
        op
      end
      :($(op).($(e...)))
    else
      ex
    end
  end
end


"""
    @finite_math(expr)

A macro that transforms the standard mathematical operations in the input expression `expr` to their finite versions.
The macro replaces division, logarithm, exponentiation, and power operations with `finite_divide`, `finite_log`, `finite_exp`, and `finite_power` functions, respectively.

# Usage

```julia
@finite_math Y = log(Y / X^2)
```

This will convert the expression to:

```julia
Y = finite_log(finite_power(Y * finite_inverse(X), 2))
```
"""
macro finite_math(expr)
  esc(finite_math(expr))
end

function create_worker_processes(; n_workers = Sys.CPU_THREADS - 2, revise = false)
  N = last(sort(workers()))
  PIDS[] = asyncmap(1:n_workers) do i
    worker_number = N + i
    worker_str = "Worker $worker_number"
    @info "Requesting Worker $(worker_number)..."
    pid = only(addprocs(1))
    project = Pkg.project().path
    Distributed.remotecall_eval(Main, pid, :(using Pkg; Pkg.activate($(project))))
    if revise
      @info "Loading Revise on $(worker_str)..."
      Distributed.remotecall_eval(Main, pid, :(using Revise))
    end
    @info "Loading EnergyModel on $(worker_str)..."
    Distributed.remotecall_eval(Main, pid, :(import EnergyModel as M))
    @info "$(worker_str) ready, PID $(pid)"
    pid
  end
end


# @setup_workload begin
#   @compile_workload begin
#     d = EnergyModel.ReadDisk(DataFrame, DB, "MOutput/Inflation")
#   end
# end
"""
    @autoinfiltrate
    @autoinfiltrate condition::Bool

Invoke the `@infiltrate` macro of the package Infiltrator.jl to create a breakpoint for ad-hoc
interactive debugging in the REPL. If the optional argument `condition` is given, the breakpoint is
only enabled if `condition` evaluates to `true`.

Note: For this macro to work, the Infiltrator.jl package needs to be installed in your current Julia
environment stack.

See also: [Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl)
"""
macro autoinfiltrate(cond = true)
  pkgid = Base.PkgId(Base.UUID("5903a43b-9cc3-4c30-8d17-598619ec4e9b"), "Infiltrator")
  if !haskey(Base.loaded_modules, pkgid)
    try
      Base.eval(Main, :(using Infiltrator))
    catch err
      @error "Cannot load Infiltrator.jl. Make sure it is included in your environment stack."
    end
  end
  i = get(Base.loaded_modules, pkgid, nothing)
  lnn = LineNumberNode(__source__.line, __source__.file)

  if i === nothing
    return Expr(:macrocall, Symbol("@warn"), lnn, "Could not load Infiltrator.")
  end

  return Expr(:macrocall, Expr(:., i, QuoteNode(Symbol("@infiltrate"))), lnn, esc(cond))
end
