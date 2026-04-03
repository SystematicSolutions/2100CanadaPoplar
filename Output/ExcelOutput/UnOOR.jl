#
# UnOOR.jl
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

Base.@kwdef struct UnOORData
  db::String

  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  Months::Vector{Int}    = collect(Select(Month))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  Yr2004 = 2004 - 1985 + 1
  Yr2010 = Yr(2010)  

  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEAF::VariableArray{2} = ReadDisk(db, "EGInput/UnEAF",Yr2010) #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnHRt::VariableArray{1} = ReadDisk(db,"EGInput/UnHRt",Yr2010) #[Unit,Year]  Heat Rate (BTU/KWh)
  UnMustRun::VariableArray{1} = ReadDisk(db, "EGInput/UnMustRun") #[Unit]  Must Run (1=Must Run)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOOR::VariableArray{2} = ReadDisk(db, "EGCalDB/UnOOR") #[Unit,Year]  Operational Outage Rate (MW/MW)
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPCF::VariableArray{2} = ReadDisk(db, "EGOutput/UnPCF") #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  xUnEGA::VariableArray{1} = ReadDisk(db, "EGInput/xUnEGA",Yr2004) #[Unit,Year]  Historical Unit Generation
  xUnGC::VariableArray{2} = ReadDisk(db, "EGInput/xUnGC") #[Unit,Year]  Generating Capacity (MW)
  
  #
  # Scratch Variables
  #
  UnGCYLoc = zeros(Float32, length(Unit))
  ZZZ = zeros(Float32, length(Year))  
end

function UnOOR_DtaRun(data)
  (; Unit,Year, Units,SceName) = data
  (; UnCode,UnCogen,UnEAF,UnHRt,UnGC,UnGCYLoc,UnName,UnNode) = data
  (; UnOOR,UnOwner,UnPlant,xUnEGA,xUnGC,ZZZ) = data

  years = collect(Yr(2004):Yr(2050))
  for unit in Units
    UnGCYLoc[unit] = maximum(UnGC[unit,year] for year in years)
  end  
  
  years = collect(Yr(2010):Yr(2050))
  
  iob = IOBuffer()
  print(iob, "Unit Code;Owner;Plant Name;Plant Type;Node;Capacity;")
  print(iob, "Heat Rate;Energy Avail Factor;Ind Cogen;2004 GWH")
  for year in years
    print(iob,";",Year[year]," MW/MW")
  end
  println(iob)
        
  for unit in Units
    # if UnGCYLoc[unit] > 0.0
      print(iob,UnCode[unit])
      print(iob,";",UnOwner[unit])
      print(iob,";",UnName[unit])
      print(iob,";",UnPlant[unit])
      print(iob,";",UnNode[unit])
      print(iob,";",@sprintf("%.5f", UnGCYLoc[unit]))
      print(iob,";",@sprintf("%.5f", UnHRt[unit]))
      print(iob,";",@sprintf("%.5f", UnEAF[unit,1]))
      print(iob,";",Int(UnCogen[unit]))
      print(iob,";",@sprintf("%.5f",xUnEGA[unit]))
      for year in years
        ZZZ[year] = UnOOR[unit,year]
        print(iob,";",@sprintf("%.5f",ZZZ[year]))
      end
      println(iob)
    # end
  end
 
  filename = "UnOOR-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnOOR_DtaControl(db)
  @info "UnOOR_DtaControl"
  data = UnOORData(; db)

  UnOOR_DtaRun(data)

end
if abspath(PROGRAM_FILE) == @__FILE__
UnOOR_DtaControl(DB)
end
