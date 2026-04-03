#
# AdjustElectricity_HeatRates.jl 
#
# This file replaces heat rates that are outside a pre-defined range by values 
# that bound the range. This is done for projection years only; the range depends 
# upon the plant type, whether the unit is utility or cogen, and in some cases the fuel. 
# For the values used, see the following file: 
# T:\Modeling Data\Electricity\Heat Rate Data\PTTU21-060_e2020 heat rates review_2021-11-29.xlsx
# JSLandry; Nov 6, 2019 and Thomas Dandres; Mar 2024
#
# Modified to remove two specific units (NL_MEGA_FOM and NL_Hebron). 
# JSLandry; Jul 6, 2020. 
#
# Modified to exclude cogen to prevent discontinuities between last historical year and projection years.
# RST 14July2023
#
# Modified to reflect ECD min and max (as calculated from real data: avg +/- 2 standard dev.)
# TD 8Sept2023
#
# Modified to implement ECD min and max for 'cogen' plants
# TD May 2024
#
# Modified to exclude some plants for which ECD has provided specific values (those values are implemented in macros generating vData)
# TD May 2024
#
# Updated some values, added fuel/tech combination according to new ECD data
# TD July 2024
#
using EnergyModel

module AdjustElectricity_HeatRates

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

  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnF1::Array{String} = ReadDisk(db,"EGInput/UnF1") # [Unit] Fuel Source 1
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Unit,Units,Year,YearDS,Years) = data
  (;UnArea,UnCode,UnCogen,UnF1,UnHRt,UnNation,UnPlant) = data

  #
  # Changes apply to projections only
  #
  years=collect(Future:Final)

  #
  # Loop through all units and change UnHRt of emitting units in Canada if needed
  # (CoalCCS units are not covered here)
  #
  for unit in Units
    #
    # 1. Utility units, Biomass Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "Biomass") && (UnCogen[unit] == 0)
      for year in years
        UnHRt[unit,year]=max(10848,min(UnHRt[unit,year],19530))
      end
    end

    #
    # 2. Utility units, Coal Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "Coal") && (UnCogen[unit] == 0)
      for year in years
        UnHRt[unit,year]=max(9066,min(UnHRt[unit,year],12207))
      end
    end

    #
    # 3. Utility units, OGCC Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "OGCC") && (UnCogen[unit] == 0)
      for year in years
        UnHRt[unit,year]=max(6149,min(UnHRt[unit,year],8227))
      end
    end

    #
    # 4. Utility units, OGCT Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "OGCT") && (UnCogen[unit] == 0) && (UnArea[unit] != "YT")
      # 4.1 Values for NG-like fuels
      if (UnF1[unit] == "NaturalGas") || (UnF1[unit] == "NaturalGasRaw") || (UnF1[unit] == "RNG") || (UnF1[unit] == "StillGas")
        for year in years
          UnHRt[unit,year]=max(7861,min(UnHRt[unit,year],14452))
        end
        #
        # The EIA recently disaggregated Diesel plants enabling ECD to compute these numbers
        #   4.2 Values for Diesel (gasoline should be included here aswell, see Electricity issue tracker #228
        #       Keep it as is for now due to NextGrid alignment for the CER modelling, could be resolved after the CER modelling)
      elseif (UnF1[unit] == "Diesel")
        for year in years
          UnHRt[unit,year]=max(11008,min(UnHRt[unit,year],20354))
        end

      # 4.3 Values for other fuels
      else
        for year in years
          UnHRt[unit,year]=max(9287,min(UnHRt[unit,year],18585))
        end
      end
    end

    #
    # 5. Utility units, OGSteam Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "OGSteam") && (UnCogen[unit] == 0)
      if (UnCode[unit] != "SK00015301402") && (UnCode[unit] != "SK00015301403") && (UnCode[unit] != "SK00015301804")
        # 5.1 Values for Biomass
        if (UnF1[unit] == "Biomass")
          for year in years
            UnHRt[unit,year]=max(10848,min(UnHRt[unit,year],19530))
          end
        # 5.2 Values for Petrocoke
        elseif (UnF1[unit] == "Petrocoke")
          for year in years
            UnHRt[unit,year]=max(9066,min(UnHRt[unit,year],12207))
          end
        # 5.3 Values for Waste
        elseif (UnF1[unit] == "Waste")
          for year in years
            UnHRt[unit,year]=max(8029,min(UnHRt[unit,year],15838))
          end
        # 5.4 Values for other fuels
        else
          for year in years
            UnHRt[unit,year]=max(9093,min(UnHRt[unit,year],13468))
          end
        end
      end
    end

    #
    # 6. Utility units, Waste Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "Waste") && (UnCogen[unit] == 0)
      # 6.1 Values for NG-like fuels
      if (UnF1[unit] == "NaturalGas") || (UnF1[unit] == "NaturalGasRaw") || (UnF1[unit] == "RNG") || (UnF1[unit] == "StillGas")
        for year in years
          UnHRt[unit,year]=max(9221,min(UnHRt[unit,year],20296))
        end
      # 6.2 Values for Biomass
      elseif (UnF1[unit] == "Biomass")
        for year in years
          UnHRt[unit,year]=max(10848,min(UnHRt[unit,year],19530))
        end
      # 6.3 Values for other fuels
      else
        for year in years
          UnHRt[unit,year]=max(8029,min(UnHRt[unit,year],15838))
        end
      end
    end

    #
    # 7. Cogen units, Biomass Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "Biomass") && (UnCogen[unit] == 1)
      for year in years
        UnHRt[unit,year]=max(4138,min(UnHRt[unit,year],14969))
      end
    end

    #
    # 8. Cogen units, OGCC Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "OGCC") && (UnCogen[unit] == 1)
      for year in years
        UnHRt[unit,year]=max(3967,min(UnHRt[unit,year],10225))
      end
    end

    #
    # 9. Cogen units, OGCT Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "OGCT") && (UnCogen[unit] == 1)
      if (UnCode[unit] != "NL_MEGA_FOM") && (UnCode[unit] != "NL_Hebron") && (UnCode[unit] != "AB00035000101") && (UnCode[unit] != "AB00035000102") && (UnCode[unit] != "AB_OSU003002") && (UnCode[unit] != "AB00001200101") && (UnArea[unit] != "YT")
        # 9.1 Values for NG-like fuels
        if (UnF1[unit] == "NaturalGas") || (UnF1[unit] == "NaturalGasRaw") || (UnF1[unit] == "RNG") || (UnF1[unit] == "StillGas")
          for year in years
            UnHRt[unit,year]=max(3881,min(UnHRt[unit,year],11011))
          end
        # 9.2 Values for Petrocoke
        elseif (UnF1[unit] == "Petrocoke")
          for year in years
            UnHRt[unit,year]=max(3834,min(UnHRt[unit,year],11876))
          end
        # 9.3 Values for other fuels
        else
          for year in years
            UnHRt[unit,year]=max(4549,min(UnHRt[unit,year],9176))
          end
        end
      end
    end

    #
    # 10. Cogen units, OGSteam Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "OGSteam") && (UnCogen[unit] == 1) && (UnArea[unit] != "YT")
      # 10.1 Values for Petrocoke and CokeOvenGas
      if (UnF1[unit] == "Petrocoke") || (UnF1[unit] == "CokeOvenGas")
        for year in years
          UnHRt[unit,year]=max(3834,min(UnHRt[unit,year],11876))
        end
      # 10.2 Values for Biomass
      elseif (UnF1[unit] == "Biomass")
        for year in years
          UnHRt[unit,year]=max(4138,min(UnHRt[unit,year],14969))
        end
      # 10.3 Values for other fuels
      else
        for year in years
          UnHRt[unit,year]=max(3674,min(UnHRt[unit,year],11301))
        end
      end
    end

    #
    # 11. Cogen units, Waste Plants
    #
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "Waste") && (UnCogen[unit] == 1)
      # 11.1 Values for NG-like fuels
      if (UnF1[unit] == "NaturalGas") || (UnF1[unit] == "NaturalGasRaw") || (UnF1[unit] == "RNG") || (UnF1[unit] == "StillGas")
        for year in years
          UnHRt[unit,year]=max(5021,min(UnHRt[unit,year],6574))
        end
      # 11.2 Values for Biomass
      elseif (UnF1[unit] == "Biomass")
        for year in years
          UnHRt[unit,year]=max(4138,min(UnHRt[unit,year],14969))
        end
      # 11.3 Values for other fuels
      else
        for year in years
          UnHRt[unit,year]=max(3952,min(UnHRt[unit,year],8016))
        end
      end
    end

  end

  WriteDisk(db,"EGInput/UnHRt",UnHRt)


end

function CalibrationControl(db)
  @info "AdjustElectricity_HeatRates.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
