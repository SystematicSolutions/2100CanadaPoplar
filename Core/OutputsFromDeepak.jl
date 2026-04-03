#
# OutputsFromDeepak.jl
#

module Outputs

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
using ..EnergyModel: HDF5DataSetNotFoundException,OutputFolder, rm_dir_contents

using HDF5, DataFrames, CSV, Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

"""
Outputs a variable in long tabular form as a dataframe.

```julia
output_df(M.DB, "RInput/CERSM")
output_df(M.DB, "RInput/CERSM"; skip_zeros = true, parse_year = true, row_index = true)
```

You can pass it the path to the HDF5 file, and the name of the variable you are trying to output.
This only works for variables, and will not work for any of the sets or scalar values.
"""
function output_df(db, name; skip_zeros = true, parse_year = true, row_index = true)
  df = ReadDisk(DataFrame, db, name; skip_zeros)
  if row_index
    df.id = 1:nrow(df)
    select!(df, :id, Not(:id))
  elseif "id" in names(df)
    select!(df, Not(:id))
  end
  rename!(df, :Value => basename(name))
  if !parse_year
    df.Year = String.(df.Year)
  end
  df
end

"""
Outputs a variable in long tabular form as a SSV (semicolon separated values).

```julia
output_dta(M.DB, "RInput/CERSM")
output_dta(M.DB, "RInput/CERSM"; skip_zeros = true)
output_dta(M.DB, "RInput/CERSM"; skip_zeros = true, startyear = 1985, endyear = 2050)
output_dta(
  M.DB,
  "RInput/CERSM";
  skip_zeros = true,
  startyear = 1985,
  endyear = 2050,
  year_across_columns = false,
  sort = true,
)
```

You can pass it the path to the HDF5 file, and the name of the variable you are trying to output, and as an optional argument whether you want only nonzero values.
If you set this optional keyword argument to true, it'll output an empty CSV for every variable.
This only works for variables, and will not work for any of the sets or scalar values.
Outputs are all written to folder called `out`, with the appropriate path inside the `out` folder.
For example, "RInput/CERSM" is written out to "out/RInput/CERSM.dta".
The first line is the header. The remaining lines are values.

**This function is a prototype and is just for debugging, testing and experimenting**
"""
function output_dta(
  db,
  name;
  skip_zeros = true,
  startyear = 1985,
  endyear = 2050,
  year_across_columns = false,
  sort = true)
  variable = basename(name)
  df = output_df(db, name; skip_zeros, parse_year = false, row_index = false)
  df[!, :Units] = repeat([metadata(df, "units")], size(df, 1))
  if "Year" in names(df)
    df.Year = parse.(Int, df.Year)
    df = filter(row -> (row.Year >= startyear && row.Year <= endyear), df)
  end
  if year_across_columns
    unstack(df, :Year, Symbol(variable))
  else
    rename!(df, Symbol(variable) => :zData)
    df[!, :Variable] .= 'z' * variable
    if "Year" in names(df)
      select!(df, :Variable, :Year, Not([:Units, :zData]), :Units, :zData)
    elseif !year_across_columns
      select!(df, :Variable, Not([:Units, :zData]), :Units, :zData)
    end
  end
  if sort
    sort!(df)
  end
  mkpath(joinpath(OutputFolder, dirname(name)))
  CSV.write(joinpath(OutputFolder, dirname(name), "z" * basename(name) * ".dta"), df; delim = ';')
end

"""
Outputs a variable in long tabular form as a CSV (comma separated values).

```julia
output_csv(M.DB, "RInput/CERSM")
output_csv(M.DB, "RInput/CERSM"; skip_zeros = true)
output_csv(
  M.DB,
  "RInput/CERSM";
  skip_zeros = true,
  startyear = 1985,
  endyear = 2050,
  quotestrings = true,
  year_across_columns = false,
  sort = false)
```

You can pass it the path to the HDF5 file, and the name of the variable you are trying to output, and as an optional argument whether you want only nonzero values.
If you set this optional keyword argument to true, it'll output an empty CSV for every variable.
This only works for variables, and will not work for any of the sets or scalar values.
Outputs are all written to folder called `out`, with the appropriate path inside the `out` folder.
For example, "RInput/CERSM" is written out to "out/RInput/CERSM.csv".
The first line is the header. The remaining lines are values.

**This function is a prototype and is just for debugging, testing and experimenting**
"""
function output_csv(
  db,
  name;
  skip_zeros = true,
  startyear = 1985,
  endyear = 2050,
  quotestrings = true,
  year_across_columns = false,
  sort = false)
  variable = basename(name)
  df = output_df(db, name; skip_zeros, parse_year = false, row_index = false)
  df[!, :Units] = repeat([metadata(df, "units")], size(df, 1))
  df[!, :Variable] .= "z" * variable
  if "Year" in names(df)
    df.Year = parse.(Int, df.Year)
    df = filter(row -> (row.Year >= startyear && row.Year <= endyear), df)
  end
  if year_across_columns
    unstack(df, :Year, Symbol(variable))
  end
  if "Year" in names(df)
    select!(df, :Variable, :Year, Not([:Units, Symbol(variable)]), :Units, Symbol(variable))
  elseif !year_across_columns
    select!(df, :Variable, Not([:Units, Symbol(variable)]), :Units, Symbol(variable))
  end
  if sort
    sort!(df)
  end
  mkpath(joinpath(OutputFolder, dirname(name)))
  CSV.write(joinpath(OutputFolder, dirname(name), "z" * basename(name) * ".csv"), df; quotestrings = quotestrings)
end

function diff_database(new_db, old_db)
  variables = Dict()
  h5open(new_db) do f
    for group in f
      for dataset in group
        attr = Dict(attrs(dataset))
        if "type" in keys(attr) && attr["type"] == "variable"
          variables[string(lstrip(HDF5.name(dataset), '/'))] =
            [Symbol(dim) => collect(read(group["$dim"])) for dim in attr["dims"]]
        end
      end
    end
  end
  iob = IOBuffer()
  for k in keys(variables)
    _, variable_name = String.(split(k, '/'))
    new = ReadDisk(new_db, k)
    old = ReadDisk(old_db, k)
    if count(==(false), isapprox.(new, old)) > 0
      percent = count(==(true), isapprox.(new, old)) / length(new) * 100
      println(iob, "? $percent% match for $k")
      println(iob, repeat("=", 80))
      println(iob, "Found differences in $k")
      df = output_df(new_db, k; skip_zeros = false)
      _df = output_df(old_db, k; skip_zeros = false)
      df[!, "old_$variable_name"] = _df[!, variable_name]
      rename!(df, variable_name => "new_$variable_name")
      df = subset(df, ["new_$variable_name", "old_$variable_name"] => (new, old) -> (!).(isapprox.(new, old)))
      if !isempty(df)
        println(iob, describe(df))
      end
      println(iob, repeat("=", 80))
    else
      println(iob, "? 100% match for $k")
    end
    break
  end
  write(joinpath(@__DIR__, "../../out/difference.log"), String(take!(iob)))
end

end
