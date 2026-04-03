#
# TransMarketShare.jl
#



using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}
Base.@kwdef struct TransMarketShareData
  db::String

  
  Enduse::SetArray = ReadDisk(db, "MainDB/Enduse")
  Tech::SetArray = ReadDisk(db, "MainDB/Tech")
  EC::SetArray = ReadDisk(db, "MainDB/EC")
  Area::SetArray = ReadDisk(db, "MainDB/Area")
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Nation::SetArray = ReadDisk(db, "MainDB/Nation")
  CTech::SetArray = ReadDisk(db, "MainDB/CTech")
  ECC::SetArray = ReadDisk(db, "MainDB/ECC")
  Poll::SetArray = ReadDisk(db, "MainDB/Poll")
  Age::SetArray = ReadDisk(db, "MainDB/Age")
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEP")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  AMSF::VariableArray{5} = ReadDisk(db, "9/AMSF") # [Enduse,Tech,EC,Area,Year] Average Market Share ($/$)
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CMSF::VariableArray{6} = ReadDisk(db, "Outpt/CMSF") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Fraction by Device ($/$)
  CMSM0::VariableArray{6} = ReadDisk(db, "CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  DAct::VariableArray{5} = ReadDisk(db, "Input/DAct") # [Enduse,Tech,EC,Area,Year] Device Activity Level (Ton-Miles/Vehicle-Mile)
  DCC::VariableArray{5} = ReadDisk(db, "9/DCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost ($/Mile/Yr)
  DCCR::VariableArray{5} = ReadDisk(db, "8/DCCR") # [Enduse,Tech,EC,Area,Year] Device Capital Charge Rate (($/Yr)/$) 
  DEE::VariableArray{5} = ReadDisk(db, "9/DEE") # [Tech,Area,Enduse,EC,Year] Device Efficiency (Mile/mmBtu) 
  DEEA::VariableArray{5} = ReadDisk(db, "9/DEEA") # [Tech,Area,Enduse,EC,Year] Average Device Efficiency (Mile/mmBtu)
  DER::VariableArray{5} = ReadDisk(db, "Outpt/DER") # [Tech,Area,Enduse,EC,Year] Energy Requirement (mmBtu/Yr)
  DERA::VariableArray{5} = ReadDisk(db, "Outpt/DERA") # [Tech,Area,Enduse,EC,Year] Energy Requirement Addition (mmBtu/Yr)
  DERR::VariableArray{5} = ReadDisk(db, "Outpt/DERR") # [Tech,Area,Enduse,EC,Year] Device Energy Rqmt. Retire. (mmBtu/Yr/Yr)
  DEStd::VariableArray{5} = ReadDisk(db, "Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu) 
  DEStdP::VariableArray{5} = ReadDisk(db, "Input/DEStdP") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards Policy (Btu/Btu) 
  Dmd::VariableArray{5} = ReadDisk(db, "Outpt/Dmd") # [Tech,Area,Enduse,EC,Year] Total Energy Demand (TBtu/Yr)
  DPL::VariableArray{5} = ReadDisk(db, "Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (YRS) 
  Driver::VariableArray{3} = ReadDisk(db, "MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  ECFP::VariableArray{5} = ReadDisk(db, "Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  ECUF::VariableArray{3} = ReadDisk(db, "MOutput/ECUF") # [ECC,Area,Year] Capital Utilization Fraction (Btu/Btu)
  EuPol::VariableArray{4} = ReadDisk(db, "SOutput/EuPol") # [ECC,Poll,Area,Year] Energy Related Pollution (Tonnes/Yr)
  EUPC::VariableArray{6} = ReadDisk(db, "Outpt/EUPC") # [Tech,Area,Enduse,Age,EC,Year] Production Capacity by Enduse (M$/Yr) 
  EUPCA::VariableArray{6} = ReadDisk(db, "Outpt/EUPCA") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity Additions ((M$/Yr)/Yr)
  EUPCAC::VariableArray{6} = ReadDisk(db, "Outpt/EUPCAC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity Additions from Device Conversions ((M$/Yr)/Yr)
  EUPCR::VariableArray{6} = ReadDisk(db, "Outpt/EUPCR") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity Retirement ((M$/Yr)/Yr)
  EUPCRC::VariableArray{6} = ReadDisk(db, "Outpt/EUPCRC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity Retirements from Conversions ((M$/Yr)/Yr)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MCFU::VariableArray{5} = ReadDisk(db, "9/MCFU") # [Tech,Area,Enduse,EC,Year] Marginal Cost of Fuel Use ($/mmBtu)
  MMSF::VariableArray{5} = ReadDisk(db, "8/MMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction by Device ($/$)
  MMSM0::VariableArray{5} = ReadDisk(db, "8/MMSM0") # [Tech,Area,Enduse,EC,Year] Non-price Factors. ($/$)
  PCA::VariableArray{4} = ReadDisk(db, "MOutput/PCA") # [Age,ECC,Area,Year] Production Capacity Additions (M$/Yr/Yr)
  PCC::VariableArray{3} = ReadDisk(db, "Outpt/PCC") # [Tech,Area,Year] Process Capital Cost ($/($/Yr))
  PCEU::VariableArray{5} = ReadDisk(db, "Outpt/PCEU") # [Enduse,Tech,EC,Area,Year] Production Capacity (Driver/Yr)
  PCPL::VariableArray{3} = ReadDisk(db, "MInput/PCPL") # [ECC,Area,Year] Physical Life of Production Capacity (Years)
  PEE::VariableArray{5} = ReadDisk(db, "Outpt/PEE") # [Tech,Area,Enduse,EC,Year] Process Efficiency ($/Mile)
  PEEA::VariableArray{5} = ReadDisk(db, "Outpt/PEEA") # [Tech,Area,Enduse,EC,Year] Average Process Efficiency ($/Mile)
  PEPL::VariableArray{5} = ReadDisk(db, "Outpt/PEPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Process Requirements (Years)
  PER::VariableArray{5} = ReadDisk(db, "15/PER") # [Tech,Area,Enduse,EC,Year] Process Requirement (Miles/Yr)
  PERA::VariableArray{5} = ReadDisk(db, "15/PERA") # [Tech,Area,Enduse,EC,Year] Process Energy Rqmt. Addition (Miles/YR/Yr)
  PERR::VariableArray{5} = ReadDisk(db, "Outpt/PERR") # [Tech,Area,Enduse,EC,Year] Process Energy Rqmt. Retire. (mmBtu/Yr/Yr)
  POCA::VariableArray{7} = ReadDisk(db, "9/POCA") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Average Pollution Coefficients (Tonnes/TBtu)
  UMS::VariableArray{3} = ReadDisk(db, "9/UMS") # [Tech,Area,Year] Short Term Price Response (Btu/Btu)
  VehicleRetire::VariableArray{5} = ReadDisk(db, "Outpt/VehicleRetire") # [Enduse,Tech,EC,Area,Year] Retirement of Vehicles (Vehicles)
  VehicleSales::VariableArray{5} = ReadDisk(db, "Outpt/VehicleSales") # [Enduse,Tech,EC,Area,Year] Total Sales of Vehicles (Vehicles)
  VehicleStock::VariableArray{5} = ReadDisk(db, "Outpt/VehicleStock") # [Enduse,Tech,EC,Area,Year] Stock of Vehicles (Vehicles)
  VDT::VariableArray{5} = ReadDisk(db, "Outpt/VDT") # [Tech,Area,Enduse,EC,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  CERSM::VariableArray{4} = ReadDisk(db, "8/CERSM") # [Enduse,EC,Area,Year] Capital Energy Requirement (Btu/Btu)
  xDPL::VariableArray{5} = ReadDisk(db, "Input/xDPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  xMMSF::VariableArray{5} = ReadDisk(db, "CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction by Device ($/$)
end
