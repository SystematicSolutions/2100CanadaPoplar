#
# UnitCapacityFactors.jl
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

Base.@kwdef struct UnitCapacityFactorsData
  db::String

  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  Months::Vector{Int}    = collect(Select(Month))
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  Yr2005 = Yr(2005)

  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEAF::VariableArray{2} = ReadDisk(db, "EGInput/UnEAF", Yr2005) #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  # UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") #[Unit]  Generating Company
  # UnHRt::VariableArray{1} = ReadDisk(db, "EGInput/UnHRt", Final) #[Unit,Year]  Heat Rate (BTU/KWh)
  UnMustRun::VariableArray{1} = ReadDisk(db, "EGInput/UnMustRun") #[Unit]  Must Run (1=Must Run)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOOR::VariableArray{1} = ReadDisk(db, "EGCalDB/UnOOR", Yr2005) #[Unit,Year]  Operational Outage Rate (MW/MW)
  UnOR::VariableArray{3} = ReadDisk(db, "EGInput/UnOR", Yr2005) # [Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPCF::VariableArray{2} = ReadDisk(db, "EGOutput/UnPCF") #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  xUnEGA::VariableArray{2} = ReadDisk(db, "EGInput/xUnEGA") #[Unit,Year]  Historical Unit Generation
  xUnGC::VariableArray{2} = ReadDisk(db, "EGInput/xUnGC") #[Unit,Year]  Generating Capacity (MW)

  UnGCYLoc = zeros(Float32, length(Unit))
  xUnPCF = zeros(Float32, length(Unit), length(Year))
  ZZZ = zeros(Float32, length(Year))
end

function UnitCapacityFactors_DtaRun(data)
  (; SceName,Unit,Year, Units) = data
  (; UnCode,UnCogen,UnEAF,UnGC,UnGCYLoc,UnMustRun,UnName,UnNode) = data
  (; UnOOR,UnOR,UnOwner,UnPCF,UnPlant,xUnEGA,xUnGC,xUnPCF,ZZZ) = data
  
  years = collect(Yr(1997):Yr(2004))
  for year in years, unit in Units
    @finite_math xUnPCF[unit,year]=xUnEGA[unit,year]/xUnGC[unit,year]/(8760/1000)
    UnPCF[unit,year]=xUnPCF[unit,year]
  end
  
  years = collect(Yr(2004):Yr(2050))
  for unit in Units
    UnGCYLoc[unit] = maximum(UnGC[unit,year] for year in years)
  end
  
  timep = 1
  month = 1  
  years = collect(Yr(2004):Yr(2050))
  iob = IOBuffer()
  print(iob, "Unit Code; Owner; Plant Name; Plant Type; Node;Capacity;")
  print(iob, "Energy Avail Factor; Outage Rate; Outage Rate Adjustment; Ind Cogen; Must Run")
  for year in years
    print(iob,";",Year[year]," Capacity Factor")
  end
  println(iob)

  for unit in Units
    # if UnGCYLoc[unit] > 0.0
      print(iob,UnCode[unit])
      print(iob,";",UnOwner[unit])
      print(iob,";",UnName[unit])
      print(iob,";",UnPlant[unit])
      print(iob,";",UnNode[unit])
      print(iob,";",@sprintf("%.5f",UnGCYLoc[unit]))
      print(iob,";",@sprintf("%.5f",UnEAF[unit]))
      print(iob,";",@sprintf("%.5f",UnOR[unit,timep,month]))
      print(iob,";",@sprintf("%.5f",UnOOR[unit]))
      print(iob,";",Int(UnCogen[unit]))
      print(iob,";",@sprintf("%.5f",UnMustRun[unit]))
      for year in years
        ZZZ[year] = UnPCF[unit,year]
        print(iob,";",@sprintf("%.5f",ZZZ[year]))
      end
      println(iob)
    #end
  end
 
  filename = "UnitCapacityFactors-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitCapacityFactors_DtaControl(db,)
  @info "UnitCapacityFactors_DtaControl"
  data = UnitCapacityFactorsData(; db)

  UnitCapacityFactors_DtaRun(data)

end

if abspath(PROGRAM_FILE) == @__FILE__
UnitCapacityFactors_DtaControl(DB)
end

