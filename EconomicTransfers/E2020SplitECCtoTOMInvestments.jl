#
# E2020SplitECCtoTOMInvestments.jl - Calculate fractions to split ECC into ECCTOM
#                                  based industry investment rations
#
using EnergyModel

module E2020SplitECCtoTOMInvestments

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name
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

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case)

  IFCinto::VariableArray{3} = ReadDisk(db,"KOutput/IFCinto") # [ECCTOM,AreaTOM,Year]  Construction Investments (2017 $M/Yr)
  IFMEinto::VariableArray{3} = ReadDisk(db,"KOutput/IFMEinto") # [ECCTOM,AreaTOM,Year]  Investments in Machinery & Equipment (2017 $M/Yr)
  IFCinto_BAU::VariableArray{3} = ReadDisk(RefNameDB,"KOutput/IFCinto") # [ECCTOM,AreaTOM,Year]  Construction Investments (2017 $M/Yr)
  IFMEinto_BAU::VariableArray{3} = ReadDisk(RefNameDB,"KOutput/IFMEinto") # [ECCTOM,AreaTOM,Year]  Investments in Machinery & Equipment (2017 $M/Yr)

  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM")   # [Area,AreaTOM]  Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map between ECC and ECCTOM
  MapUSECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSECCtoTOM") # [ECC,ECCTOM] Map from ECC to ECCTOM
  SplitECCtoTOMIFC::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFC") # [ECC,ECCTOM,AreaTOM,Year]  Split ECC to ECCTOM based on Construction Investments, IFC ($/$)
  SplitECCtoTOMIFME::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFME") # [ECC,ECCTOM,AreaTOM,Year]  Split ECC to ECCTOM based on M&E Investments, IFME ($/$)

  #
  # Scratch Variables
  #
  # counter 'Number of TOM industries, ECCTOM, associated with each ECC'
  IFCintoTot_BAU::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Construction Investments (2017 $M/Yr)
  IFCTot_BAU::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Construction Investments (2017 $M/Yr)
  IFMEintoTot_BAU::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Investments in Machinery & Equipment (2017 $M/Yr)
  IFMETot_BAU::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Investments in Machinery & Equipment (2017 $M/Yr)
end

function ReadDatabases(db)
   data = MControl(; db)
  (; BaseSw,RefSwitch) = data
  (; IFCinto,IFMEinto,IFMEinto_BAU) = data
  (; IFCinto_BAU) = data

  if (BaseSw == 0) && (RefSwitch == 0)
    # IFC from Reference Case
    # IFME from Reference Case
  else
    # Variables from default database
    @. IFCinto_BAU = IFCinto
    @. IFMEinto_BAU = IFMEinto
  end
end

function CalcCNSplitECCtoTOMInvestments(db)
  data = MControl(; db)
  (; AreaTOM,AreaTOMs,ECC,ECCs,ECCTOM,ECCTOMs,Nation,Years) = data
  (; IFCinto_BAU,IFCintoTot_BAU,IFMEinto_BAU,IFMEintoTot_BAU,MapAreaTOMNation) = data
  (; MapECCtoTOM,SplitECCtoTOMIFC,SplitECCtoTOMIFME) = data

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1)
  years = collect(First:Final)

  #
  # For ECC mapped to ECCTOM:
  #    1-to-1:      SplitECCtoIFC equals 1.0
  #    Many-to-1:   SplitECCtoIFC equals 1.0
  #    1-to-many:   Calculate split based on IFC
  #
  for year in years, areatom in areatoms, ecctom in ECCTOMs, ecc in ECCs
    SplitECCtoTOMIFC[ecc,ecctom,areatom,year] = 0
    SplitECCtoTOMIFME[ecc,ecctom,areatom,year] = 0
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
    # If counter is 1, then 1-1 mapping; if counter greater than 1, then calc SplitECCtoTOM based on Investments
    #
    if counter == 1
      for year in years, areatom in areatoms, ecctom in ecctoms
        SplitECCtoTOMIFC[ecc,ecctom,areatom,year] = 1
        SplitECCtoTOMIFME[ecc,ecctom,areatom,year] = 1
      end
    elseif counter > 1
      for year in years, areatom in areatoms
        IFCintoTot_BAU[areatom,year] = sum(IFCinto_BAU[ecctom,areatom,year] for ecctom in ecctoms)
        IFMEintoTot_BAU[areatom,year] = sum(IFMEinto_BAU[ecctom,areatom,year] for ecctom in ecctoms)

        for ecctom in ecctoms
          @finite_math SplitECCtoTOMIFC[ecc,ecctom,areatom,year] = IFCinto_BAU[ecctom,areatom,year]/
                         IFCintoTot_BAU[areatom,year]
          @finite_math SplitECCtoTOMIFME[ecc,ecctom,areatom,year] = IFMEinto_BAU[ecctom,areatom,year]/
                         IFMEintoTot_BAU[areatom,year]
       end
      end
    end # If counter > 1
  end # ECC

  WriteDisk(db,"KOutput/SplitECCtoTOMIFC",SplitECCtoTOMIFC)
  WriteDisk(db,"KOutput/SplitECCtoTOMIFME",SplitECCtoTOMIFME)


