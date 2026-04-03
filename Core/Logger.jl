#
# Logger.jl
#

module Logger

using ..EnergyModel
using Logging, LoggingExtras, LoggingFormats
using Dates
using Printf

LogFolder = abspath(joinpath(dirname(@__DIR__),"2020Model", "log"))

const LOGGER = current_logger()
const DATE_FORMAT = dateformat"yyyy-mm-dd HH:MM:SS"

function current_module_message_filter(log)
  log._module === EnergyModel || log._module !== nothing && parentmodule(log._module) === EnergyModel
end

function run_all_filter(log)
  log.group == :RunAll
end

function file_logger(name::String = "info.log")
  FormatLogger(joinpath(LogFolder, "$name"); append = false) do io, args
    date = Dates.format(now(), DATE_FORMAT)
    level = rpad(args.level, 4, " ")
    filename = lpad(basename(args.file), 15, " ")
    lineno = rpad(args.line, 4, " ")
    message = args.message
    println(io, "$date | $level | $(gethostname()) | $filename  |  $lineno | $message")
    if :exception ∈ keys(args.kwargs)
      e, stacktrace = args.kwargs[:exception]
      println(io, "exception = ")
      showerror(io, e, stacktrace)
      println(io)
    end
  end
end

filename_logger(logger) =
  TransformerLogger(logger) do log
    merge(log, (; message = "$(basename(log.file)) - $(log.message)"))
  end

function LoggerInitialize()
  isdir(LogFolder) || mkpath(LogFolder)
  global_logger(
    TeeLogger(
      EarlyFilteredLogger(current_module_message_filter, MinLevelLogger(file_logger("info.log"), Logging.Info)),
      MinLevelLogger(file_logger("debug.log"), Logging.Debug),
      EarlyFilteredLogger(run_all_filter, MinLevelLogger(file_logger("RunAll_Report.log"), Logging.Info)),
      EarlyFilteredLogger(current_module_message_filter, filename_logger(LOGGER)),
      EarlyFilteredLogger(!current_module_message_filter, LOGGER),
    ),
  )
  @info "Initialized logger"
  nothing
end

function reset()
  global_logger(LOGGER)
  nothing
end

end
