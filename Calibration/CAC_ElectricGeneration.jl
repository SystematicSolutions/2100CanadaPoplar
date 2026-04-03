#
# CAC_ElectricGeneration.jl - this file calculates the CAC coefficients for the
# electric generation sector (MEPOCX,UnMECX, UnPOCX) using the NPRI emissions
# data and engineering estimates for units not included in the NPRI data.  The
# coefficients are then scaled to the provincial emissions totals.  JSA 10/27/10
#
using EnergyModel

module CAC_ElectricGeneration

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
  Last = HisTime-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DmdFA::VariableArray{3} = ReadDisk(db,"EGOutput/DmdFA") # [Fuel,Area,Year] Energy Demands (TBtu/Yr)
  EGPA::VariableArray{3} = ReadDisk(db,"EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  MEPOCX::VariableArray{4} = ReadDisk(db,"EGInput/MEPOCX") # [Plant,Poll,Area,Year] Process Emission Coefficients (Tonnes/GWh)
  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnDmd::VariableArray{3} = ReadDisk(db,"EGOutput/UnDmd") # [Unit,FuelEP,Year] Energy Demands (TBtu)
  UnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UnEGA") # [Unit,Year] Generation (GWh)
  UnMECX::VariableArray{3} = ReadDisk(db,"EGInput/UnMECX") # [Unit,Poll,Year] Process Pollution Coefficient (Tonnes/GWh)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)
  UnPol::VariableArray{4} = ReadDisk(db,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution (Tonnes)
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)
  xOREnFPol::VariableArray{5} = ReadDisk(db,"SInput/xOREnFPol") # [FuelEP,ECC,Poll,Area,Year] Off-Road Pollution (Tons/Yr)
  xUnPolSw::VariableArray{3} = ReadDisk(db,"EGInput/xUnPolSw") # [Unit,Poll,Year] Historical Pollution Switch (1=No Unit Data)
  vUnPol::VariableArray{4} = ReadDisk(db,"vData_ElectricUnits/vUnPol") # [Unit,FuelEP,Poll,Year] Electric Unit Pollution (Tonnes/Yr)

  # Scratch Variables
  CXMax::VariableArray{1} = zeros(Float32,length(Poll)) # [Poll] Maximum Emission Coefficient (Tonnes/GWh)
  MECXMin::VariableArray{1} = zeros(Float32,length(Poll)) # [Poll] Minimum Value for Process Coefficient UnMECX (Tonnes/GWh)
  MisPol::VariableArray{3} = zeros(Float32,length(Unit),length(Poll),length(Area)) # [Unit,Poll,Area] Missing Pollution (Tonnes/Yr)
  TotUnPol::VariableArray{2} = zeros(Float32,length(FuelEP),length(Poll)) # [FuelEP,Poll] Total UnPol
  UnXMEPol::VariableArray{2} = zeros(Float32,length(Unit),length(Poll)) # [Unit,Poll] xMEPol Weighted by Unit
end

function POCXValues(data, ecc, areas,polls,years,YrData)
  (;FuelEPs,Units,Plants) = data
  (;EGPA,MEPOCX,UnMECX,UnPOCX,xMEPol) = data

  for year in years, area in areas, poll in polls, plant in Plants

    @finite_math MEPOCX[plant,poll,area,year] =
      xMEPol[ecc,poll,area,year]/sum(EGPA[p,area,year] for p in Plants)

    # MEPOCX(Plant,Poll,Area,Y)=xMEPol(ECC,Poll,Area,Y)/Sum(P)(EGPA(P,Area,Y))
    # * MEPOCX(Plant,Poll,Area,Y)=MECXMin(Poll)
  end

  for year in years, poll in polls, unit in Units
    UnMECX[unit,poll,year] = UnMECX[unit,poll,YrData]
    for fuelep in FuelEPs
      UnPOCX[unit,fuelep,poll,year] = UnPOCX[unit,fuelep,poll,YrData]
    end
  end
end

function CreateCoeff(data,ecc,areas,polls,year)
  (;Area,FuelEPs,Fuels,Plants,Fuel,FuelEP,Units) = data
  (;UnMECX,DmdFA,EGPA,MEPOCX,POCX,UnPOCX,UnArea,UnPol,UnDmd,UnEGA,xMEPol,vUnPol) = data
  (;CXMax,MECXMin,MisPol,TotUnPol,UnXMEPol) = data

  #
  # UnPOCX is historical unit emissions divided by historical unit demands
  #
  for area in areas, poll in polls, unit in Units
    MisPol[unit,poll,area] = 0
  end
  for unit in Units
    #
    # Only run code if we have historical values for Unit
    #
    if sum(vUnPol[unit,fuelep,poll,year] for fuelep in FuelEPs, poll in polls) > 0
      for poll in polls
        for fuelep in FuelEPs
          @finite_math UnPOCX[unit,fuelep,poll,year] = min(max(vUnPol[unit,fuelep,poll,year]/UnDmd[unit,fuelep,year],0.0000000001),CXMax[poll])

          #
          # Attempt to reproduce the inventory using the new coefficient.
          #
          UnPol[unit,fuelep,poll,year] = UnPOCX[unit,fuelep,poll,year]*UnDmd[unit,fuelep,year]
        end

        #
        # Differences between the historical input and calculated inventories get moved into MisPol
        #
        area = Select(Area[areas],UnArea[unit])
        MisPol[unit,poll,area]=sum((vUnPol[unit,fuelep,poll,year] - UnPol[unit,fuelep,poll,year]) for fuelep in FuelEPs)
      end
    end
  end

  #
  # Calculate sector-wide POCX using the calculated inventory
  #
  for fuel in Fuels
    fuelep = findall(FuelEP .== Fuel[fuel])
    if fuelep != []
      fuelep = fuelep[1]
      for area in areas, plant in Plants
        units = findall(UnArea .== Area[area])
        for poll in polls
          TotUnPol[fuelep,poll] = sum(UnPol[unit,fuelep,poll,year] for unit in units)
        end
        for poll in polls
          @finite_math POCX[fuelep,plant,poll,area,year] = TotUnPol[fuelep,poll]/DmdFA[fuel,area,year]
        end
      end
    end
  end

  #
  # Calculate process emissions using xMEPol
  #
  for area in areas
    units = findall(UnArea .== Area[area])

    #
    # Ignore vMEPol input for CACs in the Utility sector - 10/19/2012 E-Mail from Lifang
    #
    for poll in polls, unit in units, plant in Plants

      @finite_math MEPOCX[plant,poll,area,year] =
        xMEPol[ecc,poll,area,year]/sum(EGPA[p,area,year] for p in Plants)

      # MEPOCX(Plant,Poll,Area,Y)=xMEPol(ECC,Poll,Area,Y)/Sum(P)(EGPA(P,Area,Y))
      # * MEPOCX(Plant,Poll,Area,Y)=MECXMin(Poll)
      #
      # Weight out xMEPol by Unit to capture any input process emissions
      #
      @finite_math UnXMEPol[unit,poll] = xMEPol[ecc,poll,area,year]*
                  (UnEGA[unit,year]/sum(UnEGA[u,year] for u in units))
      # * UnXMEPol(U,Poll)=0
      #
      # Create UnMECX using MisPol and weighted xMEPol
      #
      @finite_math UnMECX[unit,poll,year] =
                  (MisPol[unit,poll,area]+UnXMEPol[unit,poll])/UnEGA[unit,year]

      #
      # Constrain UnMECX
      #
      UnMECX[unit,poll,year] = min(max(UnMECX[unit,poll,year],MECXMin[poll]),CXMax[poll])
    end
  end
end

function Ctrl(data)
  (;ECC,FuelEPs,Nation,Poll,Years) = data
  (;ANMap,UnNation,UnPOCX,xMEPol,xOREnFPol) = data

  ecc = Select(ECC,"UtilityGen")
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","Hg","BC"])

  # MoveOffRoad
  for poll in polls, area in areas, year in Years
    xMEPol[ecc,poll,area,year] = xMEPol[ecc,poll,area,year]+
       sum(xOREnFPol[fuelep,ecc,poll,area,year] for fuelep in FuelEPs)
  end

  #
  # RemoveDefaultCNPOCX
  # Rob - All CAC emissions are in input inventories so
  # remove default CAC coefficient - 09/16/14 Ian
  #
  units = findall(UnNation .== "CN")
  @. UnPOCX[units,FuelEPs,polls,Years] = 0

  CreateCoeff(data,ecc,areas,polls,Yr(1990))
  years = collect(Yr(1985):Yr(1989))
  POCXValues(data,ecc,areas,polls,years,Yr(1990))

  years = collect(Yr(1991):Yr(2023))
  for year in years
    CreateCoeff(data,ecc,areas,polls,year)
  end

  # TODOSimplify - There appears to be a gap here. Future is 2022,
  # but CAC calibration stops in 2020 - Luke 11/06/24
  # This is different in Walnut - Jeff Amlin 11/14/24

  years = collect(Future:Final)
  POCXValues(data,ecc,areas,polls,years,Yr(2023))
end

function VBUnits(data)
  (;Last,ECC,Units,FuelEPs,Nation,Poll) = data
  (;ANMap,UnPOCX,UnSector,xUnPolSw,SecMap,UnCogen) = data

  #
  # Use xUnPolSw as a switch to tell demand sector whether we use
  # vUnPol or vCogFPol values for UnPOCX or not. '2' means the Unit is
  # in the Commercial sector. '3' means the Unit is in the Industrial sector.
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  # *Select Poll(PMT,PM10,PM25,SOX,NOX,VOC,COX,NH3,Hg,BC)
  polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","BC"])
  years = Yr(1990):Last

  @. xUnPolSw[Units,polls,years]=0
  for year in years, poll in polls
    unit1 = findall(UnCogen[Units] .> 0)
    unit2 = findall(sum(UnPOCX[Units,fuelep,poll,year] for fuelep in FuelEPs) .< 0.000001)
    units = intersect(unit1,unit2)
    if units != []
      for unit in units
        ecc = Select(ECC,UnSector[unit])
        if SecMap[ecc] == 2
          xUnPolSw[unit,poll,year] = 2
        elseif SecMap[ecc] == 3
          xUnPolSw[unit,poll,year] = 3
        end
      end
    end
  end
end

function ElecCalibration(db)
  data = EControl(; db)
  (;Polls,Poll) = data
  (;UnMECX,MEPOCX,UnPOCX,xUnPolSw) = data
  (;CXMax,MECXMin,MisPol) = data

  @. CXMax[Polls] = 1e12

  #
  # Minimum Process Emission Coefficient
  #
  @. MECXMin[Polls] = 0.00000001
  MECXMin[Select(Poll,"Hg")] = 0.00000000001
  @. MisPol = 0

  Ctrl(data)
  VBUnits(data)

  WriteDisk(db,"EGInput/UnPOCX",UnPOCX)
  WriteDisk(db,"EGInput/MEPOCX",MEPOCX)
  WriteDisk(db,"EGInput/UnMECX",UnMECX)
  WriteDisk(db,"EGInput/xUnPolSw",xUnPolSw)
end

function CalibrationControl(db)
  @info "CAC_ElectricGeneration.jl - CalibrationControl"

  ElecCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
