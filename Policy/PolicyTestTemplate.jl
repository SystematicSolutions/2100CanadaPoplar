#
# PolicyNo_OBA.jl
#

module PolicyTest

import ...EnergyModel: DB

include("CarbonTax_OBARemoval.jl")

function IncorporatePolicyTest()
  @info "IncorporatePolicyTest - Policy Group Name"
  
  CarbonTax_OBARemoval.PolicyControl(DB)
  
end

end
  
  