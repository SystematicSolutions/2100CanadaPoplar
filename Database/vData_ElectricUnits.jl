#
# vData_ElectricUnits.jl - Input Database creation file
#

Base.@kwdef struct vData_ElectricUnits <: HDF5GroupDatabase
  db::String=DB
  ########################
  #
  # Define Sets
  #
  Unit = ReadSetFromCSV("Unit","Key")
  tv = ReadSetFromCSV("tv","Key")
  FuelEP = ReadSetFromCSV("FuelEP","Key")
  Year = ReadSetFromCSV("Year","Key")
  Month = ReadSetFromCSV("Month","Key")
  Poll = ReadSetFromCSV("Poll","Key")
  TimeP = ReadSetFromCSV("TimeP","Key")  
  
  #
  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  vUnArea::SetArray = Unit
  vUnCogen = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnCogen", (:Unit,),"Industrial Generation Switch (Switch) (1=Industrial Generation)","Switch")
  vUnDmd = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnDmd", (:Unit, :FuelEP, :Year),"Energy Demands (TBtu/Yr)","TBtu/Yr")
  vUnEAF = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnEAF", (:Unit, :Month, :Year),"Energy Avaliability Factor (GWh/GWh)","GWh/GWh")
  vUnEffStorage = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnEffStorage", (:Unit,),"Storage Efficiency (GWH/GWH)","GWH/GWH")
  vUnEGA = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnEGA", (:Unit, :Year),"Generation (GWh/Yr)","GWh/Yr")
  vUnEmit = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnEmit", (:Unit,),"Does this Unit Emit Pollution (Switch) (1=Yes)","Switch")
  vUnFacility::SetArray = Unit
  vUnF1::SetArray = Unit
  vUnFlFr = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnFlFr", (:Unit, :FuelEP, :Year),"Fuel Fraction (Btu/Btu)","Btu/Btu")
  vUnGC = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnGC", (:Unit, :Year),"Generating Capacity (MW/Yr)","MW/Yr")
  vUnGCCC = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnGCCC", (:Unit, :Year),"Generating Unit Capital Cost (Real \$/Kw)","Real \$/Kw")
  vUnGenCo::SetArray = Unit
  vUnHRt = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnHRt", (:Unit, :Year),"Heat Rate (BTU/KWh)","BTU/KWh")
  vUnLimited = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnLimited", (:Unit, :Year),"Limited Energy Units Switch (Switch) (1=Limited Energy Unit)","Switch")
  vUnMustRun = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnMustRun", (:Unit,),"Must Run (Switch) (1=Must Run)","Switch")
  vUnName::SetArray = Unit
  vUnNation::SetArray = Unit
  vUnNode::SetArray = Unit
  vUnOnLine = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnOnLine", (:Unit,),"On-Line Date (Year)","Year")
  vUnOUREG = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnOUREG", (:Unit, :Year),"Own Use Rate for Generation (MW/MW)","MW/MW")
  vUnOURGC = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnOURGC", (:Unit, :Year),"Own Use Rate for Generating Capacity (MW/MW)","MW/MW")
  vUnOR = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnOR", (:Unit,:TimeP,:Month,:Year),"Outage Rate (MW/MW)","MW/MW")
  vUnOwner::SetArray = Unit
  vUnPlant::SetArray = Unit
  vUnPol = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnPol", (:Unit, :FuelEP, :Poll, :Year),"Electric Unit Pollution (Tonnes/Yr)","Tonnes/Yr")
  vUnRetire = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnRetire", (:Unit,),"Retirement Date (Year)","Year")
  vUnSector::SetArray = Unit
  vUnSource = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnSource", (:Unit,),"Source (Switch) (1=Endogenous, 0=Exogenous)","Switch")
  vUnStorage = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnStorage", (:Unit,),"Storage (Switch) (1=Storage, 0=Non-storage)","Switch")
  vUnSqFr = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnSqFr", (:Unit, :Poll, :Year),"Sequestered Pollution Fraction (Tonne/Tonne)","Tonne/Tonne")
  vUnUFOMC = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnUFOMC", (:Unit, :Year),"Fixed O&M Costs (Real \$/Kw/Yr)","Real \$/Kw/Yr")
  vUnUOMC = CreateVariableInHDF5(db, "vData_ElectricUnits/vUnUOMC", (:Unit, :Year),"Variable O&M Costs (Real \$/MWh)","Real \$/MWh")
end # struct vData_ElectricUnits
