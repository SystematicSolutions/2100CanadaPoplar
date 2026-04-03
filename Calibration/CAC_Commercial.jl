#
# CAC_Commercial.jl - this file calculates the CAC coefficients for the
# commercial sector including the enduse (POCX), cogeneration (CgPOCX),
# non-combustion (FsPOCX), and process (MEPOCX).  JSA 1/11/10
#
using EnergyModel
module CAC_Commercial

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  CgDem::VariableArray{4} = ReadDisk(db,"$Outpt/CgDem") # [FuelEP,EC,Area,Year] Cogeneration Demands (TBtu/Yr)
  CgPOCX::VariableArray{5} = ReadDisk(db,"$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coeff. (Tonnes/TBtu)
  CgPolEC::VariableArray{5} = ReadDisk(db,"$Outpt/CgPolEC") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution (Tonnes/Yr)
  EuDem::VariableArray{5} = ReadDisk(db,"$Outpt/EuDem") # [Enduse,FuelEP,EC,Area,Year] Enduse Demands (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FlPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FlPOCX") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions Coefficient (Tonnes/Driver)
  FsDem::VariableArray{4} = ReadDisk(db,"$Outpt/FsDem") # [Fuel,EC,Area,Year] Feedstock Demands (TBtu/Yr)
  FsPOCX::VariableArray{5} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)
  FsPol::VariableArray{5} = ReadDisk(db,"$Outpt/FsPol") # [Fuel,EC,Poll,Area,Year] Feedstock Pollution (Tonnes/Yr)
  FuPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCX") # [ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  MEDriver::VariableArray{3} = ReadDisk(db,"MOutput/MEDriver") # [ECC,Area,Year] Driver for Process Emissions (Various Millions/Yr)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Economic Driver)
  ORMEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/ORMEPOCX") # [ECC,Poll,Area,Year] Non-Energy Off Road Pollution Coefficient (Tonnes/Economic Driver)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)
  Polute::VariableArray{6} = ReadDisk(db,"$CalDB/Polute") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution (Tonnes/Yr)
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnDmd::VariableArray{3} = ReadDisk(db,"EGOutput/UnDmd") # [Unit,FuelEP,Year] Energy Demands (TBtu)
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)
  VnPOCX::VariableArray{4} = ReadDisk(db,"MEInput/VnPOCX") # [ECC,Poll,Area,Year] Fugitive Venting Emissions Coefficient (Tonnes/Driver)
  xCgFPol::VariableArray{5} = ReadDisk(db,"SInput/xCgFPol") # [FuelEP,ECC,Poll,Area,Year] Cogeneration Related Pollution (Tonnes/Yr)
  xEnFPol::VariableArray{5} = ReadDisk(db,"SInput/xEnFPol") # [FuelEP,ECC,Poll,Area,Year] Actual Energy Related Pollution excluding Off Road (Tonnes/Yr)
  xFlPol::VariableArray{4} = ReadDisk(db,"SInput/xFlPol") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  xFuPol::VariableArray{4} = ReadDisk(db,"SInput/xFuPol") # [ECC,Poll,Area,Year] Fugitive Emissions (Tonnes/Yr)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)
  xOREnFPol::VariableArray{5} = ReadDisk(db,"SInput/xOREnFPol") # [FuelEP,ECC,Poll,Area,Year] Off-Road Pollution (Tons/Yr)
  xORMEPol::VariableArray{4} = ReadDisk(db,"SInput/xORMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)
  xUnPolSw::VariableArray{3} = ReadDisk(db,"EGInput/xUnPolSw") # [Unit,Poll,Year] Historical Pollution Switch (1=No Unit Data)
  xVnPol::VariableArray{4} = ReadDisk(db,"SInput/xVnPol") # [ECC,Poll,Area,Year] Fugitive Venting Emissions (Tonnes/Yr)

  # Scratch Variables
  CgDmdNPRI::VariableArray{3} = zeros(Float32,length(FuelEP),length(EC),length(Area)) # [FuelEP,EC,Area] Demands for NPRI Cogen units
  CgPolNPRI::VariableArray{4} = zeros(Float32,length(FuelEP),length(ECC),length(Poll),length(Area)) # [FuelEP,ECC,Poll,Area] Emissions for NPRI Cogen units
  EPOCX::VariableArray{4} = zeros(Float32,length(FuelEP),length(EC),length(Poll),length(Area)) # [FuelEP,EC,Poll,Area] Emission Coefficient (Tonnes/TBtu)
  MisPol::VariableArray{3} = zeros(Float32,length(EC),length(Poll),length(Area)) # [EC,Poll,Area] Missing Pollution (Tonnes/Yr)
  xXCgDem::VariableArray{3} = zeros(Float32,length(FuelEP),length(EC),length(Area)) # [FuelEP,EC,Area] Cogen demands minus NPRI units
  xXCgFPol::VariableArray{4} = zeros(Float32,length(FuelEP),length(ECC),length(Poll),length(Area)) # [FuelEP,ECC,Poll,Area] Cogeneration Related Pollution (Tonnes/Yr)
end

function GetUnitSets(data,unit)
  (; Area,EC,ECs,ECC,UnArea,UnSector) = data;
  #
  # This procedure selects the sets for a particular unit
  #
  # ec = findall(EC .== UnSector[unit])
  if (UnSector[unit] != "Null") && (UnArea[unit] != "Null")
    ecc = Select(ECC,UnSector[unit])
    area = Select(Area,UnArea[unit])
    #
    if UnSector[unit] in EC 
      ec = Select(EC,UnSector[unit])
      valid = true
    else
      valid = false; ec = 1; ecc = 1; area = 1;
    end
    #
  else
    ec = 1
    ecc = 1
    area = 1
    valid = false
  end
  return ec,ecc,area,valid
end

function UnitCgDmd(data,year,polls)
  (;Area,Areas,ECC,ECCs,EC,ECs,Year) = data
  (;FuelEPs,Units) = data
  (;CgDem,UnCogen,UnDmd) = data
  (;UnPOCX,UnSector,xCgFPol,xUnPolSw) = data
  (;CgDmdNPRI,CgPolNPRI,xXCgDem,xXCgFPol) = data

  #
  # Cogen based emissions are found both in xEnFPol and in cogen-unit
  # data in vUnPol. According to EnvCa this data does not overlap so
  # we want the units with emissions specified in vUnPol to use
  # coefficients created from that data and units that are unspecified
  # to use a coefficient based on xEnFPol
  # Ian 10/22/2012

  # Select NPRI Units that have cogen demands using our placeholder
  # variable from CAC_ElectricGeneration.txt (xUnPolSw)
  #
  # Read UnDmd into a scratch variable for use in calculating energy coefficient
  #

  unit1 = findall(sum(xUnPolSw[Units,poll,year] for poll in polls) .== 0)
  unit2 = findall(UnCogen[:] .> 0)
  units = intersect(unit1,unit2)

  @. CgDmdNPRI[FuelEPs,ECs,Areas] = 0
  @. CgPolNPRI[FuelEPs,ECCs,polls,Areas] = 0

  for unit in units
    ec,ecc,area,valid = GetUnitSets(data,unit)
    if valid==true
      for fuelep in FuelEPs
        CgDmdNPRI[fuelep,ec,area] = CgDmdNPRI[fuelep,ec,area] + UnDmd[unit,fuelep,year]
        for poll in polls
          CgPolNPRI[fuelep,ecc,poll,area] = CgPolNPRI[fuelep,ecc,poll,area] + UnPOCX[unit,fuelep,poll,year]*UnDmd[unit,fuelep,year]
        end
      end
    end
  end

  #
  # xXCgDem is CgDem minus the demands from NPRI cogen units
  #
  for fuelep in FuelEPs, ec in ECs, area in Areas
    xXCgDem[fuelep,ec,area] = CgDem[fuelep,ec,area,year] - CgDmdNPRI[fuelep,ec,area]
  end

  #
  # xXCgFPol is xCgFPol minus the emissions from NPRI cogen units
  #
  for area in Areas, poll in polls, ec in ECs, fuelep in FuelEPs
    ecc = Select(ECC,EC[ec])
    xXCgFPol[fuelep,ecc,poll,area] = max((xCgFPol[fuelep,ecc,poll,area,year] - CgPolNPRI[fuelep,ecc,poll,area]), 0)
  end
end

function CalcCoefficients(data,polls,year)
  (;Area,ECC,EC,ECs,Enduse) = data
  (;Enduses,FuelEPs,Fuels,Nation,Year,Poll) = data
  (;ANMap,CgPOCX,CgPolEC) = data
  (;EuDem,FlPOCX,FsDem,FsPOCX,FsPol,FuPOCX) = data
  (;MEDriver,MEPOCX,ORMEPOCX,POCX,Polute) = data
  (;VnPOCX,xEnFPol,xFlPol,xFuPol,xMEPol,xOREnFPol) = data
  (;xORMEPol,xVnPol) = data
  (;EPOCX,MisPol,xXCgDem,xXCgFPol) = data

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
        if xXCgDem[fuelep,ec,area] < 0.00001
          xXCgDem[fuelep,ec,area] = 0
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
  # enduses = Select(Enduse,!=("OffRoad"))
  # offroad = Select(Enduse, "OffRoad")
  enduses = collect(Select(Enduse))
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    #
    # Emission factor for enduse and cogeneration emissions except off-road enduse
    #
    for area in areas, poll in polls
      for fuelep in FuelEPs
        @finite_math EPOCX[fuelep,ec,poll,area] = xEnFPol[fuelep,ecc,poll,area,year] / sum(EuDem[eu,fuelep,ec,area,year] for eu in enduses)
        for enduse in enduses
          POCX[enduse,fuelep,ec,poll,area,year] = EPOCX[fuelep,ec,poll,area]
        end
      end

      #
      # We now have Cogeneration emissions inventories so coefficient is now
      # calculated seperately from xEnFPol - Ian 08/04/14
      #
      for fuelep in FuelEPs
        @finite_math EPOCX[fuelep,ec,poll,area] = xXCgFPol[fuelep,ecc,poll,area] / xXCgDem[fuelep,ec,area]
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
        CgPolEC[fuelep,ec,poll,area,year] = xXCgDem[fuelep,ec,area] * CgPOCX[fuelep,ec,poll,area,year]
      end
      for fuel in Fuels
        FsPol[fuel,ec,poll,area,year] = FsDem[fuel,ec,area,year] * FsPOCX[fuel,ec,poll,area,year]
      end

      #
      # Missing emissions (MisPol) are the difference between the historical energy
      # emissions (xEnFPol, xOREnFPol,xCgPol) and the calculated energy emissions (Polute,CgPolEC).
      # Missing emissions occur when historical energy demands (EuDem, CgDem) are zero,
      # but historical emissions (xEnFPol, xOREnFPol) are non-zero.
      #
      MisPol[ec,poll,area] = sum(xEnFPol[fep,ecc,poll,area,year] + xOREnFPol[fep,ecc,poll,area,year] + xXCgFPol[fep,ecc,poll,area] -
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

      #
      # Set other coefficients using the process emissions driver
      #
      @finite_math FuPOCX[ecc,poll,area,year] = xFuPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
      @finite_math FlPOCX[ecc,poll,area,year] = xFlPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
      @finite_math VnPOCX[ecc,poll,area,year] = xVnPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
    end
  end
end

function UnitCoefficients(data,polls,year)
  (;EC,ECs,FuelEPs,Units) = data
  (;CgPOCX,UnPOCX,UnSector,xUnPolSw) = data

  #
  # Assign POCX to Cogen Units that do not have NPRI data
  #
  for poll in polls
    units = findall(xUnPolSw[Units,poll,year] .== 2)
    for unit in units
      ec,ecc,area,valid = GetUnitSets(data,unit)
      if valid==true
            for fuelep in FuelEPs
              UnPOCX[unit,fuelep,poll,year] = CgPOCX[fuelep,ec,poll,area,year]
        end
      end
    end
  end
end

function ExtCoefficients(data,polls,years,Yr1,Yr2)
  (;ANMap,ECC,EC,ECs,Enduses,FuelEPs,Fuels,Nation) = data
  (;Units,CgPOCX,UnSector,UnPOCX,VnPOCX,xUnPolSw) = data
  (;FlPOCX,FsPOCX,FuPOCX,MEPOCX,ORMEPOCX,POCX) = data

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

    @finite_math FlPOCX[ecc,poll,area,year] = FlPOCX[ecc,poll,area,Yr1] +
      (FlPOCX[ecc,poll,area,Yr2] - FlPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)

    @finite_math FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr1] +
      (FuPOCX[ecc,poll,area,Yr2] - FuPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)

    @finite_math VnPOCX[ecc,poll,area,year] = VnPOCX[ecc,poll,area,Yr1] +
      (VnPOCX[ecc,poll,area,Yr2] - VnPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)

    @finite_math ORMEPOCX[ecc,poll,area,year] = ORMEPOCX[ecc,poll,area,Yr1] +
      (ORMEPOCX[ecc,poll,area,Yr2] - ORMEPOCX[ecc,poll,area,Yr1]) /
      (Yr2 - Yr1) * (year - Yr1)
  end


  for poll in polls, year in years
    units1 = findall(xUnPolSw[Units,poll,year] .== 2)
    units2 = findall(in.(UnSector,Ref(EC)))
    units = intersect(units1,units2)
    for fuelep in FuelEPs, unit in units
      @finite_math UnPOCX[unit,fuelep,poll,year] = UnPOCX[unit,fuelep,poll,Yr1] +
        (UnPOCX[unit,fuelep,poll,Yr2] - UnPOCX[unit,fuelep,poll,Yr1]) /
        (Yr2 - Yr1) * (year - Yr1)
    end
  end
end

function ComCalibration(db)
  data = CControl(; db)
  (;Input,Poll) = data
  (;CgPOCX,FlPOCX,FsPOCX,FuPOCX) = data
  (;MEPOCX,ORMEPOCX,POCX,UnPOCX,VnPOCX) = data

  #
  # Calculate Coefficients for years which have data
  #
  polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","Hg","BC"])
  for year in Yr(1990):Yr(2023)
    UnitCgDmd(data,year,polls)
    CalcCoefficients(data,polls,year)
    UnitCoefficients(data,polls,year)
  end

  #
  # Specify values for missing years
  #
  ExtCoefficients(data,polls,1:Yr(1989),Yr(1990),Yr(1990))
  ExtCoefficients(data,polls,Yr(2024):Final,Yr(2023),Yr(2023))

  WriteDisk(db,"$Input/CgPOCX",CgPOCX)
  WriteDisk(db,"MEInput/FlPOCX",FlPOCX)
  WriteDisk(db,"$Input/FsPOCX",FsPOCX)
  WriteDisk(db,"MEInput/FuPOCX",FuPOCX)
  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
  WriteDisk(db,"MEInput/ORMEPOCX",ORMEPOCX)
  WriteDisk(db,"$Input/POCX",POCX)
  WriteDisk(db,"EGInput/UnPOCX",UnPOCX)
  WriteDisk(db,"MEInput/VnPOCX",VnPOCX)
end

function CalibrationControl(db)
  @info "CAC_Commercial.jl - CalibrationControl"

  ComCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
