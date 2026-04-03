rem
rem  AutoFormatter.cmd
rem
     @echo off
rem  AutoFormat Julia code.
rem
     cd ..
     Echo Installing dependencies ...
     julia -e "using Pkg; Pkg.add(\"JuliaFormatter\")"
     Echo AutoFormatting code ...
     julia --project -e "using JuliaFormatter; import EnergyModel as M; format(\".\")"
rem
rem  Pause till the user hits a key to exit
rem
     pause
