import Pkg
Pkg.activate(@__DIR__)

import Serialization: serialize

import JSON
import Downloads: download

version = v"1.52.0"

skip  = false
mdb   = joinpath(@__DIR__, "mimedb.jd")
e2m   = joinpath(@__DIR__, "ext2mime.jd")
m2e   = joinpath(@__DIR__, "mime2ext.jd")

_source_preference = ("nginx", "apache", nothing, "iana")

# Check if there's a new version and alert the user, don't automatically take
# it as the format of the JSON may change
begin
    url = "https://registry.npmjs.org/mime-db/"
    d   = JSON.parse(read(download(url), String))
    vs  = sort([VersionNumber(k) => v for (k, v) in d["versions"]]; by=first)

    latest_version = last(vs)[1]

    if version == latest_version
        @info "✅  The version matches the latest version of the mime DB."
        skip = isfile(mdb) && isfile(e2m) && isfile(m2e)
        skip && @info "✅  The files are already there, nothing to do."
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
    _mimedb = let
        # https://github.com/jshttp/mime-db/issues/194
        d["text/javascript"], d["application/javascript"] = d["application/javascript"], d["text/javascript"]
        d
    end

    @info "👷  constructing the ext2mime and mime2ext maps..."

    _ext2mime = Dict{String,String}()
    _mime2ext = Dict{String,Vector}()

    # Ported straight from https://github.com/jshttp/mime-types/blob/2.1.35/index.js#L154
    for (mime_str, val) in _mimedb
        mime = mime_str

        exts = get(val, "extensions", nothing)
        if exts === nothing
            continue
        end
        _mime2ext[mime] = exts

        src = get(val, "source", nothing)
        for ex in exts
            if haskey(_ext2mime, ex)
                other_src = get(_mimedb[identity(_ext2mime[ex])], "source", nothing)

                from = findfirst(isequal(other_src), _source_preference)
                to = findfirst(isequal(src), _source_preference)

                if (
                    !(_ext2mime[ex] isa MIME"application/octet-stream") &&
                    (
                        from > to ||
                        (from == to && startswith(identity(_ext2mime[ex]), "application/")
                        )
                    )
                )
                    # skip the remapping
                    continue
                end
            end
            _ext2mime[ex] = mime
        end
    end

    @info "✏  writing to files ($mdb, $e2m, $m2e)..."
    open(mdb, "w") do f
        serialize(f, _mimedb)
    end
    open(e2m, "w") do f
        serialize(f, _ext2mime)
    end
    open(m2e, "w") do f
        serialize(f, _mime2ext)
    end
    @info "✅  all done with mime DB version $version."
end
