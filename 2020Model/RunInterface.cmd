rem  RunInterface.cmd
     @echo off
rem
rem  Run the EnergyModel Database Interface
rem
     cd ..
     julia --project --banner=no -i RunInterface.jl
