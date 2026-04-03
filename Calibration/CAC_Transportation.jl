#
# CAC_Transportation.jl - this file calculates the CAC coefficients
# for the transportation sector including the enduse (POCX),
# non-combustion (FsPOCX), and process (TrMEPX).
# Jeff Amlin 6/9/12
#
using EnergyModel
module CAC_Transportation

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TransControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  DmdFEPTech::VariableArray{5} = ReadDisk(db,"$Outpt/DmdFEPTech") # [FuelEP,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  FsPOCX::VariableArray{6} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)
  ORMEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/ORMEPOCX") # [ECC,Poll,Area,Year] Non-Energy Off Road Pollution Coefficient (Tonnes/Economic Driver)
  POCX::VariableArray{7} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Pollution coefficient (Tonnes/TBtu)
  Polute::VariableArray{7} = ReadDisk(db,"$CalDB/Polute") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Pollution (Tonnes/Yr)
  TrMEPX::VariableArray{5} = ReadDisk(db,"$Input/TrMEPX") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Vehicle Miles)
  VDT::VariableArray{5} = ReadDisk(db,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  xOREnFPol::VariableArray{5} = ReadDisk(db,"SInput/xOREnFPol") # [FuelEP,ECC,Poll,Area,Year] Off Road Actual Energy Related Pollution (Tonnes/Yr)
  xORMEPol::VariableArray{4} = ReadDisk(db,"SInput/xORMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)
  xTrEnFPol::VariableArray{7} = ReadDisk(db,"$Input/xTrEnFPol") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Actual Transportation Energy Pollution (Tonnes/Yr)
  xTrMEPol::VariableArray{5} = ReadDisk(db,"$Input/xTrMEPol") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)

  # Scratch Variables
  MisPol::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Poll),length(Area)) # [Tech,EC,Poll,Area] Missing Pollution (Tonnes/Yr)
end

function CalcCoefficients(data,polls,year)
  (;Area,Areas,ECC,EC,ECs,Enduses, Enduse, Fuels,FuelEP,FuelEPs,Nation,Poll,Tech,Techs,Year) = data
  (;ANMap,DmdFEPTech,ECCMap,FsPOCX,ORMEPOCX,POCX,Polute) = data
  (;TrMEPX,VDT,xOREnFPol,xORMEPol,xTrEnFPol,xTrMEPol,MisPol) = data
  (; EC, Area, Poll) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # When demands are zero, we often set them equal to a very small
  # number to facilitate the running of the model.  In this case
  # these very small demands cause a problem since we would like to
  # move the emissions from the enduses with zero fuel demands into
  # the process emissions, these very small demands just cause a very
  # high coefficients which is undesirable.  Therefore, any very small
  # demands are set to zero (temporarily in this file).
  #

  for area in areas, ec in ECs, tech in Techs, fuelep in FuelEPs
    if DmdFEPTech[fuelep,tech,ec,area,year] < 0.00001
      DmdFEPTech[fuelep,tech,ec,area,year] = 0
    end
  end

  #
  # Add OffRoad data series into xTrEnFPol for coefficient calculation
  #
  tech = Select(Tech,"OffRoad")
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for area in areas, poll in polls, fuelep in FuelEPs
      xTrEnFPol[1,fuelep,tech,ec,poll,area,year] =
        xTrEnFPol[1,fuelep,tech,ec,poll,area,year] + xOREnFPol[fuelep,ecc,poll,area,year]
    end
  end

  for area in areas, poll in polls, ec in ECs, tech in Techs, fuelep in FuelEPs, eu in Enduses
    #
    # Emission Coefficient (POCX) is Pollution (xTrEnFPol) divided by Energy Demands (DmdFEPTech).
    #
    @finite_math POCX[eu,fuelep,tech,ec,poll,area,year] =
      xTrEnFPol[1,fuelep,tech,ec,poll,area,year] / DmdFEPTech[fuelep,tech,ec,area,year]

    #
    # Enduse Emissions
    #
    Polute[eu,fuelep,tech,ec,poll,area,year] =
      DmdFEPTech[fuelep,tech,ec,area,year] * POCX[eu,fuelep,tech,ec,poll,area,year]
  end

  #
  # Feedstock emissions are zero per e-mail from Lifang on 05/07/2012 - Ian
  #
  for area in areas, poll in polls, ec in ECs, tech in Techs, fuel in Fuels
    FsPOCX[fuel,tech,ec,poll,area,year] = 0
  end

  #
  # Missing emissions
  #
  for area in areas, poll in polls, ec in ECs, tech in Techs
    MisPol[tech,ec,poll,area] = sum(xTrEnFPol[1,fep,tech,ec,poll,area,year] for fep in FuelEPs) -
      sum(Polute[eu,fep,tech,ec,poll,area,year] for eu in Enduses, fep in FuelEPs)
  end

  #
  # If the missing emissions (MisPol) are not significant, then they are set to zero.
  #
  iob = IOBuffer()
  io = open("cac_transportation.log","w")


  for area in areas, poll in polls, ec in ECs, tech in Techs
    @finite_math CheckValue = abs(MisPol[tech,ec,poll,area] / sum(xTrEnFPol[enduse,fuelep,tech,ec,poll,area,year] for fuelep in FuelEPs, enduse in Enduses))
    if  CheckValue < 0.0001
      MisPol[tech,ec,poll,area] = 0.0
    else
      println(io, "Mispol NOTZERO Tech: ", Tech[tech], " , EC:" , EC[ec] , " , Poll: " , Poll[poll] , " , Area: ", Area[area] , " , Mispol: ", MisPol[tech,ec,poll,area])
    end
  end

  #
  # Process Emission Coefficient (TrMEPX) are Process Emissions (TrMEPol)
  # plus missing Energy Emissions (MisPol) divided by Vehicle Distance Traveled (VDT).
  #
  for area in areas, poll in polls, ec in ECs, tech in Techs
    DistTrav=sum(VDT[enduse,tech,ec,area,year] for enduse in Enduses)
    if DistTrav < 0.0005
      DistTrav = 0
    end

    @finite_math TrMEPX[tech,ec,poll,area,year] = (xTrMEPol[tech,ec,poll,area,year] + MisPol[tech,ec,poll,area])/DistTrav
  end

  #
  # Process Off Road Emission Coefficient (TrMEPX) are Emissions (ORMEPol) divided by the Driver.
  #
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for area in areas, poll in polls
      @finite_math ORMEPOCX[ecc,poll,area,year] = xORMEPol[ecc,poll,area,year]/
        sum(VDT[enduse,tech,ec,area,year] for tech in Techs, enduse in Enduses)
    end
  end
