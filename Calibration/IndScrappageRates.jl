#
# IndScrappageRates.jl
#
using EnergyModel

module IndScrappageRates

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Vintage::SetArray = ReadDisk(db,"$Input/VintageKey")
  VintageDS::SetArray = ReadDisk(db,"$Input/VintageDS")
  Vintages::Vector{Int} = collect(Select(Vintage))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DActV::VariableArray{5} = ReadDisk(db,"$Input/DActV") # [Enduse,Tech,EC,Area,Vintage] Activity Rate of Equipment by Vintage (1/1)
  DPLV::VariableArray{6} = ReadDisk(db,"$Input/DPLV") # [Enduse,Tech,EC,Area,Vintage,Year] Scrappage Rate of Equipment by Vintage (1/1) 
  PCPL::VariableArray{3} = ReadDisk(db,"MInput/PCPL") # [ECC,Area,Year] Physical Life of Production Capacity (Years)
  xDPL::VariableArray{5} = ReadDisk(db,"$Input/xDPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)

  # Scratch Variables
  DPL::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  KLAMBDA1::VariableArray{1} = zeros(Float32,length(Vintage)) # [Vintage] Weibull Scratch Variable
  KLAMBDA2::VariableArray{1} = zeros(Float32,length(Vintage)) # [Vintage] Weibull Scratch Variable
  Lambda::VariableArray{2} = zeros(Float32,length(Enduse),length(Tech)) # [Enduse,Tech] Weibull Lambda term from NEMS data
  SVRTE::VariableArray{1} = zeros(Float32,length(Vintage)) # [Vintage] Weibull Survival Rate
 # VintagePointer     'Vintage Pointer'
  k::VariableArray{2} = zeros(Float32,length(Enduse),length(Tech)) # [Enduse,Tech] Weibull k term from NEMS data
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,AreaDS,Areas,EC,ECC,ECCDS,ECCs,ECDS,ECs,Enduse) = data
  (;EnduseDS,Enduses,Tech,TechDS,Techs,Vintage,VintageDS,Vintages,Year,YearDS) = data
  (;Years) = data
  (;DActV,DPLV,PCPL,xDPL) = data
  (;DPL,KLAMBDA1,KLAMBDA2,Lambda,SVRTE,k) = data

  #
  # Default value for DActV is 1.0
  #
  @. DActV=1.0
  #
  # Device Lifetime using old Method
  #
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    ecc=Select(ECC,EC[ec])
    DPL[enduse,tech,ec,area,year]=min(xDPL[enduse,tech,ec,area,year],PCPL[ecc,area,year])
  end
  #
  # Initialize Scrappage Rate
  #
  @. DPLV = 0.0
  Loc1=Int(length(Vintage))

  #
  # Default value for DPLV is the current lifespan converted to annual Scrappage rate
  #
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    @finite_math DPLV[enduse,tech,ec,area,vintage,year]=1/DPL[enduse,tech,ec,area,year]
  end
  #
  #########################
  #
  # Data below applies NEMS values from Residential to use as defaults for 
  # Industrial scrappage rates.
  # - Ian 04/02/24
  #
  # Select best match for devices in E2020 compared to NEMS data
  #
  # k Heat
  #
  Heat=Select(Enduse,"Heat")

  Electric=Select(Tech,"Electric")
  Solar=Select(Tech,"Solar")
  HeatPump=Select(Tech,"HeatPump")
  Gas=Select(Tech,"Gas")
  LPG=Select(Tech,"LPG")
  Oil=Select(Tech,"Oil")
  Coal=Select(Tech,"Coal")
  OffRoad=Select(Tech,"OffRoad")
  Biomass=Select(Tech,"Biomass")
  Steam=Select(Tech,"Steam")
 
  k[Heat,Electric]=4.33 #ELEC_RAD
  k[Heat,Solar]=4.33 #ELEC_RAD
  k[Heat,HeatPump]=3.28 #ELEC_HP
  k[Heat,Gas]=5.64 #NG_FA
  k[Heat,LPG]=5.64 #LPG_FA
  k[Heat,Oil]=5.88 # DIST_FA
  k[Heat,Coal]=5.88 # DIST_FA
  k[Heat,OffRoad]=5.88 # DIST_FA
  k[Heat,Biomass]=4.10 # WOOD_HT
  k[Heat,Steam]=4.33 #ELEC_RAD

  #
  # Lambda values adjusted using calculation in 24.04.11 Residential Scrappage Lambda Adjustment.xlxs'
  # 
  #
  # Lambda Heat
  # 
  Lambda[Heat,Electric]=19.3 #ELEC_RAD
  Lambda[Heat,Solar]=19.3 #ELEC_RAD
  Lambda[Heat,HeatPump]=27.0 #ELEC_HP
  Lambda[Heat,Gas]=15.9 #NG_FA
  Lambda[Heat,LPG]=19.0 #LPG_FA
  Lambda[Heat,Oil]=15.9 # DIST_FA
  Lambda[Heat,Coal]=15.9 # DIST_FA
  Lambda[Heat,OffRoad]=15.9 # DIST_FA
  Lambda[Heat,Biomass]=19.3 # WOOD_HT
  Lambda[Heat,Steam]=19.3 #ELEC_RAD

  #
  # k Motors
  #
  Motors=Select(Enduse,"Motors")

  k[Motors,Electric]=4.33 #ELEC_RAD
  k[Motors,HeatPump]=4.33 #ELEC_RAD

  #
  # Lambda Motors
  # 
  Lambda[Motors,Electric]=19.3 #ELEC_RAD
  Lambda[Motors,HeatPump]=19.3 #ELEC_RAD

  #
  # Electric Enduses use Motors values, others use Heat
  #
  OthNSub=Select(Enduse,"OthNSub")
  k[OthNSub,Electric]=k[Motors,Electric]
  Lambda[OthNSub,Electric]=Lambda[Motors,Electric]
  #
  enduses=Select(Enduse,["OthSub","OffRoad","Steam"])
  for enduse in enduses, tech in Techs
    k[enduse,tech]=k[Heat,tech]
    Lambda[enduse,tech]=Lambda[Heat,tech]
  end

  #
  # If 'k' has a value then calculate Weibull curve for the technology.
  # Applies same value across EC, Area, and Year. Equations replicate
  # NEMS Fortran procedure
  #
  # Curve output is a survival curve. Adapted to fit DPLV which is a scrappage rate
  #
  for tech in Techs, enduse in Enduses
    if k[enduse,tech] != 0
      #
      # NEMS seems to treat the current year as Vintage 0, meaning no scrappage ratre
      # Modify pointer to do the same, meaning E2020 vintages will be one slot lower
      # than NEMS values (Base 1 vs Base 0) - Ian 04/10/24
      #
      # Changed VintagePointer to +2 to match smaller Ind Vintage set
      # Started VintagePointer later to get retirements into earlier Vintages
      #
      vintagepointer=5
      for vintage in Vintages
        KLAMBDA1[vintage] = Float32(vintagepointer)/Lambda[enduse,tech]
        KLAMBDA2[vintage] = KLAMBDA1[vintage]^k[enduse,tech]
        SVRTE[vintage] = exp(-KLAMBDA2[vintage])
        vintagepointer=vintagepointer+2
      end
      vintage=1
      for year in Years, area in Areas, ec in ECs
        DPLV[enduse,tech,ec,area,vintage,year] = 0
      end
      vintages=collect(2:Loc1)
      for year in Years, vintage in vintages, area in Areas, ec in ECs
        @finite_math DPLV[enduse,tech,ec,area,vintage,year]=1-(SVRTE[vintage]/SVRTE[vintage-1])
      end
    end
  end
  #
  # Set final vintage scrappage to 1.0 to avoid accumulation issues - Ian 04/03/24
  #
  # vintage=Loc1
  # for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
  #   DPLV[enduse,tech,ec,area,vintage,year] = 1.0
  # end

  # for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
  #   if DPLV[enduse,tech,ec,area,vintage,year] < 1e-8
  #     DPLV[enduse,tech,ec,area,vintage,year] = 0.0
  #   end
  # end

  WriteDisk(db,"$Input/DPLV", DPLV)
  WriteDisk(db,"$Input/DActV", DActV)

end

function CalibrationControl(db)
  @info "IndScrappageRates.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
