#
# MainDBData.jl
#
using EnergyModel

module MainDBData

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey") 
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")  
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))    
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")  
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))


  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation],"Map between Area and Nation (Map)","Map")
  BugSw::Float32 = ReadDisk(db,"MainDB/BugSw")[1] # [tv] "Bugs switch (0=No bug,1=Bug)","0=No bug,1=Bug")
  Com::Float32 = ReadDisk(db,"MainDB/Com")[1] # [tv] "Commercial setting for Sector sets","1,0")
  ECCCLMap::VariableArray{2} = ReadDisk(db,"MainDB/ECCCLMap") # [ECC,Class],"Map Between ECC and Class (Map)","Map")
  ECCSector::VariableArray{1} = ReadDisk(db,"MainDB/ECCSector") # [Sector],"ECC number where each sector begins","NoUnit")
  ECom::Float32 = ReadDisk(db,"MainDB/ECom")[1] # [tv] "Commercial setting for ECC sets","2,0")
  EInd::Float32 = ReadDisk(db,"MainDB/EInd")[1] # [tv] "Starting Industrial Index for ECC set","2,0")
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  Epsilon::Float32 = ReadDisk(db,"MainDB/Epsilon")[1] #[tv] A Very Small Number  
  ERes::Float32 = ReadDisk(db,"MainDB/ERes")[1] # [tv] "Residential setting for ECC sets","2,0")
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0  Epsilon = ReadDisk(db,"MainDB/Epsilon")[1] # [tv] "A Very Small Number","10,8")
  FSMap::VariableArray{1} = ReadDisk(db,"MainDB/FSMap") # [Fuel],"Fuel to Segment Map (Map)","Map")
  Ind::Float32 = ReadDisk(db,"MainDB/Ind")[1] # [tv] "Industrial Index for Sector set","1,0")
  Infinity::Float32 = ReadDisk(db,"MainDB/Infinity")[1] # [tv] "Largest Number to include in Promula equations","10,15")
  NonExist::Float32 = ReadDisk(db,"MainDB/NonExist")[1] # [tv] "Does not exist or is not used setting for SegSw","2,0")
  PreCalc::Float32 = ReadDisk(db,"MainDB/PreCalc")[1] # [tv] "Values are pre-calculated setting for SegSw","2,0")

  RfName::SetArray = RfUnit
  RfCode::SetArray = RfUnit

  Res::Float32 = ReadDisk(db,"MainDB/Res")[1] # [tv] "Residential setting for Sector sets","1,0")
  SegMap::VariableArray{1} = ReadDisk(db,"MainDB/SegMap") # [Seg],"Menu to Segment Map (Map)","Map")
  SegName::SetArray = Seg
  SegSw::VariableArray{1} = ReadDisk(db,"MainDB/SegSw") # [Seg],"Sector Execution Switch (Switch)","Switch")
  Smallest::Float32 = ReadDisk(db,"MainDB/Smallest")[1] # [tv] "Smallest Number to include in Promula equations","10,15")
  Unique::Float32 = ReadDisk(db,"MainDB/Unique")[1] # [tv] "Values have a special calculation setting for SegSw","2,0")
  xSegSw::VariableArray{1} = ReadDisk(db,"MainDB/xSegSw") # [Seg],"Sector Execution Switch (Switch)","Switch")
  YrNum::VariableArray{1} = ReadDisk(db,"MainDB/YrNum") # [Year],"Year Number from 1 to Year:M","2,0")
  Yrv::VariableArray{1} = ReadDisk(db,"MainDB/Yrv") # [Year],"Time from 1985 - 2020,in 1-Year Increments (Year)","Year")

end

