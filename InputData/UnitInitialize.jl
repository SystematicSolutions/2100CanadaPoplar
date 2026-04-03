#
# UnitInitialize.jl
#

include("../Core/Core.jl") 

db=DatabaseName 

startDirectory = pwd()

startLength=length(startDirectory)
rootLength=startLength-10
ModelRoot=SubString(startDirectory,1,rootLength) * "\\"
println("modelRoot " * ModelRoot)
  
#read in UnCodes from CN vUnArea
#add codes from US
#Read set size file for total Units
#add nulls to unit set size
#fix hard code in datareader
UnCodesToStore::Vector{String}=[]

function FillCodeList(DatFileName)
  
  open(DatFileName) do uncodes
    for line in eachline(uncodes)
     
        
      lineSplit = split(line, ";")
      CodeInFile = String(lineSplit[2])
       if CodeInFile!=="Unit"
      push!(UnCodesToStore,CodeInFile)
      #println(CodeInFile)
      end
      
    end
  end
end


function MakeUnitSet()
  VariableName="vUnArea"
  DatFileName= ModelRoot * "InputData\\vData_ElectricUnits_CN\\" * VariableName * ".dat"
  FillCodeList(DatFileName)
  DatFileName= ModelRoot * "InputData\\vData_ElectricUnits_US\\" * VariableName * ".dat"
  FillCodeList(DatFileName)
  OutputCSV()
  #println(UnCodesToStore)
end

function OutputCSV()
  UnitCsvName= ModelRoot * "DataBase\\Sets\\" * "Unit.csv"
  if isfile(UnitCsvName)
    rm(UnitCsvName, force=true)
  end  
  
  UnitCSV = open(UnitCsvName, "a")
  
  for unCode in UnCodesToStore
    write(UnitCSV, unCode * "," * unCode * "\n")
  end
  CountUnCode=length(UnCodesToStore)
  println("CountUnCode $CountUnCode")
  NullsNeeded = 4000 - CountUnCode
  println("NullsNeeded $NullsNeeded")
  startIndex=(CountUnCode+1)
  println("startIndex $startIndex")
  units = collect(startIndex:4000)
  
  for unitIndex in units
  #  println("unitIndex $unitIndex")
    write(UnitCSV, "Null" * "," * "Null" * "\n")
  end
  close(UnitCSV)
  
  #todo todo dont forget nulls
  # get size from SetSize 
  # add nulls for SetSize - size of UnCodesToStore
end


function MakeDatFile(datFileName,inputVariable,VariableName)
  
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
    
function CreateUnitSet()
  @time MakeUnitSet()
end


function Control()
  @info "UnitInitialize.jl - Control"
  CreateUnitSet()
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control()
  println("Unit Set Created!")
end

  
         

