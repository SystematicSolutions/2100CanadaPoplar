#
# IndVintages.jl
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

Base.@kwdef struct IndVintagesData
  db::String
  Input = "IInput"
  Outpt = "IOutput"

  Age    = ReadDisk(db,"MainDB/AgeKey")
  AgeDS  = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS = ReadDisk(db,"MainDB/AreaDS")
  AreaKey     = ReadDisk(db,"MainDB/AreaKey")
  EC     = ReadDisk(db,"$Input/ECKey")
  ECDS   = ReadDisk(db,"$Input/ECDS")  
  ECC    = ReadDisk(db,"MainDB/ECCKey")
  ECCDS  = ReadDisk(db,"MainDB/ECCDS")
  ECCKey = ReadDisk(db,"MainDB/ECCKey")
  Enduse = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS    = ReadDisk(db,"$Input/EnduseDS")  
  Enduses::Vector{Int} = collect(Select(Enduse))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech::SetArray   = ReadDisk(db,"$Input/TechKey")
  TechDS = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Vintage::SetArray = ReadDisk(db,"$Input/VintageKey")
  VintageDS = ReadDisk(db,"$Input/VintageDS")
  VintageKey::SetArray = ReadDisk(db,"$Input/VintageKey")  
  Vintages::Vector{Int} = collect(Select(Vintage))  
  Year   = ReadDisk(db,"MainDB/YearDS")

  DERRDV::VariableArray{6} = ReadDisk(db,"$Outpt/DERRDV") # [Enduse,Tech,EC,Area,Vintage,Year] Device Retire from Device Retire. by Vintage (mmBtu/YR) 
  DERRRCV::VariableArray{6} = ReadDisk(db,"$Outpt/DERRRCV") # [Enduse,Tech,EC,Area,Vintage,Year] Device Retirements from Conversions by Vintage (mmBtu/Yr/Yr)
  DERRV::VariableArray{6} = ReadDisk(db,"$Outpt/DERRV") # [Enduse,Tech,EC,Area,Vintage,Year] Device Energy Requirement Retirements by Vintage (mmBtu/YR)
  DERV::VariableArray{6} = ReadDisk(db,"$Outpt/DERV") # [Enduse,Tech,EC,Area,Vintage,Year] Energy Requirement by Vintage (mmBtu/YR) 

end

function IndVintages_DtaRun(data,area,ec)
  (; SceName,Year,AgeDS,Ages,Area,AreaDS,AreaKey,EC,ECDS,ECC,ECCDS,ECCKey) = data
  (; EnduseDS,Enduses,TechDS,Techs,VintageDS,Vintages,DERV) = data
  (; DERRDV,DERRRCV,DERRV,DERV) = data
    
  AreaName = AreaDS[area]
  ECName = ECDS[ec]
  ecc = Select(ECC,EC[ec])
  ECCName = ECCDS[ecc]

  iob = IOBuffer()
  ZZZ = zeros(Float32,length(Year))

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"This file was produced by IndVintages.jl")
  println(iob)

  years = collect(Yr(1985):Yr(2050))

  print(iob,";")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)  
  
  println(iob)

  for enduse in Enduses, tech in Techs
  
    #
    # DERV
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",TechDS[tech]," Device Energy Requirements (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"DERV;Total") 
    for year in years
      ZZZ[year] = sum(DERV[enduse,tech,ec,area,vintage,year]/1000000 for vintage in Vintages)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob) 
    for vintage in Vintages
      print(iob,"DERV;",VintageDS[vintage]) 
      for year in years
        ZZZ[year] = DERV[enduse,tech,ec,area,vintage,year]/1000000
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob) 
    end
    println(iob) 
    
    #
    # DERRV
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",TechDS[tech]," Device Energy Requirement Retirements (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"DERRV;Total") 
    for year in years
      ZZZ[year] = sum(DERRV[enduse,tech,ec,area,vintage,year]/1000000 for vintage in Vintages)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob) 
    for vintage in Vintages
      print(iob,"DERRV;",VintageDS[vintage]) 
      for year in years
        ZZZ[year] = DERRV[enduse,tech,ec,area,vintage,year]/1000000
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob) 
    end    
    println(iob) 
    
    #
    # DERRDV
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",TechDS[tech]," Device Energy Requirement Retirements (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"DERRDV;Total") 
    for year in years
      ZZZ[year] = sum(DERRDV[enduse,tech,ec,area,vintage,year]/1000000 for vintage in Vintages)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob) 
    for vintage in Vintages
      print(iob,"DERRDV;",VintageDS[vintage]) 
      for year in years
        ZZZ[year] = DERRDV[enduse,tech,ec,area,vintage,year]/1000000
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob) 
    end     
    println(iob) 
    
    #
    # DERRRCV
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",TechDS[tech]," Device Energy Requirement Retirements for Conversions (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"DERRRCV;Total") 
    for year in years
      ZZZ[year] = sum(DERRRCV[enduse,tech,ec,area,vintage,year]/1000000 for vintage in Vintages)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob) 
    for vintage in Vintages
      print(iob,"DERRRCV;",VintageDS[vintage]) 
      for year in years
        ZZZ[year] = DERRRCV[enduse,tech,ec,area,vintage,year]/1000000
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob) 
    end      
    println(iob) 
  
  end

  filename = "IndVintages-$(AreaKey[area])-$(ECCKey[ecc])-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function IndVintages_DtaControl(db)
  @info "IndVintages_DtaControl"
  data = IndVintagesData(; db)
  (; Area, EC, ECC) = data
  areas = Select(Area,["ON","QC"])
  ecs = Select(EC,["Food","PulpPaperMills"])
  for ec in ecs
    for area in areas
      IndVintages_DtaRun(data,area,ec)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
IndVintages_DtaControl(DB)
end
