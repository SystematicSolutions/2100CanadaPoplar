#
# OG_Endogenous.jl
#
using EnergyModel

module OG_Endogenous

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String
  
  OGCode::Vector{String} = ReadDisk(db, "MainDB/OGCode")
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGCode")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DevMaxM::VariableArray{2} = ReadDisk(db,"SpInput/DevMaxM") # [OGUnit,Year] Development Rate Maximum Multiplier from ROI (Btu/Btu)
  DevMinM::VariableArray{2} = ReadDisk(db,"SpInput/DevMinM") # [OGUnit,Year] Development Rate Minimum Multiplier from ROI (Btu/Btu)
  DevSw::VariableArray{2} = ReadDisk(db,"SpInput/DevSw") # [OGUnit,Year] Development Switch
  DevVar::VariableArray{2} = ReadDisk(db,"SpInput/DevVar") # [OGUnit,Year] Development Rate Variance (Btu/Btu)
  PdMaxM::VariableArray{2} = ReadDisk(db,"SpInput/PdMaxM") # [OGUnit,Year] Production Rate Maximum Multiplier from ROI (Btu/Btu)
  PdMinM::VariableArray{2} = ReadDisk(db,"SpInput/PdMinM") # [OGUnit,Year] Production Rate Minimum Multiplier from ROI (Btu/Btu)
  PdSw::VariableArray{2} = ReadDisk(db,"SpInput/PdSw") # [OGUnit,Year] Production Switch
  PdVar::VariableArray{2} = ReadDisk(db,"SpInput/PdVar") # [OGUnit,Year] Production Rate Variance (Btu/Btu)

end

function SupplyPolicy(db)
  data = SControl(; db)
  (;OGUnit,OGUnits) = data
  (;DevMaxM,DevMinM,DevSw,DevVar,PdMaxM,PdMinM,PdSw,PdVar) = data

  #
  # Historically use exogenous forecast (DevSw=0)
  #
  DevSw .= 0
  PdSw .= 0
  #
  # After the historical period, the switch is set to adjust the
  # development rate when the economics change from the reference
  # case (DevSw=2) - Jeff Amlin 02/12/19
  #
  years=collect(Yr(2021):Final)
  for year in years, ogunit in OGUnits
    DevSw[ogunit,year] = 2.0
    PdSw[ogunit,year] = 2.0
  end
  #
  ogunit=Select(OGUnit,"AB_OS_Mining_0001")
  years=collect(Yr(2023):Final)
  for year in years
    DevSw[ogunit,year] = 7
  end
  #
  WriteDisk(db,"SpInput/DevSw",DevSw)
  WriteDisk(db,"SpInput/PdSw",PdSw)
  
  #
  # Initial Values
  #
  years=collect(Yr(2021):Final)
  for year in years, ogunit in OGUnits
    DevMaxM[ogunit,year] =  30.00
    DevVar[ogunit,year]  = 1/DevMaxM[ogunit,year]
    DevMinM[ogunit,year] =   0.00
  #
    PdMaxM[ogunit,year] =   1.00
    PdVar[ogunit,year]  = 1/PdMaxM[ogunit,year]
    PdMinM[ogunit,year] =   0.00
  end 
  #

  WriteDisk(db,"SpInput/DevMaxM",DevMaxM)
  WriteDisk(db,"SpInput/DevMinM",DevMinM)
  WriteDisk(db,"SpInput/DevVar",DevVar)
  WriteDisk(db,"SpInput/PdMaxM",PdMaxM)
  WriteDisk(db,"SpInput/PdMinM",PdMinM)
  WriteDisk(db,"SpInput/PdVar",PdVar)

end

function PolicyControl(db)
  @info "OG_Endogenous.jl - PolicyControl"

  SupplyPolicy(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
