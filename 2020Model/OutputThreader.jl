#
# OutputThreader.jl
#


#rm_dir_contents(OutputFolder)
#create_folder() = isdir(dirname(OutputFolder)) || mkpath(dirname(OutputFolder))

current_dir = pwd()
modelRoot = dirname(current_dir) * "\\"

if length(ARGS) > 0
  OutputType=ARGS[1]
else
  OutputType=ARGS["ExcelDTAs"]
end

FilesToRun::Vector{String}=[]

function WriteFile(filename,message)
  fileToWrite = open(filename, "a")
  write(fileToWrite, message * "\n")
  close(fileToWrite)
  #@info "$message"
end

function ReadFileNames(FileList,OutputFolder)
  open(FileList) do outputList
  for line in eachline(outputList)
    if startswith(line, "#") 
      else
        fileName =  OutputFolder * "/" * line
        println(fileName)
        push!(FilesToRun,fileName)
      end
    end
  end
end

if OutputType=="ExcelDTAs"
  OutputFiles = modelRoot * "Output/ExcelOutput.txt"
  ReadFileNames(OutputFiles,"ExcelOutput")
elseif OutputType=="AccessDTAs"
  OutputFiles = modelRoot * "Output/AccessOutput.txt"
  ReadFileNames(OutputFiles,"AccessOutput")
elseif OutputType=="All"
  OutputFiles = modelRoot * "Output/ExcelOutput.txt"
  ReadFileNames(OutputFiles,"ExcelOutput")
  OutputFiles = modelRoot * "Output/AccessOutput.txt"
  ReadFileNames(OutputFiles,"AccessOutput")
elseif OutputType=="Test"
  OutputFiles = modelRoot * "Output/TestOutput.txt"
  ReadFileNames(OutputFiles,"TestOutput")
else
  OutputFiles = modelRoot * "Output/ExcelOutput.txt"
  ReadFileNames(OutputFiles,"ExcelOutput")
end



println(FilesToRun)
FileCount = length(FilesToRun)
println("FileCount: $FileCount")   

#Threads.@threads for index in 1:FileCount
  @time Threads.@threads for index in 1:FileCount
  println(index)
  FileName=modelRoot * "Output/" * (FilesToRun[index]) * ".jl" 
  BatFileName =modelRoot * "2020Model/" * "TempOutputFile$index.bat"
  println(FileName)
  println(BatFileName)
  
  rm(BatFileName,force=true)
  touch(BatFileName)
  WriteFile(BatFileName,"julia --project $FileName")
  run(`cmd /c Call $BatFileName`)           
  rm(BatFileName,force=true)
end


         
println("Output Run Complete")