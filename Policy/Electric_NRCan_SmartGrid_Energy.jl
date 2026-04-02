#
# Electric_NRCan_SmartGrid_Energy.jl - Smart Grid, reduces energy and peak
#

using EnergyModel

module Electric_NRCan_SmartGrid_Energy

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String
  
  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmdBase::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Base Case Energy Demand (TBtu/Yr)
  DSMEU::VariableArray{5} = ReadDisk(db,"$Input/DSMEU") # [Enduse,Tech,EC,Area,Year] Exogenous DSM (TBtu/Yr)
  GrElecBase::VariableArray{3} = ReadDisk(BCNameDB,"SOutput/GrElec") # [ECC,Area,Year] Base Case Gross Electric Usage (GWh)

  # Scratch Variables
  DSMFraction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] DSM Reduction Fraction (TBtu/TBtu)
  ForecastReduction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Reduction in Electricity Sales (GWh)
  HistoricalReduction::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Reduction in Electricity Sales (GWh)
  SalesReduction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Reduction in Electricity Sales (GWh)
end

function ResPolicy(db)
  data = RControl(; db)
  (; Input) = data
  (; Area,ECCs,ECs) = data 
  (; Enduses,Tech) = data
  (; Year) = data
  (; DmdBase,DSMEU,DSMFraction,ForecastReduction,GrElecBase) = data
  (; HistoricalReduction,SalesReduction) = data

  areas = Select(Area,["AB","SK","NB","NS"])
  SalesReduction[areas,Select(Year,"2024")] = [609650,  213912,  139043,  106956]   /1000
  SalesReduction[areas,Select(Year,"2025")] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Select(Year,"2026")] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Select(Year,"2027")] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Select(Year,"2028")] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Select(Year,"2029")] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Select(Year,"2030")] = [677388,  237680,  154492,  118840]   /1000
  years = collect(Yr(2031):Final)
  for year in years, area in areas
    SalesReduction[area,year] = SalesReduction[area,Yr(2030)]
  end

  # 
  # Historical DSM reductions are assumed to be included in input data
  # Calculate the amount of addition reductions made in forecast
  #   
  HistoricalReduction[areas] = SalesReduction[areas,Last]
  years = collect(Future:Final)
  for year in years, area in areas
    ForecastReduction[area,year] = SalesReduction[area,year] - 
      HistoricalReduction[area]
  end
  
  # 
  for year in years, area in areas
    @finite_math DSMFraction[area,year] = ForecastReduction[area,year] / 
      sum(GrElecBase[ecc,area,year] for ecc in ECCs)
  end

    # 
    # Compute DSM reduction as a fraction (DSMFraction) of base case demands (DmdBase)
    #    
    years = collect(Future:Final)
    Electric = Select(Tech,"Electric")
    for year in years, area in areas, ec in ECs, enduse in Enduses
      DSMEU[enduse,Electric,ec,area,year] = DSMEU[enduse,Electric,ec,area,year] + 
        DmdBase[enduse,Electric,ec,area,year] * DSMFraction[area,year] 
    end

    WriteDisk(db,"$Input/DSMEU",DSMEU)
end

Base.@kwdef struct CControl
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput" 
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmdBase::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Base Case Energy Demand (TBtu/Yr)
  DSMEU::VariableArray{5} = ReadDisk(db,"$Input/DSMEU") # [Enduse,Tech,EC,Area,Year] Exogenous DSM (TBtu/Yr)
  GrElecBase::VariableArray{3} = ReadDisk(BCNameDB,"SOutput/GrElec") # [ECC,Area,Year] Base Case Gross Electric Usage (GWh)

  # Scratch Variables
  DSMFraction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] DSM Reduction Fraction (TBtu/TBtu)
  ForecastReduction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Reduction in Electricity Sales (GWh)
  HistoricalReduction::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Reduction in Electricity Sales (GWh)
  SalesReduction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Reduction in Electricity Sales (GWh)
end

