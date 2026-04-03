#
# TransScrappageRates.jl
#
using EnergyModel

module TransScrappageRates

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

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
  DActVHDV::VariableArray{1} = zeros(Float32,length(Vintage)) # [Vintage] DActV input for HDV Vehicles (1/1)
  DPL::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  xDPLVintage::VariableArray{2} = zeros(Float32,length(Vintage),length(Tech)) # [Tech,Vintage] Input for AEO Data
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,AreaDS,Areas,EC,ECC,ECCDS,ECCs,ECDS,ECs,Enduse) = data
  (;EnduseDS,Enduses,Tech,TechDS,Techs,Vintage,VintageDS,Vintages,Year,YearDS) = data
  (;Years) = data
  (;DActV,DPLV,PCPL,xDPL) = data
  (;DActVHDV,DPL,xDPLVintage) = data

  #
  # Default value for DActV is 1.0
  #
  @. DActV=1.0
  #
  # Estimates from AEO data - Jeff Amlin 5/21/23
  #
  techs=Select(Tech,(from="LDVGasoline",to="LDVFuelCell"))
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year]=11.0
  end
  #
  # Light Trucks
  #
  techs=Select(Tech,(from="LDTGasoline",to="LDTFuelCell"))
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year]=14.5
  end

  WriteDisk(db,"$Input/xDPL", xDPL)

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
  #
  # Default value for DPLV is the current lifespan converted to annual Scrappage rate
  # These values are used for all the technologies for which we do not have
  # values for the scrappage rates by Vintage.
  #
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    @finite_math DPLV[enduse,tech,ec,area,vintage,year]=1/DPL[enduse,tech,ec,area,year]
  end

  #
  ########################
  #
  # Passenger LDV and LDT
  # MOVES model data extracted by Matthew Lewis at ECCC, sent 24/02/23
  #
  techs=Select(Tech,["LDVGasoline","LDTGasoline"])
  #                       LDV     LDT
  xDPLVintage[ 1,techs]=[ 0.0     0.0   ]
  xDPLVintage[ 2,techs]=[ 0.003   0.009 ]
  xDPLVintage[ 3,techs]=[ 0.003   0.009 ]
  xDPLVintage[ 4,techs]=[ 0.007   0.014 ]
  xDPLVintage[ 5,techs]=[ 0.01    0.019 ]
  xDPLVintage[ 6,techs]=[ 0.014   0.024 ]
  xDPLVintage[ 7,techs]=[ 0.019   0.03  ]
  xDPLVintage[ 8,techs]=[ 0.024   0.036 ]
  xDPLVintage[ 9,techs]=[ 0.029   0.042 ]
  xDPLVintage[10,techs]=[ 0.035   0.048 ]
  xDPLVintage[11,techs]=[ 0.041   0.054 ]
  xDPLVintage[12,techs]=[ 0.047   0.06  ]
  xDPLVintage[13,techs]=[ 0.088   0.065 ]
  xDPLVintage[14,techs]=[ 0.146   0.071 ]
  xDPLVintage[15,techs]=[ 0.168   0.087 ]
  xDPLVintage[16,techs]=[ 0.187   0.092 ]
  xDPLVintage[17,techs]=[ 0.201   0.097 ]
  xDPLVintage[18,techs]=[ 0.213   0.102 ]
  xDPLVintage[19,techs]=[ 0.221   0.106 ]
  xDPLVintage[20,techs]=[ 0.228   0.109 ]
  xDPLVintage[21,techs]=[ 0.233   0.112 ]
  xDPLVintage[22,techs]=[ 0.237   0.115 ]
  xDPLVintage[23,techs]=[ 0.24    0.117 ]
  xDPLVintage[24,techs]=[ 0.243   0.12  ]
  xDPLVintage[25,techs]=[ 0.243   0.121 ]
  xDPLVintage[26,techs]=[ 0.246   0.123 ]
  xDPLVintage[27,techs]=[ 0.246   0.125 ]
  xDPLVintage[28,techs]=[ 0.247   0.125 ]
  xDPLVintage[29,techs]=[ 0.248   0.127 ]
  xDPLVintage[30,techs]=[ 0.248   0.128 ]
  xDPLVintage[31,techs]=[ 0.7     0.7   ]
  xDPLVintage[32,techs]=[ 1.0     1.0   ]
  xDPLVintage[33,techs]=[ 1.0     1.0   ]
  xDPLVintage[34,techs]=[ 1.0     1.0   ]

  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=xDPLVintage[vintage,tech]
  end

  #
  # Map to Other Vehicle Types (Technologies) 
  #
  techs1=Select(Tech,(from="LDVDiesel",to="LDVFuelCell"))
  techs2=Select(Tech,"Motorcycle")
  techs=union(techs1,techs2)
  LDVGasoline=Select(Tech,"LDVGasoline")
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=DPLV[enduse,LDVGasoline,ec,area,vintage,year]
  end

  techs=Select(Tech,(from="LDTDiesel",to="LDTFuelCell"))
  LDTGasoline=Select(Tech,"LDTGasoline")
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=DPLV[enduse,LDTGasoline,ec,area,vintage,year]
  end

  #
  ########################
  #
  # Freight HDV
  # MOVES model data extracted by Batey Brock at ECCC, sent 24/04/17
  #
  # vintages=collect(1:31)
  techs=Select(Tech,["HDV2B3Diesel","HDV45Diesel","HDV8Diesel","HDV2B3Gasoline","HDV45Gasoline","HDV8Gasoline"])
  #                       Diesel  Diesel  Diesel Gasoline Gasoline Gasoline
  #                       Class3  Class46 Class78 Class3  Class46 Class78
  xDPLVintage[ 1,techs]=[ 0.0000  0.0000  0.0000  0.0000  0.0000  0.0000 ]
  xDPLVintage[ 2,techs]=[ 0.0000  0.0000  0.0000  0.0000  0.0000  0.0000 ]
  xDPLVintage[ 3,techs]=[ 0.0000  0.0000  0.0000  0.0000  0.0000  0.0000 ]
  xDPLVintage[ 4,techs]=[ 0.0000  0.0000  0.0000  0.0000  0.0000  0.0000 ]
  xDPLVintage[ 5,techs]=[ 0.0100  0.0100  0.0100  0.0100  0.0100  0.0100 ]
  xDPLVintage[ 6,techs]=[ 0.0198  0.0198  0.0198  0.0198  0.0198  0.0198 ]
  xDPLVintage[ 7,techs]=[ 0.0194  0.0194  0.0194  0.0194  0.0194  0.0194 ]
  xDPLVintage[ 8,techs]=[ 0.0285  0.0285  0.0285  0.0285  0.0285  0.0285 ]
  xDPLVintage[ 9,techs]=[ 0.0277  0.0277  0.0277  0.0277  0.0277  0.0277 ]
  xDPLVintage[10,techs]=[ 0.0268  0.0268  0.0268  0.0268  0.0268  0.0268 ]
  xDPLVintage[11,techs]=[ 0.0347  0.0347  0.0347  0.0347  0.0347  0.0347 ]
  xDPLVintage[12,techs]=[ 0.0333  0.0333  0.0333  0.0333  0.0333  0.0333 ]
  xDPLVintage[13,techs]=[ 0.0400  0.0400  0.0400  0.0400  0.0400  0.0400 ]
  xDPLVintage[14,techs]=[ 0.0380  0.0380  0.0380  0.0380  0.0380  0.0380 ]
  xDPLVintage[15,techs]=[ 0.0361  0.0361  0.0361  0.0361  0.0361  0.0361 ]
  xDPLVintage[16,techs]=[ 0.0411  0.0411  0.0411  0.0411  0.0411  0.0411 ]
  xDPLVintage[17,techs]=[ 0.0387  0.0387  0.0387  0.0387  0.0387  0.0387 ]
  xDPLVintage[18,techs]=[ 0.0424  0.0424  0.0424  0.0424  0.0424  0.0424 ]
  xDPLVintage[19,techs]=[ 0.0394  0.0394  0.0394  0.0394  0.0394  0.0394 ]
  xDPLVintage[20,techs]=[ 0.0419  0.0419  0.0419  0.0419  0.0419  0.0419 ]
  xDPLVintage[21,techs]=[ 0.0386  0.0386  0.0386  0.0386  0.0386  0.0386 ]
  xDPLVintage[22,techs]=[ 0.0355  0.0355  0.0355  0.0355  0.0355  0.0355 ]
  xDPLVintage[23,techs]=[ 0.0367  0.0367  0.0367  0.0367  0.0367  0.0367 ]
  xDPLVintage[24,techs]=[ 0.0334  0.0334  0.0334  0.0334  0.0334  0.0334 ]
  xDPLVintage[25,techs]=[ 0.0304  0.0304  0.0304  0.0304  0.0304  0.0304 ]
  xDPLVintage[26,techs]=[ 0.0307  0.0307  0.0307  0.0307  0.0307  0.0307 ]
  xDPLVintage[27,techs]=[ 0.0277  0.0277  0.0277  0.0277  0.0277  0.0277 ]
  xDPLVintage[28,techs]=[ 0.0249  0.0249  0.0249  0.0249  0.0249  0.0249 ]
  xDPLVintage[29,techs]=[ 0.0247  0.0247  0.0247  0.0247  0.0247  0.0247 ]
  xDPLVintage[30,techs]=[ 0.0219  0.0219  0.0219  0.0219  0.0219  0.0219 ]
  xDPLVintage[31,techs]=[ 0.1243  0.1243  0.1243  0.1243  0.1243  0.1243 ]
  xDPLVintage[32,techs]=[ 0.1243  0.1243  0.1243  0.1243  0.1243  0.1243 ]
  xDPLVintage[33,techs]=[ 0.1243  0.1243  0.1243  0.1243  0.1243  0.1243 ]
  xDPLVintage[34,techs]=[ 0.1243  0.1243  0.1243  0.1243  0.1243  0.1243 ]


  #
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=xDPLVintage[vintage,tech]
  end

  #
  # HDV Class67 Uses Average of NEMS Class46 and NEMS Class78
  #
  HDV67Diesel=Select(Tech,"HDV67Diesel")
  HDV45Diesel=Select(Tech,"HDV45Diesel")
  HDV8Diesel=Select(Tech,"HDV8Diesel")
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, enduse in Enduses
    DPLV[enduse,HDV67Diesel,ec,area,vintage,year]=(DPLV[enduse,HDV45Diesel,ec,area,vintage,year]+
                                                  DPLV[enduse,HDV8Diesel,ec,area,vintage,year])/2
  end

  HDV67Gasoline=Select(Tech,"HDV67Gasoline")
  HDV45Gasoline=Select(Tech,"HDV45Gasoline")
  HDV8Gasoline=Select(Tech,"HDV8Gasoline")
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, enduse in Enduses
    DPLV[enduse,HDV67Gasoline,ec,area,vintage,year]=(DPLV[enduse,HDV45Gasoline,ec,area,vintage,year]+
                                                  DPLV[enduse,HDV8Gasoline,ec,area,vintage,year])/2
  end

  #
  # Other Fuels use Scrappage Rate of Gasoline
  #
  HDV2B3Gasoline=Select(Tech,"HDV2B3Gasoline")
  techs=Select(Tech,["HDV2B3Electric","HDV2B3NaturalGas","HDV2B3Propane","HDV2B3FuelCell"])
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=DPLV[enduse,HDV2B3Gasoline,ec,area,vintage,year]
  end

  HDV45Gasoline=Select(Tech,"HDV45Gasoline")
  techs=Select(Tech,["HDV45Electric","HDV45NaturalGas","HDV45Propane","HDV45FuelCell"])
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=DPLV[enduse,HDV45Gasoline,ec,area,vintage,year]
  end

  HDV67Gasoline=Select(Tech,"HDV67Gasoline")
  techs=Select(Tech,["HDV67Electric","HDV67NaturalGas","HDV67Propane","HDV67FuelCell"])
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=DPLV[enduse,HDV67Gasoline,ec,area,vintage,year]
  end

  HDV8Gasoline=Select(Tech,"HDV8Gasoline")
  techs=Select(Tech,["HDV8Electric","HDV8NaturalGas","HDV8Propane","HDV8FuelCell"])
  for year in Years, vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=DPLV[enduse,HDV8Gasoline,ec,area,vintage,year]
  end

  #
  # Set final vintage to 1.0 for now. Look to readjust curves for techs missing 
  # data. - Ian 04/03/24
  #
  vintage=Int(length(Vintage))
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    DPLV[enduse,tech,ec,area,vintage,year]=1.0
  end
  WriteDisk(db,"$Input/DPLV", DPLV)

  #
  # HDV Activity Rates by Vintage sent by ECCC on 03/14/24. Considered premliminary data. 
  # Historical trend converted to smooth line for simplicity in 24.04.02 HDV Premliminary Activity Rates.xlsx
  # Trend equals 2.47% reduction in activity rate per vintage.
  # Ian 04/02/24
  #
  vintage=1
  DActVHDV[vintage]=1.0
  vintages=collect(2:Int(length(Vintage)))
  for vintage in vintages
    DActVHDV[vintage]=max(DActVHDV[vintage-1]-0.0247,0)
  end

  techs=Select(Tech,(from="HDV2B3Gasoline",to="HDV8Diesel"))
  for vintage in Vintages, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    DActV[enduse,tech,ec,area,vintage]=DActVHDV[vintage]
  end
  WriteDisk(db,"$Input/DActV", DActV)

end

function CalibrationControl(db)
  @info "TransScrappageRates.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
