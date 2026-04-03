#
# Steam_VB.jl - VBInput Steam Data
#
using EnergyModel

module Steam_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name
  Last=HisTime-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduses::Vector{Int} = collect(Select(vEnduse))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  StFFrac::VariableArray{3} = ReadDisk(db,"SInput/StFFrac") # [FuelEP,Area,Year] Steam Generation Fuel Fraction (Btu/Btu)
  StHR::VariableArray{2} = ReadDisk(db,"SInput/StHR") # [Area,Year] Steam Generation Heat Rate (Btu/Btu)
  StPOCX::VariableArray{4} = ReadDisk(db,"SInput/StPOCX") # [FuelEP,Poll,Area,Year] Steam Generation Pollution Coefficient (Tonnes/TBtu)
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vDmd::VariableArray{5} = ReadDisk(db,"VBInput/vDmd") # [vEnduse,Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  vPOCX::VariableArray{5} = ReadDisk(db,"VBInput/vPOCX") # [FuelEP,ECC,Poll,vArea,Year] Pollution coefficient (Tonnes/TBtu)
  vStDmd::VariableArray{3} = ReadDisk(db,"VBInput/vStDmd") # [FuelEP,Area,Year] Steam Generation Fuel Demands (TBtu/Yr)
  xStDmd::VariableArray{3} = ReadDisk(db,"SInput/xStDmd") # [FuelEP,Area,Year] Steam Generation Fuel Demands (TBtu/Yr)
  xStEuDmd::VariableArray{4} = ReadDisk(db,"SInput/xStEuDmd") # [FuelEP,ECC,Area,Year] RCI Fuel Demands for Steam Generation (TBtu/Yr)
  xStPur::VariableArray{3} = ReadDisk(db,"SInput/xStPur") # [ECC,Area,Year] Net Steam Purchases (TBtu/Yr)
  xStSold::VariableArray{3} = ReadDisk(db,"SInput/xStSold") # [ECC,Area,Year] RCI Steam Sold into Steam Market (TBtu/Yr)
end

function ECalibration(db)
  data = EControl(; db)
  (;Areas,ECC,ECCs,Fuel) = data
  (;FuelEPs,Fuels,Nation,Polls,vAreas,vEnduse,vEnduses,Years) = data
  (;ANMap,FFPMap,StFFrac,StHR,StPOCX,vDmd,vPOCX,vStDmd,xStDmd,xStEuDmd) = data
  (;xStPur,xStSold,Last,vAreaMap) = data

  CN = Select(Nation,"CN")
  areas = Select(ANMap[Areas,CN], ==(1))
  years = collect(Zero:Last)
  
  # 
  # Fuel used to generate utility steam which is sold into the steam market - from Steam Supply sector.
  # 
  for fuelep in FuelEPs, area in areas, year in years
    xStDmd[fuelep,area,year] = vStDmd[fuelep,area,year]
  end

  # 
  # Fuel Used to generate industrial steam which is all sold into the steam market - Enduse(Steam)
  #
  v_steam = Select(vEnduse,"Steam")
  for fuelep in FuelEPs, ecc in ECCs, area in areas, year in years
    xStEuDmd[fuelep,ecc,area,year]=sum(vDmd[v_steam,fuel,ecc,area,year]*FFPMap[fuelep,fuel] for fuel in Fuels) 
  end

  # 
  # Steam Purchased from Market - Fuel(Steam) - total in the steam market
  # 
  f_steam = Select(Fuel,"Steam")
  for ecc in ECCs, area in areas, year in years
    xStPur[ecc,area,year] = sum(vDmd[veu,f_steam,ecc,area,year] for veu in vEnduses) 
  end

  # 
  # Steam Heat Rate is the same for all industries and fuels.
  # 
  for area in areas, year in years
    @finite_math StHR[area,year] =
       (sum(xStDmd[fuelep,area,year] for fuelep in FuelEPs)+
        sum(xStEuDmd[fuelep,ecc,area,year] for fuelep in FuelEPs, ecc in ECCs))/
       sum(xStPur[ecc,area,year] for ecc in ECCs)
  end
  
  # 
  # The heat rate is constrained to be greater than 0.5 and less than 3.0
  # - Jeff Amlin 12/24/18/24
  # 
  #for area in areas, year in years
  #  StHR[area,year] = max(min(StHR[area,year],3),0.50)             
  #end

  # 
  # The heat rate in the Last historical year is used for the forecast,
  # but is constrained to be greater than 1.0 and less than 10.0
  # - Jeff Amlin 8/18/14
  # 
  
  years = collect(Future:Final)  
  for area in areas, year in years
    if StHR[area,year] == 0.0
      StHR[area,year] = max(min(StHR[area,year-1],10),1)
    end
  end

  # 
  # NB Steam Heat Rate Patch
  # 
  # Select Area(NB)
  # StHR(Area,Y)=3.33
  # Select Area*
  # Select Area If ANMap(Area,CN) eq 1
  # 


  # 
  # RCI Steam Sold into Steam Market
  # 
  years = collect(Zero:Last)
  for ecc in ECCs, area in areas, year in years
    @finite_math xStSold[ecc,area,year] = sum(xStEuDmd[fuelep,ecc,area,year]/
                                          StHR[area,year] for fuelep in FuelEPs)
  end

  # 
  # Steam Fraction
  # 
  for fuelep in FuelEPs, area in areas
    years = collect(Zero:Last)
    for year in years
      @finite_math StFFrac[fuelep,area,year] = xStDmd[fuelep,area,year]/
                   sum(xStDmd[f,area,year] for f in FuelEPs)
    end
    years = collect(Future:Final)  
    for year in years
      if StFFrac[fuelep,area,year] == 0.0
        StFFrac[fuelep,area,year] =StFFrac[fuelep,area,year-1]
      end
    end
  end

  # 
  # Steam Emissions Coefficient
  # 
  esteam = Select(ECC,"Steam")
  for fuelep in FuelEPs, poll in Polls, area in areas
    years = collect(Zero:Last)
    for year in years
      StPOCX[fuelep,poll,area,year] = sum(vPOCX[fuelep,esteam,poll,varea,year]*
                                      vAreaMap[area,varea] for varea in vAreas)
    end
    years = collect(Future:Final)      
    for year in years
      if StPOCX[fuelep,poll,area,year] == 0.0 
        StPOCX[fuelep,poll,area,year] = StPOCX[fuelep,poll,area,year-1]
      end
    end
  end

  WriteDisk(db,"SInput/StFFrac",StFFrac)
  WriteDisk(db,"SInput/StHR",StHR)
  WriteDisk(db,"SInput/StPOCX",StPOCX)
  WriteDisk(db,"SInput/xStDmd",xStDmd)
  WriteDisk(db,"SInput/xStEuDmd",xStEuDmd)
  WriteDisk(db,"SInput/xStPur",xStPur)
  WriteDisk(db,"SInput/xStSold",xStSold)
  
end

function Control(db)
  @info "Steam_VB.jl - Control"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
