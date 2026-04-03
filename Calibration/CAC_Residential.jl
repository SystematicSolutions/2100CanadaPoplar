#
# CAC_Residential.jl - this file calculates the CAC coefficients for the
# residential sector including the enduse (POCX), cogeneration (CgPOCX),
# non-combustion (FsPOCX), and process (MEPOCX).  JSA 1/11/10
#
using EnergyModel
module CAC_Residential

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  CgDem::VariableArray{4} = ReadDisk(db,"$Outpt/CgDem") # [FuelEP,EC,Area,Year] Cogeneration Demands (TBtu/Yr)
  CgPOCX::VariableArray{5} = ReadDisk(db,"$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coeff. (Tonnes/TBtu)
  CgPolEC::VariableArray{5} = ReadDisk(db,"$Outpt/CgPolEC") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution (Tonnes/Yr)
  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  EuDem::VariableArray{5} = ReadDisk(db,"$Outpt/EuDem") # [Enduse,FuelEP,EC,Area,Year] Enduse Demands (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FsDem::VariableArray{4} = ReadDisk(db,"$Outpt/FsDem") # [Fuel,EC,Area,Year] Feedstock Demands (TBtu/Yr)
  FsPOCX::VariableArray{5} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)
  FsPol::VariableArray{5} = ReadDisk(db,"$Outpt/FsPol") # [Fuel,EC,Poll,Area,Year] Feedstock Pollution (Tonnes/Yr)
  MEDriver::VariableArray{3} = ReadDisk(db,"MOutput/MEDriver") # [ECC,Area,Year] Driver for Process Emissions (Various Millions/Yr)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Economic Driver)
  ORMEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/ORMEPOCX") # [ECC,Poll,Area,Year] Non-Energy Off Road Pollution Coefficient (Tonnes/Economic Driver)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)
  Polute::VariableArray{6} = ReadDisk(db,"$CalDB/Polute") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution (Tonnes/Yr)
  xEnFPol::VariableArray{5} = ReadDisk(db,"SInput/xEnFPol") # [FuelEP,ECC,Poll,Area,Year] Actual Energy Related Pollution excluding Off Road (Tonnes/Yr)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)
  xOREnFPol::VariableArray{5} = ReadDisk(db,"SInput/xOREnFPol") # [FuelEP,ECC,Poll,Area,Year] Off-Road Pollution (Tons/Yr)
  xORMEPol::VariableArray{4} = ReadDisk(db,"SInput/xORMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)

  # Scratch Variables
  EPOCX::VariableArray{4} = zeros(Float32,length(FuelEP),length(EC),length(Poll),length(Area)) # [FuelEP,EC,Poll,Area] Emission Coefficient (Tonnes/TBtu)
  MisPol::VariableArray{3} = zeros(Float32,length(EC),length(Poll),length(Area)) # [EC,Poll,Area] Missing Pollution (Tonnes/Yr)
end

function CalcCoefficients(data,polls,year)
  (;ECC,Enduses,EC,ECs,Enduse,FuelEPs,Fuels,Nation) = data
  (;ANMap,CgDem,CgPOCX,CgPolEC,EuDem,FsDem,FsPOCX) = data
  (;FsPol,MEDriver,MEPOCX,ORMEPOCX,POCX,Polute,xEnFPol) = data
  (;xMEPol,xOREnFPol,xORMEPol) = data
  (;EPOCX,MisPol) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # When demands are zero, we often set them equal to a very small number to
  # facilitate the running of the model.  In this case these very small demands
  # cause a problem since we would like to move the emissions from the enduses
  # with zero fuel demands into the process emissions, these very small demands
  # just cause a very high coefficients which is undesirable.  Therefore, any
  # very small demands are set to zero (temporarily in this file).
  #

  for area in areas, ec in ECs
    for fuelep in FuelEPs
      for enduse in Enduses
        if EuDem[enduse,fuelep,ec,area,year] < 0.00001
          EuDem[enduse,fuelep,ec,area,year] = 0
        end
      end
        if CgDem[fuelep,ec,area,year] < 0.00001
          CgDem[fuelep,ec,area,year] = 0
        end
    end
    for fuel in Fuels
      if FsDem[fuel,ec,area,year] < 0.00001
        FsDem[fuel,ec,area,year] = 0
      end
    end
  end

  #
  # For each ECC select the appropriate EC with ECCMap
  #
  enduses = Select(Enduse,!=("OffRoad"))
  # offroad = Select(Enduse, "OffRoad")
  enduses = collect(Select(Enduse))
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    #
    # Emission factor for enduse and cogeneration emissions except off-road enduse
    #
    for area in areas, poll in polls
      for fuelep in FuelEPs
        @finite_math EPOCX[fuelep,ec,poll,area] = xEnFPol[fuelep,ecc,poll,area,year] /
          sum(EuDem[eu,fuelep,ec,area,year] + CgDem[fuelep,ec,area,year] for eu in enduses)
        for enduse in enduses
          POCX[enduse,fuelep,ec,poll,area,year] = EPOCX[fuelep,ec,poll,area]
        end
        CgPOCX[fuelep,ec,poll,area,year] = EPOCX[fuelep,ec,poll,area]
      end

      #
      # Per email from Lifang on 6/21: All historical CAC inventories should be represented in the input
      # data, not calculated endogenously by the model. Since we do not recieve inventories for
      # feedstocks set FsPOCX to zero to avoid double counting issues. - Ian 7/5/12
      #
      for fuel in Fuels
        FsPOCX[fuel,ec,poll,area,year] = 0
      end

      #
      # Emission factor for off-road enduse
      #
      # for fuelep in FuelEPs
      #   @finite_math EPOCX[fuelep,ec,poll,area] = xOREnFPol[fuelep,ecc,poll,area,year]/
      #     EuDem[offroad,fuelep,ec,area,year]
      #   POCX[offroad,fuelep,ec,poll,area,year] = EPOCX[fuelep,ec,poll,area]
      # end

      #
      # Calculate energy emissions
      #
      for fuelep in FuelEPs
        for enduse in Enduses
          Polute[enduse,fuelep,ec,poll,area,year] = EuDem[enduse,fuelep,ec,area,year] * POCX[enduse,fuelep,ec,poll,area,year]
        end
        CgPolEC[fuelep,ec,poll,area,year] = CgDem[fuelep,ec,area,year] * CgPOCX[fuelep,ec,poll,area,year]
      end
      for fuel in Fuels
        FsPol[fuel,ec,poll,area,year] = FsDem[fuel,ec,area,year] * FsPOCX[fuel,ec,poll,area,year]
      end

      #
      # Missing emissions (MisPol) are the difference between the historical energy
      # emissions (xEnFPol, xOREnFPol) and the calculated energy emissions (Polute,CgPolEC).
      # Missing emissions occur when historical energy demands (EuDem, CgDem) are zero,
      # but historical emissions (xEnFPol, xOREnFPol) are non-zero.
      #
      MisPol[ec,poll,area] = sum(xEnFPol[fep,ecc,poll,area,year] + xOREnFPol[fep,ecc,poll,area,year] -
        (sum(Polute[eu,fep,ec,poll,area,year] for eu in Enduses) + CgPolEC[fep,ec,poll,area,year]) for fep in FuelEPs)

      #
      # If the missing emissions (MisPol) are not significant, then they are set to zero.
      #
      @finite_math if abs(MisPol[ec,poll,area] / sum(xEnFPol[fep,ecc,poll,area,year] + xOREnFPol[fep,ecc,poll,area,year] for fep in FuelEPs)) < 0.0001
        MisPol[ec,poll,area] = 0
      end

      #
      # The Process emission coefficient (MEPOCX) is equal to the Process emissions
      # (xMEPol) divided by the process emission driver (MEDriver); however, the missing energy
      # emissions (MisPol) are also incorporated into the Process emission coefficient.
      #
      @finite_math MEPOCX[ecc,poll,area,year] = (xMEPol[ecc,poll,area,year] + MisPol[ec,poll,area]) / MEDriver[ecc,area,year]

      #
      # The OffRoad Proces emission coefficient (ORMEPOCX) is equal to the OffRoad Process
      # emissions(xORMEPol) divided by the process emission driver (MEDriver)
      #
      @finite_math ORMEPOCX[ecc,poll,area,year] = xORMEPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
    end
  end
end

function ExtCoefficients(data,polls,years,Yr1,Yr2)
  (;ECC,Enduses,EC,ECs,ANMap,CgPOCX,FsPOCX,FuelEPs,Fuels,Nation) = data
  (;MEPOCX,ORMEPOCX,POCX) = data

  #
  # Extrapolate CAC emissions coefficients based on (YrData).
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  for year in years, area in areas, poll in polls, ec in ECs
    ecc=Select(ECC,EC[ec])
    for fuelep in FuelEPs, enduse in Enduses
      @finite_math POCX[enduse,fuelep,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,Yr1] +
        (POCX[enduse,fuelep,ec,poll,area,Yr2] - POCX[enduse,fuelep,ec,poll,area,Yr1]) /
        (Yr2 - Yr1) * (year - Yr1)
    end

    for fuelep in FuelEPs
      @finite_math CgPOCX[fuelep,ec,poll,area,year] = CgPOCX[fuelep,ec,poll,area,Yr1] +
        (CgPOCX[fuelep,ec,poll,area,Yr2] - CgPOCX[fuelep,ec,poll,area,Yr1]) /
        (Yr2 - Yr1) * (year - Yr1)
    end

    for fuel in Fuels
      @finite_math FsPOCX[fuel,ec,poll,area,year] = FsPOCX[fuel,ec,poll,area,Yr1] +
        (FsPOCX[fuel,ec,poll,area,Yr2] - FsPOCX[fuel,ec,poll,area,Yr1]) /
        (Yr2 - Yr1) * (year - Yr1)
    end

    @finite_math MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr1] +
      (MEPOCX[ecc,poll,area,Yr2] - MEPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)

    @finite_math ORMEPOCX[ecc,poll,area,year] = ORMEPOCX[ecc,poll,area,Yr1] +
      (ORMEPOCX[ecc,poll,area,Yr2] - ORMEPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)
  end
end

function ResCalibration(db)
  data = RControl(; db)
  (;Input,Poll,MEPOCX,ORMEPOCX,POCX,CgPOCX,FsPOCX) = data

  #
  # Calculate Coefficients for years which have data
  #
  polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","Hg","BC"])
  for year in Yr(1990):Yr(2023)
    CalcCoefficients(data,polls,year)
  end

  #
  # Specify values for missing years
  #
  ExtCoefficients(data,polls,1:Yr(1989),Yr(1990),Yr(1990))
  ExtCoefficients(data,polls,Yr(2024):Final,Yr(2023),Yr(2023))

  WriteDisk(db,"$Input/CgPOCX",CgPOCX)
  WriteDisk(db,"$Input/FsPOCX",FsPOCX)
  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
  WriteDisk(db,"MEInput/ORMEPOCX",ORMEPOCX)
  WriteDisk(db,"$Input/POCX",POCX)
end

function CalibrationControl(db)
  @info "CAC_Residential.jl - CalibrationControl"

  ResCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
