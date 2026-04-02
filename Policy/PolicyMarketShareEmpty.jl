#
# PolicyMarketShareEmpty.jl - Empty Market Share Module for Calibration
#

module PolicyMarketShare

import ...EnergyModel: DB

function InitializeMarketShares()
  @info "InitializeMarketShares - PolicyMarketShareEmpty"

end

function MarketShareCoefficients()
  @info "MarketShareCoefficients - PolicyMarketShareEmpty"
  
end

end
  
  