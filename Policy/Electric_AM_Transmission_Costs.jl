# 
# Electric_AM_Transmission_Costs.txp
# 
# Note: Assume the inputs are in 2019 CN$ - Jeff Amlin 02/16/22
# 
# Modified in the context of the electrification project 
# (should be kept for annual updates, except the second 
# BC-to-AB link that is considered "highly unlikely" by 
# NRCan as of Feb 2020; the QC-NB, QC-NS, and especially 
# NL-NS links may also be removed). JSLandry; Mar 22, 2020.
# 
# The second BC-to-AB link commented out for the annual 
# update, given it is considered "highly unlikely" by 
# NRCan. JSLandry; Jun 9, 2020
# 
# Adjusted the MB-SK link to put only the 500 MW link in 2030 
# without any contract and removed the NL-NS link that started 
# in 2040; both as per NRCan guidance for PCF2.1 modelling. 
# JSLandry; Nov 3, 2020
# 
# TD (June 2025): I removed all changes to LLMax because they are
# now considered in vLLMax.dat
# 

using EnergyModel

module Electric_AM_Transmission_Costs

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PEDC::VariableArray{3} = ReadDisk(db,"ECalDB/PEDC") # [ECC,Area,Year] Real Elect. Delivery Chg. ($/MWh)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
end

# 
# ***********************
# 
# Define Variable
# HDXLoad(Node,NodeX,TimeP,Month,Year)   'Exogenous Loading on Transmission Lines (MW)',
#  Disk(EGInput,HDXLoad(Node,NodeX,TimeP,Month,Year))  
# LLMax(Node,NodeX,TimeP,Month,Year)     'Maximum Loading on Transmission Lines (MW)',
#  Disk(EGInput,LLMax(Node,NodeX,TimeP,Month,Year)) 
# End Define Variable
# 
# ***********************
# 
# BC to AB. Restoration of existing link to full capacity 
# (from 800 to 1200 MW); no contract (no change to HDXLoad). 
# 
# Select Node(AB), NodeX(BC)
# Select Year(2030-Final)
# LLMax = 1200 
# Select Node*, NodeX*, Year*
# 
# ***********************
# 
# BC to AB. New link of 1000 MW; no contract (no change to 
# HDXLoad). 
# Commented out for the annual update. JSLandry; Jun 9, 2020
# 
# Select Node(AB), NodeX(BC)
# Select Year(2030-Final)
# LLMax = LLMax + 1000 
# Select Node*, NodeX*, Year*
# 
# ***********************
# 
# MB to SK - Phase 3. New link of 500 MW in 2030, without contract.
# Update TD: Cancelled in Ref25
# 
# Select Node(SK), NodeX(MB)
# Select Year(2030-Final)
# LLMax = LLMax + 500
# Select Node*, NodeX*, Year*
# 
# ***********************
# 
# QC to NB. New link of 325 MW and contract of ~2.5 TWh/yr.  
# Changed start date to 2030, capacity to 600 MW and contract to 2 TWh/yr as per Brad Little's email. JSO; Nov 5, 2021
# 
# Select Node(NB), NodeX(QC)
# Select Year(2030-Final)
# LLMax = LLMax + 600 
# HDXLoad= HDXLoad + 228
# Select Node*, NodeX*, Year*
# 
# ***********************
# 
# QC to NS. New link of 600 MW and contract of ~5 TWh/yr. 
# Changed start date to 2030, capacity to 550 MW and contract to 2 TWh/yr as per Brad Little s email. JSO; Nov 5, 2021
# 
# Select Node(NS), NodeX(QC)
# Select Year(2030-Final)
# LLMax = LLMax + 550 
# HDXLoad= HDXLoad + 228
# Select Node*, NodeX*, Year*
# 
# ***********************
# 
# NL to NS. Second Maritime Link of 250 MW and contract of 
# ~1.7 TWh/yr.  
# Postponed to 2040 for Ref21A. JSLandry; Sep 10, 2020
# Removed based on latest NRCan guidance. JSLandry; Nov 3, 2020
# Select Node(NS), NodeX(NL)
# Select Year(2040-Final)
# LLMax = LLMax + 250 
# HDXLoad= HDXLoad + 194
# Select Node*, NodeX*, Year*
# 
# ***********************
# 
# 
# Write Disk(LLMax)
# ***********************
# 

