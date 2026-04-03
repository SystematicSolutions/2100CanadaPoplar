#
# UnitParameters.jl
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

Base.@kwdef struct UnitParametersData
  db::String

  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  Yr1985 = 1985 - 1985 + 1
  Yr2007 = 2007 - 1985 + 1
  Yr2010 = 2010 - 1985 + 1
  Final = 2050 - 1985 + 1

  InflationUnit::VariableArray{2} = ReadDisk(db, "MOutput/InflationUnit") #[Unit,Year]  Inflation Index ($/$
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  UnArea::Vector{String} = ReadDisk(db, "EGInput/UnArea") #[Unit] Unit Area
  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEAF::VariableArray{3} = ReadDisk(db, "EGInput/UnEAF") #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
  UnEmit::VariableArray{1} = ReadDisk(db, "EGInput/UnEmit") #[Unit]  Does this Unit Emit Pollution? (1=Yes)
  UnF1::Array{String} = ReadDisk(db, "EGInput/UnF1") #[Unit]  Fuel Source 1
  UnGCCC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCCC") #[Unit,Year]  Generating Unit Capital Cost ($/KW)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{2} = ReadDisk(db, "EGInput/UnHRt") #[Unit,Year]  Heat Rate (BTU/KWh)
  UnMustRun::VariableArray{1} = ReadDisk(db, "EGInput/UnMustRun") #[Unit]  Must Run (1=Must Run)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db, "EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
  UnOR::VariableArray{4} = ReadDisk(db, "EGInput/UnOR") #[Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UnRetire::VariableArray{1} = ReadDisk(db, "EGInput/UnRetire", Final) #[Unit,Year]  Retirement Date (Year)
  UnUFOMC::VariableArray{2} = ReadDisk(db, "EGInput/UnUFOMC") #[Unit,Year]  Fixed O&M Costs ($/Kw/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db, "EGInput/UnUOMC") #[Unit,Year]  Variable O&M Costs ($/Kw/Yr)

end

function UnitParameters_DtaRun(data)
  (; SceName,Month,Unit,Units,Year,Years,Yr1985,Yr2007,Yr2010) = data
  (; InflationUnit,MoneyUnitDS,UnArea,UnCode,UnCogen,UnEAF,UnEmit) = data
  (; UnF1,UnGCCC,UnGC,UnGenCo,UnHRt,UnMustRun,UnName,UnNode) = data
  (; UnOnLine,UnOR,UnOwner,UnPlant,UnRetire,UnUFOMC,UnUOMC) = data

  area1 = 1
  summer = Select(Month,"Summer")
  winter = Select(Month,"Winter")
  UnGCYLoc = zeros(Float32, length(Unit))

  iob = IOBuffer()
  print(iob, "Unit Code;","Plant Name;","Generating Company;","GenCo;","Plant Type;")
  print(iob,   "Node;","Area Name;","Capacity (MW);","Heat Rate (KJ/KWh);","Fixed O&M Costs (", MoneyUnitDS[area1],"2010/KW/Yr);")
  print(iob,   "Variable O&M Costs (", MoneyUnitDS[area1],"2010/MWh);","Capital Costs (", MoneyUnitDS[area1],"2010/KW);")
  print(iob,   "Energy Availibility Factor Summer (MW/MW);")
  print(iob,   "Energy Availibility Factor Winter (MW/MW);","Outage Rate (MW/MW);")
  print(iob,   "OnLine Date;","Retirement Date;","Fuel Source;")
  print(iob,   "Industrial Generation Switch (1=Industrial Generator);")
  print(iob,   "Emitter Switch (1=Emitter);","Must Run Switch (1=Must Run);")
  println(iob)

  for unit in Units
    UnGCYLoc[unit]=maximum(UnGC[unit,year] for year in Years)
    #
    for y in Years
      #
      # Convert from Btu to KJ    
      # 
      UnHRt[unit,y]=UnHRt[unit,y]*1.0546150
      #
      # Convert from 1985$ to 2010 $
      #
      UnUFOMC[unit,y]=UnUFOMC[unit,y]/InflationUnit[unit,Yr1985]*InflationUnit[unit,Yr2010]
      UnUOMC[unit,y]=UnUOMC[unit,y]/InflationUnit[unit,Yr1985]*InflationUnit[unit,Yr2010]
      UnGCCC[unit,y]=UnGCCC[unit,y]/InflationUnit[unit,y]*InflationUnit[unit,Yr2010]
    end
  end

  for unit in Units
    if UnGCYLoc[unit] > 0
      SumUnGC=sum(UnGC[unit,y] for y in Years)
      UnEAF1=sum(UnEAF[unit,summer,y]*UnGC[unit,y] for y in Years)/SumUnGC
      UnEAF2=sum(UnEAF[unit,winter,y]*UnGC[unit,y] for y in Years)/SumUnGC
      UnHRt0=sum(UnHRt[unit,y]*UnGC[unit,y] for y in Years)/SumUnGC
      UnOR0=sum(UnOR[unit,1,1,y]*UnGC[unit,y] for y in Years)/SumUnGC  
      UnUFO0=sum(UnUFOMC[unit,y]*UnGC[unit,y] for y in Years)/SumUnGC
      UnUOM0=sum(UnUOMC[unit,y]*UnGC[unit,y] for y in Years)/SumUnGC  
      UnGCC0=sum(UnGCCC[unit,y]*UnGC[unit,y] for y in Years)/SumUnGC
    else
      UnEAF1=UnEAF[unit,winter,Yr2007]
      UnEAF2=UnEAF[unit,winter,Yr2007]
      UnHRt0=UnHRt[unit,Yr2007]
      UnOR0=UnOR[unit,1,1,Yr2007]
      UnUFO0=0.0
      UnUOM0=0.0
      UnGCC0=0.0
    end
  
    #
    print(iob, UnCode[unit])
    print(iob, ";", UnName[unit])
    print(iob, ";", UnOwner[unit])
    print(iob, ";", UnGenCo[unit])
    print(iob, ";", UnPlant[unit])
    print(iob, ";", UnNode[unit])
    print(iob, ";", UnArea[unit])
    print(iob, ";", @sprintf("%.5f", UnGCYLoc[unit]))
    print(iob, ";", @sprintf("%.5f", UnHRt0))
    print(iob, ";", @sprintf("%.5f", UnUFO0))
    print(iob, ";", @sprintf("%.5f", UnUOM0))
    print(iob, ";", @sprintf("%.5f", UnGCC0))
    print(iob, ";", @sprintf("%.5f", UnEAF1))
    print(iob, ";", @sprintf("%.5f", UnEAF2))
    print(iob, ";", @sprintf("%.5f", UnOR0))
    print(iob, ";", @sprintf("%.f", UnOnLine[unit]))
    print(iob, ";", @sprintf("%.f", UnRetire[unit]))
    print(iob, ";", UnF1[unit])
    print(iob, ";", @sprintf("%.5f", UnCogen[unit]))
    print(iob, ";", @sprintf("%.f", UnEmit[unit]))
    print(iob, ";", @sprintf("%.f", UnMustRun[unit]))
    println(iob)
  end
 
  filename = "UnitParameters-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitParameters_DtaControl(db)
  @info "UnitParameters_DtaControl"
  data = UnitParametersData(; db)
  UnitParameters_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
UnitParameters_DtaControl(DB)
end
