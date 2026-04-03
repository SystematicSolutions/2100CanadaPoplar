import EnergyModel
import EnergyModel.Engine.RDemand as RD




import ...EnergyModel: ReadDisk, WriteDisk, Select, ITime, First, @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log

const Input = "RInput"
const Outpt = "ROutput"
const CalDB = "RCalDB"

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

  db = EnergyModel.DB
  year = 2020
  prior = 2019
  next = 2021
  Zero = 1

   Age::SetArray    = ReadDisk(db, "MainDB/AgeDS")
   Area::SetArray   = ReadDisk(db, "MainDB/AreaDS")
   CTech::SetArray  = ReadDisk(db, "$Input/TechDS")
   EC::SetArray     = ReadDisk(db, "$Input/ECDS")
   ECC::SetArray    = ReadDisk(db, "MainDB/ECCDS")
   ES::SetArray     = ReadDisk(db, "MainDB/ESDS")
   Enduse::SetArray = ReadDisk(db, "$Input/EnduseDS")
   Fuel::SetArray   = ReadDisk(db, "MainDB/FuelDS")
   FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
   Market::SetArray  = ReadDisk(db, "MainDB/Market")

   Month::SetArray  = ReadDisk(db, "MainDB/MonthDS")
   Nation::SetArray = ReadDisk(db, "MainDB/NationDS")
   Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
   PCov::SetArray   = ReadDisk(db, "MainDB/PCovDS")
   Plant::SetArray = ReadDisk(db, "MainDB/PlantDS")
   Poll::SetArray   = ReadDisk(db, "MainDB/PollDS")
   Tech::SetArray   = ReadDisk(db, "$Input/TechDS")

   #
   # SubSets
   #
   HeatpumpSubSet = ["Geothermal","HeatPump","DualHPump","FuelCell"]
   RetrofitEnduseSubSet = ["Heat","Ground","Air/Water","Carriage"]

Base.@kwdef struct Data

   AB::VariableArray{4} = ReadDisk(db, "$Outpt/AB", year)   # Average Market Share ($/$) [Enduse, Tech, EC, Area]
   ADCC::VariableArray{4} = ReadDisk(db, "$Outpt/ADCC", year) # Average Device Capital Cost ($/mmBtu/Yr) [Enduse, Tech, EC, Area]
   AGFr::VariableArray{3} = ReadDisk(db, "SInput/AGFr", year) # Government Subsidy ($/$) [ECC,Poll,Area]
   AMSF::VariableArray{4} = ReadDisk(db, "$Outpt/AMSF", year) # Capital Energy Requirement (Btu/Btu) [Enduse, Tech, EC, Area]
   AMSFPrior::VariableArray{4} = ReadDisk(db, "$Outpt/AMSF", prior) # Capital Energy Requirement (Btu/Btu) [Enduse, Tech, EC, Area]
end
