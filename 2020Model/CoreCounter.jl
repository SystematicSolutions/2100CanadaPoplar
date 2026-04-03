#
# CoreCounter.jl - count cores availible for threading.
#

function WriteFile(filename,message)
  fileToWrite = open(filename, "a")
  write(fileToWrite, message * "\n")
  close(fileToWrite)
  #@info "$message"
end

function DetermineOptimalThreadCount()
    available_cores = Threads.nthreads()
    println("available_cores $available_cores")
    physical_cores = max(1, div(available_cores, 2))  # Assume hyperthreading
    println("physical_cores $physical_cores")
    # Heuristic based on workload characteristics
    if available_cores <= 2
      return 1  # Single-threaded for very limited systems
    elseif available_cores <= 4
      return min(2, available_cores)  # Conservative for small systems
    elseif available_cores <= 8
      return min(4, available_cores - 1)  # Leave one core for OS
    else
      #return min( 1, available_cores - 2)  # Cap at  1 threads, leave 2 cores for OS
      #return min( 4, available_cores - 2)  # Cap at  2 threads, leave 2 cores for OS
       return min( 8, available_cores - 2)  # Cap at  8 threads, leave 2 cores for OS
      #return min(12, available_cores - 2)  # Cap at 12 threads, leave 2 cores for OS
      #return min(15, available_cores - 2)  # Cap at 15 threads, leave 2 cores for OS
    end
    
    
end

function GetThreadCount()
  ThreadsToUse=DetermineOptimalThreadCount()
  println("Using Threadcount:$ThreadsToUse" )
  BatFileName="SetThreadCount.bat"
  rm(BatFileName,force=true)
  touch(BatFileName)
  WriteFile(BatFileName,"set JULIA_NUM_THREADS=$ThreadsToUse")
end


if abspath(PROGRAM_FILE) == @__FILE__
  GetThreadCount()
end


