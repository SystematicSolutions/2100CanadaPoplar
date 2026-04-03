#
# IndDmFrac.jl
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

Base.@kwdef struct IndDmFracData
  db::String
  Input = "IInput"
  Outpt = "IOutput"
 
  Area   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS = ReadDisk(db,"MainDB/AreaDS")
  AreaKey  = ReadDisk(db,"MainDB/AreaKey")
  EC     = ReadDisk(db,"$Input/ECKey")
  ECKey  = ReadDisk(db,"$Input/ECKey")
  ECDS   = ReadDisk(db,"$Input/ECDS")    
  Enduse = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS    = ReadDisk(db,"$Input/EnduseDS")  
  EnduseKey = ReadDisk(db,"$Input/EnduseKey")  
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelKey::SetArray = ReadDisk(db,"MainDB/FuelKey")  
  Fuels::Vector{Int} = collect(Select(Fuel)) 
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech::SetArray   = ReadDisk(db,"$Input/TechKey")
  TechDS = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))  
  Year   = ReadDisk(db,"MainDB/YearDS")
  
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #  [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  ZZZ = zeros(Float32,length(Year))
  
end

function IndDmFrac_DtaRun(data,area,ec,techs,fuels,enduse)
  (; Year,Area,EC,Enduse,Fuel,Tech) = data
  (; DmFrac,ZZZ,SceName) = data

  iob = IOBuffer()


  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"This file was produced by IndDmFrac.jl")
  println(iob)

  years = collect(Yr(1990):Yr(2050))
  println(iob,"Year;",";",join(Year[years],";"))
  println(iob)

  for tech in techs
    print(iob,Area[area]," ",EC[ec]," ",Enduse[enduse]," ",Tech[tech]," Demand Fuel/Tech Fraction (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
  
    for fuel in fuels
      print(iob,"DmFrac;",Fuel[fuel])
      for year in years
         ZZZ[year] = DmFrac[enduse,fuel,tech,ec,area,year]     
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end
  println(iob)

  filename = "IndDmFrac-$(Area[area])-$(EC[ec])-$(Enduse[enduse])-$SceName.dta"
  open(joinpath(OutputFolder,filename), "w") do filename
    write(filename,String(take!(iob)))
  end
end

function IndDmFrac_DtaControl(db)
  @info "IndDmFrac_DtaControl"
  data = IndDmFracData(; db)
  (; Area,EC,Enduse,Fuel,Fuels,Tech,Techs) = data

  #areas = Select(Area,["ON","MB","SK","AB","BC","QC","PE","NS","NB"])
  areas = Select(Area,["ON","BC","QC"])  
  ecs = Select(EC,"OtherMetalMining")
  enduse = Select(Enduse,"Heat")
  
  for ec in ecs
    for area in areas
      IndDmFrac_DtaRun(data,area,ec,Techs,Fuels,enduse)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
IndDmFrac_DtaControl(DB)
end

