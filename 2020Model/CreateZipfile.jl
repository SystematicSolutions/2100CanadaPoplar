using ZipFile
using Dates

function exclude(p)
  ".git" in splitpath(p) ||
    "test" in splitpath(p) ||
    "EnergyModelArchive" in splitpath(p) ||
    "AzurePipelines.yml" in splitpath(p) ||
    ("docs" in splitpath(p) && "build" in splitpath(p)) ||
    endswith(p, ".zip") ||
    endswith(p, ".tar") ||
    endswith(p, ".hdf5") ||
    endswith(p, ".dta") ||
    endswith(p, ".csv") ||
    endswith(p, ".pdf") ||
    endswith(p, ".log") ||
    endswith(p, "LocalPreferences.toml") ||
    endswith(p, ".bak")
end

function get_folder_name()
  initials = join([c for c in basename(homedir()) if isuppercase(c)])
  current_date = Dates.format(now(), "yy.mm.dd")
  current_hour = Dates.format(now(), "IIMM p")
  "$current_date Julia EnergyModel $initials $current_hour"
end

function main(folder_name)
  zipfile = "$(tempname()).zip"
  compress_dir = dirname(abspath(@__DIR__))
  zdir = ZipFile.Writer(zipfile)
  for (root, _, files) in walkdir(compress_dir)
    for file in files
      filepath = joinpath(root, file)
      zippath = replace(filepath, compress_dir => "")
      zippath = lstrip(zippath, ['\\'])
      zippath = lstrip(zippath, ['/'])
      if exclude(zippath)
        continue
      end
      println("\t$(zippath)")
      content = strip(join(readlines(filepath), "\r\n"))
      if !isempty(content)
        content = content * "\r\n"
      end
      zf = ZipFile.addfile(zdir, zippath; method = ZipFile.Deflate, mtime = stat(filepath).mtime)
      write(zf, content)
    end
  end
  try
    println(run(pipeline(`just summary`; stderr = Pipe())))
    zf = ZipFile.addfile(zdir, "log/MODIFIED_FILES.log"; method = ZipFile.Deflate)
    write(zf, read("log/MODIFIED_FILES.log", String))
  catch
  end
  close(zdir)
  folder = joinpath(@__DIR__, "../$folder_name")
  mkpath(folder)
  if isfile(joinpath(folder, "EnergyModel.zip"))
    rm(joinpath(folder, "EnergyModel.zip"))
  end
  cp(zipfile, joinpath(folder, "EnergyModel.zip"); force = true)
  println(abspath(folder))
end

main(length(ARGS) == 0 ? get_folder_name() : first(ARGS))
