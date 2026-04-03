#
# Core.jl
#
# This file contains core functionality to make the ENERGY 2100 modeling work in Julia like `Select`, `ReadDisk`, `WriteDisk`, etc
#
# Author: Dheepak Krishnamurthy
# Affiliation: Environment and Climate Change Canada (ECCC)
# Email: me@kdheepak.com
# Date: 2024-05-08
#
# Dheepak is the author of this file and the following functionality:
#
# - Select functions to return subsets,
# - ReadDisk functionality to read from a HDF5 file,
# - WriteDisk functionality to write to a HDF5 file,
# - @finite_math macro,
# - logging functionality,
# - Summary statistics based on last git commit
# - improved error messages when mismatched names,
# - comparisons of two dataframes from a HDF5 file,
# - zipping and unzipping files using 7z,
# - auto-packaging the code into a zip file for offline sharing,
# - e2020-data-viewer: A Rust interface for exploring the data in the HDF5 file,
# - PromulaDBA.jl: A Julia package that can read data from a DBA file into a multi-dimensional array or a dataframe,
#
# In addition, Dheepak defined the schematic of the metadata in the HDF5 datasets and defined the functions to write
# structs that represented the HDF5 dataset schema to the HDF5 files.
#
# If you have any questions regarding these topics, contact Dheepak using the email above.
#
# Credits:
#
# All members of SSI for feedback and guidance.
#
const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

HDF5_Compression_Level = 3
SHOULD_GENERATE_OUTPUTS = true
SHOULD_ZIPOUTPUTFILES = true
USE_COMPRESSION = "7z"
PIDS = Ref([])
ModelPath = dirname(@__DIR__)
E2020Folder = abspath(joinpath(ModelPath, "2020Model"))
DataFolder = abspath(joinpath(ModelPath, "2020Model"))
OutputFolder = abspath(joinpath(ModelPath,"2020Model", "out"))

DB = abspath(joinpath(E2020Folder, "database.hdf5"))
#MainDB = abspath(joinpath(E2020Folder, "database.hdf5"))
DatabaseName = joinpath(DataFolder, "database.hdf5")
#
#
# fuzzy find, utilities and better error messages
#
include("utils.jl")
include("Select.jl")
include("Math.jl")
include("HDF5_Functions.jl")

function ReadSetFromCSV(SetName)
  SetsPath= ModelPath * "\\DataBase\\Sets\\"
  SetFileName::String = SetsPath * SetName * ".csv"
  #println(SetFileName)
  SetDSNames::Vector{String}=[]
  open(SetFileName) do setDescs
    for line in eachline(setDescs)
      lineSplit = split(line, ",")
      NameInFile = String(lineSplit[1])
      push!(SetDSNames,NameInFile)
      #println(NameInFile)
    end
  end
  return SetDSNames
end


function ReadSetFromCSV(SetName,DSorKey)
  SetsPath= ModelPath * "\\DataBase\\Sets\\"
  SetFileName::String = SetsPath * SetName * ".csv"
  #println(SetFileName)
  SetDSNames::Vector{String}=[]
  open(SetFileName) do setDescs
    for line in eachline(setDescs)
      lineSplit = split(line, ",")
      if DSorKey=="DS"
        NameInFile = String(lineSplit[1])
      else
        NameInFile = String(lineSplit[2])
      end
      push!(SetDSNames,NameInFile)
      #println(NameInFile)
    end
  end
  return SetDSNames
end
#
#  Ben, move this where you want it.
#
@inline function Yr(year)
  result::Int = Int(year-ITime+1)
  return result
end

@inline function HasValues(setSelection)
  if isempty(setSelection)
    return false
  else
    return true
  end
end


"""
    copy_database(db::string, src::string, dst::string)

This function creates a new directory if needed and copies the database from source to destination
"""
function copy_database(dbname, src, dst)
  mkpath(dst)
  cp(joinpath(src, dbname), joinpath(dst, dbname); force = true)
end

"""
Remove all files in a directory that don't start with ".".

```julia
rm_dir_contents("path/to/folder")
```
"""
function rm_dir_contents(dir)
  for (root, _, files) in walkdir(dir)
    for file in files
      if !startswith(file, ".")
        rm(joinpath(root, file); force = true)
      end
    end
  end
end

function checkdata(data)
  for i in fieldnames(typeof(data))
    j = getfield(data, i)
    if isa(j, VariableArray)
      if sum(isnan.(j)) >= 1
        # @show j
        print(i)
        print(" has NaNs\n")
      else
        # print(" is okay\n")
      end
    else
      # print(" isn't a variable array\n")
    end
  end
end

function removedatanans(data)
  for i in fieldnames(typeof(data))
    j = getfield(data, i)
    if isa(j, VariableArray)
      issues = isnan.(j)
      if sum(issues) >= 1
        j[issues] .= 0
      end
    end
  end
  return(data)
end

"""
    comparedata(data, data_b)

Compares two data objects read from different databases, iterating over all VariableArray objects 

# Arguments

data, data_b: two data object both of which should be generated using the same 
SubModule.Data constructor function reading from different databases.

# Outputs 

df: A dataframe listing the difference in values of each VariableArray, var,
in data and data_b, including:

  Ref: Sum of the absolute value of every element in data.var
  Other: Sum of the absolute value of every element in data_b.var
  Diff: sum of absolute value of differences between all elements of data.var and data_b.var
  LDiff: the largest difference of a single element
  PDiff: Ratio of Diff to Ref or Other, whichever is bigger
"""
function comparedata(data, data_b)
  df = DataFrame()
  for i in fieldnames(typeof(data))
    j = getfield(data, i)
    print(i)
    if isa(j, VariableArray)
      j_b = getfield(data_b, i)
      if sum(isnan.(j)) >= 1
        print(" has NaNs\n")
      else
        print(" \n")
        Ref = sum(j)
        Other = sum(j_b)
        Diff = sum(abs.(j .- j_b))
        LDiff = maximum(abs.(j .- j_b))
        @finite_math PDiff = Diff / maximum(abs.([Ref,Other]))
        push!(df, (Var = String(i), Ref, Other, Diff,
          PDiff, LDiff))
      end
    else
      print(" isn't a variable array\n")
    end
  end
  df[sortperm(df.PDiff, rev = true),:]
  return(df)
end # compare function

"""
  unzip(fileloc)
  
Unzips a .zip file into the 2020Model subdirectory
  
# Arguments

fileloc: relative path the the zip file containing a database.hdf5 file
"""
unzip = function(fileloc::String)
  run(`wzunzip -d -o $fileloc 2020Model`)
end

function BuildStringList(pathOfListFile)
  list = String[]
  for line in eachline(pathOfListFile)
    push!(list,line)
  end
  list
end

function OpenFile(fileName, readWrite)
  open(fileName, readWrite)
end
function WriteFileHeader(fileToWrite, fileName)
  write(fileToWrite,"*\n")
  write(fileToWrite,"* $(fileName)\n")
  write(fileToWrite,"*\n")
end

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
