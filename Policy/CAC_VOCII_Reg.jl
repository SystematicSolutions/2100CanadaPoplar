#
# CAC_VOCII_Reg.jl - This jl models the VOC emission reductions for PRG-VOC Regulations
# Coefficient Multipliers Updated by Howard (Taeyeong) Park - 25.09.10
#     Updated multipliers are calculated in "2025_CAC_VOC_PetroleumSectors Analysis.xlsx
#

using EnergyModel

module CAC_VOCII_Reg

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB")#  Base Case Name

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
  FuPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCX") # [ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Process Emissions Coefficient (Tonnes/Driver)

  # Scratch Variables
  Reduce::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Year)) # [ECC,Poll,Year] Scratch Variable For Input Reductions
end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,ECC) = data
  (; Poll) = data
  (; FuPOCX) = data
  (; MEPOCX) = data
  (; Reduce) = data

  #
  # Read in reductions to marginal coefficient calculated by Environment Canada 
  # for downstream petroleum sectors for VOC emissions.
  #
  # Data is from VOC_PetroleumSectors_Coeff_calculations.xlsx
  #
  @. Reduce=1

  #
  ################
  #Alberta
  ################
  #
  areas = Select(Area,"AB")
  eccs = Select(ECC,["OilPipeline","OilSandsUpgraders","Petroleum"])
  years = collect(Yr(2026):Yr(2045))
  VOC = Select(Poll,"VOC")
  #! format: off
  Reduce[eccs, VOC, years] .= [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.7658  0.7613  0.7582  0.7564  0.7548  0.7487  0.7500  0.7505  0.7514  0.7522  0.7523  0.7523  0.7523  0.7523  0.7520  0.7513  0.7505  0.7495  0.7486  0.7479
      0.9857  0.9793  0.9730  0.9667  0.9604  0.9542  0.9542  0.9542  0.9542  0.9542  0.9542  0.9542  0.9543  0.9543  0.9543  0.9543  0.9543  0.9543  0.9543  0.9544
      0.6720  0.6454  0.6202  0.5950  0.5698  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447  0.5447
          ]
  #! format: on

  #
  # Apply reductions to fugitive coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  ################
  #British Columbia
  ################
  #
  areas = Select(Area,"BC")
  eccs = Select(ECC,["OilPipeline","Petroleum"])
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.7563  0.7510  0.7472  0.7449  0.7427  0.7359  0.7372  0.7378  0.7387  0.7396  0.7396  0.7397  0.7397  0.7396  0.7393  0.7386  0.7377  0.7367  0.7358  0.7350
      0.7122  0.7005  0.6892  0.6779  0.6666  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553  0.6553
    ]
  #! format: on

  #
  # Apply reductions to fugitive coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  ################
  #Manitoba
  ################
  #
  areas = Select(Area,"MB")
  eccs = Select(ECC,"OilPipeline")
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.5156  0.4861  0.4603  0.4378  0.4164  0.3849  0.3879  0.3892  0.3914  0.3934  0.3936  0.3936  0.3937  0.3935  0.3928  0.3912  0.3891  0.3868  0.3846  0.3828
    ]
  #! format: on

  #
  # Apply reductions to fugitive coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  ################
  #New Brunswick
  ################
  #
  areas = Select(Area,"NB")
  eccs = Select(ECC,"Petroleum")
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.7911  0.7150  0.6421  0.5693  0.4965  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236  0.4236
    ]
  #! format: on

  #
  # Apply reductions to fugitive coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  ################
  #Ontario
  ################
  #
  areas = Select(Area,"ON")
  eccs = Select(ECC,["OilPipeline","Petroleum"])
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.8350  0.8208  0.8078  0.7962  0.7851  0.7703  0.7715  0.7720  0.7728  0.7735  0.7736  0.7736  0.7736  0.7736  0.7733  0.7727  0.7719  0.7711  0.7702  0.7695
      0.9235  0.9021  0.8812  0.8602  0.8393  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183  0.8183
    ]
  #! format: on

  #
  # Apply reductions to fugitive coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  ################
  #Quebec
  ################
  #
  areas = Select(Area,"QC")
  eccs = Select(ECC,["OilPipeline","Petroleum"])
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.8956  0.8963  0.8977  0.8995  0.9013  0.9012  0.9017  0.9019  0.9023  0.9026  0.9026  0.9026  0.9026  0.9026  0.9025  0.9023  0.9019  0.9015  0.9012  0.9009
      0.8357  0.8276  0.8205  0.8135  0.8064  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993  0.7993
    ]
  #! format: on

  #
  # Apply reductions to fugitive coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  ################
  #Sask
  ################
  #
  areas = Select(Area,"SK")
  eccs = Select(ECC,["OilPipeline","OilSandsUpgraders","Petroleum"])
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] .= [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.3688  0.3720  0.3789  0.3886  0.3982  0.3969  0.3998  0.4011  0.4033  0.4052  0.4054  0.4054  0.4055  0.4053  0.4046  0.4031  0.4010  0.3988  0.3966  0.3948
      0.9139  0.8446  0.7755  0.7064  0.6374  0.5683  0.5683  0.5683  0.5683  0.5681  0.5678  0.5676  0.5676  0.5676  0.5676  0.5676  0.5676  0.5676  0.5676  0.5676
      0.7650  0.7249  0.6879  0.6509  0.6139  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769  0.5769
    ]
  #! format: on

  #
  # Apply reductions to fugitive coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  WriteDisk(db,"MEInput/FuPOCX",FuPOCX)
  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)

  #########################################################################################################
  # Adjust Other Chemical Sector which only has Process (MEPol) emissions and no fugitive (FuPol) emissions
  #########################################################################################################
  #
  ################
  #British Columbia
  ################
  #
  areas = Select(Area,"BC")
  eccs = Select(ECC,"OtherChemicals")
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.2341  0.2642  0.2812  0.2988  0.3162  0.3314  0.3467  0.3604  0.3728  0.3831  0.3922  0.4034  0.4201  0.4373  0.4530  0.4689  0.4854  0.5015  0.5175  0.5336
    ]
  #! format: on

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  ################
  #Ontario
  ################
  #
  areas = Select(Area,"ON")
  eccs = Select(ECC,"OtherChemicals")
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.9246  0.9064  0.8895  0.8735  0.8581  0.8429  0.8466  0.8500  0.8531  0.8555  0.8569  0.8589  0.8628  0.8667  0.8702  0.8731  0.8757  0.8783  0.8807  0.8829
    ]
  #! format: on

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  #
  ################
  #Quebec
  ################
  #
  areas = Select(Area,"QC")
  eccs = Select(ECC,"OtherChemicals")
  years = collect(Yr(2026):Yr(2045))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045 # Volatile Org Comp.
      0.9347  0.9188  0.9020  0.8865  0.8717  0.8572  0.8596  0.8621  0.8651  0.8685  0.8710  0.8731  0.8756  0.8782  0.8806  0.8828  0.8848  0.8870  0.8891  0.8912
    ]
  #! format: on

  #
  # Apply reductions to process coefficient
  #
  years = collect(Future:Yr(2045))
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2046):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,Yr(2045)]
  end

  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
end

function PolicyControl(db)
  @info "CAC_VOCII_Reg.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
