#
# EnergyDemands1985to1989.jl
#
using EnergyModel

module EnergyDemands1985to1989

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr,Zero
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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  # ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)

  # Scratch Variables
  # xDmdAve  'Average Value for Non-Zero Historical Demands (TBtu/Yr)'
  # xDmdMin  'Minimum Value for Non-Zero Historical Demands (TBtu/Yr)'
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Area,Areas,ECC,ECCs,EC,ECs) = data
  (;Enduses,Techs,Fuels) = data
  (;xDmd,xDmFrac,xDriver,xEuDemand) = data

  #
  # Check for missing values between 1985 and 1989
  #
  years = reverse(collect(Yr(1985):Yr(1989)))
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for enduse in Enduses, tech in Techs, area in Areas, year in years 
      if xDmd[enduse,tech,ec,area,year] <= 0 
        xDmd[enduse,tech,ec,area,year] = xDmd[enduse,tech,ec,area,year+1] *
                                          xDriver[ecc,area,year] / xDriver[ecc,area,year+1]
      end
    end
  end
 
  #
  # 1985 must have a value if there are any historical values
  #
  years = collect(First:Last)
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    if xDmd[enduse,tech,ec,area,Yr(1985)] <= 0

      #
      # Initialize with maximum value
      #
      xDmdMin = 0
      for year in years
        xDmdMin = max(xDmd[enduse,tech,ec,area,year],xDmdMin)
      end

      #
      # Search for non-zero minimum value
      #
      for year in years 
        if xDmd[enduse,tech,ec,area,year] > 0
          xDmdMin = min(xDmd[enduse,tech,ec,area,year],xDmdMin)
        end
      end
      xDmd[enduse,tech,ec,area,Yr(1985)] = xDmdMin
    end
  end

  #
  # One more adjustment for PEI and Territories
  #
  areas = Select(Area,["PE","NT","YT","NU"])
  for enduse in Enduses, tech in Techs,  ec in ECs, area in areas
    years = collect(First:Last)
    validyears = findall(x -> x > 0,xDmd[enduse,tech,ec,area,years])
    #
    # validyears returns the index of years, which starts at First ([2]). Add 1
    # to align the index back to Year. There is probably a much better way
    # to do this - Ian
    #
    validyears = validyears .+ 1
    if validyears != []
      xDmdAve = sum(xDmd[enduse,tech,ec,area,year] for year in validyears) / length(validyears)
      xDmdMin = minimum(xDmd[enduse,tech,ec,area,validyears])
      xDmdMin = max(xDmdMin,xDmdAve/100)
      years = collect(Zero:Last)
      for year in years
        xDmd[enduse,tech,ec,area,year] = max(xDmd[enduse,tech,ec,area,year],xDmdMin)
      end
    end
  end

  WriteDisk(db, "$Input/xDmd",xDmd)

  for ec in ECs
    ecc=Select(ECC,EC[ec])
    for year in years, area in Areas, fuel in Fuels
      xEuDemand[fuel,ecc,area,year] = sum(xDmd[enduse,tech,ec,area,year]*
        xDmFrac[enduse,fuel,tech,ec,area,year] for tech in Techs, enduse in Enduses)
    end
  end

  WriteDisk(db, "SInput/xEuDemand",xEuDemand)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  # ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)

  # Scratch Variables
  # xDmdAve  'Average Value for Non-Zero Historical Demands (TBtu/Yr)'
  # xDmdMin  'Minimum Value for Non-Zero Historical Demands (TBtu/Yr)'
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Area,Areas,ECC,ECCs,EC,ECs) = data
  (;Enduses,Techs,Fuels) = data
  (;xDmd,xDmFrac,xDriver,xEuDemand) = data

  #
  # Check for missing values between 1985 and 1989
  #
  years = reverse(collect(Yr(1985):Yr(1989)))
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for enduse in Enduses, tech in Techs, area in Areas, year in years 
      if xDmd[enduse,tech,ec,area,year] <= 0 
        xDmd[enduse,tech,ec,area,year] = xDmd[enduse,tech,ec,area,year+1] *
                                          xDriver[ecc,area,year] / xDriver[ecc,area,year+1]
      end
    end
  end
 
  #
  # 1985 must have a value if there are any historical values
  #
  years = collect(First:Last)
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    if xDmd[enduse,tech,ec,area,Yr(1985)] <= 0

      #
      #         Initialize with maximum value
      #
      xDmdMin = 0
      for year in years
        xDmdMin = max(xDmd[enduse,tech,ec,area,year],xDmdMin)
      end

      #
      #         Search for non-zero minimum value
      #
      for year in years 
        if xDmd[enduse,tech,ec,area,year] > 0
          xDmdMin = min(xDmd[enduse,tech,ec,area,year],xDmdMin)
        end
      end
      xDmd[enduse,tech,ec,area,Yr(1985)] = xDmdMin
    end
  end

  #
  # One more adjustment for PEI and Territories
  #
  areas = Select(Area,["PE","NT","YT","NU"])
  for enduse in Enduses, tech in Techs,  ec in ECs, area in areas
    years = collect(First:Last)
    validyears = findall(x -> x > 0,xDmd[enduse,tech,ec,area,years])
    #
    # validyears returns the index of years, which starts at First ([2]). Add 1
    # to align the index back to Year. There is probably a much better way
    # to do this - Ian
    #
    validyears = validyears .+ 1
    if validyears != []
      xDmdAve = sum(xDmd[enduse,tech,ec,area,year] for year in validyears) / length(validyears)
      xDmdMin = minimum(xDmd[enduse,tech,ec,area,validyears])
      xDmdMin = max(xDmdMin,xDmdAve/100)
      years = collect(Zero:Last)
      for year in years
        xDmd[enduse,tech,ec,area,year] = max(xDmd[enduse,tech,ec,area,year],xDmdMin)
      end
    end
  end

  WriteDisk(db, "$Input/xDmd",xDmd)

  for ec in ECs
    ecc=Select(ECC,EC[ec])
    for year in years, area in Areas, fuel in Fuels
      xEuDemand[fuel,ecc,area,year] = sum(xDmd[enduse,tech,ec,area,year]*
        xDmFrac[enduse,fuel,tech,ec,area,year] for tech in Techs, enduse in Enduses)
    end
  end

  WriteDisk(db, "SInput/xEuDemand",xEuDemand)

