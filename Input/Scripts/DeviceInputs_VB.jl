#
# DeviceInputs_VB.jl - Map residential energy demands from VBInput
#
using EnergyModel

module DeviceInputs_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreas::Vector{Int} = collect(Select(vArea))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))
  vTech::SetArray = ReadDisk(db,"MainDB/vTechKey")
  vTechDS::SetArray = ReadDisk(db,"MainDB/vTechDS")
  vTechs::Vector{Int} = collect(Select(vTech))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu) 
  DOCF::VariableArray{5} = ReadDisk(db,"$Input/DOCF") # [Enduse,Tech,EC,Area,Year] Device Operating Cost Fraction ($/Yr/$)
  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # [EC,ECC] 'Map between EC and ECC'
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vDCC::VariableArray{5} = ReadDisk(db,"VBInput/vDCC") # [vEnduse,vTech,ECC,Area,Year] Device Capital Cost (Local 1985$/mmBtu/Yr)
  vDEE::VariableArray{5} = ReadDisk(db,"VBInput/vDEE") # [vEnduse,vTech,ECC,Area,Year] Efficiency Trend (Btu/Btu)
  vDEM::VariableArray{5} = ReadDisk(db,"VBInput/vDEM") # [vEnduse,vTech,ECC,Area,Year] Maximum Device Efficiency (Btu/Btu)
  vDEStd::VariableArray{5} = ReadDisk(db,"VBInput/vDEStd") # [vEnduse,vTech,ECC,Area,Year] Device Efficiency Standards (Btu/Btu)
  vDOCF::VariableArray{4} = ReadDisk(db,"VBInput/vDOCF") # [vEnduse,vTech,ECC,Year] Device Operating Cost Fraction ($/$)
  vDPL::VariableArray{4} = ReadDisk(db,"VBInput/vDPL") # [vEnduse,vTech,ECC,Year] Physical Life of Equipment (Years)
  vEUMap::VariableArray{2} = ReadDisk(db,"$Input/vEUMap") # [vEnduse,Enduse] Map between Enduse and vEnduse
  vTechMap::VariableArray{2} = ReadDisk(db, "$Input/vTechMap") # [vTech,Tech] 'Map between Tech and vTech'
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 
  xDPL::VariableArray{5} = ReadDisk(db, "$Input/xDPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Area,Areas,Nation,ECCs,ECs,Enduses,Techs) = data
  (;Years,vAreas,vEnduses,vTechs) = data
  (;DEM,DEStd,DOCF,ECCMap,xDCC,xDEE,xDPL) = data
  (;ANMap,vDCC,vDEE,vDEM,vDEStd,vDOCF,vDPL,vAreaMap,vEUMap,vTechMap) = data

  # 
  # vDEM current reads all values into 1985
  # 
  for ecc in ECCs
    for ec in findall(ECCMap[ECs,ecc] .== 1.0)
      for enduse in Enduses
        for venduse in findall(vEUMap[vEnduses,enduse] .== 1.0)
          for tech in Techs
            for vtech in findall(vTechMap[vTechs,tech] .== 1.0) 
              for area in Areas
                DEM[enduse,tech,ec,area] = vDEM[venduse,vtech,ecc,area,Zero]
              end
            end
          end
        end
      end
    end
  end
  
  WriteDisk(db,"$Input/DEM",DEM)

  # 
  # vDEE/vDCC 
  # 
  # Initialize xDEE
  #
  @. xDEE = -99
  @. xDCC = -99

  for ecc in ECCs
    for ec in findall(ECCMap[ECs,ecc] .== 1.0)
      for enduse in Enduses
        for venduse in findall(vEUMap[vEnduses,enduse] .== 1.0)
          for tech in Techs
            for vtech in findall(vTechMap[vTechs,tech] .== 1.0) 
              for area in Areas, year in Years
                if vDEE[venduse,vtech,ecc,area,year] > 0
                  xDEE[enduse,tech,ec,area,year] = vDEE[venduse,vtech,ecc,area,year]
                end
                if vDCC[venduse,vtech,ecc,area,year] > 0
                  xDCC[enduse,tech,ec,area,year] = vDCC[venduse,vtech,ecc,area,year]
                end
                if vDEStd[venduse,vtech,ecc,area,year] > 0
                  DEStd[enduse,tech,ec,area,year] = vDEStd[venduse,vtech,ecc,area,year]
                end
                if vDOCF[venduse,vtech,ecc,year] > 0
                  DOCF[enduse,tech,ec,area,year] = vDOCF[venduse,vtech,ecc,year]
                end
              end
              for area in Areas
                vareas = findall(x -> x == 1.0,vAreaMap[area,vAreas])
                for varea in vareas
                  for year in Years
                    if vDPL[venduse,vtech,ecc,year] > 0
                      xDPL[enduse,tech,ec,area,year] = vDPL[venduse,vtech,ecc,year]
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  #
  # US/MX uses ON DPL values
  #
  
  CN = Select(Nation,"CN")
  ON = Select(Area,"ON")
  areas = findall(ANMap[:,CN] .!= 1.0)

  for enduse in Enduses, tech in Techs, ec in ECs, area in areas, year in Years
    xDPL[enduse,tech,ec,area,year] = xDPL[enduse,tech,ec,ON,year]
  end

  WriteDisk(db,"$Input/DEStd",DEStd)
  WriteDisk(db,"$Input/DOCF",DOCF)
  WriteDisk(db,"$Input/xDCC",xDCC)
  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xDPL",xDPL)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreas::Vector{Int} = collect(Select(vArea))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))
  vTech::SetArray = ReadDisk(db,"MainDB/vTechKey")
  vTechDS::SetArray = ReadDisk(db,"MainDB/vTechDS")
  vTechs::Vector{Int} = collect(Select(vTech))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu) 
  DOCF::VariableArray{5} = ReadDisk(db,"$Input/DOCF") # [Enduse,Tech,EC,Area,Year] Device Operating Cost Fraction ($/Yr/$)
  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # [EC,ECC] 'Map between EC and ECC'
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vDCC::VariableArray{5} = ReadDisk(db,"VBInput/vDCC") # [vEnduse,vTech,ECC,Area,Year] Device Capital Cost (Local 1985$/mmBtu/Yr)
  vDEE::VariableArray{5} = ReadDisk(db,"VBInput/vDEE") # [vEnduse,vTech,ECC,Area,Year] Efficiency Trend (Btu/Btu)
  vDEM::VariableArray{5} = ReadDisk(db,"VBInput/vDEM") # [vEnduse,vTech,ECC,Area,Year] Maximum Device Efficiency (Btu/Btu)
  vDEStd::VariableArray{5} = ReadDisk(db,"VBInput/vDEStd") # [vEnduse,vTech,ECC,Area,Year] Device Efficiency Standards (Btu/Btu)
  vDOCF::VariableArray{4} = ReadDisk(db,"VBInput/vDOCF") # [vEnduse,vTech,ECC,Year] Device Operating Cost Fraction ($/$)
  vDPL::VariableArray{4} = ReadDisk(db,"VBInput/vDPL") # [vEnduse,vTech,ECC,Year] Physical Life of Equipment (Years)
  vEUMap::VariableArray{2} = ReadDisk(db,"$Input/vEUMap") # [vEnduse,Enduse] Map between Enduse and vEnduse
  vTechMap::VariableArray{2} = ReadDisk(db, "$Input/vTechMap") # [vTech,Tech] 'Map between Tech and vTech'
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 
  xDPL::VariableArray{5} = ReadDisk(db, "$Input/xDPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Area,Areas,Nation,ECCs,ECs,Enduses,Techs) = data
  (;Years,vAreas,vEnduses,vTechs) = data
  (;DEM,DEStd,DOCF,ECCMap,xDCC,xDEE,xDPL) = data
  (;ANMap,vDCC,vDEE,vDEM,vDEStd,vDOCF,vDPL,vAreaMap,vEUMap,vTechMap) = data

  #* 
  #* vDEM current reads all values into 1985
  #* 
  for ecc in ECCs
    for ec in findall(ECCMap[ECs,ecc] .== 1.0)
      for enduse in Enduses
        for venduse in findall(vEUMap[vEnduses,enduse] .== 1.0)
          for tech in Techs
            for vtech in findall(vTechMap[vTechs,tech] .== 1.0) 
              for area in Areas
                DEM[enduse,tech,ec,area] = vDEM[venduse,vtech,ecc,area,Zero]
              end
            end
          end
        end
      end
    end
  end
  
  WriteDisk(db,"$Input/DEM",DEM)

  # 
  # vDEE/vDCC 
  # 
  # Initialize xDEE
  #
  @. xDEE = -99
  @. xDCC = -99

  for ecc in ECCs
    for ec in findall(ECCMap[ECs,ecc] .== 1.0)
      for enduse in Enduses
        for venduse in findall(vEUMap[vEnduses,enduse] .== 1.0)
          for tech in Techs
            for vtech in findall(vTechMap[vTechs,tech] .== 1.0) 
              for area in Areas, year in Years
                if vDEE[venduse,vtech,ecc,area,year] > 0
                  xDEE[enduse,tech,ec,area,year] = vDEE[venduse,vtech,ecc,area,year]
                end
                if vDCC[venduse,vtech,ecc,area,year] > 0
                  xDCC[enduse,tech,ec,area,year] = vDCC[venduse,vtech,ecc,area,year]
                end
                if vDEStd[venduse,vtech,ecc,area,year] > 0
                  DEStd[enduse,tech,ec,area,year] = vDEStd[venduse,vtech,ecc,area,year]
                end
                if vDOCF[venduse,vtech,ecc,year] > 0
                  DOCF[enduse,tech,ec,area,year] = vDOCF[venduse,vtech,ecc,year]
                end
              end
              for area in Areas
                vareas = findall(x -> x == 1.0,vAreaMap[area,vAreas])
                for varea in vareas
                  for year in Years
                    if vDPL[venduse,vtech,ecc,year] > 0
                      xDPL[enduse,tech,ec,area,year] = vDPL[venduse,vtech,ecc,year]
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  #
  # US/MX uses ON DPL values
  #
  
  CN = Select(Nation, "CN")
  ON = Select(Area,"ON")
  areas = findall(ANMap[:,CN] .!= 1.0)

  for enduse in Enduses, tech in Techs, ec in ECs, area in areas, year in Years
    xDPL[enduse,tech,ec,area,year] = xDPL[enduse,tech,ec,ON,year]
  end

  WriteDisk(db,"$Input/DEStd",DEStd)
  WriteDisk(db,"$Input/DOCF",DOCF)
  WriteDisk(db,"$Input/xDCC",xDCC)
  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xDPL",xDPL)

end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreas::Vector{Int} = collect(Select(vArea))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))
  vTech::SetArray = ReadDisk(db,"MainDB/vTechKey")
  vTechDS::SetArray = ReadDisk(db,"MainDB/vTechDS")
  vTechs::Vector{Int} = collect(Select(vTech))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu) 
  DOCF::VariableArray{5} = ReadDisk(db,"$Input/DOCF") # [Enduse,Tech,EC,Area,Year] Device Operating Cost Fraction ($/Yr/$)
  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # [EC,ECC] 'Map between EC and ECC'
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vDCC::VariableArray{5} = ReadDisk(db,"VBInput/vDCC") # [vEnduse,vTech,ECC,Area,Year] Device Capital Cost (Local 1985$/mmBtu/Yr)
  vDEE::VariableArray{5} = ReadDisk(db,"VBInput/vDEE") # [vEnduse,vTech,ECC,Area,Year] Efficiency Trend (Btu/Btu)
  vDEM::VariableArray{5} = ReadDisk(db,"VBInput/vDEM") # [vEnduse,vTech,ECC,Area,Year] Maximum Device Efficiency (Btu/Btu)
  vDEStd::VariableArray{5} = ReadDisk(db,"VBInput/vDEStd") # [vEnduse,vTech,ECC,Area,Year] Device Efficiency Standards (Btu/Btu)
  vDOCF::VariableArray{4} = ReadDisk(db,"VBInput/vDOCF") # [vEnduse,vTech,ECC,Year] Device Operating Cost Fraction ($/$)
  vDPL::VariableArray{4} = ReadDisk(db,"VBInput/vDPL") # [vEnduse,vTech,ECC,Year] Physical Life of Equipment (Years)
  vEUMap::VariableArray{2} = ReadDisk(db,"$Input/vEUMap") # [vEnduse,Enduse] Map between Enduse and vEnduse
  vTechMap::VariableArray{2} = ReadDisk(db, "$Input/vTechMap") # [vTech,Tech] 'Map between Tech and vTech'
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 
  xDPL::VariableArray{5} = ReadDisk(db, "$Input/xDPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,Areas,Nation,ECCs,ECs,Enduses,Techs) = data
  (;Years,vAreas,vEnduses,vTechs) = data
  (;DEM,DEStd,DOCF,ECCMap,xDCC,xDEE,xDPL) = data
  (;ANMap,vDCC,vDEE,vDEM,vDEStd,vDOCF,vDPL,vAreaMap,vEUMap,vTechMap) = data

  #* 
  #* vDEM current reads all values into 1985
  #* 
  for ecc in ECCs
    for ec in findall(ECCMap[ECs,ecc] .== 1.0)
      for enduse in Enduses
        for venduse in findall(vEUMap[vEnduses,enduse] .== 1.0)
          for tech in Techs
            for vtech in findall(vTechMap[vTechs,tech] .== 1.0) 
              for area in Areas
                DEM[enduse,tech,ec,area] = vDEM[venduse,vtech,ecc,area,Zero]
              end
            end
          end
        end
      end
    end
  end
  
  WriteDisk(db,"$Input/DEM",DEM)

  # 
  # vDEE/vDCC 
  # 
  #
  # Initialize xDEE
  #
  @. xDEE = -99
  @. xDCC = -99

  for ecc in ECCs
    for ec in findall(ECCMap[ECs,ecc] .== 1.0)
      for enduse in Enduses
        for venduse in findall(vEUMap[vEnduses,enduse] .== 1.0)
          for tech in Techs
            for vtech in findall(vTechMap[vTechs,tech] .== 1.0) 
              for area in Areas, year in Years
                if vDEE[venduse,vtech,ecc,area,year] > 0
                  xDEE[enduse,tech,ec,area,year] = vDEE[venduse,vtech,ecc,area,year]
                end
                if vDCC[venduse,vtech,ecc,area,year] > 0
                  xDCC[enduse,tech,ec,area,year] = vDCC[venduse,vtech,ecc,area,year]
                end
                if vDEStd[venduse,vtech,ecc,area,year] > 0
                  DEStd[enduse,tech,ec,area,year] = vDEStd[venduse,vtech,ecc,area,year]
                end
                if vDOCF[venduse,vtech,ecc,year] > 0
                  DOCF[enduse,tech,ec,area,year] = vDOCF[venduse,vtech,ecc,year]
                end
              end
              for area in Areas
                vareas = findall(x -> x == 1.0,vAreaMap[area,vAreas])
                for varea in vareas
                  for year in Years
                    if vDPL[venduse,vtech,ecc,year] > 0
                      xDPL[enduse,tech,ec,area,year] = vDPL[venduse,vtech,ecc,year]
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  #
  # US/MX uses ON DPL values
  #
  
  CN = Select(Nation, "CN")
  ON = Select(Area,"ON")
  areas = findall(ANMap[:,CN] .!= 1.0)

  for enduse in Enduses, tech in Techs, ec in ECs, area in areas, year in Years
    xDPL[enduse,tech,ec,area,year] = xDPL[enduse,tech,ec,ON,year]
  end

  WriteDisk(db,"$Input/DEStd",DEStd)
  WriteDisk(db,"$Input/DOCF",DOCF)
  WriteDisk(db,"$Input/xDCC",xDCC)
  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xDPL",xDPL)

end

function CalibrationControl(db)
  @info "DeviceInputs_VB.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
