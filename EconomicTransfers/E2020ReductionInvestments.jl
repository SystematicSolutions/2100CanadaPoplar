#
# E2020ReductionInvestments.jl
#
using EnergyModel

module E2020ReductionInvestments

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Run1NameDB::String = ReadDisk(db,"MainDB/Run1NameDB") # Economic Model Investments Case Name
  Run1Name::String = ReadDisk(db,"MainDB/Run1Name") # Economic Model Investments Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  IF_OthE::VariableArray{3} = ReadDisk(db,"KOutput/IF_OthE") # [ECCTOM,AreaTOM,Year] Non-productive Investments in E2020 (2017 $M/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 
  RInv::VariableArray{3} = ReadDisk(db,"SOutput/RInv") # [ECC,Area,Year] Emission Reduction Investments (M$/Yr)
  RInvRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/RInv") # [ECC,Area,Year] Emission Reduction Investments (M$/Yr)
  RInvRun1::VariableArray{3} = ReadDisk(Run1NameDB,"SOutput/RInv") # [ECC,Area,Year] Emission Reduction Investments (M$/Yr)
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC to ECCTOM ($/$)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  IF_OthArea::VariableArray{3} = zeros(Float32,length(ECCTOM),length(Area),length(Year)) # [ECCTOM,Area,Year] Non-productive Investments in E2020 (2017 $M/Yr)
end

function ReadDatabases(data)
  (;BaseSw,RefSwitch,Run1Name,SceName) = data
  (;RInv,RInvRef,RInvRun1) = data

  if (BaseSw == 0) && (RefSwitch == 0)
    # RInvRef from Reference Case
    if Run1Name != SceName[1]
      # RInvRun1 from Run1
    else
      # RInvRun1 from default database
      @. RInvRun1 = RInv
    end
  else
    # variables from default database
    @. RInvRef = RInv
    @. RInvRun1 = RInv
  end

end

function ReductionInvestments(data,areas,areatoms)
  (; db) = data
  (; Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,ECC,ECCDS) = data
  (; ECCTOM,ECCTOMs) = data
  (; ECCs,Year,YearDS,Years) = data
  (; IF_OthArea,IF_OthE,IF_OthE,MapAreaTOM) = data
  (; RInvRef,RInvRun1,SplitECCtoTOM,TOMBaseYear,xInflation) = data

  #
  # IF_OthE is the change in Reduction Investments due to policy
  # changes (RInvRun1-RInvRef).
  #
  areatom=first(areatoms)
  for year in Years, area in areas, ecctom in ECCTOMs
    IF_OthArea[ecctom,area,year]=sum((RInvRun1[ecc,area,year]-RInvRef[ecc,area,year])/
      xInflation[area,year]*xInflation[area,TOMBaseYear]*
      SplitECCtoTOM[ecc,ecctom,areatom,year] for ecc in ECCs)
  end
  for year in Years, areatom in areatoms, ecctom in ECCTOMs
    IF_OthE[ecctom,areatom,year]=sum(IF_OthArea[ecctom,area,year]*
      MapAreaTOM[area,areatom] for area in areas)
  end
  WriteDisk(db,"KOutput/IF_OthE",IF_OthE)

end

function CalcReductionInvestments(db)
  data = MControl(; db)
  (; Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,ECC,ECCDS) = data
  (; ECCTOM,ECCTOMs,ECCs,Nation,Year,YearDS,Years) = data
  (; ANMap,IF_OthE,MapAreaTOM,MapAreaTOMNation) = data
  (; RInvRef,RInvRun1,SplitECCtoTOM,xInflation) = data
  (; IF_OthArea) = data

  ReadDatabases(data)

  CN=Select(Nation,"CN")
  areas=findall(ANMap[:,CN] .== 1)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1)
  ReductionInvestments(data,areas,areatoms)
  
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  ReductionInvestments(data,areas,areatoms)

end

function Control(db)
  @info "E2020ReductionInvestments.jl - Control"
  CalcReductionInvestments(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
