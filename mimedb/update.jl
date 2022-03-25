import Pkg
Pkg.activate(@__DIR__)

import Serialization: serialize

import JSON
import Downloads: download

version = v"1.52.0"

skip  = false
fname = "mimedb.jd"
opath = joinpath(@__DIR__, fname)

# Check if there's a new version and alert the user, don't automatically take
# it as the format of the JSON may change
begin
    url = "https://registry.npmjs.org/mime-db/"
    d   = JSON.parse(read(download(url), String))
    vs  = sort([VersionNumber(k) => v for (k, v) in d["versions"]]; by=first)

    latest_version = last(vs)[1]

    if version == latest_version
        @info "✅  The version matches the latest version of the mime DB."
        skip = isfile(opath)
        skip && @info "✅  The file is already there, nothing to do."
    else
        @info """
            ❗ There's a new version $(latest_version) of the mime DB. You
            might want to check whether the JSON format has changed. Assuming
            it hasn't, you can replace the `version` assignment at the
            top of mimedb/update.jl to $(latest_version).
            """
    end
end

skip || begin
    @info "📩  downloading the DB..."
    url = "https://cdn.jsdelivr.net/gh/jshttp/mime-db@$(version)/db.json"
    d   = JSON.parse(read(download(url), String))

    @info "✏  writing to file $opath..."
    open(opath, "w") do f
        serialize(f, d)
    end
    @info "✅  all done with mime DB version $version."
end
