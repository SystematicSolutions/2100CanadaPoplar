#
# E2020PermitExpenditures.jl
#
using EnergyModel

module E2020PermitExpenditures

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  EPermit::VariableArray{3} = ReadDisk(db,"KOutput/EPermit") # [ECCTOM,AreaTOM,Year] Cost of Emissions Permits ($M/Yr)
  EPermitE::VariableArray{3} = ReadDisk(db,"KOutput/EPermitE") # [ECCTOM,AreaTOM,Year] Cost of Emissions Permits ($M/Yr)
  EPermitHHe::VariableArray{2} = ReadDisk(db,"KOutput/EPermitHHe") # [AreaTOM,Year] Household Cost of Emissions Permits ($M/Yr)
  EUPExp::VariableArray{2} = ReadDisk(db,"SOutput/EUPExp") #[Area,Year]  Electric Utility Emission Charges (M$/Yr)
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map from ECC to TOM
  PExp::VariableArray{4} = ReadDisk(db,"SOutput/PExp") # [ECC,Poll,Area,Year] Permits Expenditures (M$/Yr)
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM ($/$)

  # Scratch Variables
  NonTransitFrac::VariableArray{1} = zeros(Float32,length(AreaTOM)) # [AreaTOM] Fraction of LDV/LDT Transportation by Households Rather Than Transit
end

function InitializeExpenditures(data)
  (; db) = data
  (; Area,Areas,AreaTOM,AreaTOMs) = data
  (; ECCTOMs,Years) = data
  (; EPermitE) = data
  
  for year in Years, areatom in AreaTOMs, ecctom in ECCTOMs
    EPermitE[ecctom,areatom,year] = 0
  end
end

function ResPermitExpenditures(data)
  (;db) = data
  (; Area,Areas,AreaTOM,AreaTOMs,ECC,Nation,Polls,Years) = data
  (; MapAreaTOM,MapAreaTOMNation,EPermitHHe,NonTransitFrac,PExp) = data
  
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential"])
  for areatom in AreaTOMs
    area = Select(Area,AreaTOM[areatom])
    for year in Years
      EPermitHHe[areatom,year] = sum(PExp[ecc,poll,area,year] for poll in Polls, ecc in eccs)
    end
  end

  #
  # Residential permit expenditures from household transportation
  # Household fractions of LDV/LDT transportation. 
  # Source: "kmldvhh_sh.xlsx", M.Kleiman 
  # Increased by small amount (0.01) to eliminate bus passengers 03/01/2021 R.Levesque
  #
  NonTransitFrac[Select(AreaTOM,"AB")] = 0.955+0.01
  NonTransitFrac[Select(AreaTOM,"BC")] = 0.954+0.01
  NonTransitFrac[Select(AreaTOM,"MB")] = 0.968+0.01
  NonTransitFrac[Select(AreaTOM,"NB")] = 0.954+0.01
  NonTransitFrac[Select(AreaTOM,"NL")] = 0.966+0.01
  NonTransitFrac[Select(AreaTOM,"NS")] = 0.941+0.01
  NonTransitFrac[Select(AreaTOM,"ON")] = 0.958+0.01
  NonTransitFrac[Select(AreaTOM,"QC")] = 0.952+0.01
  NonTransitFrac[Select(AreaTOM,"SK")] = 0.964+0.01
  NonTransitFrac[Select(AreaTOM,"PE")] = 0.947+0.01
  NonTransitFrac[Select(AreaTOM,"NU")] = 0.995+0.001
  NonTransitFrac[Select(AreaTOM,"YT")] = 0.959+0.01
  NonTransitFrac[Select(AreaTOM,"NT")] = 0.957+0.01

  #
  # Set US non-transit fractions equal to Ontario
  #
  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  ON = Select(AreaTOM,"ON")
  for areatom in areatoms
    NonTransitFrac[areatom] = NonTransitFrac[ON]
  end

  ecc = Select(ECC,"Passenger")
  for year in Years, areatom in AreaTOMs
    EPermitHHe[areatom,year] = EPermitHHe[areatom,year] + 
      sum(PExp[ecc,poll,area,year]*NonTransitFrac[areatom]*
        MapAreaTOM[area,areatom] for area in Areas, poll in Polls)
  end

  WriteDisk(db,"KOutput/EPermitHHe",EPermitHHe)
