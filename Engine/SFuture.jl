#
# SFuture.jl - Future Values of Fuel Price Delivery Charges
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# (c) 2013 Systematic Solutions, Inc. All rights reserved.
#

using EnergyModel

module SFuture

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String


  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESes::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FPDChgF::VariableArray{4} = ReadDisk(db,"SCalDB/FPDChgF") # [Fuel,ES,Area,Year] Fuel Delivery Charge ($/mmBtu)
  FPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF")    # [Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF")   # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)
  YEndTime::Int = ReadDisk(db,"SInput/YEndTime") # Fixed End-year for Calibration (Date)
  YFPDChgF::VariableArray{4} = ReadDisk(db,"SInput/YFPDChgF") # [Fuel,ES,Area,Year] Method for deterining future values for FPDChgF

end



#Define Variable
#Number   'Number of Data Points'
#xI(Year) 'x index for Regressions'
#YI(Year) 'Y index for Regressions'
#SX       'sum of x'
#SXX      'sum of x*x'
#SXY      'sum of x*Y'
#SY       'sum of Y'
#Slope    'Slope of Line'
#Intercept     'Intercept of Line'
#End Define Variable
#*
#Do Year
# xI(Year)=Year:S
#End Do Year
#*
#************************
#*
#Define Procedure Regress
#*
#*  Do time trend analysis historical values
#*      Y=MX+B   :x=F(Time)
#*
#Define Parameter
#M       'Slope of Line'
#B       'Intercept of Line'
#End Define Parameter
#* 
#Number=Year:N
#SX=sum(Year)(xI(Year))
#SY=sum(Year)(YI(Year))
#SXX=sum(Year)(xI(Year)*xI(Year))
#SXY=sum(Year)(xI(Year)*YI(Year))
#M=(SX*SY-Number*SXY)/(SX*SX-Number*SXX)
#B=(SY-M*SX)/Number
#End Procedure Regress


function FutCal(data)
  (;db) = data
  (;Areas,ESes,Fuels) = data
  (;FPDChgF,xFPF,YEndTime,YFPDChgF) = data
  
  @info "SFuture.jl,FutCal - Future value of Delivery Charge (FPDChgF)"

  YLast = YEndTime-ITime+1
  
  for area in Areas, es in ESes, fuel in Fuels
  
    #
    # Define the historical and future periods, based on the first year
    # when the price (xFPF) is zero.
    #
    years = findall(xFPF[fuel,es,area,:] .!= 0.0)
    if !isempty(years)
      Last1 = maximum(years)
    else
      Last1 = MaxTime-ITime+1
    end
    Future1 = min(Last1+1,Final)
    if Future1 < Final
      years = collect(Zero:Last1)

      #
      # The future values of the delivery charges (FPDChgF) are the 
      # the average historical value (YFPDChgF=4)
      #
      if YFPDChgF[fuel,es,area,Zero] == 4
        FPDChgF[fuel,es,area,Future1] = sum(FPDChgF[fuel,es,area,year] for year in years)/Last1
        years = collect(Future1:Final)
        for year in years
          FPDChgF[fuel,es,area,year] = FPDChgF[fuel,es,area,Future1]
        end

      #
      # The future values of the delivery charges (FPDChgF) are the values from
      # the last year where prices (xFPF) are specified (YFPDC hgF=3).        
      #
      elseif YFPDChgF[fuel,es,area,Zero] == 3
        FPDChgF[fuel,es,area,Future1] = FPDChgF[fuel,es,area,Last1]
        years = collect(Future1:Final)
        for year in years
          FPDChgF[fuel,es,area,year] = FPDChgF[fuel,es,area,Future1]
        end
       
      #
      # The future values of the delivery charges (FPDChgF) are the next point
      # on a Regression line (YFPDChgF=5).
      # This is not exactly Method 5, so revise later - Jeff Amlin 02/11/19
      #
      elseif YFPDChgF[fuel,es,area,Zero] == 5
        # YI=FPDChgF
        # Regress(Slope,Intercept)
        # years = collect(Future1:Final)
        # FPDChgF=Slope*Future1+Intercept
      end
    end
  end
  
  WriteDisk(db,"SCalDB/FPDChgF",FPDChgF) 
end 

end
