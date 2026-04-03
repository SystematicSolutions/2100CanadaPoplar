#
# EInt_EnergyIntensity_Trans_Spikes.txo - Comparison of TOM baseline values to E2020 transfers
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

Base.@kwdef struct zEInt_EnergyIntensityTrans_SpikesData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  FuelTOMDS::SetArray = ReadDisk(db,"KInput/FuelTOMDS")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMDS::SetArray = ReadDisk(db,"KInput/VehicleTOMDS")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EIntTr::VariableArray{4} = ReadDisk(db,"KOutput/EIntTr") # [FuelTOM,VehicleTOM,AreaTOM,Year] TOM's Transportation Energy Intensity (mmBtu/2017$M)
  EIntETr::VariableArray{4} = ReadDisk(db,"KOutput/EIntETr") # [FuelTOM,VehicleTOM,AreaTOM,Year] Transportation Energy Intensity (mmBtu/2017$M)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation [year]
  IsActiveToFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToFuelTOM") # [FuelTOM,ToTOMVariable] "Flag Indicating Which FuelTOMs go into TOM by Variable")
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  DIF = zeros(Float32,length(Year))
  EEE = zeros(Float32,length(Year))
  HasAnnualSpike::VariableArray{4} = zeros(Float32,length(FuelTOM),length(VehicleTOM),length(AreaTOM),length(Year))
  PDIF = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
end

function EnergyIntensityTrans_Spikes_DtaRun(data,nationkey,areatoms)
  (; AreaTOM,AreaTOMDS,FuelTOM,FuelTOMs,FuelTOMDS) = data
  (; ToTOMVariable,VehicleTOM,VehicleTOMDS,VehicleTOMs,Year) = data
  (; BaseSw,EndTime,EIntTr,EIntETr,IsActiveToFuelTOM) = data
  (; DIF,EEE,HasAnnualSpike,PDIF,TOMBaseTime,TTT,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Title;Area;Fuel;VehicleTOM;Year;ENERGY2020;TOM;DIF;PercentDIF;E2020AnnualDIF")

  years = collect(First:Final)

  totomvariable = Select(ToTOMVariable,"EIntETr")
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)

  for areatom in areatoms
    for fueltom in fueltoms
      for vehicletom in VehicleTOMs
        for year in years
          TTT[year] = EIntTr[fueltom,vehicletom,areatom,year]
          EEE[year] = EIntETr[fueltom,vehicletom,areatom,year]
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
              HasAnnualSpike[fueltom,vehicletom,areatom,year] = 1
            elseif abs(AnnualDif) > 100
              HasAnnualSpike[fueltom,vehicletom,areatom,year] = 1
            end
          end
        end
      end
    end
  end

  for areatom in areatoms
    for fueltom in fueltoms
      for vehicletom in VehicleTOMs
        for year in years
          TTT[year] = EIntTr[fueltom,vehicletom,areatom,year]
          EEE[year] = EIntETr[fueltom,vehicletom,areatom,year]
          DIF[year] = TTT[year]-EEE[year]
          @finite_math PDIF[year] = (DIF[year]/EEE[year])*100
        end
        TotYears = sum(EEE[year] for year in years)
        if TotYears != 0
          if sum(HasAnnualSpike[fueltom,vehicletom,areatom,year] for year in years) > 0
            for year in years
              @finite_math AnnualDif = ((EEE[year]-EEE[year-1])/EEE[year-1])*100
              if (EEE[year] != 0) && (EEE[year-1] == 0)
                AnnualDif = 100
              end
              println(iob,"EIntTr;Energy Intensity (mmBtu/$TOMBaseTime \$1000);",AreaTOMDS[areatom],";",
                FuelTOMDS[fueltom],";",VehicleTOMDS[vehicletom],";",Year[year],";",EEE[year],";",
                TTT[year],";",DIF[year],";",PDIF[year],";",AnnualDif)
            end
          end
        end
      end
    end
  end

  filename = "zEInt_EnergyIntensity_Trans_Spikes-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zEInt_EnergyIntensity_Trans_Spikes_DtaControl(db)
  data = zEInt_EnergyIntensityTrans_SpikesData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "zEInt_EnergyIntensity_Trans_Spikes_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  EnergyIntensityTrans_Spikes_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  EnergyIntensityTrans_Spikes_DtaRun(data,Nation[US],areatoms)
end
if abspath(PROGRAM_FILE) == @__FILE__
  zEInt_EnergyIntensity_Trans_Spikes_DtaControl(DB)
end
