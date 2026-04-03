#
# Electric_Coal_FuelFractions.jl
#
using EnergyModel

module Electric_Coal_FuelFractions

  import ...EnergyModel: ReadDisk,WriteDisk,Select
  import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
  import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
  import ...EnergyModel: DB

  const VariableArray{N} = Array{Float32,N} where {N}
  const SetArray = Vector{String}

  Base.@kwdef struct EControl
    db::String

    CalDB::String = "ECalDB"
    Input::String = "EInput"
    Outpt::String = "EOutput"
    BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

    FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
    FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
    FuelEPs::Vector{Int} = collect(Select(FuelEP))
    Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
    Units::Vector{Int} = collect(Select(Unit))
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")
    YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
    Years::Vector{Int} = collect(Select(Year))

    xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
    UnFlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMax") # [Unit,FuelEP,Year] Fuel Fraction Maximum (Btu/Btu)
    UnFlFrMin::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMin") # [Unit,FuelEP,Year] Fuel Fraction Minimum (Btu/Btu)
    UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  end

  function ElecPolicy(db)
    data = EControl(; db)
    (;FuelEPs) = data
    (;xUnFlFr,UnFlFrMax,UnFlFrMin,UnPlant) = data

    #
    # The coal units fuel fractions (UnFlFr) do not change based on fuel prices.
    #   - Jeff Amlin 11/10/20, approved by email from Jean-Sebastien Landry
    #
    years=collect(Future:Final)
    units = findall(UnPlant .== "Coal")
    for year in years, fuelep in FuelEPs, unit in units
      UnFlFrMax[unit,fuelep,year] = xUnFlFr[unit,fuelep,year]
      UnFlFrMin[unit,fuelep,year] = xUnFlFr[unit,fuelep,year]
    end

    # WriteDisk(db,"EGInput/xUnFlFr",xUnFlFr)
    WriteDisk(db,"EGInput/UnFlFrMax",UnFlFrMax)
    WriteDisk(db,"EGInput/UnFlFrMin",UnFlFrMin)
  end

  function CalibrationControl(db)
    @info "Electric_Coal_FuelFractions.jl - CalibrationControl"

    ElecPolicy(db)

  end

  if abspath(PROGRAM_FILE) == @__FILE__
    CalibrationControl(DB)
  end

end
