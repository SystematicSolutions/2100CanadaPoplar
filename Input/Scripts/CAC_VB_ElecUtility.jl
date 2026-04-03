#
# CAC_VB_ElecUtility.jl - VBInput Electric Utility Pollution
#
using EnergyModel

module CAC_VB_ElecUtility

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "EGCalDB"
  Input::String = "EGInput"
  Outpt::String = "EGOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation

  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  vEUPOCX::VariableArray{5} = ReadDisk(db,"VBInput/vEUPOCX") # [FuelEP,Plant,Poll,vArea,Year] Electric Pollution Coefficient (Tonnes/TBtu)

  # Scratch Variables
  POCXAvg::VariableArray{1} = zeros(Float32,length(Poll)) # [Poll] Input Pollution Coefficient Average (Tonnes/TBtu)
end

function ReadVBInput(db)
  data = EControl(; db)
  (;Area,FuelEPs) = data
  (;Plants,Poll) = data
  (;vAreas,vAreaMap) = data
  (;POCX,vEUPOCX) = data

  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  CACs = Select(Poll,["SOX","COX","NOX","VOC","PMT","PM10","PM25","Hg","NH3","BC"])
  #
  # vEUPOCX.dat has values only for 2020 to avoid memory limitations. Apply these
  # values to all future years
  #
  years = collect(Future:Final)
  @info "EUPOCX"

  for fuelep in FuelEPs, plant in Plants, poll in CACs, area in AreasCanada, year in years
    varea = findall(x -> x == 1.0,vAreaMap[vAreas,area])
    if varea != []
      varea = varea[1]
      POCX[fuelep,plant,poll,area,year]=vEUPOCX[fuelep,plant,poll,varea,Yr(2020)]
    end
  end
  WriteDisk(db,"EGInput/POCX",POCX)


end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Areas,FuelEPs) = data
  (;Plants,Poll) = data

  ReadVBInput(db)
  years = collect(Future:Final)
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  CACs = Select(Poll,["NH3","BC","COX","Hg","NOX","PM10","PM25","PMT","SOX","VOC"])

  # TODOPromulaExtra This section appears to have been breaking POCX for all areas, and
  # without it present, Julia matches Promula. Luke - 11.04.24

  # # Add new defaults for AB OG Plants per e-mail from Andy - Ian 20/10/20
  # # "I took an average of the emission coefficients across all Alberta plants and so,
  # # the emission coefficients do stay consistent over time" - E-mail from Andy, 20.10.19
  # #
  # #  Input values are in KT/TBtu except for Hg, which is Kg/TBtu

  # TempData=
  #   "NH3         0.0000139
  #   BC           0.0003196
  #   COX          0.1197385
  #   Hg           0.0339113
  #   NOX          0.1010606
  #   PM10         0.0008344
  #   PM25         0.0008011
  #   PMT          0.0009109
  #   SOX          0.0000911
  #   VOC          0.0049485"

  # for row in split(TempData,'\n')
  #   #
  #   # Separate the elements in each row
  #   #
  #   row_values = strip.(split(row,'\t'))
  #   row_values = split(row,'\t')
  #   row_values = [split(value) for value in row_values]
  #   #
  #   # Use the elements to select the sets
  #   #
  #   p = [string(row_values[1][1])]
  #   poll = Select(Poll,p)
  #   POCXAvg[poll]= parse.(Float32,row_values[1][2:2])
  # end
  # #
  # # Kilotonnes to Tonnes
  # #
  # for poll in CACs
  #   POCXAvg[poll]=POCXAvg[poll]*1000
  # end
  # #
  # # Grams to Tonnes
  # #
  # Hg=Select(Poll,["Hg"])
  # POCXAvg[Hg]=POCXAvg[Hg]/1e6
  # #
  # # Assume emissions are applied to Natural Gas FuelEP and POCX to OG units
  # #
  # areas = Select(Area,"AB")
  # fueleps = Select(FuelEP,"NaturalGas")
  # plants = Select(Plant,["OGCC","OGCT","SmallOGCC","OGSteam"])

  # for year in Years, area in areas, poll in CACs,plant in plants, fuelep in fueleps
  #   if POCX[fuelep,plant,poll,area,year] == 0.0
  #     POCX[fuelep,plant,poll,area,year]=POCXAvg[poll]
  #   end
  # end
  # WriteDisk(db,"EGInput/POCX",POCX)

end

function CalibrationControl(db)
  @info "CAC_VB_ElecUtility.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
