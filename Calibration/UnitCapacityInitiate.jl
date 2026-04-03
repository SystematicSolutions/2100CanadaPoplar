#
# UnitCapacityInitiate.jl - Electric Unit Capacity Initiation
# and Completion
#
using EnergyModel

module UnitCapacityInitiate

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ECalib
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (YEARS)
  DPRSL::VariableArray{2} = ReadDisk(db,"EGInput/DPRSL") # [Area,Year] Straight Line Depreciation Rate (1/Yr)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnGC::VariableArray{2} = ReadDisk(db,"EGOutput/UnGC") # [Unit,Year] Generating Capacity (MW)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnNA::VariableArray{2} = ReadDisk(db,"EGOutput/UnNA") # [Unit,Year] Net Asset Value of Generating Unit (M$)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xInflationUnit::VariableArray{2} = ReadDisk(db,"MInput/xInflationUnit") # [Unit,Year] Inflation Index ($/$)
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)
  xUnGCCC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCC") # [Unit,Year] Generating Unit Capital Cost (Real $/KW)
  xUnGCCI::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCI") # [Unit,Year] Generating Capacity Initiated (MW)
  xUnGCCR::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCR") # [Unit,Year] Exogenous Generating Capacity Completion Rate (MW)
end

function GetUnitSets(data,unit)
  (;Area,Plant,UnArea,UnPlant) = data

  plant = findall(Plant .== UnPlant[unit])
  area =  findall(Area .== UnArea[unit])
return plant,area
end


function UnitCapacityInitiation(data)
  (;Areas,Units,UnPlant,CD,DPRSL,UnGC,xUnGCCC,UnNA) = data
  (;UnOnLine,xInflationUnit,xUnGC,xUnGCCI,xUnGCCR) = data

  for unit in Units

    plant,area = GetUnitSets(data,unit)
    
    if plant != [] && area != []
      plant = plant[1]
      area = area[1]

      # 
      # Units online before model starts
      # 
      if UnOnLine[unit] <= 1986
        UnGC[unit,Yr(1985)] = xUnGC[unit,Yr(1985)]
        for area in Areas
          UnNA[unit,Yr(1985)] = xUnGCCC[unit,Yr(1985)]*
            exp(-DPRSL[area,Yr(1985)]*(1985-UnOnLine[unit]))*xUnGC[unit,Yr(1985)]*xInflationUnit[unit,Yr(1985)]/1000
        end
      end

      for year in Yr(1986):Final
        YrConstr = Int(year-CD[plant,year])
        UnGCDelta = xUnGC[unit,year]-xUnGC[unit,year-1]
        if UnGCDelta < 0.0
          xUnGCCR[unit,year] = UnGCDelta
        elseif YrConstr <= 1.0
          xUnGCCR[unit,year] = UnGCDelta
        elseif (UnGCDelta > 0.0) && (UnPlant[unit] != "Nuclear")
          xUnGCCI[unit,YrConstr] = UnGCDelta
        else
          xUnGCCR[unit,year] = UnGCDelta
        end
      end

    end

  end

end

function ECalibration(db)
  data = ECalib(; db)
  (;UnGC,UnNA,xUnGCCI,xUnGCCR) = data

  UnitCapacityInitiation(data)

  WriteDisk(db,"EGOutput/UnGC",UnGC)
  WriteDisk(db,"EGOutput/UnNA",UnNA)
  WriteDisk(db,"EGInput/xUnGCCI",xUnGCCI)
  WriteDisk(db,"EGInput/xUnGCCR",xUnGCCR)
end

function CalibrationControl(db)
  @info "UnitCapacityInitiate.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
