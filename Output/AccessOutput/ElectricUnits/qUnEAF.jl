#
# qUnEAF.jl
#

Base.@kwdef struct qUnEAFData
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
  
  qUnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
  qUnEAFRef::VariableArray{3} = ReadDisk(RefNameDB,"EGInput/UnEAF") #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)

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

function qUnEAF_AssignConversions(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "MWh/MWh"
  UnitsDS[CN] = "GWh/GWh"
  
end

function qUnEAF_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  (; Month,Months,Year) = data
  (; Conversion,UnCode,UnitsDS,qUnEAF,qUnEAFRef) = data
  
  ZZZ = 0.0
  CCC = 0.0
        
  if UnitPolicy != 0 || UnitReference != 0
  
    for year in years
      for month in Months
    
        if UnitPolicy != 0
          ZZZ = qUnEAF[UnitPolicy,month,year]*Conversion[nation,year]
          OutputUnCode = UnCode[UnitPolicy]
        end
      
        if UnitReference != 0
          CCC = qUnEAFRef[UnitReference,month,year]*Conversion[nation,year]
          OutputUnCode = UnCode[UnitReference]
        end  
      
        if (ZZZ != 0 || CCC != 0)
          println(iob,"qUnEAF;",Year[year],";",Month[month],";",OutputUnCode,";",UnitsDS[nation],
                      ";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
        end
      end         
    end
  end
end

function qUnEAF_DtaRun(data,nation,SceName)
  (; Nation,Units,Year,Years) = data
  (; BaseSw,Conversion,EndTime,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,UnNationRef,qUnEAF,qUnEAFRef) = data

  if BaseSw != 0
    @. qUnEAFRef = qUnEAF
    @. UnCodeRef = UnCode
    @. UnNationRef = UnNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Month;Unit;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  for CurrentUnit in Units
    UnitPolicy,UnitReference = FindUnitsToOutput(CurrentUnit,nation)
    qUnEAF_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "qUnEAF-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end # function qUnEAF_DtaRun

function qUnEAF_DtaControl(db, SceName)
  data = qUnEAFData(; db)
  (; Nation)= data
  (; NationOutputMap)= data
  
  @info "qUnEAF_DtaControl"

  qUnEAF_AssignConversions(data)
  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      qUnEAF_DtaRun(data,nation,SceName)
    end
  end
end
