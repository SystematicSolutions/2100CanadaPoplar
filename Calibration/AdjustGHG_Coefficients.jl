#
# AdjustGHG_Coefficients.jl
#
############################################################
#                                                          #
#                       NOTICE                             #
#                                                          #
#  The ENERGY 2100 model is available by contacting        #
#  Systematic Solutions, Inc. (Telephone:937-767-1873).    #
#  The ENERGY 2100 model and all associated software are   #
#  the property of Systematic Solutions, Inc. and cannot   #
#  be distributed to others without the expressed          #
#  permission of Systematic Solutions, Inc. Any modified   #
#  ENERGY 2100-related software must include this notice   #
#  along with a designation stating who made the revision, #
#  the general focus of the revision, and the date of the  #
#  revision.                                               #
#                                                          #
#                                 March 27, 2006           #
#                                                          #
############################################################
#
#    Systematic Solutions, Inc.
#
#        Version: September 2010
#
# AdjustGHG_Coefficients.jl  Input File to Adjust Electric Unit CAC Coefficients
#
using EnergyModel

module AdjustGHG_Coefficients

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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Economic Driver)

  # Scratch Variables
end

function MacroPolicy(db)
  data = MControl(; db)
  (;Area,ECC,Poll) = data
  (;MEPOCX) = data
  
  # *
  # * Newfoundland
  # *
  NL = Select(Area,"NL")
  years = collect(Future:Final)
  # *
  # * Per 09/12/17 e-mail from Robin, NL IronOreMining is projected to have 
  # * 100kt process CO2 emissions in forecast but lacks historical data. Use
  # * coefficient from different sector that matches target projections. - Ian 09/12/17
  # *
  IronOreMining = Select(ECC,"IronOreMining")
  CO2 = Select(Poll,"CO2")
  Glass = Select(ECC,"Glass")
  @. MEPOCX[IronOreMining,CO2,NL,years] = MEPOCX[Glass,CO2,NL,years]
  
  # *
  # * Petroleum project to have 150kt of feedstock emissions but is missing demands
  # * Apply to MEPOCX for now
  # *
  #Petroleum = Select(ECC,"Petroleum")
  #OtherNonferrous = Select(ECC,"OtherNonferrous")
  #NEng = Select(Area,"NEng")
  #@. MEPOCX[Petroleum,CO2,NL,years] = MEPOCX[OtherNonferrous,CO2,NEng,years]
  # Write Disk(MEPOCX)
  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)

end

function CalibrationControl(db)
  @info "AdjustGHG_Coefficients.jl - CalibrationControl"

  MacroPolicy(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
