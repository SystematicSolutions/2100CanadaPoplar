#
# CAC_BlackCarbon.jl - Hold forecasted coefficients for BC emissions equal
# to the ratio of BC to PM25 in the last year of the input data
# - Ian 08/31/16 via e-mail from Lifang at ECCC
# Split mulitplier for R, C, and I between fuel and process - Jeff Amlin 9/23/16
#
using EnergyModel

module CAC_BlackCarbon

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
  Last = HisTime-ITime+1

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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BCarbonSw::VariableArray{1} = ReadDisk(db,"SInput/BCarbonSw") # [Year] Black Carbon coefficient switch (1=POCX set relative to PM25)
  BCMult::VariableArray{4} = ReadDisk(db,"SInput/BCMult") # [Fuel,ECC,Area,Year] Fuel Emission Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes)
  BCMultProcess::VariableArray{3} = ReadDisk(db,"SInput/BCMultProcess") # [ECC,Area,Year] Process Emission Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  xEnFPol::VariableArray{5} = ReadDisk(db,"SInput/xEnFPol") # [FuelEP,ECC,Poll,Area,Year] Actual Energy Related Pollution (Tonnes/Yr)
  xFlPol::VariableArray{4} = ReadDisk(db,"SInput/xFlPol") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  xFuPol::VariableArray{4} = ReadDisk(db,"SInput/xFuPol") # [ECC,Poll,Area,Year] Fugitive Emissions (Tonnes/Yr)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)
  xOREnFPol::VariableArray{5} = ReadDisk(db,"SInput/xOREnFPol") # [FuelEP,ECC,Poll,Area,Year] Off Road Actual Energy Related Pollution (Tonnes/Yr)
  xORMEPol::VariableArray{4} = ReadDisk(db,"SInput/xORMEPol") # [ECC,Poll,Area,Year] Non-Energy Off Road Pollution (Tonnes/Yr)
  xVnPol::VariableArray{4} = ReadDisk(db,"SInput/xVnPol") # [ECC,Poll,Area,Year] Fugitive Venting Emissions (Tonnes/Yr)
end

function SupplyCalibration(db)
  data = SControl(; db)
  (;Last,Areas,ECCs,FuelEPs,Fuels,Poll) = data
  (;BCarbonSw,BCMult,BCMultProcess,FFPMap,xEnFPol,xFlPol,xFuPol,xMEPol,xOREnFPol) = data
  (;xORMEPol,xVnPol) = data

  #
  # Set BCMult equal to the difference between PM25 and BC inventories in the last year of input data. - Ian 08/31/16
  # 
  bc_p = Select(Poll,"BC")
  pm25 = Select(Poll,"PM25")
  for fuelep in FuelEPs
    fuel = Select(FFPMap[fuelep,Fuels],==(1))
    fuel = fuel[1]
    for area in Areas, ecc in ECCs
      @finite_math BCMult[fuel,ecc,area,Last] = (xEnFPol[fuelep,ecc,bc_p,area,Last]+xOREnFPol[fuelep,ecc,bc_p,area,Last])/
                                                (xEnFPol[fuelep,ecc,pm25,area,Last]+xOREnFPol[fuelep,ecc,pm25,area,Last])
    end
  end

  for a in Areas, e in ECCs
    @finite_math BCMultProcess[e,a,Last] = 
      (xFlPol[e,bc_p,a,Last] + xFuPol[e,bc_p,a,Last] + xMEPol[e,bc_p,a,Last] + xORMEPol[e,bc_p,a,Last] + xVnPol[e,bc_p,a,Last])/
      (xFlPol[e,pm25,a,Last] + xFuPol[e,pm25,a,Last] + xMEPol[e,pm25,a,Last] + xORMEPol[e,pm25,a,Last] + xVnPol[e,pm25,a,Last])
  end

  @. BCMult[Fuels,ECCs,Areas,Future:Final] = BCMult[Fuels,ECCs,Areas,Last]
  @. BCMultProcess[ECCs,Areas,Future:Final] = BCMultProcess[ECCs,Areas,Last]

  # 
  # Set switch to use ratio to calculate BC emissions annually
  # 
  # @. BCarbonSw[Future:Final] = 1
  for year in Future:Final
    BCarbonSw[year] = 1
  end

  WriteDisk(db,"SInput/BCarbonSw",BCarbonSw)
  WriteDisk(db,"SInput/BCMult",BCMult)
  WriteDisk(db,"SInput/BCMultProcess",BCMultProcess)

  @show BCarbonSw
