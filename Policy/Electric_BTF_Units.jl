#
#    Electric_BTF_Units.jl - NRCan Clean Electricity Policy 
#

using EnergyModel

module   Electric_BTF_Units

import ...EnergyModel: ReadDisk,WriteDisk,Select,Zero
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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnPSoMaxGridFraction::VariableArray{2} = ReadDisk(db,"EGInput/UnPSoMaxGridFraction") # [Unit,Year]  Maximum Fraction Sold to Grid (GWh/GWh)
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
 
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Unit,Units,Year,Years) = data
  (; UnArea,UnCode,UnCogen,UnSector,UnPSoMaxGridFraction) = data

  years = collect(Yr(2022):Yr(2050))

  for unit in Units
    if (UnCode[unit] == "AB_OSM006001") ||
       (UnCode[unit] == "AB_Edm_95S") ||
       (UnCode[unit] == "AB_Mulligan_NG") ||
       (UnCode[unit] == "AB_Lindbergh_NG") ||
       (UnCode[unit] == "AB00029600101") ||
       (UnCode[unit] == "AB_SaddleHills") ||
       (UnCode[unit] == "AB_Edson_NG") ||
       (UnCode[unit] == "AB00018500101") ||
       (UnCode[unit] == "AB00018500102") ||
       (UnCode[unit] == "AB06100000100") ||
       (UnCode[unit] == "BC_Cariboo_BIO") ||
       (UnCode[unit] == "BC_Conifex_BIO") ||
       (UnCode[unit] == "BC_Harmac_BIO") ||
       (UnCode[unit] == "BC_Intercon_BIO") ||
       (UnCode[unit] == "BC_NorthWd_NG") ||
       (UnCode[unit] == "BC_NorthWd1_BIO") ||
       (UnCode[unit] == "BC_NorthWd2_BIO") ||
       (UnCode[unit] == "BC_PrinceG_BIO") ||
       (UnCode[unit] == "BC00002900101") ||
       (UnCode[unit] == "BC00003500101") ||
       (UnCode[unit] == "BC00003500201") ||
       (UnCode[unit] == "BC00003800101") ||
       (UnCode[unit] == "BC00003800102") ||
       (UnCode[unit] == "BC00004100101") ||
       (UnCode[unit] == "BC00004100102") ||
       (UnCode[unit] == "BC00004600101") ||
       (UnCode[unit] == "BC00005000101") ||
       (UnCode[unit] == "BC00005000103") ||
       (UnCode[unit] == "BC00020300101") ||
       (UnCode[unit] == "BC00036700101") ||
       (UnCode[unit] == "LB_Voisey_OMM") ||
       (UnCode[unit] == "LB06100000040") ||
       (UnCode[unit] == "NB_Nackawic_BIO") ||
       (UnCode[unit] == "NB00006100203") ||
       (UnCode[unit] == "NL_Hebron") ||
       (UnCode[unit] == "NL_MEGA_FOM") ||
       (UnCode[unit] == "NS_Hawkesbury") ||
       (UnCode[unit] == "ON_New_002") ||
       (UnCode[unit] == "ON_New_005") ||
       (UnCode[unit] == "ON_New_025") ||
       (UnCode[unit] == "ON_Scarborough") ||
       (UnCode[unit] == "ON_TB_Cond_BIO") ||
       (UnCode[unit] == "ON00000100500") ||
       (UnCode[unit] == "ON00008800105") ||
       (UnCode[unit] == "ON00010100103") ||
       (UnCode[unit] == "ON00015700100") ||
       (UnCode[unit] == "ON00019800101") ||
       (UnCode[unit] == "ON00023900100") ||
       (UnCode[unit] == "ON00029500101") ||
       (UnCode[unit] == "QC_Chapais_BIO") ||
       (UnCode[unit] == "QC_Felicien_BIO") ||
       (UnCode[unit] == "QC_Malartic_DIE") ||
       (UnCode[unit] == "QC_Temisca2_BIO") ||
       (UnCode[unit] == "QC_Thurso_BIO_1") ||
       (UnCode[unit] == "QC00016200801") ||
       (UnCode[unit] == "QC00016200901") ||
       (UnCode[unit] == "QC00026500101") ||
       (UnCode[unit] == "QC00026600101") ||
       (UnCode[unit] == "QC00029100101") ||
       (UnCode[unit] == "SK00015200201") ||
       (UnCode[unit] == "SK00015200202") ||
       (UnCode[unit] == "SK00038800100")
      for year in years
        UnPSoMaxGridFraction[unit,year] = 0             
      end
    end
  end
  
  units = Select(UnSector,==("FrontierOilMining"))
  for year in years, unit in units
    UnPSoMaxGridFraction[unit,year] = 0             
  end
  
  unsectors = Select(UnSector,==("HeavyOilMining"))
  unareas = Select(UnArea,==("NL"))
  units = intersect(unsectors,unareas)
  for year in years, unit in units
    UnPSoMaxGridFraction[unit,year] = 0             
  end

  WriteDisk(db,"EGInput/UnPSoMaxGridFraction",UnPSoMaxGridFraction)

end
  
function PolicyControl(db)
  @info "Electric_BTF_Units.jl - PolicyControl"
  ElecPolicy(db)
end
  
if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
