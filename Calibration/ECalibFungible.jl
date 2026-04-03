#
# ECalibFungible.jl - Fungible Demands Market Share Calibration 
#
# TODOJulia - UnFlFrMSM0 needs to be debugged - Jeff Amlin 9/30/24
#
using EnergyModel

module ECalibFungible

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ECFPFuel::VariableArray{3} = ReadDisk(db,"EGOutput/ECFPFuel") # [FuelEP,Area,Year] Fuel Price ($/mmBtu)
  FlFrMax::VariableArray{4} = ReadDisk(db,"EGInput/FlFrMax") # [FuelEP,Plant,Area,Year] Fuel Fraction Maximum (Btu/Btu)
  FlFrMin::VariableArray{4} = ReadDisk(db,"EGInput/FlFrMin") # [FuelEP,Plant,Area,Year] Fuel Fraction Minimum (Btu/Btu)
  FlFrMSM0::VariableArray{4} = ReadDisk(db,"EGInput/FlFrMSM0") # [FuelEP,Plant,Area,Year] Fuel Fraction Non-Price Factor (Btu/Btu)
  FlFrNew::VariableArray{4} = ReadDisk(db,"EGInput/FlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  FlFrTime::VariableArray{4} = ReadDisk(db,"EGInput/FlFrTime") # [FuelEP,Plant,Area,Year] Fuel Adjustment Time (Years)
  FlFrVF::VariableArray{3} = ReadDisk(db,"EGInput/FlFrVF") # [FuelEP,Plant,Area] Fuel Fraction Variance Factor (Btu/Btu)
  FPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF") # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  Inflation0::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",First) # [Area,Year] Inflation Index ($/$)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnFlFr::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnFlFrMarginal::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFrMarginal") # [Unit,FuelEP,Year] Fuel Fraction Marginal Market Share (Btu/Btu)
  UnFlFrMSF::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFrMSF") # [Unit,FuelEP,Year] Fuel Fraction Market Share (Btu/Btu)
  UnFlFrMSM0::VariableArray{3} = ReadDisk(db,"EGCalDB/UnFlFrMSM0") # [Unit,FuelEP,Year] Fuel Fraction Non-Price Factor (Btu/Btu)
  UnFlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMax") # [Unit,FuelEP,Year] Fuel Fraction Maximum (Btu/Btu)
  UnFlFrMin::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMin") # [Unit,FuelEP,Year] Fuel Fraction Minimum (Btu/Btu)
  UnFlFrTime::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrTime") # [Unit,FuelEP,Year] Fuel Adjustment Time (Years)
  UnFlFrVF::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrVF") # [Unit,FuelEP] Fuel Fraction Variance Factor (Btu/Btu)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)

  #
  # Scratch Variables
  #
  ECFPFuelNG::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Natural Gas Fuel Price ($/mmBtu)
  FlFrMAW::VariableArray{3} = zeros(Float32,length(FuelEP),length(Plant),length(Area)) # [FuelEP,Plant,Area] Allocation Weights for Fuel Fraction (DLess)
  FlFrMU::VariableArray{3} = zeros(Float32,length(FuelEP),length(Plant),length(Area)) # [FuelEP,Plant,Area] Initial Estimate of Fuel Fraction Non-Price Factor
  FlFrTMAW::VariableArray{2} = zeros(Float32,length(Plant),length(Area)) # [Plant,Area] Total of Allocation Weights for Fuel Fraction (DLess)
  UnFlFrMAW::VariableArray{2} = zeros(Float32,length(Unit),length(FuelEP)) # [Unit,FuelEP] Allocation Weights for Fuel Fraction (DLess)
  UnFlFrMU::VariableArray{2} = zeros(Float32,length(Unit),length(FuelEP)) # [Unit,FuelEP] Initial Estimate of Fuel Fraction Non-Price Factor
  UnFlFrTMAW::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit] Total of Allocation Weights for Fuel Fraction (DLess)
  UnFlFrTotal::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit] Total of Fuel Fractions (Btu/Btu)
end

