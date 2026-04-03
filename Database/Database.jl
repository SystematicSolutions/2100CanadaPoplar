#
# Database.jl
#

module Database

using HDF5
using Dates
#using ..EnergyModel: ReadDisk, E2020Folder, DB, WriteDisk, HDF5GroupDatabase, ITime, MaxTime, ReadSetFromCSV, CreateVariableInHDF5

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

include("../Core/Core.jl")
const VariableArray{N} = Array{Float32,N} where {N}

#create_folder() = isdir(dirname(E2020Folder)) || mkpath(dirname(E2020Folder))

#
# Create a Variable in the Database
# This is a place where a lower case function may make sense. - Jeff Amlin 3/5/23
# A more descriptive name would be helpful, but it cannot be too long. - Jeff Amlin 3/5/23
#
#function create(db::String, name::String, sets::Tuple, doc::String, units::String)
#  Dict(
#    :db => db,
#    :group => dirname(name),
#    :name => basename(name),
#    :ndims => length(sets),
#    :dims => sets,
#    :doc => doc,
#    :units => units,
#  )
#end


#include("MainDB.jl")
#include("MInput.jl")
#include("SInput.jl") 
include("RInput.jl")
#include("CInput.jl")
#include("IInput.jl")
#include("TInput.jl")
#include("VBInput.jl")

#include("EInput.jl") 
#include("EGInput.jl")
#include("SpInput.jl")  # This stays in until SPInput is changed in SpInput in HDF5
#include("MEInput.jl")

#include("MCalDB.jl")
#include("SCalDB.jl")
#include("RCalDB.jl")
#include("CCalDB.jl")
#include("ICalDB.jl")
#include("TCalDB.jl")
#include("ECalDB.jl")

#include("MOutput.jl")
#include("SOutput.jl")
#include("ROutput.jl")    # This stays in until they HDF5 has the ROutput2 variables
#include("COutput.jl")
#include("IOutput.jl")    # This stays in until they HDF5 has the IOutput2 variables
#include("TOutput.jl")
#include("EOutput.jl")
#include("SpOutput.jl")   # This stays in until SPInput is changed in SpInput in HDF5
#include("MEOutput.jl")
#include("EGOutput.jl")
#include("EGCalDB.jl")

#"""
#    Create_Database(db::String) -> nothing
#
#This function creates a HDF5 database in the path provided.
#"""

function Create_Database_Run(db)
  @info "Create_Database_Run($(db)"
 # CreateDisk(db)
  
 # WriteDisk(db, Database.MainDB(; db))
 # WriteDisk(db, Database.MInput(; db))
 # WriteDisk(db, Database.SInput(; db))
   
   WriteDisk(DB,Database.RInput(;db))


   
 # WriteDisk(db, Database.CInput(; db))
 # WriteDisk(db, Database.IInput(; db))
 # WriteDisk(db, Database.TInput(; db))
 # WriteDisk(db, Database.VBInput(; db))
 # WriteDisk(db, Database.EInput(; db))
 # WriteDisk(db, Database.EGInput(; db))
 # WriteDisk(db, Database.SpInput(; db))
 # WriteDisk(db, Database.MEInput(; db))
 #
 # WriteDisk(db, Database.MCalDB(; db))
 # WriteDisk(db, Database.SCalDB(; db))
 # WriteDisk(db, Database.RCalDB(; db))
 # WriteDisk(db, Database.CCalDB(; db))
 # WriteDisk(db, Database.ICalDB(; db))
 # WriteDisk(db, Database.TCalDB(; db))
 # WriteDisk(db, Database.ECalDB(; db))

 # WriteDisk(db, Database.MOutput(; db))
 # WriteDisk(db, Database.SOutput(; db))
 # WriteDisk(db, Database.ROutput(; db))
 # WriteDisk(db, Database.COutput(; db))
 # WriteDisk(db, Database.IOutput(; db))
 # WriteDisk(db, Database.TOutput(; db))
 # WriteDisk(db, Database.EOutput(; db))
 # WriteDisk(db, Database.SpOutput(; db))
 # WriteDisk(db, Database.MEOutput(; db))
 # WriteDisk(db, Database.EGOutput(; db))
 # WriteDisk(db, Database.EGCalDB(; db))

end

end
