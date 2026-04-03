#
# CarbonTaxReferenceEmissions.jl - this file generates the Reference emissions for Carbon Taxes
#
using EnergyModel

module CarbonTaxReferenceEmissions

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)
  UnZeroFr::VariableArray{4} = ReadDisk(db,"EGInput/UnZeroFr") # [Unit,FuelEP,Poll,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes) 
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
  xUnPol::VariableArray{4} = ReadDisk(db,"EGInput/xUnPol") # [Unit,FuelEP,Poll,Year] Pollution in Reference Case (Tonnes) 
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation (Name)  
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  xCgDemand::VariableArray{4} = ReadDisk(db,"SInput/xCgDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Areas,ECC,FuelEPs,Fuels,Nation,Nations,Polls,Units,Years) = data
  (;UnPOCX,UnZeroFr,xUnDmd,xUnPol,FFPMap) = data
  (;UnArea,UnCogen,xCgDemand,xEuDemand,UnNation,UnSector) = data

  for u in Units, fep in FuelEPs, poll in Polls, y in Years
    xUnPol[u,fep,poll,y] = xUnDmd[u,fep,y]*UnPOCX[u,fep,poll,y]*(1-UnZeroFr[u,fep,poll,y])
  end

  utilitygen = Select(ECC,"UtilityGen")
  xEuDemand[Fuels,utilitygen,Areas,Years] .= 0
  for unit in findall(UnCogen .== 0)
    for fuel in Fuels, a in findall(Area .== UnArea[unit]), year in Years
      xEuDemand[fuel,utilitygen,a,year] = 
        xEuDemand[fuel,utilitygen,a,year]+sum(xUnDmd[unit,fep,year]*FFPMap[fep,fuel] for fep in FuelEPs)
    end
  end

  xCgDemand .= 0
  for nation in Nations
    for unit in findall(UnNation .== Nation[nation])
      if UnCogen[unit] .== 1
        for area in findall(Area .== UnArea[unit])
          for ecc in findall(ECC .== UnSector[unit])
            for fuel in Fuels, year in Years
              xCgDemand[fuel,ecc,area,year] = 
                xCgDemand[fuel,ecc,area,year]+sum(xUnDmd[unit,fep,year]*FFPMap[fep,fuel] for fep in FuelEPs)
            end
          end
        end
      end
    end
  end
  
  WriteDisk(db,"EGInput/xUnPol",xUnPol)
  WriteDisk(db,"SInput/xCgDemand",xCgDemand)
  WriteDisk(db,"SInput/xEuDemand",xEuDemand)

end

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  PCovMap::VariableArray{5} = ReadDisk(db,"SInput/PCovMap") # [FuelEP,ECC,PCov,Area,Year] Pollution Coverage Map (1=Mapped)
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vFsPOCX::VariableArray{5} = ReadDisk(db,"VBInput/vFsPOCX") # [Fuel,ECC,Poll,vArea,Year] Feedstock Pollution Coefficient (Tonnes/TBtu)
  vPOCX::VariableArray{5} = ReadDisk(db,"VBInput/vPOCX") # [FuelEP,ECC,Poll,vArea,Year] Pollution Coefficient (Tonnes/TBtu)
  xCgDemand::VariableArray{4} = ReadDisk(db,"SInput/xCgDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (TBtu/Yr)
  xEnFPol::VariableArray{5} = ReadDisk(db,"SInput/xEnFPol") # [FuelEP,ECC,Poll,Area,Year] Energy Related Pollution (Tonnes/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  xFlPol::VariableArray{4} = ReadDisk(db,"SInput/xFlPol") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  xFuPol::VariableArray{4} = ReadDisk(db,"SInput/xFuPol") # [ECC,Poll,Area,Year] Other Fugitive Emissions (Tonnes/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Feedstock Demands (TBtu/Yr)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Process Pollution (Tonnes/Yr)
  xPolTot::VariableArray{5} = ReadDisk(db,"SInput/xPolTot") # [ECC,Poll,PCov,Area,Year] Pollution (Tonnes/Yr)
  xVnPol::VariableArray{4} = ReadDisk(db,"SInput/xVnPol") # [ECC,Poll,Area,Year] Fugitive Venting Emissions (Tonnes/Yr)
  ZeroFr::VariableArray{4} = ReadDisk(db,"SInput/ZeroFr") # [FuelEP,Poll,Area,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes) 

  # Scratch Variables
  CgDemandFEP::VariableArray{4} = zeros(Float32,length(FuelEP),length(ECC),length(Area),length(Year)) # [FuelEP,ECC,Area,Year] Cogeneration Demands (TBtu/Yr)
  EuDemandFEP::VariableArray{4} = zeros(Float32,length(FuelEP),length(ECC),length(Area),length(Year)) # [FuelEP,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  FsPOCXA::VariableArray{5} = zeros(Float32,length(Fuel),length(ECC),length(Poll),length(Area),length(Year)) # [Fuel,ECC,Poll,Area,Year] Feedstock Pollution Coefficient (Tonnes/TBtu)
  POCXA::VariableArray{5} = zeros(Float32,length(FuelEP),length(ECC),length(Poll),length(Area),length(Year)) # [FuelEP,ECC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)
end

function MCalibration(db)
  data = MControl(; db)
  (;Area,Areas,ECC,ECCs,FuelEP,FuelEPs,Fuels,Nation,PCov,PCovs,Poll,Years,vAreas) = data
  (;ANMap,FFPMap,PCovMap,vFsPOCX,vPOCX,xCgDemand,xEnFPol,xEuDemand,xFlPol,xFuPol) = data
  (;xFsDemand,xMEPol,xPolTot,xVnPol,ZeroFr,CgDemandFEP,EuDemandFEP,FsPOCXA,POCXA,vAreaMap) = data

  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])

  for ecc in ECCs, poll in polls, area in Areas, year in Years
    for fep in FuelEPs
      POCXA[fep,ecc,poll,area,year] = sum(vPOCX[fep,ecc,poll,v,year]*vAreaMap[area,v] for v in vAreas)
    end
    for fuel in Fuels
      FsPOCXA[fuel,ecc,poll,area,year] = sum(vFsPOCX[fuel,ecc,poll,v,year]*vAreaMap[area,v] for v in vAreas)
    end
  end

  US = Select(Nation,"US")
  us_areas = findall(ANMap[Areas,US] .== 1)
  AB = Select(Area,"AB")
  ON = Select(Area,"ON")
  for ecc in ECCs, poll in polls, area in us_areas, year in Years
    for fep in FuelEPs
      POCXA[fep,ecc,poll,area,year] = max(POCXA[fep,ecc,poll,AB,year],POCXA[fep,ecc,poll,ON,year])
    end
    for fuel in Fuels
      FsPOCXA[fuel,ecc,poll,area,year] = max(FsPOCXA[fuel,ecc,poll,AB,year],FsPOCXA[fuel,ecc,poll,ON,year])
    end
  end

  coalep = Select(FuelEP,"Coal")
  cokeep = Select(FuelEP,"Coke")
  for ecc in ECCs, poll in polls, area in us_areas, year in Years

    # 
    # Patch since ON and AB Coal have a 0 value for vPOCX for Coal - Jeff Amlin 8/14/23
    # Second patch (0.75) to match California value - Jeff Amlin 8/14/23
    # 
    POCXA[coalep,ecc,poll,area,year] = POCXA[cokeep,ecc,poll,ON,year]*0.75

    # 
    # Patch (0.061) to match Other Chemicals value for California - Jeff Amlin 8/17/23
    # 
    for fuel in Fuels
      FsPOCXA[fuel,ecc,poll,area,year] = FsPOCXA[fuel,ecc,poll,area,year]*0.061
    end
  end

  # 
  # Patch Electric Utility Generation - Jeff Amlin 8/18/23
  #
  utilitygen = Select(ECC,"UtilityGen")
  for fep in FuelEPs, poll in polls, area in Areas, year in Years
    POCXA[fep,utilitygen,poll,area,year] = maximum(POCXA[fep,ecc,poll,area,year] for ecc in ECCs)
    for ecc in ECCs
      EuDemandFEP[fep,ecc,area,year] = sum(xEuDemand[fuel,ecc,area,year]*FFPMap[fep,fuel] for fuel in Fuels)
      xEnFPol[fep,ecc,poll,area,year] = 
        EuDemandFEP[fep,ecc,area,year]*POCXA[fep,ecc,poll,area,year]*(1-ZeroFr[fep,poll,area,year]) 
    end
  end

  pcovs = Select(PCov,["Energy","Oil","NaturalGas"])
  for ecc in ECCs, poll in polls, pcov in pcovs, area in Areas, year in Years
    xPolTot[ecc,poll,pcov,area,year] = 
      sum(xEnFPol[fep,ecc,poll,area,year]*PCovMap[fep,ecc,pcov,area,year] for fep in FuelEPs)
  end

  for fep in FuelEPs, ecc in ECCs, area in Areas, year in Years
    CgDemandFEP[fep,ecc,area,year] = sum(xCgDemand[fuel,ecc,area,year]*FFPMap[fep,fuel] for fuel in Fuels)
    for poll in polls
      xEnFPol[fep,ecc,poll,area,year] = xEnFPol[fep,ecc,poll,area,year]+
        CgDemandFEP[fep,ecc,area,year]*POCXA[fep,ecc,poll,area,year]*(1-ZeroFr[fep,poll,area,year])
    end
  end

  cogeneration = Select(PCov,"Cogeneration")
  noncombustion = Select(PCov,"NonCombustion")
  process = Select(PCov,"Process")
  venting = Select(PCov,"Venting")
  flaring = Select(PCov,"Flaring")
  for ecc in ECCs, poll in polls, area in Areas, year in Years

    xPolTot[ecc,poll,cogeneration,area,year] = sum(CgDemandFEP[fep,ecc,area,year]*
      POCXA[fep,ecc,poll,area,year]*(1-ZeroFr[fep,poll,area,year])*PCovMap[fep,ecc,cogeneration,area,year] for fep in FuelEPs)

    xPolTot[ecc,poll,noncombustion,area,year] = sum(xFsDemand[fuel,ecc,area,year]*FsPOCXA[fuel,ecc,poll,area,year] for fuel in Fuels)

    xPolTot[ecc,poll,process,area,year] = xMEPol[ecc,poll,area,year]+xFuPol[ecc,poll,area,year]

    xPolTot[ecc,poll,venting,area,year] = xVnPol[ecc,poll,area,year]

    xPolTot[ecc,poll,flaring,area,year] = xFlPol[ecc,poll,area,year]

  end

  for ecc in ECCs, poll in polls, pcov in PCovs, area in Areas, year in Future:Final
    if xPolTot[ecc,poll,pcov,area,year] == 0
      xPolTot[ecc,poll,pcov,area,year] = xPolTot[ecc,poll,pcov,area,year-1]
    end
  end

  WriteDisk(db,"SInput/xEnFPol",xEnFPol)
  WriteDisk(db,"SInput/xPolTot",xPolTot)


