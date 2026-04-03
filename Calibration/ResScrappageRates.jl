#
# ResScrappageRates.jl
#
using EnergyModel

module ResScrappageRates

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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

function RCalibration(db)
  data = RControl(; db)
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
  # Select best match for devices in E2020 compared to NEMS data
  #
  # k Space Heat
  #
  Heat=Select(Enduse,"Heat")

  Electric=Select(Tech,"Electric")
  HeatPump=Select(Tech,"HeatPump")
  Gas=Select(Tech,"Gas")
  LPG=Select(Tech,"LPG")
  Oil=Select(Tech,"Oil")
  Biomass=Select(Tech,"Biomass")
  Geothermal=Select(Tech,"Geothermal")
  DualHPump=Select(Tech,"DualHPump")
 
  k[Heat,Electric]=4.33 #ELEC_RAD
  k[Heat,HeatPump]=3.28 #ELEC_HP
  k[Heat,Gas]=5.64 #NG_FA
  # k[Heat,Gas]=7.21 #NG_RAD
  # k[Heat,Oil]=5.88 #KERO_FA
  k[Heat,LPG]=5.64 #LPG_FA
  k[Heat,Oil]=5.88 # DIST_FA
  # k[Heat,Oil]=6.64 # DIST_RAD
  k[Heat,Biomass]=4.10 # WOOD_HT
  k[Heat,Geothermal]=3.22 # GEO_HP
  k[Heat,DualHPump]=7.21 # NG_HP

  #
  # k AC
  #
  AC=Select(Enduse,"AC")

  # k[AC,Electric]=3.92 #ROOM_AIR
  k[AC,Electric]=3.77 #CENT_AIR
  k[AC,HeatPump]=3.28 #ELEC_HP
  k[AC,Geothermal]=3.22 #GEO_HP
  k[AC,DualHPump]=7.21 #NG_HP

  #
  # k Water Heating
  # 
  HW=Select(Enduse,"HW")
  Solar=Select(Tech,"Solar")

  k[HW,Gas]=2.68 #NG_WH
  k[HW,Electric]=2.68 #ELEC_WH
  k[HW,Oil]=2.68 #DIST_WH
  k[HW,LPG]=2.68 #LPG_WH
  k[HW,Solar]=4.33 #SOLAR_WH

  #
  # k OthSub
  # 
  OthSub=Select(Enduse,"OthSub")

  # k[OthSub,--]=3.00 #CL_WASH
  # k[OthSub,--]=4.65 #DS_WASH
  k[OthSub,Gas]=5.77 #NG_STV
  k[OthSub,LPG]=5.77 #LPG_STV
  k[OthSub,Electric]=4.32 #ELEC_STV
  # k[OthSub,Gas]=3.75 #NG_DRY
  # k[OthSub,Electric]=3.75 #ELEC_DRY

  #
  # k Refrig
  # 
  Refrig=Select(Enduse,"Refrig")
  k[Refrig,Electric]=4.91 #REFR
  # k[Refrig,Electric]=6.35 #FREZ

  #
  # Lambda values adjusted using calculation in 24.04.11 Residential Scrappage Lambda Adjustment.xlxs'
  # 
  #
  # Lambda Space Heat
  # 
  Lambda[Heat,Electric]=24.7 #ELEC_RAD
  Lambda[Heat,HeatPump]=15.1 #ELEC_HP
  Lambda[Heat,Gas]=19.0 #NG_FA
  # Lambda[Heat,Gas]=26.30 #NG_RAD
  # Lambda[Heat,Oil]=28.20 #KERO_FA
  Lambda[Heat,LPG]=24.3 #LPG_FA
  Lambda[Heat,Oil]=24.4 # DIST_FA
  # Lambda[Heat,Oil]=24.30 # DIST_RAD
  Lambda[Heat,Biomass]=24.7 # WOOD_HT
  Lambda[Heat,Geothermal]=15.1 # GEO_HP
  Lambda[Heat,DualHPump]=14.5 # NG_HP

  #
  # Lambda AC
  # 
  # Lambda[AC,Electric]=10.40 #ROOM_AIR
  Lambda[AC,Electric]=15.1 #CENT_AIR
  Lambda[AC,HeatPump]=15.1 #ELEC_HP
  Lambda[AC,Geothermal]=15.1 #GEO_HP
  Lambda[AC,DualHPump]=14.5 #NG_HP
  
  #
  # Lambda Water Heating
  # 
  Lambda[HW,Gas]=9.8 #NG_WH
  Lambda[HW,Electric]=14.1 #ELEC_WH
  Lambda[HW,Oil]=14.1 #DIST_WH
  Lambda[HW,LPG]=14.1 #LPG_WH
  Lambda[HW,Solar]=14.0 #SOLAR_WH

  #
  # Lambda OthSub
  #
  # Lambda[OthSub,--]=13.00 #CL_WASH
  # Lambda[OthSub,--]=15.70 #DS_WASH
  Lambda[OthSub,Gas]=13.5 #NG_STV
  Lambda[OthSub,LPG]=13.5 #LPG_STV
  Lambda[OthSub,Electric]=13.8 #ELEC_STV
  # Lambda[OthSub,Gas]=14.30 #NG_DRY
  # Lambda[OthSub,Electric]=14.30 #ELEC_DRY

  #
  # Lambda Refrig
  #
  Lambda[Refrig,Electric]=18.0 #REFR
  # Lambda[Refrig,Electric]=23.30 #FREZ

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
      for vintage in Vintages
        KLAMBDA1[vintage] = Float32(vintage-1)/Lambda[enduse,tech]
        KLAMBDA2[vintage] = KLAMBDA1[vintage]^k[enduse,tech]
        SVRTE[vintage] = exp(-KLAMBDA2[vintage])
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
  vintage=Loc1
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year] = 1.0
  end

  WriteDisk(db,"$Input/DPLV", DPLV)
  WriteDisk(db,"$Input/DActV", DActV)

end

function CalibrationControl(db)
  @info "ResScrappageRates.jl - CalibrationControl"

  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