function Initialization(data)
  (; db,Areas,FuelEPs,Plants,Units,Year,Years) = data
  (;FlFrMax,FlFrMin,FlFrTime,FlFrVF) = data
  (;UnFlFrMax,UnFlFrMin,UnFlFrTime,UnFlFrVF) = data
  
  #@info "ECalibFungible.jl - 1 Initialization"  
  
  @. FlFrMax = 1 
  @. UnFlFrMax=1
  
  @. FlFrMin = 0
  @. UnFlFrMin=0

  @. FlFrVF=-10
  @. UnFlFrVF=-10

  years=collect(Zero:Last)
  for year in years, area in Areas, plant in Plants, fuelep in FuelEPs
    FlFrTime[fuelep,plant,area,year] = 1.0
  end
  for year in years, fuelep in FuelEPs, unit in Units
    UnFlFrTime[unit,fuelep,year] = 1.0
  end
  
  years=collect(Future:Final)
  for year in years, area in Areas, plant in Plants, fuelep in FuelEPs
    FlFrTime[fuelep,plant,area,year] = 10.0
  end
  for year in years, fuelep in FuelEPs, unit in Units
    UnFlFrTime[unit,fuelep,year] = 1.0
  end
  
  WriteDisk(db,"EGInput/FlFrMax",FlFrMax)
  WriteDisk(db,"EGInput/FlFrMin",FlFrMin)
  WriteDisk(db,"EGInput/FlFrTime",FlFrTime)
  WriteDisk(db,"EGInput/FlFrVF",FlFrVF)
  WriteDisk(db,"EGInput/UnFlFrMax",UnFlFrMax)
  WriteDisk(db,"EGInput/UnFlFrMin",UnFlFrMin)
  WriteDisk(db,"EGInput/UnFlFrTime",UnFlFrTime)
  WriteDisk(db,"EGInput/UnFlFrVF",UnFlFrVF)  

end


function UnitFuelPrices(data,year)
  (; db,Areas,ES,Fuels,FuelEP,FuelEPs) = data
  (; ECFPFuel,FFPMap,FPF) = data
  #@info "ECalibFungible.jl - 2 UnitFuelPrices"

  Electric = Select(ES,"Electric")
  for fuelep in FuelEPs, area in Areas
    ECFPFuel[fuelep,area,year] = sum(FPF[fuel,Electric,area,year]*
                                 FFPMap[fuelep,fuel] for fuel in Fuels)
  end
  
  for fuelep in FuelEPs, area in Areas
    ECFPFuel[fuelep,area,year] = max(ECFPFuel[fuelep,area,year],0.00001)
  end

end

function FungibleCalibPlant(data, year, plant, area)
  (;FuelEP,FuelEPs) = data
  (;ECFPFuel,FlFrMSM0,FlFrNew,FlFrTime,FlFrVF,Inflation,Inflation0) = data
  (;ECFPFuelNG,FlFrMAW,FlFrMU) = data
 # @info "ECalibFungible.jl - FungibleCalibPlant"   
  
  NaturalGas = Select(FuelEP,"NaturalGas")
  ECFPFuelNG[area] = ECFPFuel[NaturalGas,area,year]
  
  for fuelep in FuelEPs
    @finite_math FlFrMAW[fuelep,plant,area] = exp(FlFrVF[fuelep,plant,area]*
      log((ECFPFuel[fuelep,area,year]/Inflation[area,year])/(ECFPFuelNG[area]/Inflation0[area])))
  end
  
  for fuelep in FuelEPs
    @finite_math FlFrMU[fuelep,plant,area] = FlFrNew[fuelep,plant,area,year]/
      FlFrMAW[fuelep,plant,area]
  end
  
  FlFrMUMax = maximum(FlFrMU[FuelEPs,plant,area])
  
  for fuelep in FuelEPs
    FlFrMSM0[fuelep,plant,area,year] = log(FlFrMU[fuelep,plant,area]/FlFrMUMax)
    xxx = FlFrMSM0[fuelep,plant,area,year]
    if isinf(xxx)
      FlFrMSM0[fuelep,plant,area,year] = -170.39
    end
  end

