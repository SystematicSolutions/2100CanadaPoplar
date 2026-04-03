#
# E2020SplitECCtoTOM.txt - Split industries based on gross output splits
#

using EnergyModel

module E2020SplitECCtoTOM

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") #  Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  GY::VariableArray{3} = ReadDisk(db,"KOutput/GY") # [ECCTOM,AreaTOM,Year] Gross Output for TOM Inputs (2017 $M/Yr)
  GY_BAU::VariableArray{3} = ReadDisk(RefNameDB,"KOutput/GY") # [ECCTOM,AreaTOM,Year] Gross Output for TOM Inputs (2017 $M/Yr)
  GYinto::VariableArray{3} = ReadDisk(db,"KOutput/GYinto") # [ECCTOM,AreaTOM,Year] Gross Output for TOM Inputs (2017 $M/Yr)
  GYinto_BAU::VariableArray{3} = ReadDisk(RefNameDB,"KOutput/GYinto") # [ECCTOM,AreaTOM,Year] Gross Output for TOM Inputs (2017 $M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM")   # [Area,AreaTOM]  Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapfromECCTOM") # [ECC,ECCTOM] Map from ECCTOM to ECC
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map from ECC to TOM
  MapUSECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSECCtoTOM") # [ECC,ECCTOM] Map between ECC to ECCTOM
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM ($/$)

  #
  # Scratch Variables
  #
  # counter 'Number of TOM industries, ECCTOM, associated with each ECC'
  GYTot_BAU::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Gross Output for TOM Inputs (2017 $M/Yr)
end

function ReadDatabases(data)
  (; db) = data
  (; BaseSw,RefSwitch) = data
  (; GY,GYinto,GYinto_BAU,GY_BAU) = data
 
  if (BaseSw == 0) && (RefSwitch == 0)
    # GY from Reference Case
  else
    # Variables from default database
    @. GY_BAU = GY
    @. GYinto_BAU = GYinto
  end
end

function CalcCNSplitECCtoECCTOM(data)
  (; db) = data
  (; Area,AreaTOM,AreaTOMs,ECC,ECCs,ECCTOM,ECCTOMs,Nation,Years) = data
  (; GY_BAU,GYinto_BAU,GYTot_BAU,IsActiveToECCTOM) = data
  (; MapAreaTOMNation,MapECCtoTOM,SplitECCtoTOM) = data

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1)
  years = collect(First:Final)
  
  CoalMining = Select(ECC,"CoalMining")
  CoalMiningTOM = Select(ECCTOM,"CoalMining")
  AB = Select(Area,"AB")
  ABTOM = Select(AreaTOM,"AB")

  #
  # For ECC mapped to ECCTOM:
  #    1-to-1:      SplitECCtoTOM equals 1.0
  #    Many-to-1:   SplitECCtoTOM equals 1.0
  #    1-to-many:   Calculate split based on GY
  #
  for year in years, areatom in areatoms, ecctom in ECCTOMs, ecc in ECCs
    SplitECCtoTOM[ecc,ecctom,areatom,year] = 0
  end

  eccs1 = Select(ECC,(from="Wholesale",to="AnimalProduction"))
  eccs2 = Select(ECC,["UtilityGen","Steam"])
  eccs = union(eccs1,eccs2)

  for ecc in eccs
    ecctoms = findall(MapECCtoTOM[ecc,ECCTOMs] .== 1)
    counter = 0
    for ecctom in ecctoms
      counter = counter+1
    end

    #
    # If counter is 1, then 1-1 mapping; if counter greater than 1, then calc SplitECCtoTOM based on GY
    #
    if counter == 1.0
      for year in years, areatom in areatoms, ecctom in ecctoms
        SplitECCtoTOM[ecc,ecctom,areatom,year] = 1
      end

    elseif counter > 1.0
      for year in years, areatom in areatoms
        GYTot_BAU[areatom,year] = sum(GYinto_BAU[ecctom,areatom,year] for ecctom in ecctoms)
        for ecctom in ecctoms
          @finite_math SplitECCtoTOM[ecc,ecctom,areatom,year] = GYinto_BAU[ecctom,areatom,year]/
            GYTot_BAU[areatom,year]
        end
      end
      
    end # If counter > 1
  end # ECC
  
