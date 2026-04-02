#
# PolicyStartBase.jl
#

module Policy

import ...EnergyModel: DB

include("SetAsBaseCase.jl")

function IncorporatePolicies()
  @info "IncorporatePolicies"
  SetAsBaseCase.PolicyControl(DB)
end

end
