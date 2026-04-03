#
# WholesalePrices_Select.jl
#
using EnergyModel

module WholesalePrices_Select

  import ...EnergyModel: ReadDisk,WriteDisk,Select
  import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
  import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
  import ...EnergyModel: DB

  const VariableArray{N} = Array{Float32,N} where {N}
  const SetArray = Vector{String}

  Base.@kwdef struct SControl
    db::String

    Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
    FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
    Fuels::Vector{Int} = collect(Select(Fuel))
    Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
    NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
    Nations::Vector{Int} = collect(Select(Nation))
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")
    YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
    Years::Vector{Int} = collect(Select(Year))

    ENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN") # [Fuel,Nation,Year] Price Normal ($/mmBtu)
    xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (Real $/mmBtu)
    xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
    xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  end

  function WholesalePrices(db)
    data = SControl(; db)
    (;Fuels,Nation,Nations,Years) = data
    (;ENPN,xENPN,xExchangeRateNation,xInflationNation) = data

    #
    # Use Canada Wholesale Prices for forecast of all Nations
    #
    nations = Select(Nation,["US","MX","ROW"])
    CN = Select(Nation,"CN")
    years=collect(Future:Final)
    
    for year in years, nation in nations, fuel in Fuels
      @finite_math xENPN[fuel,nation,year] = xENPN[fuel,CN,year]*
        xInflationNation[CN,year]/xExchangeRateNation[CN,year] *
        xExchangeRateNation[nation,year]/xInflationNation[nation,year]
    end

    for year in Years, nation in Nations, fuel in Fuels
      ENPN[fuel,nation,year] = xENPN[fuel,nation,year]
    end

    WriteDisk(db,"SOutput/ENPN",ENPN)
    WriteDisk(db,"SInput/xENPN",xENPN)
  end
  
  function Control(db)
    @info "WholesalePrices_Select.jl - Control"
    WholesalePrices(db)
  end

  if abspath(PROGRAM_FILE) == @__FILE__
    Control(DB)
  end

end