end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmdFuel::VariableArray{6} = ReadDisk(db,"$Input/DmdFuel") # [Enduse,Fuel,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  FsDmdFuel::VariableArray{5} = ReadDisk(db,"$Input/FsDmdFuel") # [Fuel,Tech,EC,Area,Year] Historical Feedstock Demands by Fuel
  FsPOCX::VariableArray{6} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Pollution Coefficient (Tonnes/TBtu)
  PCovMap::VariableArray{5} = ReadDisk(db,"SInput/PCovMap") # [FuelEP,ECC,PCov,Area,Year] Pollution Coverage Map (1=Mapped)
  POCX::VariableArray{7} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Enduse Energy Pollution Coefficients (Tonnes/TBtu)
  xEnFPol::VariableArray{5} = ReadDisk(db,"SInput/xEnFPol") # [FuelEP,ECC,Poll,Area,Year] Energy Related Pollution (Tonnes/Yr)
  xPolTot::VariableArray{5} = ReadDisk(db,"SInput/xPolTot") # [ECC,Poll,PCov,Area,Year] Pollution (Tonnes/Yr)
  xTrMEPol::VariableArray{5} = ReadDisk(db,"$Input/xTrMEPol") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)
  ZeroFr::VariableArray{4} = ReadDisk(db,"SInput/ZeroFr") # [FuelEP,Poll,Area,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes) 
