#
# MControl.jl - This is only the calibration portion of MControl.src
#

# module MControl

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,STime,HisTime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DataMControl
  db::String
  
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))    
  
  
  
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0
  MacroSwitch::Vector{String} = ReadDisk(db,"MInput/MacroSwitch") #[Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  NonExist::Float32 = ReadDisk(db,"MainDB/NonExist")[1] # [tv] NonExist = -1
  SegSw::VariableArray{1} = ReadDisk(db,"MainDB/SegSw") #[Seg] Segment Execution Switch
  xSegSw::VariableArray{1} = ReadDisk(db,"MainDB/xSegSw") #[Seg] Segment Execution Switch

end

#
########################
#
function Coefficient(data)
  (;db,Seg) = data
  (;Exogenous,NonExist,SegSw) = data 
  
  @info "MControl.jl,Coefficient,MEconomy Calibration Control"

  
  # 
  # Last=Last+1
  
  
  #
  # Set SegSw Switches
  #
  SegSw .= NonExist
  seg = Select(Seg,"MEconomy")
  SegSw[seg] = Exogenous
  
  WriteDisk(db,"MainDB/SegSw",SegSw)
  
  # 
  # TEST=True
  # CTime=STime
  # BTime=CTime
  # Write Disk(BTime)
  # EndTime=HisTime+1
  # EndYear=EndTime-Yrv(1)+1
  # Write Disk(EndYear)
  # Write Disk(EndTime)
  # Last=Last-1

end


#
########################
#
function Calib(data)
  (;db) = data

  @info "MControl.jl,Calib,MEconomy Calibration Control"

  Coefficient(data)
  
  CTime=STime
  while CTime <= MaxTime
    CTime = max(CTime,STime)
    current = CTime-ITime+1
    year = current
    prior = max(current-1,1)
    prior2 = max(prior-1,1)
    next = current+1
    @info " MControl.jl,Simulating the year $CTime ..."
  
    MEconomy.Control(MEconomy.Data(; db,year,current,prior,next,CTime))
    MReductions.CtrlReductions(MReductions.Data(; db,year,prior,next,CTime))
    MPollution.Reductions(MPollution.Data(; db,year,prior,next,CTime))
    MPollution.CtrlPollution(MPollution.Data(; db,year,prior,next,CTime))
  
    CTime = CTime+1

  end

  CTime = STime

end

#
########################
#
function MCalibEntire(db)
  data = DataMControl(; db)
  (;Nation) = data
  (;MacroSwitch) = data
  
  @info "MControl.jl,Entire,MEconomy Calibration Control"

  CN = Select(Nation,"CN")

  years = collect(1:Final)
  for year in years
    current = year
    CTime = current+ITime-1
    prior = max(current-1,1)
    next = current+1

    if MacroSwitch[CN] == "TOM"
      MEconomyTOM.Control(MEconomyTOM.Data(; db,year,current,prior,next,CTime))
      MEconomy.MapForCalibExchangeRateInflation(MEconomy.Data(; db,year,current,prior,next,CTime))
    end
   
    MEconomy.ApplyDriverSwitch(MEconomy.Data(; db,year,current,prior,next,CTime))
  end

  MInitial.Initial(MInitial.Data(;db))

  Calib(data)

  #
  # MFuture is empty in Promula
  #
end # MCalibEntire


# end # Module

