using Printf

# Function to execute system command and return output
function run_command(command)
    try
        return chomp(read(`cmd /C $command`, String))
    catch
        return "Command failed"
    end
end

# CPU Information
println("CPU Information:")
println("----------------")
cpu_info = run_command("wmic cpu get name, MaxClockSpeed")
println(cpu_info)

# RAM Information
println("\nRAM Information:")
println("----------------")
total_physical_memory = Sys.total_memory() / (1024 * 1024 * 1024) # in GB
@printf("Total Physical Memory: %.2f GB\n", total_physical_memory)

# Disk Information
println("\nDisk Information:")
println("----------------")
disk_info = run_command("wmic diskdrive get model,size")
println(disk_info)

# GPU Information
println("\nGPU Information:")
println("----------------")
gpu_info = run_command("wmic path win32_VideoController get name")
println(gpu_info)

# OS Information
println("\nOperating System Information:")
println("-----------------------------")
println("OS: ", Sys.KERNEL)
println("Version: ", run_command("ver"))

# Julia Information
println("\nJulia Information:")
println("------------------")
println("Julia Version: ", VERSION)
println("Number of Julia threads: ", Threads.nthreads())
println("Architecture: ", Sys.ARCH)
