#
# GHG_VB_Res.jl - Read in Residential GHG emissions coefficients from VBInput
#
using EnergyModel

module GHG_VB_Res

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))
  
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgPOCX::VariableArray{5} = ReadDisk(db,"$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coefficient (Tonnes/TBtu)
  ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  FsPOCX::VariableArray{5} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vFsPOCX::VariableArray{5} = ReadDisk(db,"VBInput/vFsPOCX") # [Fuel,ECC,Poll,vArea,Year] Feedstock Pollution coefficient (Tonnes/TBtu)
  vPOCX::VariableArray{5} = ReadDisk(db,"VBInput/vPOCX") # [FuelEP,ECC,Poll,vArea,Year] Pollution coefficient (Tonnes/TBtu)
  # Scratch Variables
  FsFsPOCX::VariableArray{5} = zeros(Float32,length(Fuel),length(EC),length(Poll),length(vArea),length(Year)) # (Fuel,EC,Poll,vArea,Year)
  PPOCX::VariableArray{6} = zeros(Float32,length(Enduse),length(FuelEP),length(EC),length(Poll),length(vArea),length(Year)) # (Enduse,FuelEP,EC,Poll,vArea,Year)
end

function ResCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Area,ECCMap,ECC,ECs,Enduse) = data
  (;Enduses,FuelEPs,Fuels) = data
  (;Poll,Years,vArea) = data
  (;CgPOCX,FsPOCX,POCX,PPOCX,vFsPOCX,vPOCX) = data
  
  GHGs = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
    
  println("Reading Residential GHG POCX")  
  
  for eu in Enduses,fuel in FuelEPs,ec in ECs,poll in GHGs, area in AreasCanada,year in Years
    POCX[eu,fuel,ec,poll,area,year]=0
  end
  
  ResECCs = Select(ECC, (from = "SingleFamilyDetached", to = "OtherResidential"))
  
  for ecc in ResECCs
    ec = findall(x -> x == 1.0,ECCMap[ECs,ecc])
    if ec != []
      ec = ec[1]
      for area in AreasCanada
        varea = Select(vArea,Area[area])
          for eu in Enduses,fuel in FuelEPs,poll in GHGs,year in Years
            PPOCX[eu,fuel,ec,poll,varea,year]=vPOCX[fuel,ecc,poll,varea,year]
            POCX[eu,fuel,ec,poll,area,year]=PPOCX[eu,fuel,ec,poll,varea,year]
          end
      end
    end
  end
  
  years = collect(Future:Final)
  
  for eu in Enduses,fuel in FuelEPs,ec in ECs,poll in GHGs,area in AreasCanada, year in years
    if POCX[eu,fuel,ec,poll,area,year] == 0
      POCX[eu,fuel,ec,poll,area,year]=POCX[eu,fuel,ec,poll,area,year-1]
    end    
  end
  
  firstEU = Select(Enduse,"Heat")
  
  for fuel in FuelEPs,ec in ECs,poll in GHGs,area in AreasCanada, year in Years
    # Using eu 1 to mimic promula
  # CgPOCX(FuelEP,EC,Poll,Area,Y)=POCX(EU,FuelEP,EC,Poll,Area,Y)
    CgPOCX[fuel,ec,poll,area,year]=POCX[firstEU,fuel,ec,poll,area,year]
  end
  
  println("Reading Residential GHG FsPOCX")  
  
  for fuel in Fuels,ec in ECs,poll in GHGs, area in AreasCanada,year in Years
    FsPOCX[fuel,ec,poll,area,year]=0
  end
   
  for ecc in ResECCs
    ec = findall(x -> x == 1.0,ECCMap[ECs,ecc])
    if ec != []
      ec = ec[1]
      for area in AreasCanada
       varea = Select(vArea,Area[area])
       for fuel in Fuels,poll in GHGs,year in Years
         FsPOCX[fuel,ec,poll,area,year]=vFsPOCX[fuel,ecc,poll,varea,year]
       end        
      end
    end
  end
  
  years = collect(Future:Final)
  
  for fuel in Fuels,ec in ECs,poll in GHGs,area in AreasCanada, year in years
    if FsPOCX[fuel,ec,poll,area,year] == 0
      FsPOCX[fuel,ec,poll,area,year]=FsPOCX[fuel,ec,poll,area,year-1]
    end    
  end
  
  
  
  WriteDisk(db,"$Input/POCX",POCX)
  WriteDisk(db,"$Input/CgPOCX",CgPOCX)
  WriteDisk(db,"$Input/FsPOCX",FsPOCX)
end

function CalibrationControl(db)
  @info "GHG_VB_Res.jl - CalibrationControl"

  ResCalibration(db)
  

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
