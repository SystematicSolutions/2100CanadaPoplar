#
# CAC_H2Coefficients.jl
#
############################################################
#                                                          #
#                       NOTICE                             #
#                                                          #
#  The ENERGY 2100 model is available by contacting        #
#  Systematic Solutions, Inc. (Telephone:937-767-1873).    #
#  The ENERGY 2100 model and all associated software are   #
#  the property of Systematic Solutions, Inc. and cannot   #
#  be distributed to others without the expressed          #
#  permission of Systematic Solutions, Inc. Any modified   #
#  ENERGY 2100-related software must include this notice   #
#  along with a designation stating who made the revision, #
#  the general focus of the revision, and the date of the  #
#  revision.                                               #
#                                                          #
#                                 March 27, 2006           #
#                                                          #
############################################################
#
#    Systematic Solutions, Inc.
#
#        Version: September 2010
#
# CAC_H2Coefficients.jl 
#
using EnergyModel

module CAC_H2Coefficients

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Res_CAC_H2CoefficientsData
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
end

function Res_CAC_H2CoefficientsDataCalibration(db)
  data = Res_CAC_H2CoefficientsData(; db)
  (;Input) = data
  (;ECs,Enduses,FuelEP) = data
  (;Nation,Poll) = data
  (;ANMap,POCX) = data

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  years = collect(Future:Final)

# *
# * From Audrey 21/09/28 e-mail, "Use a coefficient for NOx in the demand sectors 
# * that is 85% higher than equivalent NG values" 
# *
# * Setting Coefficients for H2 equal to NG for the residential sector based on recent research that points to 
# * Equal or lower emissions with H2 blending. Audrey 22/10/19
# *
  
  NOX = Select(Poll,"NOX")
  Hydrogen = Select(FuelEP,"Hydrogen")
  NaturalGas = Select(FuelEP, "NaturalGas")
  
  for enduse in Enduses, ec in ECs, area in areas, year in years
    POCX[enduse,Hydrogen,ec,NOX,area,year]=POCX[enduse,NaturalGas,ec,NOX,area,year]
  end
  
  WriteDisk(db,"$Input/POCX",POCX)
  
end

Base.@kwdef struct Com_CAC_H2CoefficientsData
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
end

function Com_CAC_H2CoefficientsDataCalibration(db)
  data = Com_CAC_H2CoefficientsData(; db)
  (;Input) = data
  (;ECs,Enduses,FuelEP) = data
  (;Nation,Poll) = data
  (;ANMap,POCX) = data

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  years = collect(Future:Final)

#*
#* From Audrey 21/09/28 e-mail, "Use a coefficient for NOx in the demand sectors 
#* that is 85% higher than equivalent NG values" 
#*
#* Change value to 35% higher than equivalent NG values based on recent research. Audrey 22/11/15
#*
  
  NOX = Select(Poll,"NOX")
  Hydrogen = Select(FuelEP,"Hydrogen")
  NaturalGas = Select(FuelEP, "NaturalGas")
  
  for enduse in Enduses, ec in ECs, area in areas, year in years
    POCX[enduse,Hydrogen,ec,NOX,area,year]=POCX[enduse,NaturalGas,ec,NOX,area,year]*1.35
  end
  
  WriteDisk(db,"$Input/POCX",POCX)
  
end

Base.@kwdef struct Ind_CAC_H2CoefficientsData
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
end

function Ind_CAC_H2CoefficientsDataCalibration(db)
  data = Ind_CAC_H2CoefficientsData(; db)
  (;Input) = data
  (;ECs,Enduses,FuelEP) = data
  (;Nation,Poll) = data
  (;ANMap,POCX) = data

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  years = collect(Future:Final)

#*
#* From Audrey 21/09/28 e-mail, "Use a coefficient for NOx in the demand sectors 
#* that is 85% higher than equivalent NG values" 
#*
#* Change value to 35% higher than equivalent NG values based on recent research. Audrey 22/11/15
#*
  
  NOX = Select(Poll,"NOX")
  Hydrogen = Select(FuelEP,"Hydrogen")
  NaturalGas = Select(FuelEP, "NaturalGas")
  
  for enduse in Enduses, ec in ECs, area in areas, year in years
    POCX[enduse,Hydrogen,ec,NOX,area,year]=POCX[enduse,NaturalGas,ec,NOX,area,year]*1.35
  end
  
  WriteDisk(db,"$Input/POCX",POCX)
  
end

function CalibrationControl(db)
  @info "CAC_H2Coefficients.jl - CalibrationControl"
  Res_CAC_H2CoefficientsDataCalibration(db)
  Com_CAC_H2CoefficientsDataCalibration(db)
  Ind_CAC_H2CoefficientsDataCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
