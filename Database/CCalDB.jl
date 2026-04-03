#
# CCalDB.jl - Input Database creation file
#

Base.@kwdef struct CCalDB <: HDF5GroupDatabase
  db::String=DB
  ########################
  #
  # Define Sets
  #
  Enduse = ReadSetFromCSV("EnduseCom","Key")
  EC = ReadSetFromCSV("ECCom","Key")
  Area = ReadSetFromCSV("Area","Key")
  Year = ReadSetFromCSV("Year","Key")
  tv = ReadSetFromCSV("tv","Key")
  Tech = ReadSetFromCSV("TechCom","Key")
  Hour = ReadSetFromCSV("Hour","Key")
  Day = ReadSetFromCSV("Day","Key")
  Month = ReadSetFromCSV("Month","Key")
  CTech = ReadSetFromCSV("CTechCom","Key")
  Fuel = ReadSetFromCSV("Fuel","Key")
  FuelEP = ReadSetFromCSV("FuelEP","Key")
  Poll = ReadSetFromCSV("Poll","Key")
  ########################
  #
  # Define Variables on Database
  #
  #! format: off
  CERSM = CreateVariableInHDF5(db, "CCalDB/CERSM", (:Enduse, :EC, :Area, :Year),"Capital Energy Requirement Multiplier (Btu/Btu)","Btu/Btu")
  CgCUF = CreateVariableInHDF5(db, "CCalDB/CgCUF", (:Tech, :EC, :Area, :Year),"Cogeneration Capacity Utilization Factor (\$/\$)","\$/\$")
  CgLSF = CreateVariableInHDF5(db, "CCalDB/CgLSF", (:Tech, :EC, :Hour, :Day, :Month, :Area),"Cogeneration Load Shape (MW/MW)","MW/MW")
  CgLSFSold = CreateVariableInHDF5(db, "CCalDB/CgLSFSold", (:EC, :Hour, :Day, :Month, :Area),"Cogeneration Sold to Grid Load Shape (MW/MW)","MW/MW")
  CgMSM0 = CreateVariableInHDF5(db, "CCalDB/CgMSM0", (:Tech, :EC, :Area, :Year),"Cogeneration Market Share Non-Price Factor (\$/\$)","\$/\$")
  CgMSMI = CreateVariableInHDF5(db, "CCalDB/CgMSMI", (:Tech, :EC, :Area),"Cogeneration Market Share Income Factor (\$/\$)","\$/\$")
  CgVF = CreateVariableInHDF5(db, "CCalDB/CgVF", (:Tech, :EC, :Area),"Cogeneration Variance Factor (\$/\$)","\$/\$")
  CHR = CreateVariableInHDF5(db, "CCalDB/CHR", (:EC, :Area),"Cooling to Heating Ratio (Btu/Btu)","Btu/Btu")
  CMSM0 = CreateVariableInHDF5(db, "CCalDB/CMSM0", (:Enduse, :Tech, :CTech, :EC, :Area, :Year),"Conversion Market Share Multiplier (\$/\$)","\$/\$")
  CMSMI = CreateVariableInHDF5(db, "CCalDB/CMSMI", (:Enduse, :Tech, :CTech, :EC, :Area),"Conversion Market Share Multiplier (\$/\$)","\$/\$")
  CUF = CreateVariableInHDF5(db, "CCalDB/CUF", (:Enduse, :Tech, :EC, :Area, :Year),"Capital Utilization Fraction (\$/Yr/\$/Yr)","\$/Yr/\$/Yr")
  CVF = CreateVariableInHDF5(db, "CCalDB/CVF", (:Enduse, :Tech, :CTech, :EC, :Area, :Year),"Conversion Market Share Variance Factor (DLESS)","DLESS")
  DEMM = CreateVariableInHDF5(db, "CCalDB/DEMM", (:Enduse, :Tech, :EC, :Area, :Year),"Max. Device Eff. Multiplier (Btu/Btu)","Btu/Btu")
  DmFracMSM0 = CreateVariableInHDF5(db, "CCalDB/DmFracMSM0", (:Enduse, :Fuel, :Tech, :EC, :Area, :Year),"Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)","Btu/Btu")
  DSt0 = CreateVariableInHDF5(db, "CCalDB/DSt0", (:Enduse, :EC, :Area, :Year),"Device Saturation Fixed Utility (\$/\$)","\$/\$")
  DStI = CreateVariableInHDF5(db, "CCalDB/DStI", (:Enduse, :EC, :Area),"Device Saturation Income Utility (\$/\$)","\$/\$")
  DStM = CreateVariableInHDF5(db, "CCalDB/DStM", (:Enduse, :EC, :Area),"Max. Device Saturation (Btu/Btu)","Btu/Btu")
  DStP = CreateVariableInHDF5(db, "CCalDB/DStP", (:Enduse, :EC, :Area),"Device Saturation Price Utility (\$/\$)","\$/\$")
  DUF = CreateVariableInHDF5(db, "CCalDB/DUF", (:Enduse, :EC, :Day, :Month, :Area),"Daily Use Factor (Therm/Therm)","Therm/Therm")
  FsFracMSM0 = CreateVariableInHDF5(db, "CCalDB/FsFracMSM0", (:Fuel, :Tech, :EC, :Area, :Year),"Feedstock Fuel/Tech Fraction Non-Price Factor (Btu/Btu)","Btu/Btu")
  FsPEE = CreateVariableInHDF5(db, "CCalDB/FsPEE", (:Tech, :EC, :Area, :Year),"Feedstock Process Efficiency (\$/mmBtu)","\$/mmBtu")
  LSF = CreateVariableInHDF5(db, "CCalDB/LSF", (:Enduse, :EC, :Hour, :Day, :Month, :Area),"Load Shape Factor (DLESS)","DLESS")
  MMSM0 = CreateVariableInHDF5(db, "CCalDB/MMSM0", (:Enduse, :Tech, :EC, :Area, :Year),"Non-price Factors. (\$/\$)","\$/\$")
  MMSMI = CreateVariableInHDF5(db, "CCalDB/MMSMI", (:Enduse, :Tech, :EC, :Area),"Market Share Mult. from Income (\$/\$)","\$/\$")
  MVF = CreateVariableInHDF5(db, "CCalDB/MVF", (:Enduse, :Tech, :EC, :Area, :Year),"Market Share Variance Factor (\$/\$)","\$/\$")
  PEM = CreateVariableInHDF5(db, "CCalDB/PEM", (:Enduse, :EC, :Area),"Maximum Process Efficiency (\$/mmBtu)","\$/mmBtu")
  PEMM = CreateVariableInHDF5(db, "CCalDB/PEMM", (:Enduse, :Tech, :EC, :Area, :Year),"Pro. Eff. Max. Multi (\$/Btu/(\$/Btu))","\$/Btu/(\$/Btu")
  POCF = CreateVariableInHDF5(db, "CCalDB/POCF", (:Enduse, :Tech, :EC, :Area),"Process Operating Cost Fraction (\$/Yr/\$)","\$/Yr/\$")
  Polute = CreateVariableInHDF5(db, "CCalDB/Polute", (:Enduse, :FuelEP, :EC, :Poll, :Area, :Year),"Pollution (Tonnes/Yr)","Tonnes/Yr")
  RDMSM = CreateVariableInHDF5(db, "CCalDB/RDMSM", (:Enduse, :Tech, :EC, :Area, :Year),"Device Retrofit Market Share Multiplier (1/Yr)","1/Yr")
  RPMSM = CreateVariableInHDF5(db, "CCalDB/RPMSM", (:Enduse, :Tech, :EC, :Area, :Year),"Process Retrofit Market Share Multiplier (1/Yr)","1/Yr")
  xCgMSF = CreateVariableInHDF5(db, "CCalDB/xCgMSF", (:Tech, :EC, :Area, :Year),"Cogen Market Share (\$/\$)","\$/\$")
  xMMSF = CreateVariableInHDF5(db, "CCalDB/xMMSF", (:Enduse, :Tech, :EC, :Area, :Year),"Historical Market Share Fraction by Device (Fraction)","Fraction")
end # struct CCalDB
