#
# UnitDataPatch_US.jl
#
using EnergyModel

module UnitDataPatch_US

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  EAF::VariableArray{4} = ReadDisk(db,"EGInput/EAF") # [Plant,Area,MONTH,Year] Energy Avaliability Factor (MWh/MWh)
  GCCCN::VariableArray{3} = ReadDisk(db,"EGInput/GCCCN") # [Plant,Area,Year] Overnight Construction Costs ($/KW)
  HRtM::VariableArray{3} = ReadDisk(db,"EGInput/HRtM") # [Plant,Area,Year] Marginal Heat Rate (Btu/KWh)
  ORNew::VariableArray{5} = ReadDisk(db,"EGInput/ORNew") # [Plant,Area,TimeP,Month,Year]  Outage Rate for New Plants (MW/MW)
  UFOMC::VariableArray{3} = ReadDisk(db,"EGInput/UFOMC") # [Plant,Area,Year] Unit Fixed O&M Costs ($/KW)
  UOMC::VariableArray{3} = ReadDisk(db,"EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs ($/MWh)
  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Avaliability Factor (MWh/MWh)
  UnEffStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnEffStorage") # [Unit] Storage Efficiency (GWH/GWH)
  xUnGCCC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCC") # [Unit,Year] Generating Unit Capital Cost (Real $/KW)
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run (1=Must Run)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") # [Unit] Storage Switch (1=Storage Unit)
  UnUFOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUFOMC") # [Unit,Year] Fixed O&M Costs (Real $/KW/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUOMC") # [Unit,Year] Variable O&M Costs (Real $/MWH)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)

  # Scratch Variables
 # IsValid    'Boolean'
  MaxHeatRateThreshold::VariableArray{1} = zeros(Float32,length(Plant)) # [Plant] Maximum Heat Rate threshold (Btu/KWh)
  MinHeatRateThreshold::VariableArray{1} = zeros(Float32,length(Plant)) # [Plant] Minimum Heat Rate threshold (Btu/KWh)
end

function GetUnitSets(data,unit)
  (;Area,Plant) = data
  (;UnArea,UnPlant) = data

  #
  # This procedure selects the sets for a particular unit
  #
  if (UnPlant[unit] != "Null") && (UnArea[unit] != "Null")
    plant = Select(Plant,UnPlant[unit])
    area = Select(Area,UnArea[unit])
    valid = true
  else
    plant=1
    area=1
    valid = false
  end
  return plant,area,valid
end

# function ResetUnitSets(data)
# end

