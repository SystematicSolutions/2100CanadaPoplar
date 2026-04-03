rem
echo   LogRunVariables.bat >> %LogFileName%
rem 
     SetLocal
     Echo     ScenarioName %ScenarioName% >> %LogFileName%
     Echo     ScenarioFirst %ScenarioFirst% >> %LogFileName%
     Echo     OGPrice %OGPrice% >> %LogFileName%
     Echo     RunType %RunType% >> %LogFileName%
     Echo     NationsToRun %NationsToRun% >> %LogFileName%
     Echo     BeginningYear %BeginningYear% >> %LogFileName%
     Echo     TOMStartYear %TOMStartYear% >> %LogFileName%
     Echo     EndingYear %EndingYear% >> %LogFileName%
     Echo     TOMPolicyFile %TOMPolicyFile% >> %LogFileName%
     Echo     BaseCase %BaseCase% >> %LogFileName%
     Echo     RefCase %RefCase% >> %LogFileName%
     Echo     OGRefCase %OGRefCase% >> %LogFileName%
     Echo     TotalIterations %TotalIterations% >> %LogFileName%   
     Echo     InvCase %InvCase% >> %LogFileName%
     Echo     ScenarioCurrent %ScenarioCurrent% >> %LogFileName%
     Echo     ScenarioPrior %ScenarioPrior% >> %LogFileName%   
rem     Echo     CurrentYear %CurrentYear% >> %LogFileName%
rem     Echo     PriorYear %PriorYear% >> %LogFileName%
     Echo     BaseSwitch %BaseSwitch% >> %LogFileName%
     Echo     TOMScenario %TOMScenario% >> %LogFileName%
     Echo     Iteration %Iteration% >> %LogFileName%
     Echo     Root %Root% >> %LogFileName%
     EndLocal  
     Exit /B 0
