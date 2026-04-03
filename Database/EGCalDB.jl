#
# EGCalDB.jl - Input Database creation file
#

Base.@kwdef struct EGCalDB <: HDF5GroupDatabase
  db::String=DB
  ########################
  #
  # Define Sets
  #
  Fuel = ReadSetFromCSV("Fuel","Key")
  Area = ReadSetFromCSV("Area","Key")
  Year = ReadSetFromCSV("Year","Key")
  tv = ReadSetFromCSV("tv","Key")
  Unit = ReadSetFromCSV("Unit","Key")
  FuelEP = ReadSetFromCSV("FuelEP","Key")
  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  EGFAMult = CreateVariableInHDF5(db, "EGCalDB/EGFAMult", (:Fuel, :Area, :Year),"Electricity Generation by Fuel Multiplier (GWh/GWh)","GWh/GWh")
  UnFlFrMSM0 = CreateVariableInHDF5(db, "EGCalDB/UnFlFrMSM0", (:Unit, :FuelEP, :Year),"Fuel Fraction Non-Price Factor (Btu/Btu)","Btu/Btu")
  UnOOR = CreateVariableInHDF5(db, "EGCalDB/UnOOR", (:Unit, :Year),"Operational Outage Rate (MW/MW)","MW/MW")
end # struct EGCalDB
