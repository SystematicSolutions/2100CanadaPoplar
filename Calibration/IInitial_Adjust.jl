#
# IInitial_Adjust.jl
#
using EnergyModel

module IInitial_Adjust

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
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
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM")

  # Scratch Variables
 # AreaToUse     'Area To Use to Fill in Values'
end

function SetPCTC(data, techs, ecs, AreaToUse, areas)
  (;Enduses) = data
  (;Years) = data
  (;PCCN,PCTC,PFPN,PFTC,POCF,RPCTC,RPFTC,PEM) = data
  
  for area in areas
  
    @. PCCN[Enduses, techs, ecs, area] = PCCN[Enduses, techs, ecs, AreaToUse]
        
    @. PCTC[Enduses, techs, ecs, area, Years] = PCTC[Enduses, techs, ecs, AreaToUse, Years]
        
    @. PEM[Enduses, ecs, area] = PEM[Enduses, ecs, AreaToUse]
        
    @. POCF[Enduses, techs, ecs, area] = POCF[Enduses, techs, ecs, AreaToUse]
    
    @. PFPN[Enduses, techs, ecs, area] = PFPN[Enduses, techs, ecs, AreaToUse]
        
    @. PFTC[Enduses, techs, ecs, area, Years] = PFTC[Enduses, techs, ecs, AreaToUse, Years]
        
    @. RPCTC[Enduses, techs, ecs, area, Years] = RPCTC[Enduses, techs, ecs, AreaToUse, Years]
        
    @. RPFTC[Enduses, techs, ecs, area, Years] = RPFTC[Enduses, techs, ecs, AreaToUse, Years]
    
  end
  

end

function ICalibration(db)
  data = ICalib(; db)
  (;Area,Areas,EC,Enduses,Tech) = data
  (;Techs,Years) = data
  (;PCCN,PCTC,PFPN,PFTC,POCF,RPCTC,RPFTC,PEM) = data
  (;CalDB,Outpt) = data
  
  # *
  # * For Rubber
  # * use Ontario for smaller provinces/territories
  # * 
  Rubber = Select(EC,["Rubber"])
  ON = Select(Area,"ON")
  areas = Select(Area,["PE","YT","NT","NU"])
  SetPCTC(data,Techs,Rubber,ON,areas)
  
  
  # *
  # * For NS Other Metal Mining, Petrochemicals, and Other Chemicals,
  # * use Ontario
  # *
  NS = Select(Area,["NS"])
  ecs = Select(EC,["OtherMetalMining","Petrochemicals","OtherChemicals"])
  SetPCTC(data,Techs,ecs,ON,NS)

  # *
  # * For NS Industrial Gas use Ontario
  # *
  IndustrialGas = Select(EC,["IndustrialGas"])
  SetPCTC(data,Techs,IndustrialGas,ON,NS)


  # *
  # * PEI and Teritories use QC
  # *
  QC = Select(Area,"QC")
  Cement = Select(EC,["Cement"])
  areas = Select(Area,["PE","YT","NT","NU"])
  SetPCTC(data,Techs,Cement,QC,areas)

  # *
  # * SK Paper use MB
  # *
  SK = Select(Area,["SK"])
  MB = Select(Area,"MB")
  PulpPaperMills = Select(EC,["PulpPaperMills"])
  SetPCTC(data,Techs,PulpPaperMills,MB,SK)


  # *
  # * NB Aluminum uses ON - Jeff Amlin 01/13/21
  # *
  NB = Select(Area,["NB"])
  Aluminum = Select(EC,["Aluminum"])
  SetPCTC(data,Techs,Aluminum,ON,NB)


  # *
  # * TEMPORARY - Iron Ore Mining for NT and NU should be checked in next forecast
  # * NT Iron Ore Mining set to value in Pine
  # *
  IronOreMining = Select(EC,"IronOreMining")
  NT = Select(Area,"NT")
  @. PEM[Enduses, IronOreMining, NT] = 0.000084
  
  # *
  # * Heavy Oil Mining only used oil in NL (Hebron), but since Hebron
  # * is small and starts late, it messes up the Average PCTC which 
  # * impacts the Areas without Heavy Oil Mining - Jeff Amlin 7/21/22
  # *
  HeavyOilMining = Select(EC,"HeavyOilMining")
  NL = Select(Area,"NL")
  Oil = Select(Tech,"Oil")
  for area in Areas
    if area != NL
      @. PCTC[Enduses, Oil, HeavyOilMining, area, Years] = 0.0
      @. PFTC[Enduses, Oil, HeavyOilMining, area, Years] = 0.0
      @. RPCTC[Enduses, Oil, HeavyOilMining, area, Years] = 0.0
      @. RPFTC[Enduses, Oil, HeavyOilMining, area, Years] = 0.0
    end
  end
  
  
  WriteDisk(db,"$Outpt/PCCN", PCCN)
  WriteDisk(db,"$Outpt/PCTC", PCTC)
  WriteDisk(db,"$CalDB/PEM", PEM)
  WriteDisk(db,"$CalDB/POCF", POCF)
  WriteDisk(db,"$Outpt/RPFTC", RPFTC)
  WriteDisk(db,"$Outpt/RPCTC", RPCTC)
  WriteDisk(db,"$Outpt/PFTC", PFTC)
  WriteDisk(db,"$Outpt/PFPN", PFPN)


end

function CalibrationControl(db)
  @info "IInitial_Adjust.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
