#
# UnitTests.jl
#

import EnergyModel as M


function TestEPolution()
    data = M.Engine.EPollution.Data(M.DB,10,9,11)
end

function TestRDemand()
    @info "Testing RDemand Data"
    year = 2000
    db = M.DB
    
    data = M.Engine.RDemand.Data(; db=M.DB, year=2000)

    @info "Testing RDemand Data Worked Fine."
end


# TestEPolution()
TestRDemand()
