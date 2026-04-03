#
# OGUnitCalibration.jl
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


Base.@kwdef struct OGUnitCalibrationData
  db::String

  OGCode::Vector{String} = ReadDisk(db, "MainDB/OGCode")
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGCode")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  DevSw::VariableArray{2} = ReadDisk(db,"SpInput/DevSw") # [OGUnit,Year] Development Switch
  DevVF::VariableArray{2} = ReadDisk(db,"SpInput/DevVF") # [OGUnit,Year] Development Rate Variance Factor for ROI (Btu/Btu)
  OGCounter::VariableArray{1} = ReadDisk(db,"SpInput/OGCounter") # [Year] Number of OG Units for this Year (Number)
  PdSw::VariableArray{2} = ReadDisk(db,"SpInput/PdSw") # [OGUnit,Year] Production Switch
  PdVF::VariableArray{2} = ReadDisk(db,"SpInput/PdVF") # [OGUnit,Year] Production Rate Variance Factor for ROI (Btu/Btu)

  # Scratch variables
  ZZZ::VariableArray{1} = zeros(Float32, size(Year,1))
end

function OGUnitCalibration_DtaRun(data)
  (; OGCode, Year, Years) = data
  (; DevSw, DevVF, OGCounter, PdSw, PdVF, ZZZ, SceName) = data
  #
  iob = IOBuffer()
  #
  years=collect(Yr(2015):Final)

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the OG Production Units Check.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  loc1=maximum(OGCounter[year] for year in Years)
  ogunits=collect(1:Int(loc1))
  println(iob, "Development Rate Variance Factor (TBtu/TBtu);;", join(Year[years], ";"))
  for ogunit in ogunits
    print(iob, "DevVF;$(OGCode[ogunit])")  
    for year in years
      ZZZ[year] = DevVF[ogunit,year]
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Production Rate Variance Factor (TBtu/TBtu);;", join(Year[years], ";"))
  for ogunit in ogunits
    print(iob, "PdVF;$(OGCode[ogunit])")  
    for year in years
      ZZZ[year] = PdVF[ogunit,year]
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Development Switch;;", join(Year[years], ";"))
  for ogunit in ogunits
    print(iob, "DevSw;$(OGCode[ogunit])")  
    for year in years
      ZZZ[year] = DevSw[ogunit,year]
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Production Switch;;", join(Year[years], ";"))
  for ogunit in ogunits
    print(iob, "PdSw;$(OGCode[ogunit])")  
    for year in years
      ZZZ[year] = PdSw[ogunit,year]
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Create *.dta filename and write output values
  #

  OutFil="OGUnitCalibration-$(SceName).dta"
  open(joinpath(OutputFolder, OutFil), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function OGUnitCalibration_DtaControl(db)

  @info "OGUnitCalibration_DtaControl"
  data = OGUnitCalibrationData(; db)
  OGUnitCalibration_DtaRun(data)

end

if abspath(PROGRAM_FILE) == @__FILE__
OGUnitCalibration_DtaControl(DB)
end



