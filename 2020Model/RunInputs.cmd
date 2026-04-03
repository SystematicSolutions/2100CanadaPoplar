rem
rem  RunInputs.cmd
rem
     cd ..
     Echo %Date% ;%Time%; Start Inputs on %ComputerName% >> log/RunAll_Report.log
     Call RunJulia Run.jl RunInputs.jl
     Echo %Date% ;%Time%; End Inputs on %ComputerName% >> log/RunAll_Report.log
rem
rem  Pause till the user hits a key to exit
rem
