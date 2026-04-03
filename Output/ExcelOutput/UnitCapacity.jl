#
# UnitCapacity.jl
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

Base.@kwdef struct UnitCapacityData
  db::String

  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  Yr2008 = 2008 - 1985 + 1
  Final = 2050 - 1985 + 1

  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEAF::VariableArray{2} = ReadDisk(db, "EGInput/UnEAF", Final) #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
  # UnEGA::VariableArray{1} = ReadDisk(db, "EGOutput/UnEGA", year) #[Unit,Year]  Generation (GWh)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{1} = ReadDisk(db, "EGInput/UnHRt", Final) #[Unit,Year]  Heat Rate (BTU/KWh)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db, "EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
  UnOR::VariableArray{3} = ReadDisk(db, "EGInput/UnOR", Final) # [Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
  UnOwner::Vector{String} = ReadDisk(db, "EGInput/UnOwner") #[Unit]  Generating Company
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UnRetire::VariableArray{1} = ReadDisk(db, "EGInput/UnRetire", Final) #[Unit,Year]  Retirement Date (Year)
  xUnEGA::VariableArray{1} = ReadDisk(db, "EGInput/xUnEGA", Yr2008) #[Unit,Year]  Historical Unit Generation
end

function UnitCapacity_DtaRun(data)
  (; SceName,Unit,Year) = data
  (; UnCode,UnCogen,UnEAF,UnGC,UnGenCo,UnHRt,UnName,UnNode) = data
  (; UnOnLine,UnOR,UnOwner,UnPlant,UnRetire,xUnEGA) = data


  iob = IOBuffer()

  UnGCYLoc = zeros(Float32, length(Unit))
  UnGCLoc = zeros(Float32, length(Unit), length(Year))
  ZZZ = zeros(Float32, length(Year))
  
  month = 1
  units = Select(Unit)
  years = Select(Year, (from = "1990", to = "2050"))

  print(iob, "Unit Code;Owner;Plant Name;Plant Type;Node;OnLine Date;Retirement Date;Heat Rate;")
  print(iob, "Energy Avail Factor;Outage Rate;Ind Cogen;2008 GWh;Max. Capacity (MW)")
  for year in years
    print(iob,";",Year[year]," MW")
  end
  println(iob)

  for unit in units
    UnGCYLoc[unit] = maximum(UnGC[unit,year] for year in years)
    UnHRt[unit] = UnHRt[unit]*1.0546150
  end

  for year in years, unit in units
    if (UnOnLine[unit] <= parse(Int,Year[year])) && (UnRetire[unit] > parse(Int,Year[year]))
      UnGCLoc[unit,year] = UnGC[unit,year]
    end
  end

  #
  for unit in units
    # if UnGCYLoc[unit] > 0.0
      print(iob,UnCode[unit])
      print(iob,";",UnOwner[unit])
      print(iob,";",UnName[unit])
      print(iob,";",UnPlant[unit])
      print(iob,";",UnNode[unit])
      print(iob,";",Int(UnOnLine[unit]))
      print(iob,";",Int(UnRetire[unit]))
      print(iob,";",@sprintf("%.5f",UnHRt[unit]))
      print(iob,";",@sprintf("%.5f",UnEAF[unit]))
      print(iob,";",@sprintf("%.5f",UnOR[unit,1,1]))
      print(iob,";",Int(UnCogen[unit]))
      print(iob,";",@sprintf("%.5f",xUnEGA[unit]))
      print(iob,";",@sprintf("%.5f",UnGCYLoc[unit]))
      for year in years
        ZZZ[year]=UnGCLoc[unit,year]
        print(iob,";",@sprintf("%.5f",ZZZ[year]))
      end
      println(iob)
    # end
  end
 
  filename = "UnitCapacity-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitCapacity_DtaControl(db)
  @info "UnitCapacity_DtaControl"
  data = UnitCapacityData(; db)

  UnitCapacity_DtaRun(data)

end
if abspath(PROGRAM_FILE) == @__FILE__
UnitCapacity_DtaControl(DB)
end