end

function TCalibration(db)
  data = TControl(; db)
  (;Areas,EC,ECC,ECs,Enduses,Fuel,FuelEP,FuelEPs,Fuels,PCov,Poll,Techs,Years) = data
  (;DmdFuel,FsDmdFuel,FsPOCX,PCovMap,POCX,xEnFPol,xPolTot,xTrMEPol,ZeroFr) = data

  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  noncombustion = Select(PCov,"NonCombustion")
  process = Select(PCov,"Process")
  for area in Areas, ec in ECs, poll in polls, year in Years
    for ecc in findall(ECC .== EC[ec])
      for fep in FuelEPs
        for fuel in findall(Fuel .== FuelEP[fep])
          xEnFPol[fep,ecc,poll,area,year] = 
            sum(DmdFuel[eu,fuel,tech,ec,area,year]*POCX[eu,fep,tech,ec,poll,area,year] for eu in Enduses, tech in Techs)*
            (1-ZeroFr[fep,poll,area,year])
        end
      end

      for pcov in Select(PCov,["Energy","Oil","NaturalGas"])
        xPolTot[ecc,poll,pcov,area,year] = 
          sum(xEnFPol[fep,ecc,poll,area,year]*PCovMap[fep,ecc,pcov,area,year] for fep in FuelEPs)
      end

      xPolTot[ecc,poll,noncombustion,area,year] = 
        sum(FsDmdFuel[fuel,tech,ec,area,year]*FsPOCX[fuel,tech,ec,poll,area,year] for fuel in Fuels, tech in Techs)

      xPolTot[ecc,poll,process,area,year] = sum(xTrMEPol[tech,ec,poll,area,year] for tech in Techs)
 
    end
  end

  WriteDisk(db,"SInput/xEnFPol",xEnFPol)
  WriteDisk(db,"SInput/xPolTot",xPolTot)

end

function CalibrationControl(db)
  @info "CarbonTaxReferenceEmissions.jl - CalibrationControl"

  ECalibration(db)
  MCalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
