#
# PlantCharacteristics_SMNR.jl
#
# First available year of 2028. This would mean an online date of 2023
# since the construction delay is 5 years.
# Capital cost of       CN 2019$ 10,700 / kW with a declining rate of 5% per year after 2028.
# Fixed O&M costs of    CN 2019$ 168 / kW/ year
# Variable O&M costs of CN 2019$ 15 / MWh
# Heat rate of 8500 BTU/KWh
# Outage rate of 10%
# Source:
# From: St-LaurentOConnor, John
# Sent: Wednesday, March 11, 2020 3:45 PM
# To: Jeff Amlin
# Subject: ECCC - SMR
#########################
#Alignment to NextGrid Data - John St-Laurent O'Connor - October 2022
#Source is Laurentis Energy Partners contract by Afshin Matin
#GCCCN - 7985 $2018CAD/kW
#UFOMC - 145 $2018CAD/kW/Yr
#UOMC - 0.99 $2018CAD/MWh
#HRtM - 10450 BTu/KWh
#
using EnergyModel

module PlantCharacteristics_SMNR

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") # [Plant,Area] Maximum Project Size (MW)
  PjMnPS::VariableArray{2} = ReadDisk(db,"EGInput/PjMnPS") # [Plant,Area] Minimum Project Size (MW)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Months,Plant,TimePs) = data
  (;PjMax,PjMnPS) = data

  plants=Select(Plant,"Nuclear")

  areas=Select(Area,["ON","QC","BC","AB","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  #
  # Note that UOMC below is now 2.2, instead of 15 as per John's email above.
  # This is because NRCan revised the value for two reasons. First, the
  # value of 15 included fuel-related variable O&M (which should not have
  # been the case in the first place). Second, decommissioning costs have
  # now been excluded altogether. JSLandry; Oct 9, 2020
  #
  # Pushed back earliest online date to 2035 due to the fact that no
  # province has announced concrete plans to build an SMNR and that the
  # technology is unproven in Canada. John St-Laurent O'Connor; Oct 20, 2020.
  #
  #########JSO Change#########
  for area in areas, plant in plants
    PjMnPS[plant,area]=1
    PjMax[plant,area]=1000
  end
  WriteDisk(db,"EGInput/PjMax",PjMax)
  WriteDisk(db,"EGInput/PjMnPS",PjMnPS)

end

function CalibrationControl(db)
  @info "PlantCharacteristics_SMNR.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