#  for ecc in ECCs
#    ecctoms = findall(MapECCtoTOM[ecc,ECCTOMs] .== 1)
#    if !isempty(ecctoms)
#      for ecctom in ecctoms
#        @info("ECC = ",ECC[ecc])
#        @info("ECCTOM = ",ECCTOM[ecctom])
#        @info("SplitECCtoTOM = ",SplitECCtoTOM[ecc,ecctom,ABTOM,Yr(2024)])
#      end
#    end
#  end
  
#  for year in Years
#    @info("SplitECCtoTOM(CoalMining,AB) = ",SplitECCtoTOM[CoalMining,CoalMiningTOM,ABTOM,year])
#  end

end

function CalcUSSplitECCtoECCTOM(data)
  (; db) = data
  (; Area,AreaTOM,AreaTOMs,ECC,ECCs,ECCTOM,ECCTOMs,Nation,Years) = data
  (; GYinto_BAU,GYTot_BAU,MapAreaTOMNation,MapUSECCtoTOM) = data
  (; SplitECCtoTOM) = data

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  years = collect(First:Final)
  
  Retail = Select(ECC,"Retail")
  RetailTOM = Select(ECCTOM,"Retail")
  AB = Select(Area,"AB")
  ABTOM = Select(AreaTOM,"AB")

  #loc1=SplitECCtoTOM[Retail,RetailTOM,ABTOM,Yr(2023)]
  #@info " SplitECCtoTOM = $loc1 start of US"     


  #
  # For ECC mapped to ECCTOM:
  #    1-to-1:      SplitECCtoTOM equals 1.0
  #    Many-to-1:   SplitECCtoTOM equals 1.0
  #    1-to-many:   Calculate split based on GY
  #
  for year in years, areatom in areatoms, ecctom in ECCTOMs, ecc in ECCs
    SplitECCtoTOM[ecc,ecctom,areatom,year] = 0
  end

  eccs1 = Select(ECC,(from="Wholesale",to="AnimalProduction"))
  eccs2 = Select(ECC,["UtilityGen","Steam"])
  eccs = union(eccs1,eccs2)

  #loc1=SplitECCtoTOM[Retail,RetailTOM,ABTOM,Yr(2023)]
  #@info " SplitECCtoTOM = $loc1 before loop US"     

  for ecc in eccs
    ecctoms = findall(MapUSECCtoTOM[ecc,ECCTOMs] .== 1)
    counter = 0
    for ecctom in ecctoms
      counter = counter+1
    end

    #
    # If counter is 1, then 1-1 mapping; if counter greater than 1, then calc SplitECCtoTOM based on GY
    #
    if counter == 1.0
      for year in years, areatom in areatoms, ecctom in ecctoms
        SplitECCtoTOM[ecc,ecctom,areatom,year] = 1
      end
      
    #loc1 = SplitECCtoTOM[Retail,RetailTOM,ABTOM,Yr(2023)]
    #@info " SplitECCtoTOM = $loc1 US inside counter == 1"      
      
    elseif counter > 1.0
      for year in years, areatom in areatoms
        GYTot_BAU[areatom,year] = sum(GYinto_BAU[ecctom,areatom,year] for ecctom in ecctoms)
        for ecctom in ecctoms
          @finite_math SplitECCtoTOM[ecc,ecctom,areatom,year] = GYinto_BAU[ecctom,areatom,year]/
            GYTot_BAU[areatom,year]
        end
      end
      
    #loc1=SplitECCtoTOM[Retail,RetailTOM,ABTOM,Yr(2023)]
    #@info " SplitECCtoTOM = $loc1 US inside counter > 1"          
      
    end # If counter > 1    
    
  end # ECC
  
  #loc1=SplitECCtoTOM[Retail,RetailTOM,ABTOM,Yr(2023)]
  #@info " SplitECCtoTOM = $loc1 end of US"    
  
end

function CreateSplits(db)
  data = MControl(; db)
  (; SplitECCtoTOM) = data

  ReadDatabases(data)
  CalcCNSplitECCtoECCTOM(data)
  CalcUSSplitECCtoECCTOM(data)
  
  WriteDisk(db,"KOutput/SplitECCtoTOM",SplitECCtoTOM)

end 

#
########################
#
function Control(db)
  @info "E2020SplitECCtoTOM.jl - Control"
  CreateSplits(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
