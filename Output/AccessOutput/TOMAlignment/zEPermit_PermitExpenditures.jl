#
# EPermit_PermitExpenditures.jl - Comparison of TOM baseline values to E2020 transfers
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct zEPermit_PermitExpendituresData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EPermit::VariableArray{3} = ReadDisk(db,"KOutput/EPermit") # [ECCTOM,AreaTOM,Year] TOM Cost of Emissions Permits ($M/Yr)
  EPermitE::VariableArray{3} = ReadDisk(db,"KOutput/EPermitE") # [ECCTOM,AreaTOM,Year] Cost of Emissions Permits ($M/Yr)
  EPermitHH::VariableArray{2} = ReadDisk(db,"KOutput/EPermitHH") # [AreaTOM,Year] TOM Household Cost of Emissions Permits ($M/Yr)
  EPermitHHe::VariableArray{2} = ReadDisk(db,"KOutput/EPermitHHe") # [AreaTOM,Year] Household Cost of Emissions Permits ($M/Yr)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation [year]
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  DIF = zeros(Float32,length(Year))
  EEE = zeros(Float32,length(Year))
  PDIF = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
end
 
function PermitExpenditures_DtaRun(data,nationkey,areatoms)
  (; AreaTOM,AreaTOMDS) = data
  (; ECCTOM,ECCTOMs,ECCTOMDS,ToTOMVariable,Year) = data
  (; BaseSw,EndTime,EPermit,EPermitE,EPermitHH,EPermitHHe) = data
  (; IsActiveToECCTOM,TOMBaseTime,TOMBaseYear) = data
  (; DIF,EEE,PDIF,TTT,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Title;Area;Sector;Year;ENERGY2020;TOM;DIF;PercentDIF")

  years = collect(First:Final)
  totomvariable = Select(ToTOMVariable,"EPermitE")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)

  for areatom in areatoms
    for year in years
      TTT[year] = EPermitHH[areatom,year]
      EEE[year] = EPermitHHe[areatom,year]
      DIF[year] = TTT[year]-EEE[year]
    end
    TotYears = sum(EEE[year] for year in years)
    if TotYears != 0
      for year in years
  #      Write ("EPermitHH;Emission Permit Cost ($TOMBaseTime $M/Yr);",AreaTOMDS::0,";Residential;",Yrv(Year),";",TTT(Year))
  #      Write ("Emission Permit Cost ($TOMBaseTime $M/Yr);",AreaTOMDS::0,";Residential;EPermitHHe;ENERGY 2020;",Yrv(Year),";",EEE(Year))  
      end
    end

    for year in years
      TTT[year] = 0
      EEE[year] = 0
      DIF[year] = 0
    end
    
    for ecctom in ecctoms
      for year in years
        TTT[year] = EPermit[ecctom,areatom,year]
        EEE[year] = EPermitE[ecctom,areatom,year]
        DIF[year] = TTT[year]-EEE[year]
      end
      TotYears = sum(EEE[year] for year in years)
      if TotYears != 0
        for year in years
          println(iob,"EPermit;Emission Permit Cost ($TOMBaseTime \$M/Yr);",
            AreaTOMDS[areatom],";",ECCTOMDS[ecctom],";",Year[year],";",
            @sprintf("%12.4f",EEE[year]),";",@sprintf("%12.4f",TTT[year]),";",
            @sprintf("%12.4f",DIF[year]),";",PDIF[year])
        end  
      end
    end
  end

  filename = "zEPermit_PermitExpenditures-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end

end

function zEPermit_PermitExpenditures_DtaControl(db)
  data = zEPermit_PermitExpendituresData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "zEPermit_PermitExpenditures_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  PermitExpenditures_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  PermitExpenditures_DtaRun(data,Nation[US],areatoms)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zEPermit_PermitExpenditures_DtaControl(DB)
end