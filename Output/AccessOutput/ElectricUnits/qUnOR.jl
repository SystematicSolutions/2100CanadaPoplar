#
# qUnOR.jl
#

Base.@kwdef struct qUnORData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
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
  
  qUnOR::VariableArray{4} = ReadDisk(db, "EGInput/UnOR") #[Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
  qUnORRef::VariableArray{4} = ReadDisk(RefNameDB, "EGInput/UnOR") #[Unit,TimeP,Month,Year]  Outage Rate (MW/MW)

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

function qUnOR_AssignConversions(data)
  (; Nation,Month,TimeP,Years,Conversion,Unit,Units,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "MW"
  UnitsDS[CN] = "MW"
  
end

function qUnOR_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  (; Month,Months,TimeP,TimePs,Unit,Units,Year) = data
  (; Conversion,UnCode,UnitsDS,qUnOR,qUnORRef) = data
  
  ZZZ = 0.0
  CCC = 0.0
        
  if UnitPolicy != 0 || UnitReference != 0
  
    for year in years, month in Months, timep in TimePs
    
      if UnitPolicy != 0
        ZZZ = qUnOR[UnitPolicy,timep,month,year]*Conversion[nation,year]
        OutputUnCode = UnCode[UnitPolicy]
      end
      
      if UnitReference != 0
        CCC = qUnORRef[UnitReference,timep,month,year]*Conversion[nation,year]
        OutputUnCode = UnCode[UnitReference]
      end  
      
      if (ZZZ != 0 || CCC != 0)
          println(iob,"zUnOR;",Year[year],";",OutputUnCode,";",UnitsDS[nation],
                    ";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end
      
    end
  end
end

function qUnOR_DtaRun(data,nation,SceName)
  (; Nation,Units,Year,Years) = data
  (; BaseSw,Conversion,EndTime,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,UnNationRef,qUnOR,qUnORRef) = data

  if BaseSw != 0
    @. qUnORRef = qUnOR
    @. UnCodeRef = UnCode
    @. UnNationRef = UnNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Unit;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  for CurrentUnit in Units
    UnitPolicy,UnitReference = FindUnitsToOutput(CurrentUnit,nation)
    qUnOR_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "qUnOR-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end # function qUnOR_DtaRun

function qUnOR_DtaControl(db, SceName)
  data = qUnORData(; db)
  (; Nation)= data
  (; NationOutputMap)= data
  
  @info "qUnOR_DtaControl"

  qUnOR_AssignConversions(data)
  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      qUnOR_DtaRun(data,nation,SceName)
    end
  end
end
