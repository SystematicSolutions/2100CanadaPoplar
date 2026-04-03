#
# ECalDB.jl - Input Database creation file
#

Base.@kwdef struct ECalDB <: HDF5GroupDatabase
  db::String=DB
  ########################
  #
  # Define Sets
  #
  ECC = ReadSetFromCSV("ECC","Key")
  Area = ReadSetFromCSV("Area","Key")
  Year = ReadSetFromCSV("Year","Key")
  tv = ReadSetFromCSV("tv","Key")
  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  NPUC = CreateVariableInHDF5(db, "ECalDB/NPUC", (:ECC, :Area, :Year),"Non-Power Marginal Unit Cost (\$/MWh)","\$/MWh")
  PEDC = CreateVariableInHDF5(db, "ECalDB/PEDC", (:ECC, :Area, :Year),"Elect. Delivery Charge (\$/MWh)","\$/MWh")
end # struct ECalDB
