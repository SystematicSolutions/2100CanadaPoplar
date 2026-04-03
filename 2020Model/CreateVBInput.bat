rem 
rem CreateVBInput.bat
rem
rem
rem Call program
rem
    Call ..\VBInput\InputDatabaseMaker.exe PopulateVBInput
rem
rem  Copy output to Output directory
rem
rem
rem    RD /s/q VBInputOutput
rem    MD VBInputOutput
rem
    Move *.dat ..\InputData\Process






