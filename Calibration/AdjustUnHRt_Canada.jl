#
# AdjustUnHRt_Canada.jl
#
# This file replaces heat rates that are outside a pre-defined range by values
# that bound the range. This is done for projection years only; the range depends
# upon the plant type, whether the unit is utility or cogen, and in some cases the fuel.
# For the values used, see the following file:
# T:\2017_Update\Electricity\Model File Changes\heat_rates\heat_rate_ranges_2019_10_31.xlsx
# JSLandry; Nov 6, 2019
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
using EnergyModel

module AdjustUnHRt_Canada

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
  (;Units) = data
  (;UnCogen,UnF1,UnHRt,UnNation,UnPlant) = data

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
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "OGCT") && (UnCogen[unit] == 0)
      # 4.1 Values for NG-like fuels
      if (UnF1[unit] == "NaturalGas") || (UnF1[unit] == "NaturalGasRaw") || (UnF1[unit] == "RNG") || (UnF1[unit] == "StillGas")
        for year in years
          UnHRt[unit,year]=max(7861,min(UnHRt[unit,year],14452))
        end
      # 4.2 Values for other fuels
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
      for year in years
        UnHRt[unit,year]=max(9093,min(UnHRt[unit,year],13468))
      end
    end

    # *
    # * 6. Utility units, Waste Plants
    # *
    if (UnNation[unit] == "CN") && (UnPlant[unit] == "Waste") && (UnCogen[unit] == 0)
      # 6.1 Values for NG-like fuels
      if (UnF1[unit] == "NaturalGas") || (UnF1[unit] == "NaturalGasRaw") || (UnF1[unit] == "RNG") || (UnF1[unit] == "StillGas")
        for year in years
          UnHRt[unit,year]=max(9221,min(UnHRt[unit,year],20296))
        end
      # 6.2 Values for other fuels
      else
        for year in years
          UnHRt[unit,year]=max(8029,min(UnHRt[unit,year],15838))
        end
      end
    end

    #
    # Note: Cogen plants commented out in Promula
    #

    # *
    # * 7. Cogen units, Biomass Plants
    # *
    # *  Do If (UnNation == "CN") && (UnPlant == "Biomass") && (UnCogen == 1)
    # *    Do If (UnHRt lt 4800)
    # *      UnHRt = 4800
    # *    Else (UnHRt gt 8800)
    # *      UnHRt = 8800
    # *    End Do If
    # *  End Do If
    # *
    # * 8. Cogen units, OGCC Plants
    # *
    # *  Do If (UnNation == "CN") && (UnPlant == "OGCC") && (UnCogen == 1)
    # *    Do If (UnHRt lt 3900)
    # *      UnHRt = 3900
    # *    Else (UnHRt gt 7300)
    # *      UnHRt = 7300
    # *    End Do If
    # *  End Do If
    # *
    # * 9. Cogen units, OGCT Plants
    # *
    # *  Do If (UnNation == "CN") && (UnPlant == "OGCT") && (UnCogen == 1)
    # *    Do If (UnCode ne "NL_MEGA_FOM") && (UnCode ne "NL_Hebron")
    # *     9.1 Values for NG-like fuels
    # *      Do If (UnF1 == "NaturalGas") || (UnF1 == "NaturalGasRaw") || (UnF1 == "RNG") || (UnF1 == "StillGas")
    # *        Do If (UnHRt lt 5100)
    # *          UnHRt = 5100
    # *        Else (UnHRt gt 9600)
    # *          UnHRt = 9600
    # *        End Do If
    # *     9.2 Values for other fuels
    # *      Else
    # *        Do If (UnHRt lt 6200)
    # *          UnHRt = 6200
    # *        Else (UnHRt gt 11500)
    # *          UnHRt = 11500
    # *        End Do If
    # *      End Do If
    # *    End Do If
    # *  End Do If
    # *
    # * 10. Cogen units, OGSteam Plants
    # *
    # *  Do If (UnNation == "CN") && (UnPlant == "OGSteam") && (UnCogen == 1)
    # *    Do If (UnHRt lt 4700)
    # *      UnHRt = 4700
    # *    Else (UnHRt gt 8800)
    # *      UnHRt = 8800
    # *    End Do If
    # *  End Do If
    # *
    # * 11. Cogen units, Waste Plants
    # *
    # *  Do If (UnNation == "CN") && (UnPlant == "Waste") && (UnCogen == 1)
    # *   11.1 Values for NG-like fuels
    # *    Do If (UnF1 == "NaturalGas") || (UnF1 == "NaturalGasRaw") || (UnF1 == "RNG") || (UnF1 == "StillGas")
    # *      Do If (UnHRt lt 5100)
    # *        UnHRt = 5100
    # *      Else (UnHRt gt 9500)
    # *        UnHRt = 9500
    # *      End Do If
    # *   11.2 Values for other fuels
    # *    Else
    # *      Do If (UnHRt lt 8300)
    # *        UnHRt = 8300
    # *     Else (UnHRt gt 15400)
    # *        UnHRt = 15400
    # *      End Do If
    # *    End Do If
    # *  End Do If
    # *
  end

  WriteDisk(db,"EGInput/UnHRt",UnHRt)

end

function CalibrationControl(db)
  @info "AdjustUnHRt_Canada.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