end

function FungibleCalibUnit(data,year,unit,area)
  (;FuelEP,FuelEPs,Year) = data
  (;ECFPFuel,Inflation,Inflation0) = data
  (;UnFlFrMSM0,UnFlFrVF,xUnFlFr) = data
  (;ECFPFuelNG,UnFlFrMAW,UnFlFrMU) = data
  
  NaturalGas = Select(FuelEP,"NaturalGas")
  ECFPFuelNG[area] = ECFPFuel[NaturalGas,area,year]

  for fuelep in FuelEPs
    @finite_math UnFlFrMAW[unit,fuelep] = exp(UnFlFrVF[unit,fuelep]*
      log((ECFPFuel[fuelep,area,year]/Inflation[area,year])/(ECFPFuelNG[area]/Inflation0[area])))
  end
  
  for fuelep in FuelEPs     
    @finite_math UnFlFrMU[unit,fuelep] = xUnFlFr[unit,fuelep,year]/UnFlFrMAW[unit,fuelep]
  end
  
  UnFlFrMUMax = maximum(UnFlFrMU[unit,FuelEPs])
  
  for fuelep in FuelEPs
    UnFlFrMSM0[unit,fuelep,year] = log(UnFlFrMU[unit,fuelep]/UnFlFrMUMax)
    xxx = UnFlFrMSM0[unit,fuelep,year]
    if isinf(xxx)
      UnFlFrMSM0[unit,fuelep,year] = -170.39
    end
  end
  
  #@info " Inside FungibleCalibUnit Unit is $unit "
  #if (unit == 1288) ||(unit == 1281)
  #if (unit == 1288)  
  #  @info " "
  #  loc1 = Year[year]
  #  @info "ECalibFungible.jl - FungibleCalibUnit Unit = $unit, Area = $area, Year = $loc1"
  #
  #  fueleps = findall(xUnFlFr[unit,FuelEPs,year] .> 0)
  #  for fuelep in fueleps
  #    loc1 = xUnFlFr[unit,fuelep,year]
  #    @info "xUnFlFr[$unit,$fuelep,$year] = $loc1 "
  #  end
  #  for fuelep in fueleps
  #    loc1 = ECFPFuel[fuelep,area,year]
  #    @info "ECFPFuel[$fuelep,$area,$year] = $loc1 "
  #  end       
  #  for fuelep in fueleps
  #    loc1 = log(ECFPFuel[fuelep,area,year]/ECFPFuelNG[area])
  #    @info "log ECFPFuel[$fuelep,$area,$year] = $loc1 "
  #  end  
  #  for fuelep in fueleps
  #    loc1 = UnFlFrVF[unit,fuelep]
  #    @info "UnFlFrVF[$unit,$fuelep] = $loc1 "
  #  end    
  #  for fuelep in fueleps
  #    loc1 = UnFlFrMAW[unit,fuelep]
  #    @info "UnFlFrMAW[$unit,$fuelep] = $loc1 "
  #  end   
  #  for fuelep in fueleps
  #    loc1 = UnFlFrMU[unit,fuelep]
  #    @info "UnFlFrMU[$unit,$fuelep] = $loc1 "
  #  end    
  #  for fuelep in fueleps
  #    loc1 = UnFlFrMSM0[unit,fuelep,year]
  #    @info "1 UnFlFrMSM0[$unit,$fuelep,$year] = $loc1 "
  #  end    
  #  for fuelep in fueleps
  #    loc1 = log(UnFlFrMU[unit,fuelep]/UnFlFrMUMax)
  #    @info "2 UnFlFrMSM0[$unit,$fuelep,$year] = $loc1 "
  #  end        
  #end

  #
  # Add trap for the failure when UnFlFrMU equals UnFlFrMUMax
  # Currently not needed for electric units - Jeff Amlin 12/20/24
  #        
  #for fuelep in FuelEPs
  #  if UnFlFrMU[unit,fuelep] == UnFlFrMUMax  && 
  #     UnFlFrMSM0[unit,fuelep,year] != 0.0
  #    loc1 = Year[year]
  #    @info "ECalibFungible.jl - Max set to 0.0 Unit = $unit, Area = $area, Year = $loc1"
  #    UnFlFrMSM0[unit,fuelep,year] = 0.0  
  #  end
  #end
  
  #
  # Note: there are differences in UnFlFrMSM0 due to dramatic differences
  # in ECFPFuel where two fuels have non-zero market shares even the
  # difference in price is a factor of 10 or more.  
  # There is circumstantial evidence that log and exp generate diffeent
  # values in Julia and Promula espcially with very small values
  # This file is ok until we see the impact of the large model values
  # when we may need to do further testing/adjustments - Jeff Amlin 10/1/24
  # 
  
