#
# E2020GovernmentSpending.jl
#
using EnergyModel

module E2020GovernmentSpending

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
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 

  GExp_PolE::VariableArray{2} = ReadDisk(db,"KOutput/GExp_PolE") # [AreaTOM,Year] Government expenditure, total, LCU [C$] (Real $M)
  GRExp::VariableArray{4} = ReadDisk(db,"SOutput/GRExp") # [ECC,Poll,Area,Year] Reduction Government Expenses (M$/Yr)
  GRExpRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/GRExp") # [ECC,Poll,Area,Year] Reduction Government Expenses (M$/Yr)
  GRExpRun1::VariableArray{4} = ReadDisk(Run1NameDB,"SOutput/GRExp") # [ECC,Poll,Area,Year] Reduction Government Expenses (M$/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  GExp_PolArea::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Government expenditure, total, LCU [C$] (Real $M)
end

function ReadDatabases(data)
  (; BaseSw,RefSwitch,Run1Name,SceName) = data
  (; GRExp,GRExpRef,GRExpRun1) = data

  if (BaseSw == 0) && (RefSwitch == 0)
    # GRExpRef from Reference Case
    if Run1Name != SceName[1]
      # GRExpRun1 from Run1
    else
      # GRExpRun1 from default database
      @. RInvRun1 = GRExp
    end
  else
    # variables from default database
    @. GRExpRef = GRExp
    @. GRExpRun1 = GRExp
  end
end
  
function GovernmentExpenses(db)
  data = MControl(; db)
  (;Area,AreaTOM,AreaTOMs,Areas,ECC,ECCs,Nation,Poll) = data
  (;PollDS,Polls,Year,Years) = data
  (;ANMap,GExp_PolE,GRExpRef,GRExpRun1,MapAreaTOM,xInflation) = data
  (;GExp_PolArea) = data

  CN=Select(Nation,"CN")
  US=Select(Nation,"US")
  areas_cn=findall(ANMap[:,CN] .== 1)
  areas_us=findall(ANMap[:,US] .== 1)
  areas=union(areas_cn,areas_us)

  ReadDatabases(data)

  #
  # GExp_Pol is the change in government spending due to policy
  # changes (GRExpRun1-GRExpRef). Is this right (matches PInv/DInv)? Or do we just want the total passed each iteration?
  # 9/14/20 - Mike Kleiman wants changes from the base run. R.Levesque
  #
  for year in Years, area in areas
    GExp_PolArea[area,year]=sum((GRExpRun1[ecc,poll,area,year]-GRExpRef[ecc,poll,area,year])/
        xInflation[area,year]*xInflation[area,Yr(2017)] for ecc in ECCs, poll in Polls)
  end
  for year in Years, areatom in AreaTOMs
    GExp_PolE[areatom,year]=sum(GExp_PolArea[area,year]*MapAreaTOM[area,areatom] for area in areas)
  end

  WriteDisk(db,"KOutput/GExp_PolE",GExp_PolE)
end

function Control(db)
  @info "E2020GovernmentSpending.jl - Control"
  GovernmentExpenses(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