function MainDBData_Inputs(db)
  data = Data(; db)
  (; Area,Class,ECC,Fuel,Fuels,Nation,Seg,Years) = data
  (; ANMap,Com,ECCCLMap,ECom,EInd,Endogenous,Epsilon,ERes,Exogenous,FSMap) = data
  (; Ind,Infinity,NonExist,PreCalc,Res) = data  
  (; SegMap,SegSw,Smallest,Unique,xSegSw,YrNum,Yrv) = data

  #
  # ********************
  #
  Epsilon = 0.0001
  Infinity = 1e37
  Smallest = 1e-30
  WriteDisk(db,"MainDB/Epsilon",Epsilon)
  WriteDisk(db,"MainDB/Infinity",Infinity)  
  WriteDisk(db,"MainDB/Smallest",Smallest) 
  
  #
  # ********************
  #
  NonExist = -1
  Exogenous = 0
  Endogenous = 1
  PreCalc = 2
  Unique = 3
  WriteDisk(db,"MainDB/NonExist",NonExist)  
  WriteDisk(db,"MainDB/Exogenous",Exogenous) 
  WriteDisk(db,"MainDB/Endogenous",Endogenous)
  WriteDisk(db,"MainDB/PreCalc",PreCalc)  
  WriteDisk(db,"MainDB/Unique",Unique)

  #
  # ********************
  #
  # There are three economic sectors
  #
  Res = 1
  Com = 2
  Ind = 3
  WriteDisk(db,"MainDB/Res",Res)
  WriteDisk(db,"MainDB/Com",Com)
  WriteDisk(db,"MainDB/Ind",Ind)
  
  
  #
  # ********************
  #
  ERes = 1
  # There are 4 residential indices
  ECom = ERes+4
  # There are 12 commercial indices
  EInd = ECom+12
  WriteDisk(db,"MainDB/ERes",ERes)
  WriteDisk(db,"MainDB/ECom",ECom)
  WriteDisk(db,"MainDB/EInd",EInd)

  #
  # ********************
  #
  @. ECCCLMap = 0.0
  class = Select(Class,"Res")
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached",
                     "MultiFamily","OtherResidential"])
  for ecc in eccs
    ECCCLMap[ecc,class] = 1.0
  end
  class = Select(Class,"Com")
    eccs = Select(ECC,(from = "Wholesale",to = "StreetLighting"))
  for ecc in eccs
    ECCCLMap[ecc,class] = 1.0
  end
  class = Select(Class,"Ind")
  eccs = Select(ECC,(from = "Food",to = "AnimalProduction"))
  for ecc in eccs
    ECCCLMap[ecc,class] = 1.0
  end
  eccs = Select(ECC,["H2Production","BiofuelProduction"])
  for ecc in eccs
    ECCCLMap[ecc,class] = 1.0
  end
  class = Select(Class,"Transport")
  eccs = Select(ECC,(from="Passenger",to="CommercialOffRoad"))
  for ecc in eccs
    ECCCLMap[ecc,class] = 1.0
  end  
  class = Select(Class,"Misc")
  eccs = Select(ECC,"Miscellaneous")
  for ecc in eccs
    ECCCLMap[ecc,class] = 1.0
  end 
  WriteDisk(db,"MainDB/ECCCLMap",ECCCLMap)

  #
  # ********************
  #
  # Area Nation Map
  #
  @. ANMap = 0
  
  nation = Select(Nation,"CN")
  areas=Select(Area,["ON","QC","BC","AB","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  for area in areas
    ANMap[area,nation] = 1
  end
  
  nation = Select(Nation,"US")
  areas=Select(Area,["CA","NEng","MAtl","ENC","WNC","SAtl","ESC","WSC","Mtn","Pac"])
  for area in areas
    ANMap[area,nation] = 1
  end

  nation = Select(Nation,"MX")
  area=Select(Area,"MX")
  ANMap[area,nation] = 1

  nation = Select(Nation,"ROW")
  area=Select(Area,"ROW")
  ANMap[area,nation] = 1
  
  WriteDisk(db,"MainDB/ANMap",ANMap)

  #
  # ********************
  #
  BugSw = 1
  WriteDisk(db,"MainDB/BugSw",BugSw)

  #
  # Segment Map
  #
  segs=Select(Seg,["MEconomy","Residential","Commercial","Industrial",
    "Transportation","Loadcurve","Electric","Gas","Oil","Coal",
    "Biomass","Supply","Demand"])
  loc1=0
  for seg in segs
    loc1 = loc1+1
    SegMap[loc1]=seg
  end
  WriteDisk(db,"MainDB/SegMap",SegMap)   
    
  #
  # ********************
  #
  # FSMap - Map Between Fuel and Segment 
  #
  # Default value is "Oil"
  #
  seg = Select(Seg,"Oil")
  for fuel in Fuels
    FSMap[fuel] = seg
  end
  
  seg = Select(Seg,"Electric")
  fuel = Select(Fuel,"Electric")
  FSMap[fuel] = seg

  seg = Select(Seg,"Gas")
  fuels = Select(Fuel,["NaturalGas","NaturalGasRaw"])
  for fuel in fuels
    FSMap[fuel] = seg
  end

  seg = Select(Seg,"Coal")
  fuel = Select(Fuel,"Coal")
  FSMap[fuel] = seg

  seg = Select(Seg,"Biomass")
  fuel = Select(Fuel,"Biomass")
  FSMap[fuel] = seg
  
  seg = Select(Seg,"LPG")
  fuel = Select(Fuel,"LPG")
  FSMap[fuel] = seg  
  
  seg = Select(Seg,"Solar")
  fuel = Select(Fuel,"Solar")
  FSMap[fuel] = seg  

  WriteDisk(db,"MainDB/FSMap",FSMap)  
  
  #
  # ******************** 
  #
  # Switch (xSegSw) to indicate execution status of each segment (Seg).
  #
  @. xSegSw = NonExist
  
  seg = Select(Seg,"MEconomy")
  xSegSw[seg] = Exogenous
  
  seg = Select(Seg,"Residential")
  xSegSw[seg] = Endogenous
  
  seg = Select(Seg,"Commercial")
  xSegSw[seg] = Endogenous
  
  seg = Select(Seg,"Industrial")
  xSegSw[seg] = Endogenous
  
  seg = Select(Seg,"Transportation")
  xSegSw[seg] = Endogenous
  
  seg = Select(Seg,"Loadcurve")
  xSegSw[seg] = Endogenous
  
  seg = Select(Seg,"Electric")
  xSegSw[seg] = Endogenous
  
  seg = Select(Seg,"Biomass")
  xSegSw[seg] = NonExist
  
  seg = Select(Seg,"Gas")
  xSegSw[seg] = NonExist
  
  seg = Select(Seg,"Oil")
  xSegSw[seg] = NonExist
  
  seg = Select(Seg,"Auxiliary")
  xSegSw[seg] = NonExist
  
  seg = Select(Seg,"Supply")
  xSegSw[seg] = Endogenous
  
  seg = Select(Seg,"Demand")
  xSegSw[seg] = NonExist
  
  #
  # These segments will not work [need a different beginning letter).  They must be set to nonexist.
  #
  seg = Select(Seg,"Solar")
  xSegSw[seg] = NonExist
  
  seg = Select(Seg,"Coal")
  xSegSw[seg] = NonExist
  
  seg = Select(Seg,"LPG")
  xSegSw[seg] = NonExist
  
  WriteDisk(db,"MainDB/xSegSw",xSegSw) 
  
  #
  # ******************** 
  #
  # Year as integer,starting at 1 (YrNum)
  #
  for year in Years
    YrNum[year] = year
  end
  WriteDisk(db,"MainDB/YrNum",YrNum)
  
  #
  # Year as float,starting at xITime
  #
  Yrv[1] = ITime
  years = collect(2:Yr(MaxTime))
  for year in years
    Yrv[year] = Yrv[year-1]+1
  end
  WriteDisk(db,"MainDB/Yrv",Yrv)  

end 

function Control(db)
  MainDBData_Inputs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end #end module
