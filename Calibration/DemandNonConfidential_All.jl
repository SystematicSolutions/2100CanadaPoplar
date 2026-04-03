#
# DemandNonConfidential_All.jl
#

using EnergyModel

module DemandNonConfidential_All

import ...EnergyModel: ReadDisk,WriteDisk,Select,Yr
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,DT
import ...EnergyModel: DB,OutputFolder
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

using Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  vDmd::VariableArray{5} = ReadDisk(db,"VBInput/vDmd") # [vEnduse,Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  vDmdScrub::VariableArray{5} = ReadDisk(db,"VBInput/vDmdScrub") # [vEnduse,Fuel,ECC,Area,Year] Enduse Demands Confidential Switch (Switch)
  vDmdScrubCN::VariableArray{5} = ReadDisk(db,"VBInput/vDmdScrubCN") # [vEnduse,Fuel,ECC,Nation,Year] National Enduse Demands Confidential Switch (Switch)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Economic Driver (Various Units/Yr)
  Yrv::VariableArray{1} = ReadDisk(db,"MainDB/Yrv") # [Year] Year as Float32

  #
  # Scratch Variables
  #
  DmdCN::VariableArray{4}       = zeros(Float32,length(vEnduse),length(Fuel),length(ECC),length(Year)) # [vEnduse,Fuel,ECC,Year] Canada Energy Demands (TBtu/Yr)
  DriverCN::VariableArray{2}    = zeros(Float32,length(ECC),length(Year)) # [ECC,Year] Canada Economic Driver (Various Units/Yr)
  IntensityCN::VariableArray{4} = zeros(Float32,length(vEnduse),length(Fuel),length(ECC),length(Year)) # [vEnduse,Fuel,ECC,Year] Average Energy Intensity in Canada (TBtu/Driver)
  vDmdArea::VariableArray{4}    = zeros(Float32,length(vEnduse),length(Fuel),length(Area),length(Year)) # [vEnduse,Fuel,Area,Year] Provincial Energy Demands (TBtu/Yr)
  vDmdCon::VariableArray{5}     = zeros(Float32,length(vEnduse),length(Fuel),length(ECC),length(Area),length(Year)) # [vEnduse,Fuel,ECC,Area,Year] Confidential Demands (TBtu/Yr)
  vDmdEst::VariableArray{5}     = zeros(Float32,length(vEnduse),length(Fuel),length(ECC),length(Area),length(Year)) # [vEnduse,Fuel,ECC,Area,Year] Estimate of NonConfidential Demands (TBtu/Yr)
  vDmdEstArea::VariableArray{4} = zeros(Float32,length(vEnduse),length(Fuel),length(Area),length(Year)) # [vEnduse,Fuel,Area,Year] Estimate of Provincial Energy Demands (TBtu/Yr)
  vDmdNonCon::VariableArray{5}  = zeros(Float32,length(vEnduse),length(Fuel),length(ECC),length(Area),length(Year)) # [vEnduse,Fuel,ECC,Area,Year] Non-Confidential Demands (TBtu/Yr)
  ZZZ::VariableArray{1}         = zeros(Float32,length(Year)) # [Year] Display Variable
end

function ExtrapolateScrubVariables(data,areas,nation)
  (; ECCs,Fuels,vEnduses) = data
  (; vDmdScrub,vDmdScrubCN) = data

  years = collect(Yr(2021):Last)

  for year in years, ecc in ECCs, fuel in Fuels, venduse in vEnduses
    vDmdScrubCN[venduse,fuel,ecc,nation,year] = vDmdScrubCN[venduse,fuel,ecc,nation,Yr(2020)]
  end
  
  for year in years, area in areas, ecc in ECCs, fuel in Fuels, venduse in vEnduses
    vDmdScrub[venduse,fuel,ecc,area,year] = vDmdScrub[venduse,fuel,ecc,area,Yr(2020)]
  end
  
end

function InitializeNonConfidentialDemands(data,areas)
  (; Areas,ECCs,vEnduses,Fuels,Years) = data
  (; vDmd,vDmdCon,vDmdNonCon) = data
  
  for year in Years, area in areas, ecc in ECCs, fuel in Fuels, venduse in vEnduses
    vDmdCon[venduse,fuel,ecc,area,year] = vDmd[venduse,fuel,ecc,area,year]
    vDmdNonCon[venduse,fuel,ecc,area,year] = vDmd[venduse,fuel,ecc,area,year]
  end
  
