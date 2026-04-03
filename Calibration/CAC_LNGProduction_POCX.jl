#
# CAC_LNGProduction_POCX.jl - this file calculates the CAC coefficients for the
# industrial sector including the enduse (POCX), cogeneration (CgPOCX),
# non-combustion (FsPOCX), and process (MEPOCX).  JSA 1/11/10
#
using EnergyModel

module CAC_LNGProduction_POCX

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)

  # Scratch Variables
 # TJtoTBtu 'Conversion from TJ to TBtu'
end

function IndCalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;EC,Enduses,FuelEP) = data
  (;Nation,Poll) = data
  (;Years) = data
  (;ANMap,POCX) = data
  
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  
  #*
  #* Set LNGProduction CAC coefficients directly per e-mail from Audrey on 21/10/07
  #* Values from 'tbl_LNG_CAC_Emissions_Intensities.xlsx' - Ian
  #* 

  #*
  #* Input data is in Tonnes per TJ
  #*
  
  TJtoTBtu = 0.000947817
  
  LNGProduction = Select(EC,"LNGProduction")
  NaturalGas = Select(FuelEP,"NaturalGas")
  RNG = Select(FuelEP,"RNG")
  
  NOX = Select(Poll,"NOX")
  SOX = Select(Poll,"SOX")
  COX = Select(Poll,"COX")
  PM25 = Select(Poll,"PM25")
  PM10 = Select(Poll,"PM10")
  PMT = Select(Poll,"PMT")
  VOC = Select(Poll,"VOC") 
  BC = Select(Poll,"BC") 
  
  for enduse in Enduses, area in areas, year in Years
    POCX[enduse,NaturalGas,LNGProduction,NOX,area,year]=0.0404862349/TJtoTBtu
    POCX[enduse,NaturalGas,LNGProduction,SOX,area,year]=0.0054838623/TJtoTBtu
    POCX[enduse,NaturalGas,LNGProduction,COX,area,year]=0.0387172471/TJtoTBtu
    POCX[enduse,NaturalGas,LNGProduction,PM25,area,year]=0.0025473426/TJtoTBtu
    POCX[enduse,NaturalGas,LNGProduction,PM10,area,year]=0.0025473426/TJtoTBtu
    POCX[enduse,NaturalGas,LNGProduction,PMT,area,year]=0.0025473426/TJtoTBtu
    POCX[enduse,NaturalGas,LNGProduction,VOC,area,year]=0.0028244839/TJtoTBtu
    POCX[enduse,NaturalGas,LNGProduction,BC,area,year]=0.00/TJtoTBtu
    
    POCX[enduse,RNG,LNGProduction,NOX,area,year]=0.0404862349/TJtoTBtu
    POCX[enduse,RNG,LNGProduction,SOX,area,year]=0.0054838623/TJtoTBtu
    POCX[enduse,RNG,LNGProduction,COX,area,year]=0.0387172471/TJtoTBtu
    POCX[enduse,RNG,LNGProduction,PM25,area,year]=0.0025473426/TJtoTBtu
    POCX[enduse,RNG,LNGProduction,PM10,area,year]=0.0025473426/TJtoTBtu
    POCX[enduse,RNG,LNGProduction,PMT,area,year]=0.0025473426/TJtoTBtu
    POCX[enduse,RNG,LNGProduction,VOC,area,year]=0.0028244839/TJtoTBtu
    POCX[enduse,RNG,LNGProduction,BC,area,year]=0.00/TJtoTBtu
  end

    WriteDisk(db,"$Input/POCX",POCX)
    
end

function CalibrationControl(db)
  @info "CAC_LNGProduction_POCX.jl - CalibrationControl"

  IndCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
