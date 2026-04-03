#
# SCalDB.jl - Input Database creation file
#

Base.@kwdef struct SCalDB <: HDF5GroupDatabase
  db::String=DB
  ########################
  #
  # Define Sets
  #
  Day = ReadSetFromCSV("Day","Key")
  Month = ReadSetFromCSV("Month","Key")
  Area = ReadSetFromCSV("Area","Key")
  Year = ReadSetFromCSV("Year","Key")
  tv = ReadSetFromCSV("tv","Key")
  Class = ReadSetFromCSV("Class","Key")
  Hour = ReadSetFromCSV("Hour","Key")
  DACTech = ReadSetFromCSV("DACTech","Key")
  Fuel = ReadSetFromCSV("Fuel","Key")
  Nation = ReadSetFromCSV("Nation","Key")
  NationX = ReadSetFromCSV("NationX","Key")
  ES = ReadSetFromCSV("ES","Key")
  H2Tech = ReadSetFromCSV("H2Tech","Key")
  RfUnit = ReadSetFromCSV("RfUnit","Key")
  Crude = ReadSetFromCSV("Crude","Key")
  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  BaseAdj = CreateVariableInHDF5(db, "SCalDB/BaseAdj", (:Day, :Month, :Area, :Year),"Adjustment Based on All Years (MW/MW)","MW/MW")
  CDUF = CreateVariableInHDF5(db, "SCalDB/CDUF", (:Class, :Day, :Month, :Area),"Use Factor for Misc. Demand","NoUnit")
  CLSF = CreateVariableInHDF5(db, "SCalDB/CLSF", (:Class, :Hour, :Day, :Month, :Area),"Electric Class Load Shape (MW/MW)","MW/MW")
  DACLSF = CreateVariableInHDF5(db, "SCalDB/DACLSF", (:DACTech, :Hour, :Day, :Month, :Area),"DAC Production Load Shape (MW/MW)","MW/MW")
  DPKM = CreateVariableInHDF5(db, "SCalDB/DPKM", (:Month, :Area, :Year),"Gas Peak Day Multiplier","8,3")
  FlowCharge = CreateVariableInHDF5(db, "SCalDB/FlowCharge", (:Fuel, :Nation, :NationX, :Year),"Energy Flow Non-Price Factors (\$/mmBtu)","\$/mmBtu")
  FPDChgF = CreateVariableInHDF5(db, "SCalDB/FPDChgF", (:Fuel, :ES, :Area, :Year),"Fuel Delivery Charge (Real \$/mmBtu)","Real \$/mmBtu")
  FuelLimit = CreateVariableInHDF5(db, "SCalDB/FuelLimit", (:Fuel, :Area, :Year),"Fuel Limit Multiplier (Btu/Btu)","Btu/Btu")
  GBaseAdj = CreateVariableInHDF5(db, "SCalDB/GBaseAdj", (:Day, :Month, :Area),"Gas Adjustment Based on All Years (MTherm/MTherm)","MTherm/MTherm")
  H2LSF = CreateVariableInHDF5(db, "SCalDB/H2LSF", (:H2Tech, :Hour, :Day, :Month, :Area),"Hydrogen Production Load Shape (MW/MW)","MW/MW")
  HPKM = CreateVariableInHDF5(db, "SCalDB/HPKM", (:Month, :Area, :Year),"Electric Peak Hour Multiplier","NoUnit")
  RfOOR = CreateVariableInHDF5(db, "SCalDB/RfOOR", (:RfUnit, :Fuel, :Year),"Refining Unit Operational Outage Rate (Btu/Btu)","Btu/Btu")
  RPPCrudeAdjust = CreateVariableInHDF5(db, "SCalDB/RPPCrudeAdjust", (:Crude, :Area, :Year),"Crude Oil Processed Adjustment (TBtu/Yr)","TBtu/Yr")
  RPPProdAdjust = CreateVariableInHDF5(db, "SCalDB/RPPProdAdjust", (:Fuel, :Area, :Year),"Refined Petroleum Products (RPP) Production (TBtu/Yr)","RPP")
  RPPEff = CreateVariableInHDF5(db, "SCalDB/RPPEff", (:Nation, :Year),"RPP Efficiency Factor (Btu/Btu)","Btu/Btu")
end # struct SCalDB
