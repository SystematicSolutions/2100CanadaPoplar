rem
rem  InputProcessData.bat
rem
     cd..\Input\Scripts
       Call RunJulia MainDBData.jl
       Call RunJulia MData.jl
       Call RunJulia MEData.jl
       Call RunJulia TOMBaseYear.jl   
       Call RunJulia HouseholdLDVFraction.jl
       Call RunJulia ReadTOMMaps.jl    
       Call RunJulia ReadActiveTOMSetValues.jl
       Call RunJulia SData.jl
       Call RunJulia SpData.jl        
       Call RunJulia RData.jl 
       Call RunJulia CData.jl        
       Call RunJulia IData.jl 
       Call RunJulia TData.jl  
       Call RunJulia EData.jl         
       Call RunJulia EGData.jl         
     cd..\..\2020Model
rem
rem  Pause till the user hits a key to exit
rem
rem  pause