end

function ExtCoefficients(data,polls,eccs,years,Yr1,Yr2)
  (;Enduses,Techs,ECs,FuelEPs,Fuels,Nation) = data
  (;ANMap,TrMEPX,FsPOCX,ORMEPOCX,POCX) = data

  #
  # Extrapolate CAC emissions coefficients based on (YrData).
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  for year in years
    @finite_math POCX[Enduses,FuelEPs,Techs,ECs,polls,areas,year] = 
      POCX[Enduses,FuelEPs,Techs,ECs,polls,areas,Yr1]+
      (POCX[Enduses,FuelEPs,Techs,ECs,polls,areas,Yr2]-
       POCX[Enduses,FuelEPs,Techs,ECs,polls,areas,Yr1])/(Yr2-Yr1)*(year-Yr1)

    @finite_math FsPOCX[Fuels,Techs,ECs,polls,areas,year] =
      FsPOCX[Fuels,Techs,ECs,polls,areas,Yr1]+
      (FsPOCX[Fuels,Techs,ECs,polls,areas,Yr2]-
       FsPOCX[Fuels,Techs,ECs,polls,areas,Yr1])/(Yr2-Yr1)*(year-Yr1)

    #
    # TODOJulia - check parantheses - does TrMEPX need to be different
    # from the others? - Jeff Amlin 12/9/24
    #
    @finite_math TrMEPX[Techs,ECs,polls,areas,year] =
      TrMEPX[Techs,ECs,polls,areas,Yr1] +
      (((TrMEPX[Techs,ECs,polls,areas,Yr2]-
         TrMEPX[Techs,ECs,polls,areas,Yr1])/(Yr2-Yr1))*(year-Yr1))

    @finite_math ORMEPOCX[eccs,polls,areas,year] =
      ORMEPOCX[eccs,polls,areas,Yr1] +
      (ORMEPOCX[eccs,polls,areas,Yr2]-
      ORMEPOCX[eccs,polls,areas,Yr1])/(Yr2-Yr1)*(year-Yr1)
  end
end

function TransCalibration(db)
  data = TransControl(; db)
  (;Input,Poll,ECC, Area, Tech, EC) = data
  (;FsPOCX,ORMEPOCX,POCX,TrMEPX) = data

  #
  # Calculate Coefficients for years which have data
  #
  polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","Hg","BC"])
  years = collect(Yr(1990):Yr(2023))
  for year in years
    CalcCoefficients(data,polls,year)
  end

  #
  # Correct numbers to match Promula
  #
  NT = Select(Area, "NT")
  PlaneGasoline = Select(Tech, "PlaneGasoline")
  ForeignFreight = Select(EC, "ForeignFreight")
  COX = Select(Poll, "COX")
  years = [Yr(2006),Yr(2008),Yr(2018),Yr(2005),Yr(2014),Yr(2011)]
  @. TrMEPX[PlaneGasoline,ForeignFreight,COX,NT,years] = 0.0

  VOC = Select(Poll, "VOC")
  @. TrMEPX[PlaneGasoline,ForeignFreight,VOC,NT,years] = 0.0

  NOX = Select(Poll, "NOX")
  @. TrMEPX[PlaneGasoline,ForeignFreight,NOX,NT,years] = 0.0

  PE = Select(Area, "PE")
  TrMEPX[PlaneGasoline,ForeignFreight,COX,PE,Yr(2020)] = 0.0
  TrMEPX[PlaneGasoline,ForeignFreight,VOC,PE,Yr(2020)] = 0.0

  TrainDiesel = Select(Tech, "TrainDiesel")
  Passenger = Select(EC, "Passenger")
  years = collect(Yr(2007):Yr(2020))
  @. TrMEPX[TrainDiesel,Passenger,NOX,NT,years] = 0.0

  HDV2B3Propane = Select(Tech, "HDV2B3Propane")
  Freight = Select(EC, "Freight")
  NS = Select(Area, "NS")
  years = [Yr(2017),Yr(2020)]
  @. TrMEPX[HDV2B3Propane,Freight,COX,NS,years] = 0.0



  eccs = Select(ECC,(from = "Passenger", to = "CommercialOffRoad"))

  #
  # Specify values for missing years
  #
  years = collect(1:Yr(1989))
  ExtCoefficients(data,polls,eccs,years,Yr(1990),Yr(1990))
  years = collect(Yr(2024):Final)
  ExtCoefficients(data,polls,eccs,years,Yr(2023),Yr(2023))




  WriteDisk(db,"$Input/FsPOCX",FsPOCX)
  WriteDisk(db,"MEInput/ORMEPOCX",ORMEPOCX)
  WriteDisk(db,"$Input/POCX",POCX)
  WriteDisk(db,"$Input/TrMEPX",TrMEPX)
end

function CalibrationControl(db)
  @info "CAC_Transportation.jl - CalibrationControl"

  TransCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
