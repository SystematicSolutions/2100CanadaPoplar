#
# DmFrac_Calc_Com.jl - Calculate xDmFrac from vDmd and vFsDmd
#
using EnergyModel

module DmFrac_Calc_Com

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmdFuel::VariableArray{6} = ReadDisk(db,"$Input/DmdFuel") # [Enduse,Fuel,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  FsDmdFuel::VariableArray{5} = ReadDisk(db,"$Input/FsDmdFuel") # [Fuel,Tech,EC,Area,Year] Historical Feedstock Demands by Fuel
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)

  # Scratch Variables
  TotDmd::VariableArray{3} = zeros(Float32,length(Enduse),length(Tech),length(EC)) # [Enduse,Tech,EC] Total Demand Across Area (TBtu/Yr)
  TotFsDmd::VariableArray{2} = zeros(Float32,length(Tech),length(EC)) # [Tech,EC] Total Feedstock Demand Across Area (TBtu/Yr)
end

function DmFrac_Calc(db)
  data = CControl(; db)
  (;Input,Areas,ECs,Enduses,Fuel) = data
  (;Fuels,Tech,Techs,Years) = data
  (;DmdFuel,FsDmdFuel,xDmFrac,xFsFrac) = data
  (;TotDmd,TotFsDmd) = data

  # 
  # Demand Fuel to Technology Fractions (xDmFrac, FsFrac)
  # 
  for year in Years
    for area in Areas    
      
      # 
      # If demands are zero, then use the default xDmFrac if this is the first year;
      # otherwise use the xDmFrac from the previous year.
      # 
      for ec in ECs
        for tech in Techs          
          if sum(DmdFuel[eu,fuel,tech,ec,area,year] for eu in Enduses, fuel in Fuels) > 0.000005
            for eu in Enduses
              TotDmd[eu,tech,ec] = sum(DmdFuel[eu,fuel,tech,ec,area,year] for fuel in Fuels)
              for fuel in Fuels
                @finite_math xDmFrac[eu,fuel,tech,ec,area,year] = DmdFuel[eu,fuel,tech,ec,area,year] / TotDmd[eu,tech,ec]
              end
            end
          elseif year > 1
            for eu in Enduses, fuel in Fuels
              xDmFrac[eu,fuel,tech,ec,area,year] = xDmFrac[eu,fuel,tech,ec,area,year-1]
            end
          end
        end

        # 
        # Loop around Tech so NEB can add exogenous feedstock forecast for selected fuels
        # 
        for tech in Techs
          FsDmdTech = sum(FsDmdFuel[fuel,tech,ec,area,year] for fuel in Fuels)
          if FsDmdTech > 0.0005      
            TotFsDmd[tech,ec] = sum(FsDmdFuel[fuel,tech,ec,area,year] for fuel in Fuels)
            for fuel in Fuels
              @finite_math xFsFrac[fuel,tech,ec,area,year] = FsDmdFuel[fuel,tech,ec,area,year]/
                                                             TotFsDmd[tech,ec]
            end
          elseif year > 1
            for fuel in Fuels
              xFsFrac[fuel,tech,ec,area,year] = xFsFrac[fuel,tech,ec,area,year-1]
            end
          end
        end
      end
    end
  end

  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
  WriteDisk(db,"$Input/xFsFrac",xFsFrac)

end

function Control(db)
  @info "DmFrac_Calc_Com.jl - Control"

  DmFrac_Calc(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
