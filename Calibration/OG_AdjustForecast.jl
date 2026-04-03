#
# OG_AdjustForecast.jl - Financial data assumptions for oil and gas production
#
using EnergyModel

module OG_AdjustForecast

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String
  
  OGCode::Vector{String} = ReadDisk(db, "MainDB/OGCode")
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGCode")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DevVF::VariableArray{2} = ReadDisk(db,"SpInput/DevVF") # [OGUnit,Year] Development Rate Variance Factor for ROI (Btu/Btu)
  PdMinM::VariableArray{2} = ReadDisk(db,"SpInput/PdMinM") # [OGUnit,Year] Production Rate Minimum Multiplier from ROI (Btu/Btu)
  PdSw::VariableArray{2} = ReadDisk(db,"SpInput/PdSw") # [OGUnit,Year] Production Switch
  PdVF::VariableArray{2} = ReadDisk(db,"SpInput/PdVF") # [OGUnit,Year] Production Rate Variance Factor for ROI (Btu/Btu)

  #
  # Scratch Variables
  #
  DevVFAB::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Alberta Development Rate Variance Factor for ROI (Btu/Btu)
  DevVFSAGD::VariableArray{1} = zeros(Float32,length(Year)) # [Year] SAGD Development Rate Variance Factor for ROI (Btu/Btu)
end

function AdjustForecast(db)
  data = SControl(; db)
  (;OGUnit,OGUnits) = data
  (;DevVF,DevVFAB,OGCode,PdVF) = data

  #
  # Eliminate price sensitivity for selected plays - Jeff Amlin 09/07/21
  #  add ON Gas - Jeff 03/09/22 
  #
  for ogunit in OGUnits
    if (OGCode[ogunit] == "SK_OS_Upgrader_0001") ||
       (OGCode[ogunit] == "SK_ConvGas_0001")     ||
       (OGCode[ogunit] == "ON_Gas_0001")         ||
       (OGCode[ogunit] == "BC_ConvGas_0001")     ||
       (OGCode[ogunit] == "ON_LightOil_0001")
      years=collect(Yr(2017):Yr(2050))
      for year in years
        DevVF[ogunit,year] = 0.0
        PdVF[ogunit,year]  = 0.0
      end
    end

    if (OGCode[ogunit] == "AB_OS_Mining_0001") 
      years=collect(Yr(2017):Yr(2050))
      for year in years
        PdVF[ogunit,year]  = 0.0
      end
    end
  end

  #
  ########################
  #
  years=collect(Yr(2017):Yr(2050))

  ogunit=Select(OGUnit,"AB_UnconvGas_0001")
  for year in years
    DevVFAB[year] = DevVF[ogunit,year]
  end
  
  ogunit=Select(OGUnit,"BC_UnconvGas_0001")
  for year in years
    DevVF[ogunit,year] = DevVFAB[year]
  end

  #
  ########################
  #
  for ogunit in OGUnits
    if (OGCode[ogunit] == "BC_LNG_0001") ||
       (OGCode[ogunit] == "NS_LNG_0001") ||
       (OGCode[ogunit] == "QC_LNG_0001")

      years=collect(Yr(2017):Yr(2029))
      for year in years
        DevVF[ogunit,year] = 0.0
        PdVF[ogunit,year]  = 0.0
      end
    
      years=collect(Yr(2029):Yr(2050))
      for year in years
        DevVF[ogunit,year] = -0.25
        PdVF[ogunit,year]  =  0.00
      end 
    end
    
  #
  ########################
  #
    if (OGCode[ogunit] == "AB_LightOil_0001")
      years=collect(Yr(2017):Yr(2024))
      for year in years
        DevVF[ogunit,year] = 0.0
        PdVF[ogunit,year]  = 0.0
      end
    end

  #
    if (OGCode[ogunit] == "SK_LightOil_0001") ||
       (OGCode[ogunit] == "AB_HeavyOil_0001")
      years=collect(Yr(2017):Yr(2023))
      for year in years
          DevVF[ogunit,year] = 0.0
          PdVF[ogunit,year]  = 0.0
      end
    end
  
#
    if (OGCode[ogunit] == "NL_HeavyOil_0001")
      years=collect(Yr(2017):Final)
      for year in years
        DevVF[ogunit,year] = 0.0
        PdVF[ogunit,year]  = 0.0
      end
    end
  
  end # for ogunit in OGUnits


  WriteDisk(db, "SpInput/DevVF",DevVF)
  WriteDisk(db, "SpInput/PdVF",PdVF)

end

function Control(db)
  @info "OG_AdjustForecast.jl -  Control"

  AdjustForecast(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
