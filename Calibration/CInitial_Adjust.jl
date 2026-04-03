#
# CInitial_Adjust.jl
#
using EnergyModel

module CInitial_Adjust

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CCalib
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PCCN::VariableArray{4} = ReadDisk(db,"$Outpt/PCCN") # [Enduse,Tech,EC,Area] Normalized Process Capital Cost ($/mmBtu)
  PCTC::VariableArray{5} = ReadDisk(db,"$Outpt/PCTC") # [Enduse,Tech,EC,Area,Year] Process Capital Cap. Trade Off Coef. (DLESS)
  PFPN::VariableArray{4} = ReadDisk(db,"$Outpt/PFPN") # [Enduse,Tech,EC,Area] Process Normalized Fuel Price ($/mmBtu)
  PFTC::VariableArray{5} = ReadDisk(db,"$Outpt/PFTC") # [Enduse,Tech,EC,Area,Year] Process Fuel Trade Off Coefficient
  POCF::VariableArray{4} = ReadDisk(db,"$CalDB/POCF") # [Enduse,Tech,EC,Area] Process Operating Cost Fraction
  RPCTC::VariableArray{5} = ReadDisk(db,"$Outpt/RPCTC") # [Enduse,Tech,EC,Area,Year] Retrofit Process Capital Trade Off Coefficient (DLESS)
  RPFTC::VariableArray{5} = ReadDisk(db,"$Outpt/RPFTC") # [Enduse,Tech,EC,Area,Year] Retrofit Process Fuel Trade Off Coefficient

  # Scratch Variables
 # TechToUse     'Tech To Use to Fill in Values'
end

function SetPCTC(data, tech, TechToUse)
  (;CalDB,Outpt, db) = data
  (;Areas,ECs,Enduses) = data
  (;Years) = data
  (;PCCN,PCTC,PFPN,PFTC,POCF,RPCTC,RPFTC) = data
  
  @. PCCN[Enduses, tech, ECs, Areas] = PCCN[Enduses, TechToUse, ECs, Areas]
  WriteDisk(db,"$Outpt/PCCN", PCCN)
  
  @. PCTC[Enduses, tech, ECs, Areas, Years] = PCTC[Enduses, TechToUse, ECs, Areas, Years]
  WriteDisk(db,"$Outpt/PCTC", PCTC)
  
  # @. PEM[Enduses, ECs, Areas] = PEM[Enduses, ECs, Areas]
  # WriteDisk(db,"$Outpt/PEM", PEM)
  
  @. POCF[Enduses, tech, ECs, Areas] = POCF[Enduses, TechToUse, ECs, Areas]
  WriteDisk(db,"$CalDB/POCF", POCF)
  
  @. PFPN[Enduses, tech, ECs, Areas] = PFPN[Enduses, TechToUse, ECs, Areas]
  WriteDisk(db,"$Outpt/PFPN", PFPN)
  
  @. PFTC[Enduses, tech, ECs, Areas, Years] = PFTC[Enduses, TechToUse, ECs, Areas, Years]
  WriteDisk(db,"$Outpt/PFTC", PFTC)
  
  @. RPCTC[Enduses, tech, ECs, Areas, Years] = RPCTC[Enduses, TechToUse, ECs, Areas, Years]
  WriteDisk(db,"$Outpt/RPCTC", RPCTC)
  
  @. RPFTC[Enduses, tech, ECs, Areas, Years] = RPFTC[Enduses, TechToUse, ECs, Areas, Years]
  WriteDisk(db,"$Outpt/RPFTC", RPFTC)
  

end

function CCalibration(db)
  data = CCalib(; db)
  (;Tech) = data
  
  # *
  # * Until we get historical energy demands, Geothermal, Heat Pump,
  # * and Solar Process Efficiency parameters are equal to 
  # * Electric parameters.  Jeff Amlin 5/9/16
  # *
  Electric = Select(Tech, "Electric")
  techs = Select(Tech,["Geothermal","HeatPump","Solar"])
  for tech in techs
    SetPCTC(data, tech, Electric)
  end

end

function CalibrationControl(db)
  @info "CInitial_Adjust.jl - CalibrationControl"

  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
