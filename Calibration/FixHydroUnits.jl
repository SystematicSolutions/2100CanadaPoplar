#
# FixHydroUnits.jl
#
using EnergyModel

module FixHydroUnits

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Avaliability Factor (MWh/MWh)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)

  # Scratch Variables
  # StartAverage  'Year to start computing the Average (Year)'
  # zCount        'Number of years with values gt zero', Type=Real(12,4)
  # zLoop         'Loop Counter', Type=Integer(8)
  # ZNbYears      'Number of years used to compute the mean of UnEAF/UnOR', Type=Integer(8)
  # zVal          'Sum of values gt zero (MW/MW)', Type=Real(12,4)
  # zYear         'Pointer for year to average', Type=Integer(8)
end

function ECalibration(db)
  data = EControl(; db)
  (;Month,Months,TimePs,Units) = data
  (;UnArea,UnCode,UnEAF,UnNation,UnOnLine,UnOR,UnPlant,UnRetire) = data

  #
  # The objective of this file is to set the UnEAF value of PeakHydro units
  # and the UnOR value of BaseHydro and SmallHydro units over projection years,
  # so that it is equal to the mean value over the last ZNbYears historical
  # years (instead of being equal to the value over the last historical year).
  # This is done to avoid having possibly unrepresentative values from the
  # last year affecting all the projections.
  #
  # By JSLandry; July 16, 2019
  #
  # Update:
  #
  # Replacing the last historical year value for UnEAF & UnOR is expected
  # to improve E2020 simulations but might not be sufficient to solve all
  # emergency power issues related to hydro. Therefore, additional sections
  # have been added to enable the modification of UnEAF & UnOR for :
  #    a) all units located in province or territory (section 4)
  #    b) a specific unit (section 5)
  #
  # By Thomas Dandres; March 2, 2021
  #

  #
  ###################################
  # Step 0. General declarations
  ###################################
  #
  ZNbYears::Int=5
  StartAverage::Int=Last-ZNbYears
  #
  ###################################
  # Step 1. UnEAF for PeakHydro units
  ###################################
  #
  for unit in Units
    if (UnNation[unit] == "CN")       && (UnPlant[unit] == "PeakHydro") &&
          (UnOnLine[unit] <= HisTime) && (UnRetire[unit,Yr(1985)] > HisTime)
      for month in Months
        #
        # For each Unit and each Month, accumulate values over the last ZNbYears years
        #
        years=collect(StartAverage:Last)
        zVal::Float32=0.0
        zVal=sum(UnEAF[unit,month,year] for year in years)
        zCount::Float32=0.0
        @finite_math zCount=sum(UnEAF[unit,month,year]/UnEAF[unit,month,year] for year in years)
        #
        # Write error message if all values were le zero
        #
        if zCount == 0.0
          ucode=UnCode[unit]
          monthname=Month[month]
          @info "Last UnEAF values were all zero for unit $ucode in month $monthname"
        else
          years=collect(Future:Final)
          for year in years
            UnEAF[unit,month,year]=zVal/zCount
          end
        end
      end
    end
  end

  #
  ###################################
  # Step 2. UnOR for BaseHydro units
  ###################################
  #
  # TODO - add TimeP and Month loops - Jeff Amlin 2/20/25
  #      - Basic loops added; needs review - LJD 03/18/25
  #
  for unit in Units, month in Months, timep in TimePs
    if (UnNation[unit] == "CN")       && (UnPlant[unit] == "BaseHydro") &&
          (UnOnLine[unit] <= HisTime) && (UnRetire[unit,Yr(1985)] > HisTime)
      #
      # For each Unit and each Month, accumulate values over the last ZNbYears years
      # zCount => number of years with values gt zero
      # zVal => sum of values gt zero
      #
      zCount = 0.0
      zVal = 0.0
      #
      # Loop through the ZNbYears and accumulate values
      #
      zLoop::Int=0
      while zLoop < ZNbYears
        zYear:Int=0
        zYear=Last-zLoop
        if UnOR[unit,timep,month,zYear] > 0.0
          zCount = zCount + 1.0
          zVal = zVal + UnOR[unit,timep,month,zYear]
        end
        zLoop = zLoop + 1
      end
      #
      # Write error message if all values were le zero
      if zCount == 0.0
        ucode=UnCode[unit]
        @info "Last UnOR values were all zero for unit $ucode"
      else
        years=collect(Future:Final)
        for year in years
          UnOR[unit,timep,month,year]=zVal/zCount
        end
      end
    end
  end

  #
  ###################################
  # Step 3. UnOR for SmallHydro units
  ###################################
  #
  # TODO - add TimeP and Month loops - Jeff Amlin 2/20/25
  #      - Basic loops added; needs review - LJD 03/18/25
  #
  for unit in Units, month in Months, timep in TimePs
    if (UnNation[unit] == "CN")       && (UnPlant[unit] == "SmallHydro") &&
          (UnOnLine[unit] <= HisTime) && (UnRetire[unit,Yr(1985)] > HisTime)
      #
      # For each Unit and each Month, accumulate values over the last ZNbYears years
      # zCount => number of years with values gt zero
      # zVal => sum of values gt zero
      #
      zCount = 0.0
      zVal = 0.0
      #
      # Loop through the ZNbYears and accumulate values
      #
      zLoop=0
      while zLoop < ZNbYears
        zYear=Last-zLoop
        if UnOR[unit,timep,month,zYear] > 0.0
          zCount = zCount + 1.0
          zVal = zVal + UnOR[unit,timep,month,zYear]
        end
        zLoop = zLoop + 1
      end
      #
      # Write error message if all values were le zero
      if zCount == 0.0
        ucode=UnCode[unit]
        @info "Last UnOR values were all zero for unit $ucode"
      else
        years=collect(Future:Final)
        for year in years
          UnOR[unit,timep,month,year]=zVal/zCount
        end
      end
    end
  end

  #
  ######################################################################
  # Step 4. Manual changes to all units in a province or territory
  ######################################################################
  #
  # Step 4a. UnEAF for PeakHydro units
  #
  # UnEAF can be modified by an additive or multiplicative factor
  # Uncomment one of the following rows to enable the additive or multiplicative factor
  # Replace 0.0X or 1.0X by the desired value
  # Replace XX by the desired Area and Node
  #
  #Winter=Select(Month,"Winter")
  #Summer=Select(Month,"Summer")

  #
  # Update TD May 2024: I use this section to align UnEAF to ECD values (in context of the CER)
  #
  #for unit in Units
  #  years=collect(Future:Final)
  #  if (UnArea[unit] == "BC")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.473112799
  #      UnEAF[unit,Summer,year] = 0.395443388
  #    end
  #  end

  #  if (UnArea[unit] == "AB")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.206732735
  #      UnEAF[unit,Summer,year] = 0.293545516
  #    end
  #  end

  #  if (UnArea[unit] == "SK")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.514544429
  #      UnEAF[unit,Summer,year] = 0.705002491
  #    end
  #  end

  #  if (UnArea[unit] == "MB")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.714462477
  #      UnEAF[unit,Summer,year] = 0.740909194
  #    end
  #  end

  # if (UnArea[unit] == "ON")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.489651013
  #      UnEAF[unit,Summer,year] = 0.478886775
  #    end
  #  end

  #  if (UnArea[unit] == "QC")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.621548112
  #      UnEAF[unit,Summer,year] = 0.513286911
  #    end
  #  end

  #  if (UnArea[unit] == "NB")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.332357505
  #      UnEAF[unit,Summer,year] = 0.372387455
  #    end
  #  end

  #  if (UnArea[unit] == "NS")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.39529581
  #      UnEAF[unit,Summer,year] = 0.273257926
  #    end
  #  end

  #  if (UnArea[unit] == "NL")         && (UnPlant[unit] == "PeakHydro")
  #    for year in years
  #      UnEAF[unit,Winter,year] = 0.792922192
  #      UnEAF[unit,Summer,year] = 0.493739583
  #    end
  #  end

  #end
  
  #
  # Step 4b. UnOR for BaseHydro units
  #
  # UnOR can be modified by an additive or multiplicative factor
  # Uncomment one of the following rows to enable the additive or multiplicative factor
  # Replace 0.0X or 1.0X by the desired value
  # Replace XX by the desired Area and Node
  #

  # for unit in Units
  #   if (UnArea[unit] == "XX")         && (UnPlant[unit] == "BaseHydro") &&
  #       (UnOnLine[unit] <= HisTime) && (UnRetire[unit,1985] > HisTime)
  #     years=collect(Future:Final)
  #     for year in years
  #       UnOR[unit,timep,month,year] = UnOR[unit,timep,month,year]+0.0X
  #       UnOR[unit,timep,month,year] = UnOR[unit,timep,month,year]*1.0X
  #     end
  #   end
  # end

  #
  # Step 4c. UnOr for SmallHydro units (Province/Territory: XX, Node: YY)
  #
  # UnOR can be modified by an additive or multiplicative factor
  # Uncomment one of the following rows to enable the additive or multiplicative factor
  # Replace 0.0X or 1.0X by the desired value
  # Replace XX by the desired Area and Node
  #

  # for unit in Units
  #   if (UnArea[unit] == "XX")         && (UnPlant[unit] == "SmallHydro") &&
  #       (UnOnLine[unit] <= HisTime) && (UnRetire[unit,1985] > HisTime)
  #     years=collect(Future:Final)
  #     for year in years
  #       UnOR[unit,timep,month,year] = UnOR[unit,timep,month,year]+0.0X
  #       UnOR[unit,timep,month,year] = UnOR[unit,timep,month,year]*1.0X
  #     end
  #   end
  # end

  #
  #
  ###################################
  # Step 5. Manual changes to specific units
  ###################################
  # Uncomment rows to modify UnEAF/UnOR
  # Replace xXXXXXX with the desired unit name
  # Replace 0.0X or 1.0X by the desired value
  #

  # for unit in Units
  #   if UnCode[unit] == "xXXXXXX"
  #     years=collect(Future:Final)
  #     for year in years
  #       for month in Months
  #         UnEAF[unit,month,year] = 0.0X
  #       end
  #       UnOR[unit,timep,month,year] = 0.XX
  #     end
  #   end
  # end

  #
  ########################
  # Step 6. Final elements
  ########################
  #
  WriteDisk(db,"EGInput/UnEAF",UnEAF)
  WriteDisk(db,"EGInput/UnOR",UnOR)


end

function CalibrationControl(db)
  @info "FixHydroUnits.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
