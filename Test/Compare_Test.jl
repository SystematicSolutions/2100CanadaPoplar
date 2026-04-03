# Import everything necessary to create data structs
import EnergyModel as M
import EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log

# New Imports
import EnergyModel: VariableArray, SetArray, checkdata, comparedata

db = M.DB
db_b = "2020Model\\BasePromula\\database.hdf5"
year = 2020 - ITime + 1
prior = 2019 - ITime + 1
next = 2021 - ITime + 1
CTime = 2020

import EnergyModel.Engine.EDispatch as ED

# Create Data Structs from StartBasePromula with checks
unzip("2020Model\\StartBasePromula\\23.11.23 StartBasePromula.zip")

data = ED.Data(; db, year, prior, next);
checkdata(data)

# Compare to PROMULA results
data_b = ED.Data(; db = db_b, year, prior, next);
checkdata(data_b)

# Define a function comparing all variable arrays in a data struct and compare
using DataFrames, DataFramesMeta
df = comparedata(data, data_b)

# Do some manipulation of the compare dataframe to get important information
# See Documentation for this package here: 
# https://juliadata.org/DataFramesMeta.jl/stable/
@subset!(df, :LDiff .> 0)
df = @rorderby(df, -:PDiff)

name_short = "UnVCost"
ReadDisk(db, name_short)
name="EGOutput/UnVCost"
# Pick an interesting variable and get it into a dataframe. 

var = ReadDisk(DataFrame, db, name; skip_zeros = false)
var_b = ReadDisk(DataFrame, db_b, name; skip_zeros = false)

@transform!(var, :Plant = data.UnPlant[:Unit])
select!(var, Not(:Value), :Value)
@transform!(var_b, :Plant = data.UnPlant[:Unit])
select!(var_b, Not(:Value), :Value)


var_d = d.diff(var, var_b)

d.summarize_dim(var_d; dim="Plant")
# d.summarize_dim(var_d; dim="Area")

d.hist_diff(var_d; dim="Plant")
# d.hist_diff(var_d; dim="Area")

d.plot_diff(@subset(var_d, :Year .>= 2020); dim="Plant", num = 4)


