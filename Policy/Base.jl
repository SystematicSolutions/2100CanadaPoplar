#
# Base.jl
#

module Policy

import ...EnergyModel: DB

include("PatchFsPOCXTrans.jl")
include("SetAsBaseCase.jl")
include("OG_Exogenous.jl")

function IncorporatePolicies()
  @info "IncorporatePolicies - Base"
  PatchFsPOCXTrans.PolicyControl(DB)  
  SetAsBaseCase.PolicyControl(DB)
  OG_Exogenous.PolicyControl(DB)
end

end