end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  Last = HisTime-ITime+1

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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BCarbonSw::VariableArray{1} = ReadDisk(db,"SInput/BCarbonSw") # [Year] Black Carbon coefficient switch (1=POCX set relative to PM25)
  BCMultProcess::VariableArray{3} = ReadDisk(db,"SInput/BCMultProcess") # [ECC,Area,Year] Process Emission Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes)
  BCMultTr::VariableArray{5} = ReadDisk(db,"$Input/BCMultTr") # [Fuel,Tech,EC,Area,Year] Tech Emission Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes)
  ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  xOREnFPol::VariableArray{5} = ReadDisk(db,"SInput/xOREnFPol") # [FuelEP,ECC,Poll,Area,Year] Off Road Actual Energy Related Pollution (Tonnes/Yr)
  xORMEPol::VariableArray{4} = ReadDisk(db,"SInput/xORMEPol") # [ECC,Poll,Area,Year] Non-Energy Off Road Pollution (Tonnes/Yr)
  xTrEnFPol::VariableArray{7} = ReadDisk(db,"$Input/xTrEnFPol") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Energy Pollution (Tonnes/Yr)
  xTrMEPol::VariableArray{5} = ReadDisk(db,"$Input/xTrMEPol") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)
end

function TransCalibration(db)
  data = TControl(; db)
  (;Input,Last) = data
  (;Areas,ECCs,ECs) = data
  (;Enduses,FuelEPs,Fuels) = data
  (;Poll,Tech,Techs) = data
  (;BCarbonSw,BCMultProcess,BCMultTr,ECCMap,FFPMap,xOREnFPol,xORMEPol,xTrEnFPol) = data
  (;xTrMEPol) = data

  # 
  # For transportation sectors use transportation emissions
  # 
  bc_p = Select(Poll,"BC")
  pm25 = Select(Poll,"PM25")
  for ecc in ECCs
    ec = findall(x -> x == 1.0,ECCMap[ECs,ecc])
    if ec != []
      ec = ec[1]
      for area in Areas
        for fuelep in FuelEPs
          fuel = Select(FFPMap[fuelep,Fuels],==(1))
          fuel = fuel[1]
          tech = Select(Tech,!=("OffRoad"))
          for eu in Enduses
            @finite_math @. BCMultTr[fuel,tech,ec,area,Last] = xTrEnFPol[eu,fuelep,tech,ec,bc_p,area,Last] / xTrEnFPol[eu,fuelep,tech,ec,pm25,area,Last]

            offroad = Select(Tech, "OffRoad")
            @finite_math BCMultTr[fuel,offroad,ec,area,Last] = (xTrEnFPol[eu,fuelep,offroad,ec,bc_p,area,Last] + xOREnFPol[fuelep,ecc,bc_p,area,Last]) /
                                                  (xTrEnFPol[eu,fuelep,offroad,ec,pm25,area,Last] + xOREnFPol[fuelep,ecc,pm25,area,Last])
          end
        end
        @finite_math BCMultProcess[ecc,area,Last] = (sum(xTrMEPol[tech,ec,bc_p,area,Last] for tech in Techs) + xORMEPol[ecc,bc_p,area,Last]) /
                                       (sum(xTrMEPol[tech,ec,pm25,area,Last] for tech in Techs) + xORMEPol[ecc,pm25,area,Last])
      end
    end
  end
  @. BCMultTr[Fuels,Techs,ECs,Areas,Future:Final] = BCMultTr[Fuels,Techs,ECs,Areas,Last] 
  @. BCMultProcess[ECCs,Areas,Future:Final] = BCMultProcess[ECCs,Areas,Last] 

  # 
  # Set switch to use ratio to calculate BC emissions annually
  # 
  # @. BCarbonSw[Future:Final] = 1
  for year in Future:Final
    BCarbonSw[year] = 1
  end


  WriteDisk(db, "SInput/BCarbonSw",BCarbonSw)
  WriteDisk(db, "SInput/BCMultProcess",BCMultProcess)
  WriteDisk(db, "$Input/BCMultTr",BCMultTr)

  @show BCarbonSw
end

function CalibrationControl(db)
  @info "CAC_BlackCarbon.jl - CalibrationControl"

  SupplyCalibration(db)
  TransCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