end

function ControlFungibleCalib(data)
  (;db) = data
  (;Area,Areas) = data
  (;FuelEPs,Plants,Units) = data
  (;Year,YearDS,Years) = data
  (;ECFPFuel,FlFrMSM0,FlFrNew,UnArea) = data
  (;UnFlFrMSM0,xUnFlFr) = data
  @info "ECalibFungible.jl - ControlFungibleCalib"  
  
  years = collect(Zero:Final)
  for year in years
    UnitFuelPrices(data,year)
  end
  
  @. FlFrMSM0 = -170.391296386718
  @. UnFlFrMSM0 = -170.391296386718
  
  years = collect(First:Final)
  
  for year in years
    prior = max(year-1,1)
    
    UnitFuelPrices(data,year)
    
    for area in Areas
      for plant in Plants
        for fuelep in FuelEPs
          if ((FlFrNew[fuelep,plant,area,year] > 0) & (ECFPFuel[fuelep,area,year] > 0.0))
            FungibleCalibPlant(data,year,plant,area)
          else
            FlFrMSM0[fuelep,plant,area,year] = FlFrMSM0[fuelep,plant,area,year-1]
          end
        end
      end
    end
    
    for area in Areas
      units = findall(UnArea[:] .== Area[area])
      for unit in units
      
        ExecuteFungibleCalib = false
        for fuelep in FuelEPs
          if xUnFlFr[unit,fuelep,year] > 0.0 && 
             ECFPFuel[fuelep,area,year] > 0.0       
            ExecuteFungibleCalib = true  
          end
        end 

        if ExecuteFungibleCalib == true
          
          FungibleCalibUnit(data,year,unit,area)
          
        else
          for fuelep in FuelEPs
            UnFlFrMSM0[unit,fuelep,year] = UnFlFrMSM0[unit,fuelep,year-1]
          end
        end
        
      end
    end
  end
  
  WriteDisk(db,"EGOutput/ECFPFuel",ECFPFuel)
  WriteDisk(db,"EGInput/FlFrMSM0",FlFrMSM0)
  WriteDisk(db,"EGCalDB/UnFlFrMSM0",UnFlFrMSM0)
  
end

