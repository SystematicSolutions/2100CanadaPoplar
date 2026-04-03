#
# MCalDB.jl - Input Database creation file
#

Base.@kwdef struct MCalDB <: HDF5GroupDatabase
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
  ECGR = CreateVariableInHDF5(db, "MCalDB/ECGR", (:ECC, :Area, :Year),"Difference between GRP and Sector Growth Rate (1/Yr)","1/Yr")
  ECUFC = CreateVariableInHDF5(db, "MCalDB/ECUFC", (:ECC, :Area, :Year),"Capacity Utilization Factor (\$/Yr/\$/Yr)","\$/Yr/\$/Yr")
end # struct MCalDB
