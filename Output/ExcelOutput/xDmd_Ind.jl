#
# xDmd_Ind.jl
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

Base.@kwdef struct xDmd_IndData
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
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Process Heat Energy (TBtu/Yr) 

  ZZZ = zeros(Float32,length(Year))
end

function xDmd_Ind_DtaRun(data,areas,nation)
  (; Year,Area,AreaDS,EC,ECs,Enduse,Enduses,Nation,SceName,Tech,Techs) = data
  (; xDmd,ZZZ) = data

  iob = IOBuffer()

  println(iob)
  println(iob,"$Nation[nation], Industrial")
  println(iob,"This file was produced by xDmd_Ind.jl")
  println(iob)


  years = collect(1:Last)

  println(iob,"Year;;;;",";",join(Year[years],";"))
  println(iob)

  println(iob,"Variable;Enduse,Tech;EC,Area;",join(Year[years],";"))

  for enduse in Enduses
    for tech in Techs
      for ec in ECs
        for area in areas
          for year in years
            ZZZ[year] = xDmd[enduse,tech,ec,area,year]     
          end
          loc1 = sum(ZZZ[year] for year in years)
          print(iob,"xDmd;",Enduse[enduse],";",Tech[tech],";",EC[ec],";",AreaDS[area],";")
          for year in years
            print(iob,";",@sprintf("%12.4f",ZZZ[year]))
          end         
          println(iob)
        end
      end
    end
  end
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "xDmd_Ind-$(Nation[nation])-$SceName.dta"
  open(joinpath(OutputFolder,filename), "w") do filename
    write(filename,String(take!(iob)))
  end
end

function xDmd_Ind_DtaControl(db)
  @info "xDmd_Ind_DtaControl"
  data = xDmd_IndData(; db)
  (; Area,Nation) = data
  (; ANMap) = data

  nation = Select(Nation,"CN");
  areas = findall(ANMap[:,nation] .== 1);
  xDmd_Ind_DtaRun(data,areas,nation)

  nation = Select(Nation,"US");
  areas = findall(ANMap[:,nation] .== 1);
  xDmd_Ind_DtaRun(data,areas,nation)
  
end


if abspath(PROGRAM_FILE) == @__FILE__
xDmd_Ind_DtaControl(DB)
end

