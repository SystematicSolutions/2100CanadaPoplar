#
# PolicyYDEMM03.jl
#

module PolicyTest

import ...EnergyModel: DB

include("YDEMM03_All.jl")
include("ElecPriceExo.jl")

function IncorporatePolicyTest()
  @info "IncorporatePolicyTest - Policy Group Name"
  
  YDEMM03_All.PolicyControl(DB)
  ElecPriceExo.PolicyControl(DB)

end

end
  
  