function ECalibration(db)
  data = EControl(; db)
  (;Months,Plant,TimePs) = data
  (;Years) = data
  (;UnPlant,GCCCN,HRtM,ORNew,UFOMC,UOMC) = data
  (;UnEAF,UnEffStorage,xUnGCCC,UnHRt,UnMustRun,UnNation,UnOR,UnStorage,UnUFOMC,UnUOMC) = data
  (;xUnEGA,xUnGC) = data
  (;MaxHeatRateThreshold,MinHeatRateThreshold) = data

  @. MinHeatRateThreshold= 3412
  @. MaxHeatRateThreshold=15000
  plants=Select(Plant,["Biomass","Biogas"])
  for plant in plants
    MaxHeatRateThreshold[plant]=20000
  end

  #
  # Select US Units
  #
  units=findall(UnNation[:] .== "US")
  for unit in units
    plant,area,valid=GetUnitSets(data,unit)
    if valid == true
      for year in Years
        if xUnGCCC[unit,year] == 0.0
          xUnGCCC[unit,year]=GCCCN[plant,area,year]
        end
      end
      years=collect(Zero:Yr(2016))
      for year in years
        xUnGCCC[unit,year]=0.0
      end
      for year in Years
        if UnHRt[unit,year] < MinHeatRateThreshold[plant]
          UnHRt[unit,year]=HRtM[plant,area,year]
        elseif UnHRt[unit,year] > MaxHeatRateThreshold[plant]
          UnHRt[unit,year]=MaxHeatRateThreshold[plant]
        end
        for month in Months, timep in TimePs
          if UnOR[unit,timep,month,year] == 0
            UnOR[unit,timep,month,year]=ORNew[plant,area,timep,month,year]
          end
        end
        if UnUFOMC[unit,year] == 0
          UnUFOMC[unit,year]=UFOMC[plant,area,year]
        end
        if UnUOMC[unit,year] == 0
          UnUOMC[unit,year]=UOMC[plant,area,year]
        end
      end

      #
      # http://www.eia.gov/todayinenergy/detail.cfm?id=11991
      #
      if UnPlant[unit] == "PumpedHydro"
        for year in Years,month in Months
          UnEAF[unit,month,year]=0.10
        end
        UnEffStorage[unit]=0.80
        for year in Years, month in Months, timep in TimePs
          UnOR[unit,timep,month,year]=0.10
        end
        UnStorage[unit]=1.0
      end

      #
      # Other Storage, find source
      #
      if UnPlant[unit] == "Battery"
        for year in Years,month in Months
          UnEAF[unit,month,year]=0.166
        end
        UnEffStorage[unit]=0.86
        for year in Years, month in Months, timep in TimePs
          UnOR[unit,timep,month,year]=0.10
        end
        UnStorage[unit]=1.0
      end

      #
      # Energy Availability for Peak Hydro Units
      #
      if UnPlant[unit] == "PeakHydro"
        years=collect(Yr(2017):Final)
        for year in years,month in Months
          UnEAF[unit,month,year]=UnEAF[unit,month,Yr(2016)]
        end
      end

      if (UnPlant[unit] == "OGSteam") || (UnPlant[unit] == "OnshoreWind") ||
        (UnPlant[unit] == "OffshoreWind") || (UnPlant[unit] == "SolarPV") ||
        (UnPlant[unit] == "SolarThermal") || (UnPlant[unit] == "SmallHydro") ||
        (UnPlant[unit] == "Wave") || (UnPlant[unit] == "Geothermal") ||
        (UnPlant[unit] == "Waste") || (UnPlant[unit] == "Biogas")
        UnMustRun[unit]=1.0
      end

      if UnMustRun[unit] == 1.0
        years=collect(First:Last)
        for year in years, month in Months, timep in TimePs
          @finite_math UnOR[unit,timep,month,year]=1-xUnEGA[unit,year]/(xUnGC[unit,year]*8760/1000)
        end
        years=collect(Future:Final)
        for year in years, month in Months, timep in TimePs
          UnOR[unit,timep,month,year]=UnOR[unit,timep,month,Last]
        end
      end

      #
      # In 2018, Canada UnUOMC values for OGCC and OGCT increase significantly,
      # so increase UnUOMC values for OGCC in US to avoid changes to dispatch
      # Jeff Amlin 9/15/18
      #
      if UnPlant[unit] == "OGCC"
        years=collect(First:Yr(2020))
        for year in years
          UnUOMC[unit,year]=max(UnUOMC[unit,year],8.7)
        end
        years=collect(Yr(2030):Final)
        for year in years
          UnUOMC[unit,year]=max(UnUOMC[unit,year],4.9)
        end
        years=collect(Yr(2021):Yr(2029))
        for year in years
          UnUOMC[unit,year]=UnUOMC[unit,year-1]+(UnUOMC[unit,Yr(2030)]-UnUOMC[unit,Yr(2020)])/(2030-2020)
        end
      elseif UnPlant[unit] == "OGCT"
        for year in Years
          UnUOMC[unit,year]=max(UnUOMC[unit,year],4.3)
        end
      end
    end
  end

  WriteDisk(db,"EGInput/UnEAF",UnEAF)
  WriteDisk(db,"EGInput/UnEffStorage",UnEffStorage)
  WriteDisk(db,"EGInput/xUnGCCC",xUnGCCC)
  WriteDisk(db,"EGInput/UnHRt",UnHRt)
  WriteDisk(db,"EGInput/UnMustRun",UnMustRun)
  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGInput/UnStorage",UnStorage)
  WriteDisk(db,"EGInput/UnUFOMC",UnUFOMC)
  WriteDisk(db,"EGInput/UnUOMC",UnUOMC)
end

function CalibrationControl(db)
  @info "UnitDataPatch_US.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