end

function CanadaIntensity(data,areas,nation)
  (; Areas,ECC,ECCs,Fuel,Fuels,vEnduse,vEnduses,Year,Years) = data
  (; DmdCN,DriverCN,IntensityCN,vDmd,vDmdScrub,vDmdScrubCN,xDriver) = data
  
  for year in Years, ecc in ECCs, fuel in Fuels, venduse in vEnduses
  
    #
    # If national data is not confidential, then use natonal data
    #
    if vDmdScrubCN[venduse,fuel,ecc,nation,year] == 0.0
      DmdCN[venduse,fuel,ecc,year] = sum(vDmd[venduse,fuel,ecc,area,year] for area in areas)
      DriverCN[ecc,year] = sum(xDriver[ecc,area,year] for area in areas)
    
    #
    # Else only use data from areas where data is not confidential
    #
    else
      areasNC = findall(vDmdScrub[venduse,fuel,ecc,areas,year] .== 0.0)
      if !isempty(areasNC)
        DmdCN[venduse,fuel,ecc,year] = sum(vDmd[venduse,fuel,ecc,area,year] for area in areasNC)
        DriverCN[ecc,year] = sum(xDriver[ecc,area,year] for area in areasNC)
      
      #
      # Else no areas have data which is not confidential, write message, and mask data
      #
      else
        @info "All areas confidential $(vEnduse[venduse]) $(Fuel[fuel]) $(ECC[ecc]) $(Year[year])"
        DmdCN[venduse,fuel,ecc,year] = sum(vDmd[venduse,fuel,ecc,area,year] for area in areas)*1.025
        DriverCN[ecc,year] = sum(xDriver[ecc,area,year] for area in areas)*1.000
      end
    end
  end
  
  for year in Years, ecc in ECCs, fuel in Fuels, venduse in vEnduses
    if DriverCN[ecc,year] > 0.0
      IntensityCN[venduse,fuel,ecc,year] = DmdCN[venduse,fuel,ecc,year]/DriverCN[ecc,year]
    end
  end
  
end

function ProvincialTotals(data,areas)
  (; Areas,ECCs,vEnduses,Fuels,Years) = data
  (; vDmd,vDmdArea) = data
  
  for year in Years, area in areas, fuel in Fuels, venduse in vEnduses
    vDmdArea[venduse,fuel,area,year] = sum(vDmd[venduse,fuel,ecc,area,year] for ecc in ECCs)
  end
  
end

function CreateNonConfidentialDemands(data,areas)
  (; Areas,ECC,ECCs,vEnduses,Fuels,Years) = data
  (; IntensityCN,vDmd,vDmdEst,vDmdScrub,xDriver) = data
  
  for year in Years, area in areas, ecc in ECCs, fuel in Fuels, venduse in vEnduses
  
    #
    # If enduse data is not confidential, then use enduse data
    #
    if vDmdScrub[venduse,fuel,ecc,area,year] == 0.0  
      vDmdEst[venduse,fuel,ecc,area,year] = vDmd[venduse,fuel,ecc,area,year]
      
    #
    # Else if Driver is greater than zero, use national intensity
    #
    elseif xDriver[ecc,area,year] > 0.0001
      vDmdEst[venduse,fuel,ecc,area,year] =
          IntensityCN[venduse,fuel,ecc,year]*xDriver[ecc,area,year]
    end
  end
  
end

function AdjustToProvincialTotals(data,areas)
  (; Areas,ECCs,vEnduses,Fuels,Years) = data
  (; vDmdEst,vDmdEstArea,vDmdArea,vDmdNonCon) = data
  
  for year in Years, area in areas, fuel in Fuels, venduse in vEnduses
    vDmdEstArea[venduse,fuel,area,year] = 
      sum(vDmdEst[venduse,fuel,ecc,area,year] for ecc in ECCs)
  end

  for year in Years, area in areas, ecc in ECCs, fuel in Fuels, venduse in vEnduses
    if vDmdEstArea[venduse,fuel,area,year] > 0.0
      vDmdNonCon[venduse,fuel,ecc,area,year] = 
        vDmdEst[venduse,fuel,ecc,area,year]*
        vDmdArea[venduse,fuel,area,year]/
        vDmdEstArea[venduse,fuel,area,year]
    end
  end