function ElecDeliveryCharge(db)
  data = EControl(; db)
  (;Area,Areas,ECC,ECCs,Year) = data
  (;PEDC,xInflation) = data

  # 
  # ***********************
  # 
  # BC to AB. Restoration of existing link => $350M on AB 
  # over 40 years, based on mean SaEC for 2030-2040 from Ref19 
  # (i.e. 72,123 GWh/yr) and an interest rate of 3.5% (based 
  # on E2020 WCC variable); gives $0.23/MWh.
  #   
  area = Select(Area,"AB")
  years = collect(Yr(2030):Final)
  for year in years, ecc in ECCs
    PEDC[ecc,area,year] = PEDC[ecc,area,year]+0.23/xInflation[area,Yr(2019)]
  end
  # 
  # ***********************
  # 
  # BC to AB. New 1000 MW link => $2B on AB (90%) and BC (10%) 
  # over 40 years, based on mean SaEC for 2030-2040 from Ref19 
  # (i.e. 72,123 GWh/yr for AB and 74,498 GWh/yr for BC) and an 
  # interest rate of 3.5% (based on E2020 WCC variable); gives 
  # $1.17/MWh for AB and $0.13/MWh for BC.
  # 
  # Commented out (previously forgotten). JSLandry; Sep 10, 2020
  #   
  # Select Area(AB), Year(2030-Final)
  # PEDC(ECC,Area,Y)=PEDC(ECC,Area,Y)+1.17/xInflation(Area,2019)
  # Select Area*, Year*
  # 
  # Select Area(BC), Year(2030-Final)
  # PEDC(ECC,Area,Y)=PEDC(ECC,Area,Y)+0.13/xInflation(Area,2019)
  # Select Area*, Year*
  # 
  # ***********************
  # 
  # MB to SK. New 1100 MW link => $1.3B on MB (60%) and SK (40%) 
  # over 40 years, based on mean SaEC for 2027-2040 from Ref19 
  # (i.e. 24,698 GWh/yr for MB and 24,953 GWh/yr for SK) and an 
  # interest rate of 3.5% (based on E2020 WCC variable); gives 
  # $1.48/MWh for MB and $0.98/MWh for SK.
  # 
  # Previous cost was $2B, but updated to $1.3B based on the latest 
  # info; also postponed to 2030. JSLandry; Nov 3, 2020. 
  #   
  area = Select(Area,"MB")
  years = collect(Yr(2030):Final)
  for year in years, ecc in ECCs
    PEDC[ecc,area,year] = PEDC[ecc,area,year]+1.48/xInflation[area,Yr(2019)]
  end
  # 
  area = Select(Area,"SK")
  years = collect(Yr(2030):Final)
  for year in years, ecc in ECCs
    PEDC[ecc,area,year] = PEDC[ecc,area,year]+0.98/xInflation[area,Yr(2019)]
  end
  # 
  # ***********************
  # 
  # QC to NB and QC to NS. These two new links (325 MW and 600 MW) 
  # are assumed to be jointly paid by the two receiving provinces 
  # => $2.5B on NB (30%) and NS (70%) over 40 years, based on mean 
  # SaEC for 2028-2040 from Ref19 (i.e. 11,261 GWh/yr for NB and 
  # 10,428 GWh/yr for NS) and an interest rate of 3.5% (based on 
  # E2020 WCC variable); gives $3.12/MWh for NB and $7.86/MWh for NS.
  #   
  # JSO; revised Nov 5, 2021.   
  # QC to NB and QC to NS. These two new links (600 MW and 550 MW) 
  # are assumed to be jointly paid by the two receiving provinces 
  # => $3B on NB (50%) and NS (50%) over 40 years, based on mean 
  # SaEC for 2030-2050 from Ref21_NoCP_TIM (i.e. 13,335 GWh/yr for NB and 
  # 12,555 GWh/yr for NS) and an interest rate of 3.5% (based on 
  # E2020 WCC variable); gives $5.27/MWh for NB and $5.59/MWh for NS.
  # 
  # Select Area(NB), Year(2030-Final)
  # PEDC(ECC,Area,Y)=PEDC(ECC,Area,Y)+5.27/xInflation(Area,2019)
  # Select Area*, Year*
  # 
  # Select Area(NS), Year(2030-Final)
  # PEDC(ECC,Area,Y)=PEDC(ECC,Area,Y)+5.59/xInflation(Area,2019)
  # Select Area*, Year*
  # 
  # ***********************
  # 
  # NL to NS. New 250 MW link => $1.5B on NS over 40 years, 
  # based on mean SaEC for 2030-2040 from Ref19 (i.e. 
  # 10,510 GWh/yr) and an interest rate of 3.5% (based on 
  # E2020 WCC variable); gives $6.68/MWh for NS.
  #  
  # Note that the value of $6.68/MWh should ideally be modified 
  # to reflect the new starting date of 2040 (instead of 2030) 
  # re: the value of mean SaEC used for the computation. Was 
  # not done now due to time limitation, the fact that this does 
  # not impact results until 2030, and the high uncertainties 
  # at play anyway. JSLandry; Sep 10, 2020
  # 
  # Removed. JSLandry; Nov 3, 2020. 
  # 
  # Select Area(NS), Year(2040-Final)
  # PEDC(ECC,Area,Y)=PEDC(ECC,Area,Y)+6.68/xInflation(Area,2019)
  # Select Area*, Year*
  # 
  # ***********************
  #
  WriteDisk(db,"ECalDB/PEDC",PEDC)
end

function PolicyControl(db)
  @info "Electric_AM_Transmission_Costs.jl - PolicyControl"
  ElecDeliveryCharge(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
  