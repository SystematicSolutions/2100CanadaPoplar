#
# xDmFrac_Ind.jl
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct xDmFrac_IndData
  db::String
  Input = "IInput"
  Outpt = "IOutput"
 
  Area   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS = ReadDisk(db,"MainDB/AreaDS")
  AreaKey  = ReadDisk(db,"MainDB/AreaKey")
  EC     = ReadDisk(db,"$Input/ECKey")
  ECKey  = ReadDisk(db,"$Input/ECKey")
  ECDS   = ReadDisk(db,"$Input/ECDS")    
  ECs::Vector{Int} = collect(Select(EC))
  Enduse = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS    = ReadDisk(db,"$Input/EnduseDS")  
  EnduseKey = ReadDisk(db,"$Input/EnduseKey")  
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelKey::SetArray = ReadDisk(db,"MainDB/FuelKey")  
  Fuels::Vector{Int} = collect(Select(Fuel)) 
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech::SetArray   = ReadDisk(db,"$Input/TechKey")
  TechDS = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))  
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year]  'Energy Demands Fuel/Tech Split (Fraction)'
  ZZZ = zeros(Float32,length(Year))
end

function xDmFrac_Ind_DtaRun(data,area,ecs,techs,fuels,enduses)
  (; Year,Area,EC,Enduse,Fuel,SceName,Tech) = data
  (; xDmFrac,ZZZ) = data

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"This file was produced by xDmFrac_Ind.jl")
  println(iob)

  years = collect(Last:Yr(2050))
  println(iob,"Year;",";",join(Year[years],";"))
  println(iob)

  println(iob,"Energy Demands Fuel/Tech Split (Fraction);",join(Year[years],";"))
  for ec in ecs
    for enduse in enduses
      for tech in techs
        for fuel in fuels
          for year in years
            ZZZ[year] = xDmFrac[enduse,fuel,tech,ec,area,year]     
          end
          loc1 = sum(ZZZ[year] for year in years)
          loc2 = ZZZ[Future]
          if (loc1 > 0) && (loc2 < 1)
            print(iob,"xDmFrac;",Area[area],";",EC[ec],";",Enduse[enduse],";",Tech[tech],";",Fuel[fuel],";")
            for year in years
              print(iob,";",@sprintf("%12.4f",ZZZ[year]))
            end         
            println(iob)
          end
        end
      end
    end
  end
  println(iob)

  filename = "xDmFrac_Ind-$(Area[area])-$SceName.dta"
  open(joinpath(OutputFolder,filename), "w") do filename
    write(filename,String(take!(iob)))
  end
end

function xDmFrac_Ind_DtaControl(db)
  @info "xDmFrac_Ind_DtaControl"
  data = xDmFrac_IndData(; db)
  (; Area,EC,ECs,Enduses,Fuel,Fuels,Tech,Nation,Techs) = data
  (; ANMap) = data

  CN = Select(Nation,"CN");
  areas = findall(ANMap[:,CN] .== 1);
  
  for area in areas
    xDmFrac_Ind_DtaRun(data,area,ECs,Techs,Fuels,Enduses)
  end
  
end

if abspath(PROGRAM_FILE) == @__FILE__
xDmFrac_Ind_DtaControl(DB)
end

