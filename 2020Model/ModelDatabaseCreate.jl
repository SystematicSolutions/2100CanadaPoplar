#
# ModelDatabaseCreate.jl
#

#import Pkg;
#Pkg.add("HDF5");
#Pkg.add("DataFrames");
#Pkg.add("CSV");
#Pkg.add("Printf");
using CSV, DataFrames, Dates, HDF5, Printf;
include("../Core/Core.jl")

#using EnergyModel
#using ..EnergyModel: ReadDisk, E2020Folder, DB, WriteDisk, 
#  HDF5GroupDatabase, ITime, MaxTime, ReadSetFromCSV, CreateVariableInHDF5, CreateDisk


ttModel = "2020Model"
startDirectory = pwd()

if length(ARGS) > 0
  
  startLength=length(startDirectory)
  rootLength=startLength-10
  modelRoot=SubString(startDirectory,1,rootLength)

else
  modelRoot ="C:\\2020CanadaRedwood"
  println("startDirectory " * startDirectory)
end
println("ModelRoot=" * modelRoot)
println(ARGS)

 
 
hdf5DatabaseName = "$modelRoot\\$ttModel\\database.hdf5"
println(hdf5DatabaseName)
CreateDisk(hdf5DatabaseName)

@info "Including Databases"

include("$modelRoot/Database/MainDB.jl")
WriteDisk(hdf5DatabaseName, MainDB(;))
include("$modelRoot/Database/CInput.jl")
WriteDisk(hdf5DatabaseName, CInput(;))
include("$modelRoot/Database/CCalDB.jl")
WriteDisk(hdf5DatabaseName, CCalDB(;))
include("$modelRoot/Database/COutput.jl")
WriteDisk(hdf5DatabaseName, COutput(;))
include("$modelRoot/Database/ECalDB.jl")
WriteDisk(hdf5DatabaseName, ECalDB(;))
include("$modelRoot/Database/EInput.jl")
WriteDisk(hdf5DatabaseName, EInput(;))
include("$modelRoot/Database/EOutput.jl")
WriteDisk(hdf5DatabaseName, EOutput(;))
include("$modelRoot/Database/EGCalDB.jl")
WriteDisk(hdf5DatabaseName, EGCalDB(;))
include("$modelRoot/Database/EGInput.jl")
WriteDisk(hdf5DatabaseName, EGInput(;))
include("$modelRoot/Database/EGOutput.jl")
WriteDisk(hdf5DatabaseName, EGOutput(;))
include("$modelRoot/Database/ICalDB.jl")
WriteDisk(hdf5DatabaseName, ICalDB(;))
include("$modelRoot/Database/IInput.jl")
WriteDisk(hdf5DatabaseName, IInput(;))
include("$modelRoot/Database/IOutput.jl")
WriteDisk(hdf5DatabaseName, IOutput(;))
include("$modelRoot/Database/KInput.jl")
WriteDisk(hdf5DatabaseName, KInput(;))
include("$modelRoot/Database/KOutput.jl")
WriteDisk(hdf5DatabaseName, KOutput(;))
include("$modelRoot/Database/MCalDB.jl")
WriteDisk(hdf5DatabaseName, MCalDB(;))
include("$modelRoot/Database/MEInput.jl")
WriteDisk(hdf5DatabaseName, MEInput(;))
include("$modelRoot/Database/MEOutput.jl")
WriteDisk(hdf5DatabaseName, MEOutput(;))
include("$modelRoot/Database/MInput.jl")
WriteDisk(hdf5DatabaseName, MInput(;))
include("$modelRoot/Database/MOutput.jl")
WriteDisk(hdf5DatabaseName, MOutput(;))
include("$modelRoot/Database/RCalDB.jl")
WriteDisk(hdf5DatabaseName, RCalDB(;))
include("$modelRoot/Database/RInput.jl")
WriteDisk(hdf5DatabaseName, RInput(;))
include("$modelRoot/Database/ROutput.jl")
WriteDisk(hdf5DatabaseName, ROutput(;))
include("$modelRoot/Database/SCalDB.jl")
WriteDisk(hdf5DatabaseName, SCalDB(;))
include("$modelRoot/Database/SInput.jl")
WriteDisk(hdf5DatabaseName, SInput(;))
include("$modelRoot/Database/SOutput.jl")
WriteDisk(hdf5DatabaseName, SOutput(;))
include("$modelRoot/Database/SpInput.jl")
WriteDisk(hdf5DatabaseName, SpInput(;))
include("$modelRoot/Database/SpOutput.jl")
WriteDisk(hdf5DatabaseName, SpOutput(;))
include("$modelRoot/Database/TCalDB.jl")
WriteDisk(hdf5DatabaseName, TCalDB(;))
include("$modelRoot/Database/TInput.jl")
WriteDisk(hdf5DatabaseName, TInput(;))
include("$modelRoot/Database/TOutput.jl")
WriteDisk(hdf5DatabaseName, TOutput(;))
include("$modelRoot/Database/VBInput.jl")
WriteDisk(hdf5DatabaseName, VBInput(;))
include("$modelRoot/Database/vData_ElectricUnits.jl")
WriteDisk(hdf5DatabaseName, vData_ElectricUnits(;))

function WriteLog(message)
    report = open(logName, "a")
    write(report, message)
    close(report)
    @info "$message"
end

@info "HDF5 database creation complete."

