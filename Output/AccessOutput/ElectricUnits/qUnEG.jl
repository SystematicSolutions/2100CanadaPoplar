#
# qUnEG.jl
#

Base.@kwdef struct qUnEGData
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
  
  qUnEG::VariableArray{4} = ReadDisk(db, "EGOutput/UnEG") # [Unit,TimeP,Month,Year] Generation (GWh)
  qUnEGRef::VariableArray{4} = ReadDisk(RefNameDB, "EGOutput/UnEG") # [Unit,TimeP,Month,Year] Generation (GWh)

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

function qUnEG_AssignConversions(data)
  (; Nation,Month,TimeP,Years,Conversion,Unit,Units,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "GWh"
  UnitsDS[CN] = "GWh"
  
end

function qUnEG_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  (; Month,Months,TimeP,TimePs,Unit,Units,Year) = data
  (; Conversion,UnCode,UnitsDS,qUnEG,qUnEGRef) = data
  
  ZZZ = 0.0
  CCC = 0.0
        
  if UnitPolicy != 0 || UnitReference != 0
  
    for year in years, month in Months, timep in TimePs
    
      if UnitPolicy != 0
        ZZZ = qUnEG[UnitPolicy,timep,month,year]*Conversion[year]
        OutputUnCode = UnCode[UnitPolicy]
      end
      
      if UnitReference != 0
          CCC = qUnEGRef[UnitReference,timep,month,year]*Conversion[year]
        OutputUnCode = UnCode[UnitReference]
      end  
      
      if (ZZZ != 0 || CCC != 0)
          println(iob,"qUnEG;",Year[year],";",Month[month],";",TimeP[timep],";",OutputUnCode,";",UnitsDS[nation],
                    ";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end

    end
  end
end

function qUnEG_DtaRun(data,nation,SceName)
  (; Nation,Units,Year,Years) = data
  (; BaseSw,Conversion,EndTime,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,UnNationRef,qUnEG,qUnEGRef) = data

  if BaseSw != 0
    @. qUnEGRef = qUnEG
    @. UnCodeRef = UnCode
    @. UnNationRef = UnNation
  end

  iob = IOBuffer()
  # [Unit,TimeP,Month,Year] Generation (GWh)
  println(iob,"Variable;Year;Month;TimeP;Unit;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  for CurrentUnit in Units
    UnitPolicy,UnitReference = FindUnitsToOutput(CurrentUnit,nation)
    qUnEG_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "qUnEG-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end # function qUnEG_DtaRun

function qUnEG_DtaControl(db, SceName)
  data = qUnEGData(; db)
  (; Nation)= data
  (; NationOutputMap)= data
  
  @info "qUnEG_DtaControl"

  qUnEG_AssignConversions(data)
  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      qUnEG_DtaRun(data,nation,SceName)
    end
  end
end
