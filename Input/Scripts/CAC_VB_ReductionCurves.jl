#
# CAC_VB_ReductionCurves.jl - Apply Curve Values from VBInput
#
using EnergyModel

module CAC_VB_ReductionCurves

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
  ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  PCostN::VariableArray{4} = ReadDisk(db,"$Input/PCostN") # [FuelEP,EC,Poll,Area] Pollution Reduction Cost Normal ($/Tonne)
  PVF::VariableArray{4} = ReadDisk(db,"$Input/PVF") # [FuelEP,EC,Poll,Area] Pollution Reduction Variance Factor (($/Tonne)/($/Tonne))
  RPCSw::VariableArray{4} = ReadDisk(db,"$Input/RPCSw") # [EC,Poll,Area,Year] Pollution Reduction Curve Switch (1=2009, 2=2004)
  
  vPCostN::VariableArray{5} = ReadDisk(db,"VBInput/vPCostN") # [FuelEP,ECC,Poll,Area,Year] Pollution Reduction Cost Normal (Local 1985$/Tonne)
  vPVF::VariableArray{5} = ReadDisk(db,"VBInput/vPVF") # [FuelEP,ECC,Poll,Area,Year] Pollution Reduction Variance Factor ($/$)
  vRPCSw::VariableArray{4} = ReadDisk(db,"VBInput/vRPCSw") # [ECC,Poll,Area,Year] Pollution Reduction Curve Switch (Switch)
 
end

function ResCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,FuelEPs,ECC,EC,ECs,Polls) = data
  (;Years) = data
  (;PCostN,vPCostN,PVF,vPVF,RPCSw,vRPCSw) = data

  for year in Years,area in Areas,poll in Polls,ec in ECs,fuel in FuelEPs
    ecc=Select(ECC,EC[ec])
    PCostN[fuel,ec,poll,area]=vPCostN[fuel,ecc,poll,area,Zero]
    PVF[fuel,ec,poll,area]=vPVF[fuel,ecc,poll,area,Zero]
    RPCSw[ec,poll,area,year]=vRPCSw[ecc,poll,area,year]
  end
  
  WriteDisk(db, "$Input/PCostN",PCostN)
  WriteDisk(db, "$Input/PVF",PVF)
  WriteDisk(db, "$Input/RPCSw",RPCSw)
  
 
  
end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
  ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  PCostN::VariableArray{4} = ReadDisk(db,"$Input/PCostN") # [FuelEP,EC,Poll,Area] Pollution Reduction Cost Normal ($/Tonne)
  PVF::VariableArray{4} = ReadDisk(db,"$Input/PVF") # [FuelEP,EC,Poll,Area] Pollution Reduction Variance Factor (($/Tonne)/($/Tonne))
  RPCSw::VariableArray{4} = ReadDisk(db,"$Input/RPCSw") # [EC,Poll,Area,Year] Pollution Reduction Curve Switch (1=2009, 2=2004)
  
  vPCostN::VariableArray{5} = ReadDisk(db,"VBInput/vPCostN") # [FuelEP,ECC,Poll,Area,Year] Pollution Reduction Cost Normal (Local 1985$/Tonne)
  vPVF::VariableArray{5} = ReadDisk(db,"VBInput/vPVF") # [FuelEP,ECC,Poll,Area,Year] Pollution Reduction Variance Factor ($/$)
  vRPCSw::VariableArray{4} = ReadDisk(db,"VBInput/vRPCSw") # [ECC,Poll,Area,Year] Pollution Reduction Curve Switch (Switch)
end

function ComCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,FuelEPs,ECC,EC,ECs,Polls) = data
  (;Years) = data
  (;PCostN,vPCostN,PVF,vPVF,RPCSw,vRPCSw) = data
  
  for year in Years,area in Areas,poll in Polls,ec in ECs,fuel in FuelEPs
    ecc=Select(ECC,EC[ec])
    PCostN[fuel,ec,poll,area]=vPCostN[fuel,ecc,poll,area,Zero]
    PVF[fuel,ec,poll,area]=vPVF[fuel,ecc,poll,area,Zero]
    RPCSw[ec,poll,area,year]=vRPCSw[ecc,poll,area,year]
  end
  
  WriteDisk(db, "$Input/PCostN",PCostN)
  WriteDisk(db, "$Input/PVF",PVF)
  WriteDisk(db, "$Input/RPCSw",RPCSw)
  
end


Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

 
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
  ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  PCostN::VariableArray{4} = ReadDisk(db,"$Input/PCostN") # [FuelEP,EC,Poll,Area] Pollution Reduction Cost Normal ($/Tonne)
  PVF::VariableArray{4} = ReadDisk(db,"$Input/PVF") # [FuelEP,EC,Poll,Area] Pollution Reduction Variance Factor (($/Tonne)/($/Tonne))
  RPCSw::VariableArray{4} = ReadDisk(db,"$Input/RPCSw") # [EC,Poll,Area,Year] Pollution Reduction Curve Switch (1=2009, 2=2004)
  
  vPCostN::VariableArray{5} = ReadDisk(db,"VBInput/vPCostN") # [FuelEP,ECC,Poll,Area,Year] Pollution Reduction Cost Normal (Local 1985$/Tonne)
  vPVF::VariableArray{5} = ReadDisk(db,"VBInput/vPVF") # [FuelEP,ECC,Poll,Area,Year] Pollution Reduction Variance Factor ($/$)
  vRPCSw::VariableArray{4} = ReadDisk(db,"VBInput/vRPCSw") # [ECC,Poll,Area,Year] Pollution Reduction Curve Switch (Switch)
end

function IndCalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,FuelEPs,ECC,EC,ECs,Polls) = data
  (;Years) = data
  (;PCostN,vPCostN,PVF,vPVF,RPCSw,vRPCSw) = data
  
  for year in Years,area in Areas,poll in Polls,ec in ECs,fuel in FuelEPs
    ecc=Select(ECC,EC[ec])
    PCostN[fuel,ec,poll,area]=vPCostN[fuel,ecc,poll,area,Zero]
    PVF[fuel,ec,poll,area]=vPVF[fuel,ecc,poll,area,Zero]
    RPCSw[ec,poll,area,year]=vRPCSw[ecc,poll,area,year]
  end
  
  WriteDisk(db, "$Input/PCostN",PCostN)
  WriteDisk(db, "$Input/PVF",PVF)
  WriteDisk(db, "$Input/RPCSw",RPCSw)
  
end


function CalibrationControl(db)
  @info "CAC_VB_ReductionCurves.jl - CalibrationControl"
  @info "CAC_VB_ReductionCurves.jl - Res"
  ResCalibration(db)
  @info "CAC_VB_ReductionCurves.jl - Com"
  ComCalibration(db)
  @info "CAC_VB_ReductionCurves.jl - Ind"
  IndCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
