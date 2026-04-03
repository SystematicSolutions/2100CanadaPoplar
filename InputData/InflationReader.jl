#
# InflationReader.jl
#

include("../Core/Core.jl") 

db=DatabaseName 

startDirectory = pwd()

startLength=length(startDirectory)
rootLength=startLength-10
modelRoot=SubString(startDirectory,1,rootLength) * "\\"
println("modelRoot " * modelRoot)
  


Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  NationTOM::SetArray = ReadDisk(db,"KInput/NationTOMKey")
  NationTOMs::Vector{Int} = collect(Select(NationTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation")  # [Nation,Year]  Inflation Index ($/$)
end



#After we read TOM initial/process DB

#Have Julia read the code and spit out a dat file.

function MakeCurrencyDatFile(db)
  data = MControl(; db)
  (; xExchangeRateNation,xInflationNation, Years, Nations,NationDS) = data
  ModelDBName="MInput" 
  
  VariableName="xInflationNation"
  FullName=ModelDBName * "/" * VariableName
  inputVariable = xInflationNation
  datFileName=modelRoot * "InputData\\Process\\" * VariableName * ".dat"
  MakeDatFile(datFileName,inputVariable,VariableName)
  
  VariableName="xExchangeRateNation"
  FullName=ModelDBName * "/" * VariableName
  inputVariable = xExchangeRateNation
  datFileName=modelRoot * "InputData\\Process\\" * VariableName * ".dat"
  MakeDatFile(datFileName,inputVariable,VariableName)
end

function MakeDatFile(datFileName,inputVariable,VariableName)
  data = MControl(; db)
  (; xInflationNation, Years, Nations,NationDS) = data
  
  if isfile(datFileName)
    rm(datFileName, force=true)
  end  
  
  
  datFile = open(datFileName, "a")
  write(datFile, "Variable;Area;Year;Units;Data" * "\n")
  for nation in Nations, year in Years
    dataString=string(inputVariable[nation,year])
    yearAdjust=(Years[year])+1984
    if yearAdjust < 2051
      write(datFile, VariableName * ";" * NationDS[nation] * ";" * string(yearAdjust) * ";" * "Dollar/Dollar" * ";" * "$dataString" * "\n" )
    end  
    
  end
  close(datFile)
end
    
function InputDataControl(db)
  @time MakeCurrencyDatFile(db)
end


function Control(db)
  @info "InflationReader.jl - Control"
  InputDataControl(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
  println("Dat files created!")
end

  
         

