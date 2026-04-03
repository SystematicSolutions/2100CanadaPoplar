#
# EnergyModel.jl
#

module EnergyModel

using CSV
using DataFrames
using HDF5
using JSON3
using StaticArrays
using TimerOutputs
using TOML
using Dates
using ZipFile
using Preferences
using DataStructures
using PrecompileTools
using Distributed
using p7zip_jll
using JuliaFormatter
using MacroTools
using LinearRegression

import QuickMenus as QM

#
# Local Julia Functions
#
include("../Core/Core.jl")
include("../Core/Logger.jl")
include("../Core/CoreE2020.jl")

#
# Model Equations (Engine)
#
include("../Engine/E2020_Constants.jl")
include("../Engine/Engine.jl")

#
# Create Model Databases
#
include("../Database/Database.jl")

#
# Incorporate Policy data into databases
#
include("../Policy/Policy.jl")
include("../Policy/PolicyTest.jl")
include("../Policy/PolicyMarketShare.jl")

#
# Create Output Files
#
include("../Output/Outputs.jl")

#
# Main Routines
#
include("../Engine/Main.jl")

#
# Interface Utitilies
#
# include("../Interface/Interface.jl")

#
# Initialize Model
# Later, consider moving call to Database.create_folder to place where database is created - Jeff Amlin 3/5/23
# Later, consider moving call to Output.create_folder to place where outputs are created - Jeff Amlin 3/5/23
#
function initialize()
  !isinteractive() && Logger.initialize() # sets up the logger
  Database.create_folder() # creates a ./data folder if it does not exist
  Outputs.create_folder() # creates a ./out folder if it does not exist
  # mkpath(Process_Folder)
  # mkpath(Start_Folder)
  # mkpath(Base_Folder)
  # mkpath(Ref23_Folder)
  # mkpath(OGRef_Folder)
  # mkpath(Policy_Folder)
end



end
