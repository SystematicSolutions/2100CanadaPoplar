using Tar
using Dates

function exclude(p)
  ".git" in splitpath(p) ||
    "test" in splitpath(p) ||
    "AzurePipelines.yml" in splitpath(p) ||
    "EnergyModelArchive" in splitpath(p) ||
    ("docs" in splitpath(p) && "build" in splitpath(p)) ||
    endswith(p, ".zip") ||
    endswith(p, ".tar") ||
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
  dir = joinpath(tempdir(), "EnergyModel")
  rm(dir; force = true, recursive = true)
  mkpath(dir)
  compress_dir = dirname(abspath(@__DIR__))
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
      mkpath(dirname(joinpath(dir, zippath)))
      cp(filepath, joinpath(dir, zippath))
    end
  end
  folder = joinpath(@__DIR__, "../$folder_name")
  mkpath(folder)
  if isfile(joinpath(folder, "EnergyModel.tar"))
    rm(joinpath(folder, "EnergyModel.tar"))
  end
  Tar.create(dir, joinpath(folder, "EnergyModel.tar"))
  println(abspath(folder))
end

main(length(ARGS) == 0 ? get_folder_name() : first(ARGS))
