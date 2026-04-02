#
# Trans_MS_HDV_Electric_A.jl (similar to iMHZEV.txp (from ZEV_HDV.txp))
#
# Targets for ZEV market shares representing Transport Canada analysis on iMHZEV program.
# To Modify, adjust EVInput below
#
# 
# To be run after Trans_MS_HDV_Electric_BC
# 
# Brock Batey - October 7th 2022.
#
# Extended Electrification to reflect Liberal Party platform BB-Nov 18 2021
#

using EnergyModel

module Trans_MS_HDV_Electric_A

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TransMSHDVElectricAData
  db::String
  
  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
  DDD::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Variable for Displaying Outputs
  MSFTarget::VariableArray{3} = zeros(Float32,length(Tech),length(Area),length(Year)) # [Tech,Area,Year] Target Market Share for Policy Vehicles (Driver/Driver)
  MSFTrucksBase::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Truck Market Shares in Base
  TTMSChange::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Trucks Market Share factor (Driver/Driver)
  TTMSNew::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Trucks Market Share New,after shift to Transit (Driver/Driver)
  TTMSOld::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Trucks Market Share Old,before shift to Transit(Driver/Driver)
  ZEVInput::VariableArray{3} = zeros(Float32,length(Tech),length(Area),length(Year)) # [Tech,Area,Year] Target ZEV fractions of truck class (Driver/Driver)
end

