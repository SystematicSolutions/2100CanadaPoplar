rem
rem  RunOutputs.cmd
rem
     cd ..
     Echo %Date% ;%Time%; Start Outputs on %ComputerName% >> log/RunAll_Report.log
     Call RunJulia Run.jl RunOutputs.jl
     Echo %Date% ;%Time%; End RunOutputs on %ComputerName% >> log/RunAll_Report.log
rem
rem  Pause till the user hits a key to exit
rem
     pause
