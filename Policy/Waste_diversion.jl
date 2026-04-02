#
# Waste_diversion.jl
# Diversion values from the "Policy Summary" tab of the "Waste Diversion Notes" excel, "Waste Diversion John Approach" excel, and the List of Ref25 Policies SharePoint list. This version was last updated on July 10 2025. 
# Diversion targets are provincial averages based on bulk waste quantities or organic waste diversion targets
# Diversion rate values are a linear relationship between last historical year's diversion value and a provinces announced diversion target.
#
########################
#  MODEL VARIABLE    VDATA VARIABLE
#  ProportionDivertedWaste = vDiversionRate
########################
#

using EnergyModel

module Waste_diversion

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Waste::SetArray = ReadDisk(db,"MainDB/WasteKey")
  WasteDS::SetArray = ReadDisk(db,"MainDB/WasteDS")
  Wastes::Vector{Int} = collect(Select(Waste))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ProportionDivertedWaste::VariableArray{3} = ReadDisk(db,"MInput/ProportionDivertedWaste") # [Waste,Area,Year] Proportion of Diverted Waste <PDvW> (Tonnes/Tonnes)
  DiversionRate::VariableArray{3} = zeros(Float32,length(Waste),length(Area),length(Year)) # [Waste,Area,Year] proportion of diverted waste (tonnes/tonnes)
