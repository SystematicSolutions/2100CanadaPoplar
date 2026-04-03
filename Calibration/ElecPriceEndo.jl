#
# ElecPriceEndo.jl - Endogenous Electric Prices
#
using EnergyModel

module ElecPriceEndo

  import ...EnergyModel: ReadDisk,WriteDisk,Select
  import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
  import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
  import ...EnergyModel: DB

  const VariableArray{N} = Array{Float32,N} where {N}
  const SetArray = Vector{String}

  Base.@kwdef struct SControl
    db::String

    CalDB::String = "SCalDB"
    Input::String = "SInput"
    Outpt::String = "SOutput"
    BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

    Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
    AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
    Areas::Vector{Int} = collect(Select(Area))
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")
    YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
    Years::Vector{Int} = collect(Select(Year))

    ElecPrSw::VariableArray{2} = ReadDisk(db,"SInput/ElecPrSw") # [Area,Year] Electricity Price Switch (0=Exogenous Prices)
    Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  end

  function SupplyPolicy(db)
    data = SControl(; db)
    (;Areas) = data
    (;ElecPrSw,Endogenous) = data

    years=collect(Future:Final)
    for year in years, area in Areas
      ElecPrSw[area,year] = Endogenous
    end
    WriteDisk(db,"SInput/ElecPrSw",ElecPrSw)
  end

  function CalibrationControl(db)
    @info "ElecPriceEndo.jl - CalibrationControl"

    SupplyPolicy(db)

  end

  if abspath(PROGRAM_FILE) == @__FILE__
    CalibrationControl(DB)
  end

end