end

function SaveNonConfidentialDemands(data,areas)
  (; db) = data
  (; Areas,ECCs,vEnduses,Fuels,Years) = data
  (; vDmd,vDmdNonCon) = data
  
  for year in Years, area in areas, ecc in ECCs, fuel in Fuels, venduse in vEnduses
    vDmd[venduse,fuel,ecc,area,year] = vDmdNonCon[venduse,fuel,ecc,area,year]
  end
 
  WriteDisk(db,"VBInput/vDmd",vDmd)

end

function WriteOutputToCheckResults(data,areas)
  (; Area,AreaDS,Areas,ECCDS,ECCs,vEnduseDS,vEnduses) = data
  (; FuelDS,Fuels,Year,Years,Yrv) = data
  (; IntensityCN,xDriver,vDmdCon,vDmdNonCon,vDmdScrub) = data

  years = collect(Zero:Last)    
  
  iobCN = IOBuffer()
  println(iobCN,"Year;Area;Sector;Fuel;Enduse;vDmdScrub;vDmdCon;vDmdNonCon;Differ;Fraction")
  
  for area in areas
  
     iobArea = IOBuffer()
     println(iobArea,"Year;Area;Sector;Fuel;Enduse;vDmdScrub;vDmdCon;vDmdNonCon;Differ;Fraction")
    
    for year in years, ecc in ECCs, fuel in Fuels, venduse in vEnduses
    
      Scrub  = vDmdScrub[venduse,fuel,ecc,area,year]
      Con    = vDmdCon[venduse,fuel,ecc,area,year]
      NonCon = vDmdNonCon[venduse,fuel,ecc,area,year]
      Differ = NonCon-Con
      @finite_math Fraction = Differ/Con
     
      if Con > 0.00001 || NonCon > 0.00001 || Con < -0.00001 || NonCon < -0.00001
        
        Scrub  = @sprintf("%.4f",Scrub)
        Con    = @sprintf("%.4f",Con)
        NonCon = @sprintf("%.4f",NonCon)
        Differ = @sprintf("%.4f",Differ)
        Fraction = @sprintf("%.4f",Fraction)      
      
        println(iobArea,
          Year[year],";",AreaDS[area],";",ECCDS[ecc],";",FuelDS[fuel],";",vEnduseDS[venduse],";",
          Scrub,";",Con,";",NonCon,";",Differ,";",Fraction)
        
        println(iobCN,
          Year[year],";",AreaDS[area],";",ECCDS[ecc],";",FuelDS[fuel],";",vEnduseDS[venduse],";",
          Scrub,";",Con,";",NonCon,";",Differ,";",Fraction) 
          
      end
    end              

    #
    # Create *.dta filename and write output values
    #
    AreaKey = Area[area]
    filename = "NonConfidentialCheck-$AreaKey.dta"
    open(joinpath(OutputFolder,filename),"w") do filename
      write(filename,String(take!(iobArea)))
    end   
    
  end # for areas
  
  AreaKey = "CN"
  filename = "NonConfidentialCheck-$AreaKey.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iobCN)))
  end   
  
  
end


function NonConfidentialDemands(data)
  (; ANMap,Nation) = data
  
  @info "Canada NonConfidentialDemands"
  
  iob = IOBuffer()

  nation = Select(Nation,"CN")
  areas = findall(ANMap[:,nation] .== 1)  
  
  ExtrapolateScrubVariables(data,areas,nation)  
  InitializeNonConfidentialDemands(data,areas)
  CanadaIntensity(data,areas,nation)
  ProvincialTotals(data,areas)
  CreateNonConfidentialDemands(data,areas)
  AdjustToProvincialTotals(data,areas)
  SaveNonConfidentialDemands(data,areas)
  WriteOutputToCheckResults(data,areas)
end

function DemandControl(db)
  @info "DemandNonConfidential_All.jl - DemandControl"
  data = SControl(; db)
  NonConfidentialDemands(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  DemandControl(DB)
end

end