end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,Waste) = data
  (; DiversionRate,ProportionDivertedWaste) = data 
  
  BC = Select(Area,"BC")
  AB = Select(Area,"AB")
  SK = Select(Area,"SK")
  MB = Select(Area,"MB")
  ON = Select(Area,"ON")
  QC = Select(Area,"QC")
  NB = Select(Area,"NB") 
  NS = Select(Area,"NS")
  NL = Select(Area,"NL")
  YT = Select(Area,"YT")
  
  years = collect(Yr(2024):Yr(2050))
  
  #
  # assign standard diversion rates to all non-wood waste
  #  
  AshDry = Select(Waste,"AshDry")
  #                                 2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050  
  DiversionRate[AshDry,ON,years] = [0.25   0.27   0.28   0.29   0.31   0.32   0.33   0.35   0.36   0.37   0.39   0.40   0.41   0.43   0.44   0.45   0.46   0.48   0.49   0.50   0.52   0.53   0.54   0.56   0.57   0.58   0.60]
  DiversionRate[AshDry,NL,years] = [0.13   0.14   0.15   0.16   0.17   0.18   0.20   0.21   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.31   0.32   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43]
  DiversionRate[AshDry,SK,years] = [0.19   0.20   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30]
  DiversionRate[AshDry,YT,years] = [0.25   0.25   0.26   0.27   0.28   0.29   0.29   0.30   0.31   0.32   0.32   0.33   0.34   0.35   0.35   0.36   0.37   0.38   0.39   0.39   0.40   0.40   0.40   0.40   0.40   0.40   0.40]
  
  waste1 = Select(Waste,!=("WoodWastePulpPaper"))
  waste2 = Select(Waste,!=("WoodWasteSolidWood"))
  wastes = intersect(waste1,waste2)
  
  areas = Select(Area,["ON","NL","YT"])
  for year in years, area in areas, waste in wastes
  ProportionDivertedWaste[waste,area,year] = DiversionRate[AshDry,area,year]
  end

  #
  # Assign Organic diversion rates
  #
  areas = Select(Area,["BC","ON","QC","NL","MB","YT","SK"])
  years = collect(Yr(2024):Yr(2050))  
  #
  # Food Dry
  # 
  FoodDry = Select(Waste,"FoodDry")
  #                                  2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050
  DiversionRate[FoodDry,BC,years] = [0.40   0.41   0.43   0.44   0.46   0.47   0.49   0.50   0.52   0.53   0.55   0.56   0.58   0.59   0.61   0.62   0.64   0.65   0.67   0.68   0.70   0.71   0.73   0.74   0.76   0.77   0.79] 
  DiversionRate[FoodDry,ON,years] = [0.25   0.27   0.28   0.29   0.31   0.32   0.33   0.35   0.36   0.37   0.39   0.40   0.41   0.43   0.44   0.45   0.46   0.48   0.49   0.50   0.52   0.53   0.54   0.56   0.57   0.58   0.60]
  DiversionRate[FoodDry,QC,years] = [0.33   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43   0.44   0.45   0.46   0.47   0.49   0.50   0.51   0.52   0.53   0.54   0.55   0.57   0.58   0.59   0.60   0.61   0.62]
  DiversionRate[FoodDry,NL,years] = [0.13   0.14   0.15   0.16   0.17   0.18   0.20   0.21   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.31   0.32   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43]
  DiversionRate[FoodDry,MB,years] = [0.21   0.22   0.23   0.24   0.25   0.26   0.27   0.29   0.30   0.31   0.32   0.33   0.34   0.35   0.36   0.37   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38]
  DiversionRate[FoodDry,YT,years] = [0.25   0.25   0.26   0.27   0.28   0.29   0.29   0.30   0.31   0.32   0.32   0.33   0.34   0.35   0.35   0.36   0.37   0.38   0.39   0.39   0.40   0.40   0.40   0.40   0.40   0.40   0.40]
  DiversionRate[FoodDry,SK,years] = [0.19   0.20   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30]
  #
  # Food Wet
  #  
  FoodWet = Select(Waste,"FoodWet")
  #                                  2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050
  DiversionRate[FoodWet,BC,years] = [0.40   0.41   0.43   0.44   0.46   0.47   0.49   0.50   0.52   0.53   0.55   0.56   0.58   0.59   0.61   0.62   0.64   0.65   0.67   0.68   0.70   0.71   0.73   0.74   0.76   0.77   0.79]
  DiversionRate[FoodWet,ON,years] = [0.25   0.27   0.28   0.29   0.31   0.32   0.33   0.35   0.36   0.37   0.39   0.40   0.41   0.43   0.44   0.45   0.46   0.48   0.49   0.50   0.52   0.53   0.54   0.56   0.57   0.58   0.60]
  DiversionRate[FoodWet,QC,years] = [0.33   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43   0.44   0.45   0.46   0.47   0.49   0.50   0.51   0.52   0.53   0.54   0.55   0.57   0.58   0.59   0.60   0.61   0.62]
  DiversionRate[FoodWet,NL,years] = [0.13   0.14   0.15   0.16   0.17   0.18   0.20   0.21   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.31   0.32   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43]
  DiversionRate[FoodWet,MB,years] = [0.21   0.22   0.23   0.24   0.25   0.26   0.27   0.29   0.30   0.31   0.32   0.33   0.34   0.35   0.36   0.37   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38]
  DiversionRate[FoodWet,YT,years] = [0.25   0.25   0.26   0.27   0.28   0.29   0.29   0.30   0.31   0.32   0.32   0.33   0.34   0.35   0.35   0.36   0.37   0.38   0.39   0.39   0.40   0.40   0.40   0.40   0.40   0.40   0.40]
  DiversionRate[FoodWet,SK,years] = [0.19   0.20   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30]
  #
  # Yard And Garden Dry
  #  
  YardGardenDry = Select(Waste,"YardAndGardenDry")
  #                                        2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050
  DiversionRate[YardGardenDry,BC,years] = [0.40   0.41   0.43   0.44   0.46   0.47   0.49   0.50   0.52   0.53   0.55   0.56   0.58   0.59   0.61   0.62   0.64   0.65   0.67   0.68   0.70   0.71   0.73   0.74   0.76   0.77   0.79]
  DiversionRate[YardGardenDry,ON,years] = [0.25   0.27   0.28   0.29   0.31   0.32   0.33   0.35   0.36   0.37   0.39   0.40   0.41   0.43   0.44   0.45   0.46   0.48   0.49   0.50   0.52   0.53   0.54   0.56   0.57   0.58   0.60]
  DiversionRate[YardGardenDry,QC,years] = [0.33   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43   0.44   0.45   0.46   0.47   0.49   0.50   0.51   0.52   0.53   0.54   0.55   0.57   0.58   0.59   0.60   0.61   0.62]
  DiversionRate[YardGardenDry,NL,years] = [0.13   0.14   0.15   0.16   0.17   0.18   0.20   0.21   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.31   0.32   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43]
  DiversionRate[YardGardenDry,MB,years] = [0.21   0.22   0.23   0.24   0.25   0.26   0.27   0.29   0.30   0.31   0.32   0.33   0.34   0.35   0.36   0.37   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38]
  DiversionRate[YardGardenDry,YT,years] = [0.25   0.25   0.26   0.27   0.28   0.29   0.29   0.30   0.31   0.32   0.32   0.33   0.34   0.35   0.35   0.36   0.37   0.38   0.39   0.39   0.40   0.40   0.40   0.40   0.40   0.40   0.40]
  DiversionRate[YardGardenDry,SK,years] = [0.19   0.20   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30]
  #
  # Yard And Garden Wet
  # 
  YardGardenWet = Select(Waste,"YardAndGardenWet")
  #                                        2024   2025   2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050
  DiversionRate[YardGardenWet,BC,years] = [0.40   0.41   0.43   0.44   0.46   0.47   0.49   0.50   0.52   0.53   0.55   0.56   0.58   0.59   0.61   0.62   0.64   0.65   0.67   0.68   0.70   0.71   0.73   0.74   0.76   0.77   0.79]
  DiversionRate[YardGardenWet,ON,years] = [0.25   0.27   0.28   0.29   0.31   0.32   0.33   0.35   0.36   0.37   0.39   0.40   0.41   0.43   0.44   0.45   0.46   0.48   0.49   0.50   0.52   0.53   0.54   0.56   0.57   0.58   0.60]
  DiversionRate[YardGardenWet,QC,years] = [0.33   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43   0.44   0.45   0.46   0.47   0.49   0.50   0.51   0.52   0.53   0.54   0.55   0.57   0.58   0.59   0.60   0.61   0.62]
  DiversionRate[YardGardenWet,NL,years] = [0.13   0.14   0.15   0.16   0.17   0.18   0.20   0.21   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.31   0.32   0.34   0.35   0.36   0.37   0.38   0.39   0.41   0.42   0.43]
  DiversionRate[YardGardenWet,MB,years] = [0.21   0.22   0.23   0.24   0.25   0.26   0.27   0.29   0.30   0.31   0.32   0.33   0.34   0.35   0.36   0.37   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38   0.38]
  DiversionRate[YardGardenWet,YT,years] = [0.25   0.25   0.26   0.27   0.28   0.29   0.29   0.30   0.31   0.32   0.32   0.33   0.34   0.35   0.35   0.36   0.37   0.38   0.39   0.39   0.40   0.40   0.40   0.40   0.40   0.40   0.40]
  DiversionRate[YardGardenWet,SK,years] = [0.19   0.20   0.22   0.23   0.24   0.25   0.27   0.28   0.29   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30   0.30]
  
  wastes = Select(Waste,["FoodDry","FoodWet","YardAndGardenDry","YardAndGardenWet"])
  areas = Select(Area,["BC","ON","QC","NL","MB","YT","SK"])
  for waste in wastes, area in areas, year in years
    ProportionDivertedWaste[waste,area,year] = DiversionRate[waste,area,year]  
  end

  WriteDisk(db,"MInput/ProportionDivertedWaste",ProportionDivertedWaste)
end

function PolicyControl(db)
  @info "Waste_diversion.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
