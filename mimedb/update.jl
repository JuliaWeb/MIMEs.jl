import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

import JSON
import Downloads: download
import OrderedCollections: OrderedDict

version = v"1.54.0"

mdb = joinpath(@__DIR__, "mimedb.jlon")

_source_preference = ("nginx", "apache", nothing, "iana")



unorder(d::AbstractDict) = Dict(k => unorder(v) for (k, v) in d)
unorder(d::AbstractVector) = map(unorder, d)
unorder(x::Any) = x


# Check if there's a new version and alert the user, don't automatically take
# it as the format of the JSON may change
begin
    url = "https://registry.npmjs.org/mime-db/"
    d   = JSON.parse(read(download(url), String))
    vs  = sort([VersionNumber(k) => v for (k, v) in d["versions"]]; by=first)

    latest_version = last(vs)[1]

    if version == latest_version
        @info "✅  The version matches the latest version of the mime DB."
    else
        @info """
            ❗ There's a new version $(latest_version) of the mime DB. You
            might want to check whether the JSON format has changed. Assuming
            it hasn't, you can replace the `version` assignment at the
            top of mimedb/update.jl to $(latest_version).
            """
    end
end

begin
    @info "📩  downloading the DB..."
    url = "https://cdn.jsdelivr.net/gh/jshttp/mime-db@$(version)/db.json"
    d   = JSON.parse(read(download(url), String); dicttype=OrderedDict)
    _mimedb = let
        d["text/julia"] = Dict{String,Any}(
            "charset" => "UTF-8",
            "compressible" => true,
            "extensions" => ["jl"],
        )
        
        d
    end

    @info "👷  constructing the ext2mime and mime2ext maps..."

    _ext2mime = Dict{String,String}()
    _mime2ext = Dict{String,Vector}()

    # Ported straight from https://github.com/jshttp/mime-types/blob/2.1.35/index.js#L154
    for (mime_str, val) in _mimedb
        mime = mime_str
        @assert mime isa String

        exts = get(val, "extensions", nothing)
        if exts === nothing
            continue
        end
        @assert exts isa Vector
        _mime2ext[mime] = exts

        src = get(val, "source", nothing)
        for ex in exts
            if haskey(_ext2mime, ex)
                other_src = get(_mimedb[_ext2mime[ex]], "source", nothing)

                from = findfirst(isequal(other_src), _source_preference)
                to = findfirst(isequal(src), _source_preference)

                if (
                    !(_ext2mime[ex] isa MIME"application/octet-stream") &&
                    (
                        from > to ||
                        (from == to && startswith(_ext2mime[ex], "application/")
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
    
    # Changing the default mime for the .mp4 extension to video/mp4
    # this is the more common and expected type, and makes the assumption that the file contains video
    # The RFC https://www.rfc-editor.org/rfc/rfc4337.txt does not specify a **default** mime type for mp4 files, it should depend on content. application/mp4 should be used for mp4 files without video/audio content, so it is not necessarily a better default than video/mp4.
    _ext2mime["mp4"] = "video/mp4"

    @info "✏  writing to file $mdb..."
    write(mdb, string(
        (unorder(_mimedb), _ext2mime, _mime2ext)
    ))
    @info "✅  all done with mime DB version $version."
end
