#
# zIFME_DeviceInvestments.jl - Comparison of TOM baseline values to E2020 transfers
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

Base.@kwdef struct zIFME_DeviceInvestmentsData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  IFME::VariableArray{3} = ReadDisk(db,"KOutput/IFME") # [ECCTOM,AreaTOM,Year]  Investments in Machinery & Equipment (2017 $M/Yr)
  IFMEe::VariableArray{3} = ReadDisk(db,"KOutput/IFMEe") # [ECCTOM,AreaTOM,Year] E2020 Investments in Machinery & Equipment (2017 $M/Yr)
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

function DeviceInvestments_DtaRun(data,nationkey,areatoms)
  (; AreaTOM,AreaTOMDS) = data
  (; ECCTOM,ECCTOMDS,ToTOMVariable,Year) = data
  (; BaseSw,EndTime,IFME,IFMEe,IsActiveToECCTOM,TOMBaseTime,TOMBaseYear) = data
  (; DIF,EEE,PDIF,TTT,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Title;Area;Sector;Year;ENERGY2020;TOM;DIF;PercentDIF;AnnualDIF")

  years = collect(First:Final)
  totomvariable = Select(ToTOMVariable,"DefaultintoTOM")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)

    for ecctom in ecctoms
      for areatom in areatoms
        @. TTT = 0
        @. EEE = 0
        @. DIF = 0
        @. PDIF = 0
        for year in years
          TTT[year] = IFME[ecctom,areatom,year]
          EEE[year] = IFMEe[ecctom,areatom,year]
          DIF[year] = TTT[year]-EEE[year]
          @finite_math PDIF[year] = (DIF[year]/EEE[year])*100 
        end
        TotYears = sum(EEE[year] for year in years)
        if TotYears != 0
          for year in years
            @finite_math AnnualDif = ((EEE[year]-EEE[year-1])/EEE[year-1])*100
  
            #
            # If previous EEE(Y) is nonzero and EEE(Y-1) is zero, then write 100%
            #
            if (EEE[year] != 0) && (EEE[year-1] == 0) && (year !=Yr(1986))
              AnnualDif = 100
            end
            println(iob,"IFME;Device Investments ($TOMBaseTime \$M);",AreaTOMDS[areatom],";",
              ECCTOMDS[ecctom],";",Year[year],";",EEE[year],";",TTT[year],";",DIF[year],";",
              PDIF[year],";",AnnualDif)
           
          end
        end
      end
    end
      
    @. TTT = 0
    @. EEE = 0
    @. DIF = 0
    @. PDIF = 0
  
  filename = "zIFME_DeviceInvestments-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zIFME_DeviceInvestments_DtaControl(db)
  data = zIFME_DeviceInvestmentsData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "zIFME_DeviceInvestments_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  DeviceInvestments_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  DeviceInvestments_DtaRun(data,Nation[US],areatoms)
end

if abspath(PROGRAM_FILE) == @__FILE__
  zIFME_DeviceInvestments_DtaControl(DB)
end