end

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  # ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)

  # Scratch Variables
  # xDmdAve  'Average Value for Non-Zero Historical Demands (TBtu/Yr)'
  # xDmdMin  'Minimum Value for Non-Zero Historical Demands (TBtu/Yr)'
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,Areas,ECC,ECCs,EC,ECs) = data
  (;Enduses,Techs,Fuels) = data
  (;xDmd,xDmFrac,xDriver,xEuDemand) = data


  #
  # Check for missing values between 1985 and 1989
  #
  years = reverse(collect(Yr(1985):Yr(1989)))
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for enduse in Enduses, tech in Techs, area in Areas, year in years 
      if xDmd[enduse,tech,ec,area,year] <= 0 
        xDmd[enduse,tech,ec,area,year] = xDmd[enduse,tech,ec,area,year+1] *
                                          xDriver[ecc,area,year] / xDriver[ecc,area,year+1]
      end
    end
  end
 
  #
  # 1985 must have a value if there are any historical values
  #
  years = collect(First:Last)
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    if xDmd[enduse,tech,ec,area,Yr(1985)] <= 0

      #
      #         Initialize with maximum value
      #
      xDmdMin = 0
      for year in years
        xDmdMin = max(xDmd[enduse,tech,ec,area,year],xDmdMin)
      end

      #
      #         Search for non-zero minimum value
      #
      for year in years 
        if xDmd[enduse,tech,ec,area,year] > 0
          xDmdMin = min(xDmd[enduse,tech,ec,area,year],xDmdMin)
        end
      end
      xDmd[enduse,tech,ec,area,Yr(1985)] = xDmdMin
    end
  end

  #
  # One more adjustment for PEI and Territories
  #
  areas = Select(Area,["PE","NT","YT","NU"])
  for enduse in Enduses, tech in Techs,  ec in ECs, area in areas
    years = collect(First:Last)
    validyears = findall(x -> x > 0,xDmd[enduse,tech,ec,area,years])
    #
    # validyears returns the index of years, which starts at First ([2]). Add 1
    # to align the index back to Year. There is probably a much better way
    # to do this - Ian
    #
    validyears = validyears .+ 1
    if validyears != []
      xDmdAve = sum(xDmd[enduse,tech,ec,area,year] for year in validyears) / length(validyears)
      xDmdMin = minimum(xDmd[enduse,tech,ec,area,validyears])
      xDmdMin = max(xDmdMin,xDmdAve/100)
      years = collect(Zero:Last)
      for year in years
        xDmd[enduse,tech,ec,area,year] = max(xDmd[enduse,tech,ec,area,year],xDmdMin)
      end
    end
  end
  
  #
  # NT Petroleum should not be adjusted per e-mail from Robin 6/08/21 - Ian
  #
  ec = Select(EC,"Petroleum")
  NT = Select(Area,"NT")
  years = collect(Yr(1999):Last)
  for year in years, tech in Techs, enduse in Enduses
    xDmd[enduse,tech,ec,NT,year] = 0
  end

  WriteDisk(db, "$Input/xDmd",xDmd)

  for ec in ECs
    ecc=Select(ECC,EC[ec])
    for year in years, area in Areas, fuel in Fuels
      xEuDemand[fuel,ecc,area,year] = sum(xDmd[enduse,tech,ec,area,year]*
        xDmFrac[enduse,fuel,tech,ec,area,year] for tech in Techs, enduse in Enduses)
    end
  end

  WriteDisk(db, "SInput/xEuDemand",xEuDemand)

