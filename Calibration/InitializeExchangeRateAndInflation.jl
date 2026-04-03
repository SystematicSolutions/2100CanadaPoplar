#
# InitializeExchangeRateandInflation.jl - Assigns values to exchange rate and inflation variables
#
########################
#  - Extend variables from macro model to 2050 (xExchR0)
#  - Assign values to new variables by Area, Nation (xExchangeRate, xExchangeRateNation, xInflationNation)
#  - Assign descriptor for money units by Area-CN$,US$,MX Peso (MoneyUnitDS)
########################
#
using EnergyModel

module InitializeExchangeRateAndInflation

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ExchangeRate::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  GDPDefl::VariableArray{2} = ReadDisk(db,"Informet/GDPDefl") # [Nation,Year] GDP Deflator (Index)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  INST::Float32 = ReadDisk(db,"MInput/INST")  # Inflation Rate Smooth Time (Years)
  MacroSwitch::Vector{String} = ReadDisk(db, "MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchR0::VariableArray{2} = ReadDisk(db,"Informet/ExchR0") # [Nation,Year] Exchange Rate (CN$/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  xInflationRate::VariableArray{2} = ReadDisk(db,"MInput/xInflationRate") # [Area,Year] Inflation Rate ($/$)
  xInflationRateNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationRateNation") # [Nation,Year] Inflation Rate ($/$)
  xInSm::VariableArray{2} = ReadDisk(db,"MInput/xInSm") # [Area,Year] Smoothed Inflation Rate (1/Yr)

end

function Initialize(db)
  data = MControl(; db)
  (;Areas,Nation,Nations,Years) = data
  (;ANMap,ExchangeRate,ExchangeRateNation,GDPDefl,Inflation,InflationNation,INST,MacroSwitch,MoneyUnitDS) = data
  (;MoneyUnitDS,xExchangeRate,xExchangeRateNation,xExchR0) = data
  (;xInflation,xInflationNation,xInflationRate,xInflationRateNation,xInSm) = data

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  MX = Select(Nation,"MX")
  ROW = Select(Nation,"ROW")
  #
  # Use GDP deflator from Informetrica as inflation rate
  #
  if MacroSwitch[CN] == "TIM"
    for area in Areas
      xInflation[area,1] = 1.0
    end
    for nation in Nations
      xInflationNation[nation,1] = 1.0
    end
    
    years = collect(2:Final)
    for year in years
      xInflationNation[US,year] = GDPDefl[US,year]/GDPDefl[US,1]
      xInflationNation[CN,year] = GDPDefl[CN,year]/GDPDefl[CN,1]
      xInflationNation[MX,year] = GDPDefl[US,year]/GDPDefl[US,1]
      xInflationNation[ROW,year] = GDPDefl[US,year]/GDPDefl[US,1]
    end
    
    for year in years, area in Areas
      xInflation[area,year] = xInflationNation[US,year]
    end

    areas = findall(ANMap[:,CN] .== 1.0)
    for year in years, area in areas   
      xInflation[area,year] = xInflationNation[CN,year] 
    end
  end


  years = collect(2:Final)
  for year in years, area in Areas 
    xInflationRate[area,year] = 
     (xInflation[area,year]-xInflation[area,year-1])/xInflation[area,year-1]
  end

  for year in years, nation in Nations
    xInflationRateNation[nation,year] = (xInflationNation[nation,year]-
      xInflationNation[nation,year-1])/xInflationNation[nation,year-1]
  end

  # 
  # Fill in values after data ends
  #
  for year in years, area in Areas
    if (xInflationRate[area,year] == -1.0) || (xInflationRate[area,year] == 0)
      xInflationRate[area,year] = xInflationRate[area,year-1]
      xInflation[area,year] = xInflation[area,year-1]*(1+xInflationRate[area,year])      
    end
  end
  #
  for year in years, nation in Nations
    if (xInflationRateNation[nation,year] == -1.0) || (xInflationRateNation[nation,year] == 0)
      xInflationRateNation[nation,year] = xInflationRateNation[nation,year-1]
      xInflationNation[nation,year] = xInflationNation[nation,year-1]*
                                     (1+xInflationRateNation[nation,year])
    end
  end

  for area in Areas 
    xInSm[area,1]=xInflation[area,1]
  end
  for year in years, area in Areas 
    xInSm[area,year] = xInSm[area,year-1]+
      (xInflationRate[area,year]-xInSm[area,year-1])/INST
  end
  
  #
  # Initialize Nation Variables
  #
  if MacroSwitch[CN] == "TIM"
    @. xExchangeRate = 1
    @. xExchangeRateNation = 1
    
    areas = findall(ANMap[:,CN] .== 1.0)
    for year in Years, area in areas   
      xExchangeRate[area,year] = xExchR0[CN,year]
    end
    for year in Years      
      xExchangeRateNation[CN,year] = xExchR0[CN,year]
    end
  end

  areas = findall(ANMap[:,CN] .== 1.0)
  for area in Areas   
    MoneyUnitDS[area] = "CN\$"
  end
  areas = findall(ANMap[:,US] .== 1.0)
  for area in Areas   
    MoneyUnitDS[area] = "US\$"
  end  
  area = 24
  MoneyUnitDS[area] = "MX Pesos"
  
  @. ExchangeRate = xExchangeRate 
  @. ExchangeRateNation = xExchangeRateNation
  @. Inflation = xInflation
  @. InflationNation = xInflationNation

  WriteDisk(db,"MOutput/ExchangeRate",ExchangeRate)
  WriteDisk(db,"MOutput/ExchangeRateNation",ExchangeRateNation)  
  WriteDisk(db,"MOutput/Inflation",Inflation)
  WriteDisk(db,"MOutput/InflationNation",InflationNation)
  WriteDisk(db,"MInput/MoneyUnitDS",MoneyUnitDS)
  WriteDisk(db,"MInput/xExchangeRate",xExchangeRate)
  WriteDisk(db,"MInput/xExchangeRateNation",xExchangeRateNation)
  WriteDisk(db,"MInput/xInflation",xInflation)
  WriteDisk(db,"MInput/xInflationNation",xInflationNation)
  WriteDisk(db,"MInput/xInflationRate",xInflationRate)
  WriteDisk(db,"MInput/xInflationRateNation",xInflationRateNation)
  WriteDisk(db,"MInput/xInSm",xInSm)

end

function Control(db)
  @info "InitializeExchangeRateAndInflation.jl - Control"
  Initialize(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