function TransPolicyHDVElectric(db)
  data = TransMSHDVElectricAData(; db)
  (; CalDB) = data
  (; Area,EC,Enduse) = data 
  (; Nation,Tech,) = data
  (; ANMap,MSFTarget) = data
  (; TTMSChange,TTMSNew,TTMSOld,xMMSF,ZEVInput) = data
  
  ON = Select(Area,"ON");
  Freight = Select(EC,"Freight");
  Carriage = Select(Enduse,"Carriage");
  years = collect(Yr(2023):Yr(2040));
  techs = Select(Tech,["HDV2B3Electric","HDV45Electric","HDV67Electric","HDV8Electric","HDV67FuelCell","HDV8FuelCell"]);

  # 
  # Read in EVInput, fractional market share of on road freight trucks
  # EVInput represents the fraction of the Tech to switch to ZEV
  # 

  ZEVInput[techs,ON,years] = [
    #2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040 # Electric Shares
    0.063  0.095   0.207   0.252   0.150   0.200   0.250   0.300   0.350   0.400   0.450   0.500   0.550   0.640   0.730   0.820   0.910   0.980 # HDV2B3
    0.013  0.020   0.110   0.130   0.200   0.300   0.400   0.500   0.550   0.600   0.650   0.700   0.750   0.800   0.850   0.900   0.950   0.980 # HDV45
    0.012  0.015   0.077   0.091   0.140   0.210   0.280   0.350   0.385   0.420   0.455   0.490   0.525   0.560   0.595   0.630   0.665   0.686 # HDV67 Electric
    0.015  0.016   0.066   0.084   0.125   0.177   0.230   0.291   0.318   0.344   0.371   0.398   0.424   0.451   0.477   0.504   0.531   0.557 #HDV8 Electric
    0.000  0.000   0.033   0.039   0.060   0.090   0.120   0.150   0.165   0.180   0.195   0.210   0.225   0.240   0.255   0.270   0.285   0.294 # HDV67 FuelCell
    0.000  0.000   0.028   0.036   0.053   0.076   0.098   0.125   0.136   0.148   0.159   0.170   0.182   0.193   0.205   0.216   0.227   0.239 # HDV8 FuelCell
    ]
  
  CN = Select(Nation,"CN");
  areas = findall(ANMap[:,CN] .== 1);
  for year in years, area in areas, tech in techs
    ZEVInput[tech,area,year] = ZEVInput[tech,ON,year];
  end;

  #
  # Scale down NT and NU by half since it is triggering emergency generation around 2040.
  #  
  areas = Select(Area,["NT","NU"]);
  for year in years, area in areas, tech in techs
    ZEVInput[tech,area,year] = ZEVInput[tech,area,year] * 0.5;
  end;

  areas = findall(ANMap[:,CN] .== 1);
  
  # 
  # Select fraction of on road freight trucks of total freight
  # and Scale EVInput using TTMSOld. This should maintain truck
  # market share vs trains and boats
  # 
  
  techs = Select(Tech,(from="HDV2B3Gasoline",to="HDV2B3FuelCell"))
  for area in areas, year in years
    TTMSOld[area,year] = sum(xMMSF[Carriage,tech,Freight,area,year] for tech in techs)
  end
  
  HDV2B3Electric = Select(Tech,"HDV2B3Electric");
  for area in areas, year in years
    MSFTarget[HDV2B3Electric,area,year] = ZEVInput[HDV2B3Electric,area,year]*
      TTMSOld[area,year]
    TTMSNew[area,year] = TTMSOld[area,year]-MSFTarget[HDV2B3Electric,area,year]
    @finite_math TTMSChange[area,year] = TTMSNew[area,year] / TTMSOld[area,year]
  end
  
  techs = Select(Tech,["HDV2B3Gasoline","HDV2B3Diesel","HDV2B3NaturalGas","HDV2B3Propane"])
  for area in areas, tech in techs, year in years
    MSFTarget[tech,area,year] = xMMSF[Carriage,tech,Freight,area,year] * 
      TTMSChange[area,year]
  end

  techs = Select(Tech,(from="HDV45Gasoline",to="HDV45FuelCell"))
  for area in areas, year in years
    TTMSOld[area,year] = sum(xMMSF[Carriage,tech,Freight,area,year] for tech in techs)
  end
  
  HDV45Electric = Select(Tech,"HDV45Electric");
  for area in areas, year in years
    MSFTarget[HDV45Electric,area,year] = 
      ZEVInput[HDV45Electric,area,year]*TTMSOld[area,year]
    TTMSNew[area,year] = TTMSOld[area,year]-MSFTarget[HDV45Electric,area,year]
    @finite_math TTMSChange[area,year] = TTMSNew[area,year] / TTMSOld[area,year]
  end
  
  techs = Select(Tech,["HDV45Gasoline","HDV45Diesel","HDV45NaturalGas","HDV45Propane"])
  for area in areas, tech in techs, year in years
    MSFTarget[tech,area,year] = xMMSF[Carriage,tech,Freight,area,year] * 
      TTMSChange[area,year]
  end


  techs = Select(Tech,(from="HDV67Gasoline",to="HDV67FuelCell"))
  for area in areas, year in years
    TTMSOld[area,year] = sum(xMMSF[Carriage,tech,Freight,area,year] for tech in techs)
  end
  
  HDV67Electric = Select(Tech,"HDV67Electric");
  HDV67FuelCell = Select(Tech,"HDV67FuelCell")
  techs = Select(Tech,["HDV67Electric","HDV67FuelCell"]);
  for area in areas, year in years, tech in techs
    MSFTarget[tech,area,year] = ZEVInput[tech,area,year]*
      TTMSOld[area,year]
  end
  for area in areas, year in years
    TTMSNew[area,year] = TTMSOld[area,year]-MSFTarget[HDV67Electric,area,year]-MSFTarget[HDV67FuelCell,area,year]
    @finite_math TTMSChange[area,year] = TTMSNew[area,year] / TTMSOld[area,year]
  end
  
  techs = Select(Tech,["HDV67Gasoline","HDV67Diesel","HDV67NaturalGas","HDV67Propane"])
  for area in areas, tech in techs, year in years
    MSFTarget[tech,area,year] = xMMSF[Carriage,tech,Freight,area,year] * 
      TTMSChange[area,year]
  end
  
  techs = Select(Tech,(from="HDV8Gasoline",to="HDV8FuelCell"))
  for area in areas, year in years
    TTMSOld[area,year] = sum(xMMSF[Carriage,tech,Freight,area,year] for tech in techs)
  end
  
  HDV8Electric = Select(Tech,"HDV8Electric");
  HDV8FuelCell = Select(Tech,"HDV8FuelCell");
  techs = Select(Tech,["HDV8Electric","HDV8FuelCell"]);
  for area in areas, year in years, tech in techs
    MSFTarget[tech,area,year] = ZEVInput[tech,area,year]*
      TTMSOld[area,year]
  end
  for area in areas, year in years
    TTMSNew[area,year] = TTMSOld[area,year]-MSFTarget[HDV8Electric,area,year]-MSFTarget[HDV8FuelCell,area,year]
    @finite_math TTMSChange[area,year] = TTMSNew[area,year] / TTMSOld[area,year]
  end
  
  techs = Select(Tech,["HDV8Gasoline","HDV8Diesel","HDV8NaturalGas","HDV8Propane"])
  for area in areas, tech in techs, year in years
    MSFTarget[tech,area,year] = xMMSF[Carriage,tech,Freight,area,year] * 
      TTMSChange[area,year]
  end

  years = collect(Yr(2041):Final);
  techs = Select(Tech,(from="HDV2B3Gasoline",to="HDV8FuelCell"))
  for year in years, area in areas, tech in techs
    MSFTarget[tech,area,year] = MSFTarget[tech,area,Yr(2040)]
  end

  years = collect(Future:Final);
  for year in years, tech in techs, area in areas
    xMMSF[Carriage,tech,Freight,area,year] = MSFTarget[tech,area,year]
  end

  WriteDisk(db,"$CalDB/xMMSF",xMMSF);
end

function PolicyControl(db)
  @info ("Trans_MS_HDV_Electric_A.jl - PolicyControl");
  TransPolicyHDVElectric(db);
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
