rem
rem  Update.cmd
rem
rem  This did not work for me; I ended up with double copies of Julia
rem  -- Jeff Amlin 2/16/24
rem
rem  Uses juliaup to update local julia installation to most recent version
rem  juliaup can be added by running the folloing line you cmd then restarting
rem  the terminal:
rem     winget install julia -s msstore
rem
rem  Run Install.cmd after update to add dependencies required for EnergyModel
rem  (Install only needs to be done once but no harm in running it every time)
rem  
rem  Issues may occur if multiple julia installations are present on the computer
rem  Check julia installations using:
     where julia
rem  Remove older julia versions using:
     juliaup gc
rem  
rem VS Code Integration:
rem   To ensure VS Code's julia extension finds the machine's julia installation
rem   copy the path output from `where julia` 
rem   (likely C:\Users\Owner\AppData\Local\Microsoft\WindowsApps\julia.exe)
rem   and paste into the "Julia: Executable Path" in VS Code's setting
rem   (open settings in VS Code by hitting Ctrl+, then search "julia path") 
rem 
rem     @echo off
     cd ..
     juliaup update
     Echo %Date% ;%Time%; Update Local Julia installation >> log/RunAll_Report.log
rem
rem  Pause till the user hits a key to exit
rem
     pause