end #CalcCNSplitECCtoTOMInvestments

function CalcUSSplitECCtoTOMInvestments(db)
  data = MControl(; db)
  (; AreaTOM,AreaTOMs,ECC,ECCs,ECCTOMs,Nation,Years) = data
  (; IFCinto_BAU,IFCintoTot_BAU,IFMEinto_BAU,IFMEintoTot_BAU,MapAreaTOMNation,MapUSECCtoTOM) = data
  (; SplitECCtoTOMIFC,SplitECCtoTOMIFME) = data

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  years = collect(First:Final)

  #
  # For ECC mapped to ECCTOM:
  #    1-to-1:      SplitECCtoIFC equals 1.0
  #    Many-to-1:   SplitECCtoIFC equals 1.0
  #    1-to-many:   Calculate split based on IFC
  #
  for year in years, areatom in areatoms, ecctom in ECCTOMs, ecc in ECCs
    SplitECCtoTOMIFC[ecc,ecctom,areatom,year] = 0
    SplitECCtoTOMIFME[ecc,ecctom,areatom,year] = 0
  end

  eccs1 = Select(ECC,(from="Wholesale",to="AnimalProduction"))
  eccs2 = Select(ECC,["UtilityGen","Steam"])
  eccs = union(eccs1,eccs2)

  for ecc in eccs
    ecctoms = findall(MapUSECCtoTOM[ecc,ECCTOMs] .== 1)
    counter = 0
    for ecctom in ecctoms
      counter = counter+1
    end

    #
    # If counter is 1, then 1-1 mapping; if counter greater than 1, then calc SplitECCtoTOM based on Investments
    #
    if counter == 1.0
      for year in years, areatom in areatoms, ecctom in ecctoms
        SplitECCtoTOMIFC[ecc,ecctom,areatom,year] = 1
        SplitECCtoTOMIFME[ecc,ecctom,areatom,year] = 1
      end
    elseif counter > 1.0
      for year in years, areatom in areatoms
        IFCintoTot_BAU[areatom,year] = sum(IFCinto_BAU[ecctom,areatom,year] for ecctom in ecctoms)
        IFMEintoTot_BAU[areatom,year] = sum(IFMEinto_BAU[ecctom,areatom,year] for ecctom in ecctoms)

        for ecctom in ecctoms
          @finite_math SplitECCtoTOMIFC[ecc,ecctom,areatom,year] = IFCinto_BAU[ecctom,areatom,year]/
                                                IFCintoTot_BAU[areatom,year]
          @finite_math SplitECCtoTOMIFME[ecc,ecctom,areatom,year] = IFMEinto_BAU[ecctom,areatom,year]/
            IFMEintoTot_BAU[areatom,year]
       end
      end
    end # If counter > 1
  end # ECC

  WriteDisk(db,"KOutput/SplitECCtoTOMIFC",SplitECCtoTOMIFC)
  WriteDisk(db,"KOutput/SplitECCtoTOMIFME",SplitECCtoTOMIFME)

end #CalcUSSplitECCtoTOMInvestments

function CallSplits(db)
  data = MControl(; db)
  # (; SplitECCtoTOMIFC,SplitECCtoTOMIFME) = data

  ReadDatabases(db)
  CalcCNSplitECCtoTOMInvestments(db)
  CalcUSSplitECCtoTOMInvestments(db)

end # CallSplits

#
########################
#
function Control(db)
  @info "E2020SplitECCtoTOMInvestments.jl - Control"
  CallSplits(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