end

function PermitExpenditures(data)
  (; db) = data
  (; Area,Areas,AreaTOM,AreaTOMs,ECC,ECCs,Nation) = data
  (; ECCTOM,ECCTOMs,Polls,Years) = data
  (; ANMap,MapAreaTOM,MapECCtoTOM,EPermit,EPermitE) = data
  (; EPermitHHe,EUPExp,MapAreaTOMNation,NonTransitFrac,PExp,SplitECCtoTOM) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas_cn = findall(ANMap[Areas,CN] .== 1.0)
  areas_us = findall(ANMap[Areas,US] .== 1.0)
  areas = union(areas_cn,areas_us)
  
  #
  # After this calculation, overwrite UtilityGen and transportation
  # which are calculated differently. 10/14/25 R.Levesque
  #
  for area in areas
    areatom = Select(AreaTOM,Area[area])
    for ecctom in ECCTOMs
      eccs = findall(MapECCtoTOM[ECCs,ecctom] .== 1.0)
      if !isempty(eccs)
        for year in Years
          EPermitE[ecctom,areatom,year] = 
            sum(sum(PExp[ecc,poll,area,year] for poll in Polls)*
            SplitECCtoTOM[ecc,ecctom,areatom,year] for ecc in eccs)
        end
      end
    end
  end

  CoalMining = Select(ECC,"CoalMining")
  CoalMiningTOM = Select(ECCTOM,"CoalMining")
  AB = Select(Area,"AB")
  ABTOM = Select(AreaTOM,"AB")
  loc1 = sum(PExp[CoalMining,poll,AB,Yr(2024)] for poll in Polls)
  @info("PExp[CoalMining,poll,AB,2024] = ",loc1)
  loc1 = EPermitE[CoalMiningTOM,ABTOM,Yr(2024)]
  @info("EPermitE[CoalMining,AB,2024] = ",loc1)
  @info("SplitECCtoTOM[CoalMining,CoalMiningTOM,AB,Yr(2024)] = ",SplitECCtoTOM[CoalMining,CoalMiningTOM,ABTOM,Yr(2024)])
  
  #
  # UtilityGen based on EUPExp
  #
  ecctom = Select(ECCTOM,"UtilityGen")
  ecc = Select(ECC,"UtilityGen")
  for area in areas
    areatom = Select(AreaTOM,Area[area])
    for year in Years
      EPermitE[ecctom,areatom,year] = EUPExp[area,year]
    end
  end

  #
  # Transportation includes just the "Transit" portion
  #
  ecctoms = Select(ECCTOM,["Transit","Truck","Air","Rail","Water"])
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    area = Select(Area,Area[areatom])
    EPermitE[ecctom,areatom,year] = sum(PExp[ecc,poll,area,year]*
      MapECCtoTOM[ecc,ecctom]*(1-NonTransitFrac[areatom]) for ecc in ECCs, poll in Polls)
    
    if isnan(EPermitE[ecctom,areatom,year]) == true
      EPermitE[ecctom,areatom,year] = 0
    end        
  end

  #
  # Patch NB NonferrousMetal 7/31/25 - Ian
  #
  ecctom = Select(ECCTOM,"NonferrousMetal")
  areatom = Select(AreaTOM,"NB")
  for year in Years
    EPermitE[ecctom,areatom,year] = EPermit[ecctom,areatom,year]
  end

  WriteDisk(db,"KOutput/EPermitE",EPermitE)

end

function CalcPermitExpenditures(db)
  data = MControl(; db)

  InitializeExpenditures(data)
  ResPermitExpenditures(data)
  PermitExpenditures(data)
end

function Control(db)
  @info "E2020PermitExpenditures.jl - Control"
  CalcPermitExpenditures(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
