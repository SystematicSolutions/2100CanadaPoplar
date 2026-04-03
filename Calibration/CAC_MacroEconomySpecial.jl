#
# CAC_MacroEconomySpecial.jl
#
using EnergyModel

module CAC_MacroEconomySpecial

  import ...EnergyModel: ReadDisk,WriteDisk,Select
  import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
  import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
  import ...EnergyModel: DB

  const VariableArray{N} = Array{Float32,N} where {N}
  const SetArray = Vector{String}

  Base.@kwdef struct MControl
    db::String

    CalDB::String = "MCalDB"
    Input::String = "MInput"
    Outpt::String = "MOutput"
    BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

    Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
    AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
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
    MEDriver::VariableArray{3} = ReadDisk(db,"MOutput/MEDriver") # [ECC,Area,Year] Driver for Process Emissions (Various Millions/Yr)
    MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-Output)
    xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Process Pollution (Tonnes/Yr)

  end

  function MacroPolicy(db)
    data = MControl(; db)
    (;ECC,Nation,Poll) = data
    (;ANMap,MEDriver,MEPOCX,xMEPol) = data
    
    #
    #########################
    #
    # Process emission coefficient (MEPOCX) is extapolated into the future
    # based in last year of historical emissions (xMEPol) and the forecast
    # of the process emission driver (MEDriver).
    #
    # Removed NH3 per e-mail from Lifang - Ian 12/13/17
    # Changed years to start in Future, based on Last - Jeff Amlin 9/19/24
    #
    
    CN = Select(Nation,"CN")
    areas = findall(ANMap[:,CN] .== 1) 
    years = collect(Yr(2024):Final)
    polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","Hg","BC"])
    eccs = Select(ECC,["OnFarmFuelUse","CropProduction","AnimalProduction"])
    
    for year in years, area in areas, poll in polls, ecc in eccs
      xMEPol[ecc,poll,area,year] = xMEPol[ecc,poll,area,Last]
    end
    
    for year in years, area in areas, poll in polls, ecc in eccs
      MEPOCX[ecc,poll,area,year] = xMEPol[ecc,poll,area,year]/MEDriver[ecc,area,year]
    end

    #
    # Check for missing MEDriver
    #
    years = collect(Future:Final)
    for year in years, area in areas, poll in polls, ecc in eccs
      if (MEDriver[ecc,area,year]<1.00) || (xMEPol[ecc,poll,area,year] == 0)
        MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year - 1]
      end
    end
    
    WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
    WriteDisk(db,"SInput/xMEPol",xMEPol)

  end

  function CalibrationControl(db)
    @info "CAC_MacroEconomySpecial.jl - CalibrationControl"

    MacroPolicy(db)

  end

  if abspath(PROGRAM_FILE) == @__FILE__
    CalibrationControl(DB)
  end

end
