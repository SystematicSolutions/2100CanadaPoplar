#
# CAC_VOC_PetroleumSectors.jl - This jl models the VOC emission reductions for PRG-VOC Regulations
# Coefficient Multipliers Updated by Howard (Taeyeong) Park - 25.09.10
#     Updated multipliers are calculated in "2025_CAC_VOC_PetroleumSectors Analysis.xlsx
#

using EnergyModel

module CAC_VOC_PetroleumSectors

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

  # Scratch Variables
  Reduce::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Year)) # [ECC,Poll,Year] Scratch Variable For Input Reductions
end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,ECC) = data
  (; Poll) = data
  (; FuPOCX) = data
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
  eccs = Select(ECC,["OilSandsUpgraders","Petrochemicals","Petroleum"])
  years = collect(Yr(2020):Yr(2037))
  VOC = Select(Poll,"VOC")
  #! format: off
  Reduce[eccs, VOC, years] .= [
    # 2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037 # Volatile Org Comp.
      1.00    1.00    0.9521  0.9240  0.9307  0.9307  0.9307  0.9265  0.9265  0.9265  0.9265  0.9265  0.9265  0.9265  0.9265  0.9265  0.9265  0.9265
      1.00    1.00    0.7605  0.6266  0.5944  0.6049  0.5911  0.5717  0.5754  0.5960  0.6249  0.6455  0.6649  0.6665  0.6700  0.6740  0.6733  0.6739
      1.00    1.00    0.8910  0.8325  0.8372  0.8372  0.8372  0.8284  0.8284  0.8284  0.8284  0.8284  0.8284  0.8284  0.8284  0.8284  0.8284  0.8284
          ]
  #! format: on

  #
  # Apply reductions to coefficient
  #
  years = collect(Future:Yr(2037))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2038):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2037)]
  end

  #
  ################
  #British Columbia
  ################
  #
  areas = Select(Area,"BC")
  eccs = Select(ECC,"Petroleum")
  years = collect(Yr(2020):Yr(2037))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037 # Volatile Org Comp.
      1.00    1.00    0.8985  0.8455  0.8393  0.8339  0.8339  0.8298  0.8298  0.8298  0.8298  0.8298  0.8298  0.8298  0.8298  0.8298  0.8298  0.8298
    ]
  #! format: on

  #
  # Apply reductions to coefficient
  #
  years = collect(Future:Yr(2037))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2038):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2037)]
  end

  #
  ################
  #New Brunswick
  ################
  #
  areas = Select(Area,"NB")
  eccs = Select(ECC,"Petroleum")
  years = collect(Yr(2020):Yr(2037))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037 # Volatile Org Comp.
      1.00    1.00    0.6554  0.4681  0.4500  0.4500  0.4500  0.4202  0.4202  0.4202  0.4202  0.4202  0.4202  0.4202  0.4202  0.4202  0.4202  0.4202
    ]
  #! format: on

  #
  # Apply reductions to coefficient
  #
  years = collect(Future:Yr(2037))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2038):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2037)]
  end

  #
  ################
  #Newfoundland
  ################
  #
  # NOTE: Newfoundland Petro. Prod. facilities are converted to biofuel units.
  #    Updated by Howard (Taeyeong) Park - 22.10.04
  #
  # areas = Select(Area,"NL")
  # eccs = Select(ECC,"Petroleum")
  # years = collect(Yr(2020):Yr(2037))
  #! format: off
  # Reduce[eccs, VOC, years] = [
  #   # 2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037 # Volatile Org Comp.
  #     1.00    1.00    0.5340  0.3287  0.3287  0.3287  0.3287  0.2865  0.2865  0.2865  0.2865  0.2865  0.2865  0.2865  0.2865  0.2865  0.2865  0.2865 # Petroleum Products
  #   ]
  #! format: on

  # #
  # # Apply reductions to coefficient
  # #
  # years = collect(Future:Yr(2037))
  # for year in years, area in areas, poll in VOC, ecc in eccs
  #   FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  # end

  # years = collect(Yr(2038):Final)
  # for year in years, area in areas, poll in VOC, ecc in eccs
  #   FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2037)]
  # end

  #
  ################
  #Ontario
  ################
  #
  areas = Select(Area,"ON")
  eccs = Select(ECC,["Petrochemicals","Petroleum"])
  years = collect(Yr(2020):Yr(2037))
  #! format: off
  Reduce[eccs, VOC, years] .= [
    # 2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037 # Volatile Org Comp.
      1.00    1.00    0.9357  0.9104  0.9386  0.9439  0.9435  0.9417  0.9431  0.9442  0.9451  0.9457  0.9463  0.9467  0.9469  0.9472  0.9469  0.9470
      1.00    1.00    0.7932  0.6925  0.8554  0.8599  0.8623  0.8559  0.8559  0.8559  0.8559  0.8559  0.8559  0.8559  0.8559  0.8559  0.8559  0.8559
    ]
  #! format: on

  #
  # Apply reductions to coefficient
  #
  years = collect(Future:Yr(2037))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2038):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2037)]
  end

  #
  ################
  #Quebec
  ################
  #
  areas = Select(Area,"QC")
  eccs = Select(ECC,"Petroleum")
  years = collect(Yr(2020):Yr(2037))
  #! format: off
  Reduce[eccs, VOC, years] = [
    # 2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037 # Volatile Org Comp.
      1.00    1.00    0.6122  0.4671  0.7716  0.7716  0.7716  0.7600  0.7600  0.7600  0.7600  0.7600  0.7600  0.7600  0.7600  0.7600  0.7600  0.7600
    ]
  #! format: on

  #
  # Apply reductions to coefficient
  #
  years = collect(Future:Yr(2037))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2038):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2037)]
  end

  #
  ################
  #Sask
  ################
  #
  areas = Select(Area,"SK")
  eccs = Select(ECC,["OilSandsUpgraders","Petroleum"])
  years = collect(Yr(2020):Yr(2037))
  #! format: off
  Reduce[eccs, VOC, years] = [
  # 2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037 # Volatile Org Comp.
    1.00    1.00    0.9413  0.9113  0.9113  0.9128  0.9128  0.9076  0.9076  0.9076  0.9076  0.9076  0.9076  0.9076  0.9076  0.9066  0.9057  0.9047 #  Oil Sands Upgraders
    1.00    11.00   0.8184  0.7163  0.7765  0.7765  0.7765  0.7629  0.7629  0.7629  0.7629  0.7629  0.7629  0.7629  0.7629  0.7629  0.7629  0.7629
  ]
  #! format: on

  #
  # Apply reductions to coefficient
  #
  years = collect(Future:Yr(2037))
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,year]*Reduce[ecc,poll,year]
  end

  years = collect(Yr(2038):Final)
  for year in years, area in areas, poll in VOC, ecc in eccs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2037)]
  end

  WriteDisk(db,"MEInput/FuPOCX",FuPOCX)
end

function PolicyControl(db)
  @info "CAC_VOC_PetroleumSectors.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