function ComPolicy(db)
  data = CControl(; db)
  (; Input) = data
  (; Area,ECCs,ECs) = data 
  (; Enduses,Tech) = data
  (; DmdBase,DSMEU,DSMFraction,ForecastReduction,GrElecBase) = data
  (; HistoricalReduction,SalesReduction) = data

  areas = Select(Area,["AB","SK","NB","NS"])
  SalesReduction[areas,Yr(2024)] = [609650,  213912,  139043,  106956]   /1000
  SalesReduction[areas,Yr(2025)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2026)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2027)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2028)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2029)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2030)] = [677388,  237680,  154492,  118840]   /1000
  years = collect(Yr(2031):Final)
  for year in years, area in areas
    SalesReduction[area,year] = SalesReduction[area,Yr(2030)]
  end

  # 
  # Historical DSM reductions are assumed to be included in input data
  # Calculate the amount of addition reductions made in forecast
  # 
  
  years = collect(Future:Final)
  HistoricalReduction[areas] = SalesReduction[areas,Last]
  for year in years, area in areas
    ForecastReduction[area,year] = SalesReduction[area,year] - 
      HistoricalReduction[area]
  end
  # 
  for year in years, area in areas
    DSMFraction[area,year] = ForecastReduction[area,year] / 
      sum(GrElecBase[ecc,area,year] for ecc in ECCs)
  end

  # 
  # Compute DSM reduction as a fraction (DSMFraction) of base case demands (DmdBase)
  # 
  
  Electric = Select(Tech,"Electric")
  years = collect(Future:Final)
  for year in years, area in areas, ec in ECs, enduse in Enduses
    DSMEU[enduse,Electric,ec,area,year] = DSMEU[enduse,Electric,ec,area,year] + 
      DmdBase[enduse,Electric,ec,area,year] * DSMFraction[area,year]
  end

  WriteDisk(db,"$Input/DSMEU",DSMEU)
end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmdBase::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Base Case Energy Demand (TBtu/Yr)
  DSMEU::VariableArray{5} = ReadDisk(db,"$Input/DSMEU") # [Enduse,Tech,EC,Area,Year] Exogenous DSM (TBtu/Yr)
  GrElecBase::VariableArray{3} = ReadDisk(BCNameDB,"SOutput/GrElec") # [ECC,Area,Year] Base Case Gross Electric Usage (GWh)

  # Scratch Variables
  DSMFraction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] DSM Reduction Fraction (TBtu/TBtu)
  ForecastReduction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Reduction in Electricity Sales (GWh)
  HistoricalReduction::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Reduction in Electricity Sales (GWh)
  SalesReduction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Reduction in Electricity Sales (GWh)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,ECCs,ECs) = data 
  (; Enduses,Tech) = data
  (; DmdBase,DSMEU,DSMFraction,ForecastReduction,GrElecBase) = data
  (; HistoricalReduction,SalesReduction) = data

  areas = Select(Area,["AB","SK","NB","NS"])
  SalesReduction[areas,Yr(2024)] = [609650,  213912,  139043,  106956]   /1000
  SalesReduction[areas,Yr(2025)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2026)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2027)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2028)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2029)] = [677388,  237680,  154492,  118840]   /1000
  SalesReduction[areas,Yr(2030)] = [677388,  237680,  154492,  118840]   /1000
  years = collect(Yr(2031):Final)
  for year in years, area in areas
    SalesReduction[area,year] = SalesReduction[area,Yr(2030)]
  end

  # 
  # Historical DSM reductions are assumed to be included in input data
  # Calculate the amount of addition reductions made in forecast
  # 
  
  years = collect(Future:Final)
  HistoricalReduction[areas] = SalesReduction[areas,Last]
  for year in years, area in areas
    ForecastReduction[area,year] = SalesReduction[area,year] - 
      HistoricalReduction[area]
  end
  # 
  for year in years, area in areas
    DSMFraction[area,year] = ForecastReduction[area,year] / 
      sum(GrElecBase[ecc,area,year] for ecc in ECCs)
  end

  # 
  # Compute DSM reduction as a fraction (DSMFraction) of base case demands (DmdBase)
  # 
  
  Electric = Select(Tech,"Electric")
  for year in years, area in areas, ec in ECs, enduse in Enduses
    DSMEU[enduse,Electric,ec,area,year] = DSMEU[enduse,Electric,ec,area,year] + 
      DmdBase[enduse,Electric,ec,area,year] * DSMFraction[area,year] 
  end

  WriteDisk(db,"$Input/DSMEU",DSMEU)
end

function PolicyControl(db)
  @info "Electric_NRCan_SmartGrid_Energy.jl - PolicyControl"
  ResPolicy(db)
  ComPolicy(db)
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
