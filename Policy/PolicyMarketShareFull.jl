#
# PolicyMarketShareFull.jl - Market Share Initialization, Nomalization, and Coefficient Calculation
#

module PolicyMarketShare

import ...EnergyModel: DB

#
# Alphabetize "include" statements since order does not matter
#
include("Com_MS_Coefficient.jl")
include("Com_MS_Conversions.jl")
include("Com_MS_Initialize.jl")
include("Com_MS_Normalize.jl")
include("Com_MS_ConvElectric_CA.jl")

include("Ind_Fungible_Coefficients.jl")
include("Ind_Fungible_Initialize.jl")
include("Ind_Fungible_Normalize.jl")
include("Ind_FungibleFS_Coefficients.jl")
include("Ind_FungibleFS_Initialize.jl")
include("Ind_FungibleFS_Normalize.jl")
include("Ind_MS_Coefficient.jl")
include("Ind_MS_Conversions.jl")
include("Ind_MS_Initialize.jl")
include("Ind_MS_Normalize.jl")

include("Res_MS_Coefficient.jl")
include("Res_MS_Conversions.jl")
include("Res_MS_Initialize.jl")
include("Res_MS_Normalize.jl")
include("Res_MS_ConvElectric_CA.jl")

include("Trans_MS_Coefficient.jl")
include("Trans_MS_Conversions.jl")
include("Trans_MS_Initialize.jl")
include("Trans_MS_Normalize.jl")
include("Trans_MS_Conversions_CA.jl")
# include("Trans_MS_FreightConversions.jl")

function InitializeMarketShares()
  @info "InitializeMarketShares"
  
  #
  # Residential
  #
  Res_MS_Initialize.PolicyControl(DB)

  #
  # Commercial
  #
  Com_MS_Initialize.PolicyControl(DB)

  #
  # Industrial
  #
  Ind_MS_Initialize.PolicyControl(DB)
  Ind_Fungible_Initialize.PolicyControl(DB)
  Ind_FungibleFS_Initialize.PolicyControl(DB)

  #
  # Transportation
  #
  Trans_MS_Initialize.PolicyControl(DB)

end

function MarketShareCoefficients()
  @info "MarketShareCoefficients"
  
  #
  # Residential
  # 
  Res_MS_Normalize.PolicyControl(DB)
  Res_MS_Coefficient.PolicyControl(DB)
  
  Res_MS_Conversions.PolicyControl(DB)
  Res_MS_ConvElectric_CA.PolicyControl(DB)  
  
  #
  # Commercial
  #  
  Com_MS_Normalize.PolicyControl(DB)
  Com_MS_Coefficient.PolicyControl(DB)
  
  Com_MS_Conversions.PolicyControl(DB)
  Com_MS_ConvElectric_CA.PolicyControl(DB)
  
  #
  # Industrial
  #
  Ind_MS_Normalize.PolicyControl(DB)
  Ind_MS_Coefficient.PolicyControl(DB)
  Ind_MS_Conversions.PolicyControl(DB)
  
  Ind_Fungible_Normalize.PolicyControl(DB)
  Ind_Fungible_Coefficients.PolicyControl(DB)
  
  Ind_FungibleFS_Normalize.PolicyControl(DB)
  Ind_FungibleFS_Coefficients.PolicyControl(DB)

  #
  # Transportation
  #  
  Trans_MS_Normalize.PolicyControl(DB)      
  Trans_MS_Coefficient.PolicyControl(DB)
  
  Trans_MS_Conversions.PolicyControl(DB)

end

end
  
  