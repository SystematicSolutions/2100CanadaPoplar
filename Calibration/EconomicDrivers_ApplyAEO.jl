#
# EconomicDrivers_ApplyAEO.jl - If MacroSwitch(US) eq "AEO", then assign AEO drivers.
#                 If MacroSwitch eq "TOM", then use AEO growth in future to calibrate to AEO.
#
using EnergyModel

module EconomicDrivers_ApplyAEO

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  Floorspace::VariableArray{3} = ReadDisk(db,"MOutput/Floorspace") # [ECC,Area,Year] Floor Space (Million Sq Ft)
  MacroSwitch::Vector{String} = ReadDisk(db, "MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  xFloorspaceAEO::VariableArray{3} = ReadDisk(db,"MInput/xFloorspaceAEO") # [ECC,Area,Year] Floor Space from AEO (Million Sq Ft)
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (2017 M$/Yr)
  xGOAEO::VariableArray{3} = ReadDisk(db,"MInput/xGOAEO") # [ECC,Area,Year] Gross Output from AEO (Real M$/Yr)
  xGRP::VariableArray{2} = ReadDisk(db,"MInput/xGRP") # [Area,Year] Gross Regional Product (2017 $M/Yr)
  xGRPAEO::VariableArray{2} = ReadDisk(db,"MInput/xGRPAEO") # [Area,Year] US Gross Regional Product from AEO (Real M$/Yr)
  xHHSAEO::VariableArray{3} = ReadDisk(db,"MInput/xHHSAEO") # [ECC,Area,Year] Households from AEO (Households)
  xHHS::VariableArray{3} = ReadDisk(db,"MInput/xHHS") # [ECC,Area,Year] Households (Households)
  xTHHS::VariableArray{2} = ReadDisk(db,"MInput/xTHHS") # [Area,Year] Total Households (Households)
  xHSize::VariableArray{3} = ReadDisk(db,"MInput/xHSize") # [ECC,Area,Year] Households (Households)
  xPop::VariableArray{3} = ReadDisk(db,"MInput/xPop") # [ECC,Area,Year] Population (Millions)
  xPopT::VariableArray{2} = ReadDisk(db,"MInput/xPopT") # [Area,Year] Population (Millions of People)
  xPopAEO::VariableArray{3} = ReadDisk(db,"MInput/xPopAEO") # [ECC,Area,Year] Population by Household Type (Millions)
  xPopTAEO::VariableArray{2} = ReadDisk(db,"MInput/xPopTAEO") # [Area,Year] Population (Millions)
  xRPI::VariableArray{2} = ReadDisk(db,"MInput/xRPI") # [Area,Year] Total Personal Income (Real M$/Yr)
  xRPIAEO::VariableArray{2} = ReadDisk(db,"MInput/xRPIAEO") # [Area,Year] Total Personal Income (Real M$/Yr)

  # Scratch Variables
  AEOGrowthFlspc::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Annual Growth Rate AEO Floor Space
  AEOGrowthGO::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Annual Growth Rate AEO Gross Output
  AEOGrowthGRP::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Annual Growth Rate AEO GRP
  AEOGrowthHHS::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Annual Growth Rate AEO Households
  AEOGrowthPop::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Annual Growth Rate AEO Population
  AEOGrowthPopT::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Annual Growth Rate AEO Population
  AEOGrowthRPI::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Annual Growth Rate AEO Personal Income
end

function MCalibration(db)
  data = MControl(; db)
  (;ECC,ECCs,Nation,Years) = data
  (;ANMap,Floorspace,MacroSwitch,xFloorspaceAEO,xGO,xGOAEO,xGRP,xGRPAEO,xHHSAEO,xHHS) = data
  (;xTHHS,xHSize,xPop,xPopT,xPopAEO,xPopTAEO,xRPI,xRPIAEO) = data
  (;AEOGrowthFlspc,AEOGrowthGO,AEOGrowthGRP,AEOGrowthHHS,AEOGrowthPop,AEOGrowthPopT,AEOGrowthRPI) = data
  
  #
  # US Areas Only
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  # if MacroSwitch[US] == "AEO"

  #   #
  #   # Assign AEO values to drivers
  #   #
  #   for area in areas
  #     xGRP[area,:] .= xGRPAEO[area,:]
  #     xHHS[:,area,:] .= xHHSAEO[:,area,:]
  #     xPop[:,area,:] .= xPopAEO[:,area,:]
  #     xPopT[area,:] .= xPopTAEO[area,:]
  #     xRPI[area,:] .= xRPIAEO[area,:]
  #   end

  #   #
  #   # Total households and average household size
  #   #
  #   for year in Years, area in areas
  #     xTHHS[area,year] = sum(xHHS[ecc,area,year] for ecc in ECCs)
  #   end
  #   for year in Years, area in areas
  #     @finite_math xHSize[area,year] = xPop[ecc,area,year]/xHHS[ecc,area,year]
  #   end

  #   #
  #   # Commercial
  #   #
  #   eccs = Select(ECC, (from = "Wholesale", to = "StreetLighting"))
  #   for ecc in eccs, area in areas
  #     Floorspace[ecc,area,:] .= xFloorspaceAEO[ecc,area,:]
  #   end

  #   #
  #   # Industrial Gross Output - Use xGOAEO for Industrial Gross Output
  #   #
  #   eccs = Select(ECC, (from = "Food", to = "AnimalProduction"))
  #   for ecc in eccs, area in areas
  #     xGO[ecc,area,:] .= xGOAEO[ecc,area,:]
  #   end
  
  #   WriteDisk(db,"MOutput/Floorspace",Floorspace)
  #   WriteDisk(db,"MInput/xGO",xGO)
  #   WriteDisk(db,"MInput/xGRP",xGRP)
  #   WriteDisk(db,"MInput/xHHS",xHHS)
  #   WriteDisk(db,"MInput/xTHHS",xTHHS)
  #   WriteDisk(db,"MInput/xHSize",xHSize)
  #   WriteDisk(db,"MInput/xPop",xPop)
  #   WriteDisk(db,"MInput/xPopT",xPopT)
  #   WriteDisk(db,"MInput/xRPI",xRPI)

  # end

  #
  # Apply AEO growth to drivers when reading the Oxford Model US values
  #
  # TODOJulia MacroSwitch
  # if MacroSwitch[US] == "TOM"
    #
    # Calculate annual growth rates
    #
    years = collect(Future:Final)
    for area in areas, year in years
      @finite_math AEOGrowthGRP[area,year] = (xGRPAEO[area,year] - xGRPAEO[area,year-1]) /
          xGRPAEO[area,year-1]
      @finite_math AEOGrowthPopT[area,year] = (xPopTAEO[area,year] - xPopTAEO[area,year-1]) /
          xPopTAEO[area,year-1]
      @finite_math  AEOGrowthRPI[area,year] = (xRPIAEO[area,year] - xRPIAEO[area,year-1]) /
          xRPIAEO[area,year-1]
      for ecc in ECCs
        @finite_math  AEOGrowthFlspc[ecc,area,year] = (xFloorspaceAEO[ecc,area,year] -
            xFloorspaceAEO[ecc,area,year-1]) / xFloorspaceAEO[ecc,area,year-1]
        @finite_math  AEOGrowthGO[ecc,area,year] = (xGOAEO[ecc,area,year] - 
            xGOAEO[ecc,area,year-1]) / xGOAEO[ecc,area,year-1]
        @finite_math  AEOGrowthHHS[ecc,area,year] = (xHHSAEO[ecc,area,year] -
           xHHSAEO[ecc,area,year-1]) / xHHSAEO[ecc,area,year-1]      
        @finite_math  AEOGrowthPop[ecc,area,year] = (xPopAEO[ecc,area,year] -
            xPopAEO[ecc,area,year-1]) / xPopAEO[ecc,area,year-1]   
      end
    end
    
    #
    # GRP - Apply AEO's Growth Rate to GRP
    #
    for area in areas, year in years
      xGRP[area,year] = xGRP[area,year-1] * (1 + AEOGrowthGRP[area,year])
    end

    #
    # Households - Do not read US households from TOM yet; comment out until xHHS comes from TOM.
    # 
    # Select Year(Future-Final)
    # xHHS(ECC,A,Y)=xHHS(ECC,A,Y-1)*(1+AEOGrowthHHS(ECC,A,Y))
    #
    # Residential - Apply AEO Growth Rates to Personal Income, and Population
    #
    for area in areas, year in years
      for ecc in ECCs
        xPop[ecc,area,year] = xPop[ecc,area,year-1] * (1 + AEOGrowthPop[ecc,area,year])
      end
      xPopT[area,year] = xPopT[area,year-1] * (1 + AEOGrowthPopT[area,year])
      xRPI[area,year] = xRPI[area,year-1] * (1 + AEOGrowthRPI[area,year])
    end

    # Commercial Gross Output - Grow TOM's GO with AEO Floor Space Growth Rate (for calibration to AEO)
    #
    # Note:  When running with TOM, US commercial driver is gross output.
    #
    eccs = Select(ECC,(from = "Wholesale", to = "OtherCommercial"))
    for ecc in eccs, area in areas, year in years
      xGO[ecc,area,year] = xGO[ecc,area,year-1] * (1 + AEOGrowthFlspc[ecc,area,year])
    end
    
    #
    # Industrial Gross Output - Apply xGOAEO Growth Rate to Industrial Gross Output
    #
    eccs1 = Select(ECC,(from = "Food", to = "NonMetalMining"))
    eccs2 = Select(ECC,["LightOilMining","ConventionalGasProduction"])
    eccs3 = Select(ECC,(from = "CoalMining", to = "CropProduction"))
    eccs = union(eccs1,eccs2,eccs3)
    for ecc in eccs, area in areas, year in years
      xGO[ecc,area,year] = xGO[ecc,area,year-1] * (1 + AEOGrowthGO[ecc,area,year])
    end

    WriteDisk(db,"MInput/xHHS",xHHS)
    WriteDisk(db,"MInput/xPop",xPop)
    WriteDisk(db,"MInput/xPopT",xPopT)
    WriteDisk(db,"MInput/xRPI",xRPI)
    WriteDisk(db,"MInput/xGO",xGO)
    WriteDisk(db,"MInput/xGRP",xGRP)

  # end 

end

function CalibrationControl(db)
  @info "EconomicDrivers_ApplyAEO.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