function Fungible(data,unit,year,area)
  (;db) = data
  (;FuelEP,FuelEPs,Year) = data
  (;ECFPFuel,Inflation,Inflation0) = data
  (;UnFlFr,UnFlFrMarginal,UnFlFrMSF,UnFlFrMSM0,UnFlFrMax,UnFlFrMin,UnFlFrTime,UnFlFrVF) = data
  (;ECFPFuelNG,UnFlFrMAW,UnFlFrTMAW,UnFlFrTotal) = data
 # @info "ECalibFungible.jl - 6 Fungible Unit = $unit, Area = $area, Year = $year"  
  
  NaturalGas = Select(FuelEP,"NaturalGas")
  ECFPFuelNG[area] = ECFPFuel[NaturalGas,area,year]

  for fuelep in FuelEPs
    if UnFlFrMSM0[unit,fuelep,year] > -100.00
      @finite_math UnFlFrMAW[unit,fuelep] = exp(UnFlFrMSM0[unit,fuelep,year]+
        UnFlFrVF[unit,fuelep]*log((ECFPFuel[fuelep,area,year]/Inflation[area,year])/
        (ECFPFuelNG[area]/Inflation0[area])))
    else
      UnFlFrMAW[unit,fuelep] = 0.0
    end
  end
  
  UnFlFrTMAW[unit] = sum(UnFlFrMAW[unit,fuelep] for fuelep in FuelEPs)
  
  for fuelep in FuelEPs
    @finite_math UnFlFrMSF[unit,fuelep,year] = UnFlFrMAW[unit,fuelep]/UnFlFrTMAW[unit]
  end
  
  #
  # Apply Minimums and Maximums
  #
  UnFlFrCount = 1
  for fuelep in FuelEPs
    UnFlFrMarginal[unit,fuelep,year] = UnFlFrMSF[unit,fuelep,year]
  end
  while UnFlFrCount <= 10
  
    for fuelep in FuelEPs
      UnFlFrMarginal[unit,fuelep,year] = 
        min(max(UnFlFrMarginal[unit,fuelep,year],
                     UnFlFrMin[unit,fuelep,year]),
                     UnFlFrMax[unit,fuelep,year])
    end
  
    UnFlFrTotal[unit] = sum(UnFlFrMarginal[unit,fuelep,year] for fuelep in FuelEPs)
  
    for fuelep in FuelEPs
      @finite_math UnFlFrMarginal[unit,fuelep,year] = UnFlFrMarginal[unit,fuelep,year]/
                   UnFlFrTotal[unit]
    end
  
    UnFlFrCount = UnFlFrCount+1
  end
  
  prior = max(year-1,1)
  for fuelep in FuelEPs
    @finite_math UnFlFr[unit,fuelep,year] = UnFlFr[unit,fuelep,prior] + 
      ((UnFlFrMarginal[unit,fuelep,year]-UnFlFr[unit,fuelep,prior])/
      UnFlFrTime[unit,fuelep,year])
  end
  
  UnFlFrTotal[unit] = sum(UnFlFr[unit,fuelep,year] for fuelep in FuelEPs)
  for fuelep in FuelEPs
    @finite_math UnFlFr[unit,fuelep,year] = UnFlFr[unit,fuelep,year]/UnFlFrTotal[unit]
  end
  
  #@info " Inside Fungible Unit is $unit "
  #if (unit == 1288)
  #  @info " "
  #  loc1 = Year[year]
  #  @info "ECalibFungible.jl - FungibleCalibUnit Unit = $unit, Area = $area, Year = $loc1"
  #
  #  for fuelep in FuelEPs
  #    #if UnFlFr[unit,fuelep,year] > 0.00001
  #      loc1 = UnFlFr[unit,fuelep,year]
  #      @info "UnFlFr[$unit,$fuelep,$year] = $loc1 "
  #    #end
  #  end
  #  
  #  #for fuelep in FuelEPs
  #  #  loc1 = UnFlFrMSM0[unit,fuelep,year]
  #  #  @info "UnFlFrMSM0[$unit,$fuelep,$year] = $loc1 "
  #  #end     
  # 
  #end

end

function ControlFungible(data)
  (;db) = data
  (;Area,Areas,Units,Years) = data
  (;UnArea,UnFlFr,UnFlFrMarginal,UnFlFrMSF) = data
  @info "ECalibFungible.jl - ControlFungible"
  
  for year in Years
    for area in Areas
      units = findall(UnArea[:] .== Area[area])
      for unit in units
        Fungible(data,unit,year,area)
      end
    end
  end
  
  WriteDisk(db,"EGOutput/UnFlFr",UnFlFr)
  WriteDisk(db,"EGOutput/UnFlFrMarginal",UnFlFrMarginal)
  WriteDisk(db,"EGOutput/UnFlFrMSF",UnFlFrMSF)

end

function ControlFlow(db)
  data = EControl(; db)
  (; UnFlFr,UnFlFrMarginal,UnFlFrMSF,db) = data
  #@info "ECalibFungible.jl - ControlFlow"    

  Initialization(data)
  ControlFungibleCalib(data)
  ControlFungible(data)

end

function Control(db)
  @info "ECalibFungible.jl - Control"
  ControlFlow(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