end

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  # ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)

  # Scratch Variables
  # xDmdAve  'Average Value for Non-Zero Historical Demands (TBtu/Yr)'
  # xDmdMin  'Minimum Value for Non-Zero Historical Demands (TBtu/Yr)'
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,Areas,ECC,ECCs,EC,ECs) = data
  (;Enduses,Techs,Fuels) = data
  (;xDmd,xDmFrac,xDriver,xEuDemand) = data

  #
  # Check for missing values between 1985 and 1989
  #
  years = reverse(collect(Yr(1985):Yr(1989)))
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for enduse in Enduses, tech in Techs, area in Areas, year in years 
      if xDmd[enduse,tech,ec,area,year] <= 0 
        xDmd[enduse,tech,ec,area,year] = xDmd[enduse,tech,ec,area,year+1] *
                                          xDriver[ecc,area,year] / xDriver[ecc,area,year+1]
      end
    end
  end
 
  #
  # 1985 must have a value if there are any historical values
  #
  years = collect(First:Last)
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    if xDmd[enduse,tech,ec,area,Yr(1985)] <= 0

      #
      #         Initialize with maximum value
      #
      xDmdMin = 0
      for year in years
        xDmdMin = max(xDmd[enduse,tech,ec,area,year],xDmdMin)
      end

      #
      #         Search for non-zero minimum value
      #
      for year in years 
        if xDmd[enduse,tech,ec,area,year] > 0
          xDmdMin = min(xDmd[enduse,tech,ec,area,year],xDmdMin)
        end
      end
      xDmd[enduse,tech,ec,area,Yr(1985)] = xDmdMin
    end
  end

  #
  # One more adjustment for PEI and Territories
  #
  areas = Select(Area,["PE","NT","YT","NU"])
  for enduse in Enduses, tech in Techs,  ec in ECs, area in areas
    years = collect(First:Last)
    validyears = findall(x -> x > 0,xDmd[enduse,tech,ec,area,years])
    #
    # validyears returns the index of years, which starts at First ([2]). Add 1
    # to align the index back to Year. There is probably a much better way
    # to do this - Ian
    #
    validyears = validyears .+ 1
    if validyears != []
      xDmdAve = sum(xDmd[enduse,tech,ec,area,year] for year in validyears) / length(validyears)
      xDmdMin = minimum(xDmd[enduse,tech,ec,area,validyears])
      xDmdMin = max(xDmdMin,xDmdAve/100)
      years = collect(Zero:Last)
      for year in years
        xDmd[enduse,tech,ec,area,year] = max(xDmd[enduse,tech,ec,area,year],xDmdMin)
      end
    end
  end

  WriteDisk(db, "$Input/xDmd",xDmd)

  for ec in ECs
    ecc=Select(ECC,EC[ec])
    for year in years, area in Areas, fuel in Fuels
      xEuDemand[fuel,ecc,area,year] = sum(xDmd[enduse,tech,ec,area,year]*
        xDmFrac[enduse,fuel,tech,ec,area,year] for tech in Techs, enduse in Enduses)
    end
  end

  WriteDisk(db, "SInput/xEuDemand",xEuDemand)

end

function Control(db)
  @info "EnergyDemands1985to1989.jl - Control"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
