#
# qUnPol.jl
#

Base.@kwdef struct qUnPolData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCodeRef::Array{String} = ReadDisk(RefNameDB,"EGInput/UnCode") # [Unit] Unit Code
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") #[Year]  Number of Units
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNationRef::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  
  qUnPol::VariableArray{4} = ReadDisk(db,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution (Tonnes)
  qUnPolRef::VariableArray{4} = ReadDisk(RefNameDB,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution (Tonnes)

  #
  # Scratch Variables for Unit selection between Reference and Policy
  #
  Conversion = zeros(Float32,length(Nation),length(Year)) # [Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  # CurrentUnit   'Pointer to the Unit being Processed (Number)'
  # OutputUnCode   'Code for the Unit being Output (Number)',  Type=String(20)
  # PolicyUnit    'Pointer to Policy Unit (Number)'
  # ReferenceUnit 'Pointer to Reference Unit (Number)'

end

function qUnPol_AssignConversions(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Tonnes"
  UnitsDS[CN] = "Tonnes"
  
end

function qUnPol_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  (; FuelEP,FuelEPDS,FuelEPs,Poll,PollDS,Polls,Year) = data
  (; Conversion,UnCode,UnitsDS,qUnPol,qUnPolRef) = data
  
  ZZZ = 0.0
  CCC = 0.0
        
  if UnitPolicy != 0 || UnitReference != 0
  
    for year in years, poll in Polls, fuelep in FuelEPs
    
      if UnitPolicy != 0
        ZZZ = qUnPol[UnitPolicy,fuelep,poll,year]*Conversion[nation,year]
        OutputUnCode = UnCode[UnitPolicy]
      end
      
      if UnitReference != 0
        CCC = qUnPolRef[UnitReference,fuelep,poll,year]*Conversion[nation,year]
        OutputUnCode = UnCode[UnitReference]
      end  
      
      if (ZZZ != 0 || CCC != 0)
        println(iob,"qUnPol;",Year[year],";",PollDS[poll],";",FuelEPDS[fuelep],";",OutputUnCode,
                ";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end
      
    end
  end
end

function qUnPol_DtaRun(data,nation,SceName)
  (; Nation,Units,Year,Years) = data
  (; BaseSw,Conversion,EndTime,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,UnNationRef,qUnPol,qUnPolRef) = data

  if BaseSw != 0
    @. qUnPolRef = qUnPol
    @. UnCodeRef = UnCode
    @. UnNationRef = UnNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Poll;FuelEP;Unit;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  for CurrentUnit in Units
    UnitPolicy,UnitReference = FindUnitsToOutput(CurrentUnit,nation)
    qUnPol_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "qUnPol-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end # function qUnPol_DtaRun

function qUnPol_DtaControl(db, SceName)
  data = qUnPolData(; db)
  (; Nation)= data
  (; NationOutputMap)= data
  
  @info "qUnPol_DtaControl"

  qUnPol_AssignConversions(data)
  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      qUnPol_DtaRun(data,nation,SceName)
    end
  end
end
