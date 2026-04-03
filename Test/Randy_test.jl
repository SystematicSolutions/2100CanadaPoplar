import EnergyModel
using Pkg
# Pkg.add(url=raw"https://github.com/SystematicSolutions/PromulaDBA.jl.git")
Pkg.add(url="https://github.com/pnvolkmar/JuliaCompare.jl.git")
import EnergyModel as M
import PromulaDBA as P
import JuliaCompare as J

import JuliaCompare: db_files, Canada

using DataFrames, DataFramesMeta

# JuliaCompare retrieves variables from user-specified locations to compare 
# to each other. The first step is using JuliaCompare is to specify those locations
# Specifically, where are the dba or hdf5 files:

fldr1 = raw"\\Silver\c\2020CanadaRedwood\2020Model\Process"
fldr2 = raw"\\Silver\c\2020CanadaRedwood\2020Model\Process2"
fldr3 = raw"\\Silver\c\2020CanadaRedwood\2020Model\Calib"

# There are two types of JuliaCompare locations: one for Promula (loc_p) and 
# another for Julia (loc_j). A location is a Julia struct that contains several 
# important attributes that will make it easier to look up and tidy the variables

# abstract type Location end

# struct Loc_p <: Location
#   vars::DataFrame
#   DATA_FOLDER::String
#   name::String
# end
# struct Loc_j <: Location
#   vars::DataFrame
#   HDF5_path::String
#   name::String
# end

# Let's go by attributes, the first entry "vars" is a dataframe with all the 
# information necessary to retrieve every variable in the respective model. 
# We'll need to create these with list_vars

#vars_pine = J.list_vars(fldr1, db_files) # a Promula vars requires a pointer to the data folder and a list of files to parse
vars_j = J.list_vars(joinpath(fldr1,"database.hdf5")) # a Julia vars requires a pointer directly to the hdf5 file
vars_k = J.list_vars(joinpath(fldr2,"database.hdf5")) # a Julia vars requires a pointer directly to the hdf5 file
vars_i = J.list_vars(joinpath(fldr3,"database.hdf5")) # a Julia vars requires a pointer directly to the hdf5 file

# the list of variables probably didn't change between our two Julia models, so we'll only do it once

# pine = J.Loc_p(vars_pine, fldr1, "Pine")
process = J.Loc_j(vars_j, joinpath(fldr1,"database.hdf5"), "Process")
process2 = J.Loc_j(vars_k, joinpath(fldr2,"database.hdf5"), "Process2")
process3 = J.Loc_j(vars_i, joinpath(fldr3,"database.hdf5"), "Process3")

locs = [process2, process3]

# There are two helper objects we need to create before we can get started: 
#   sec::Char, a pointer to which sector the variables is in like R,C,I,T,M,S is used in 2020.bat
#   filter::Dict, a filter which will indicate which dimensions should be shown

sec = 'M'
filter = Dict{Symbol, Any}()

# we can modify these as we need. Let's just look at forecast values in Canada for now
push!(filter, :Year => string.(1985:2020))
push!(filter, :Area => Canada)

# Now we have everything we need. Let's get cracking.

xGO = J.var("xGO", locs; filter, sec)

# We have TotPol, let's get a better view of what's going on.

J.plot_lines(xGO, locs; title = "Gross Output (2017 Dollars)")

# Well, we're seeing differences, but where, specifically. Let's add differences 
# using another function 
# (note, we can just read the variables in with differences if we wanted as well)
# add_differences!(df::DataFrame, 
#   locs::Vector{<:Location}, 
#   diff::Union{Bool, Symbol, Vector{Int}})

J.add_differences!(xGO, locs, :all)
describe(xGO)

# So the redwood versions are matching. Let's look a little deeper into 
# the differences between Pine and NewRed using
# plot_sets(data::DataFrame; 
#   col::Union{String,Symbol} = "", 
#   dim::Union{String,Symbol}="ECC", 
#   num::Integer=10, 
#   title::String="New Plot")

J.plot_sets(xGO; col = :Process2_minus_Process3, dim = "ECC")

pop!(filter, :Year)
push!(filter, :Year => string.(1985:2015))

push!(filter, :ECC => "OtherChemicals", :EC => "OtherChemicals")
push!(filter, :Area => "NT")
J.subset_dataframe!(xGO, filter)
J.plot_sets(xGO; col = :Process_minus_Process2, dim = "Area")

J.plot_lines(xGO, locs; title = "Gross Output - OtherChemicals")

#xGOTOM = J.var("xGOTOM", locs; filter, sec, diff = true, pdiff = true)
#GY = J.var("GY", locs; filter, sec='K', diff = true, pdiff = true)

# push!(filter, :Enduse => "Heat", :Tech => "Electric", :Year => "1985")
# xGO = J.var("xGO", locs; filter, sec='K')
# xDmd = J.var("xDmd", locs; filter, sec='C')
# leftjoin(xGO, xDmd, on = [:ECC => :EC, :Area, :Year], renamecols = "_xGO"  => "_xDmd")

using CSV
CSV.write("xGOOut.csv", xGO)
#
#EuDemand = J.var("EuDemand", locs; filter, sec='K', diff = true, pdiff = true)
#J.plot_sets(EuDemand, col = :Pine_minus_NewRed, dim = "Fuel")
#
#push!(filter, :Fuel => "Electric")
#
#Dmd = J.var("Dmd", locs; filter, sec, diff = true, pdiff = true)
#J.plot_sets(Dmd, col = :Pine_minus_NewRed, dim = "Tech")
#J.plot_sets(Dmd, col = :Pine_minus_NewRed, dim = "Enduse")
#
#push!(filter, :Fuel => ["Electric", "NaturalGas"])
#push!(filter, :Tech => ["Electric", "Gas"])
#push!(filter, :Enduse => ["OthSub", "Motors"])
#
#pop!(filter, :Year)
#push!(filter, :Year => string.(2004:2025))
#
#J.plot_lines(Dmd, locs)
#
#xDmd = J.var("xDmd", locs; filter, sec, diff = true, pdiff = true)
#J.plot_sets(xDmd, col = :Pine_minus_NewRed, dim = "Tech")
#J.plot_lines(xDmd, locs)
