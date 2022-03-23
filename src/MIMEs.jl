module MIMEs

export mime_from_extension, mime_from_path, extension_from_mime, charset_from_mime, compressible_from_mime, contenttype_from_mime

import JSON
using Artifacts


const _mimedb_root = artifact"mimedb"

const _mimedb_json = joinpath(_mimedb_root, "package", "db.json")
const _mimedb = let
    d = JSON.parse(read(_mimedb_json, String))

    # https://github.com/jshttp/mime-db/issues/194
    d["text/javascript"], d["application/javascript"] = d["application/javascript"], d["text/javascript"]
    
    d
end


const _source_preference = ("nginx", "apache", nothing, "iana")

const _ext2mime = Dict{String,String}()
const _mime2ext = Dict{String,Vector}()

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

"""
```julia
mime_from_extension(query::String[, default=nothing])::MIME
```

# Examples:
```julia
mime_from_extension(".json") == MIME"application/json"()
mime_from_extension("html") == MIME"text/html"()
mime_from_extension("asdfff") == nothing
mime_from_extension("asdfff", MIME"text/plain"()) == MIME"text/plain"()
```
"""
function mime_from_extension(query::String, default=nothing)
    m = get(_ext2mime, lowercase(lstrip(query, '.')), nothing)
    m === nothing ? default : MIME(m)
end


"""
```julia
mime_from_path(path::String[, default::T=nothing])::Union{MIME,T}
```

Return the MIME type of the file at `path`, based on the file extension.

# Examples:
```julia
mime_from_path("hello.json") == MIME"application/json"()
mime_from_path("/home/fons/wow.html") == MIME"text/html"()
mime_from_path("/home/fons/wow") == nothing
mime_from_path("/home/fons/wow", MIME"text/plain"()) == MIME"text/plain"()
```
"""
function mime_from_path(path::String, default=nothing)
    mime_from_extension(splitext(path)[2], default)
end


"""
```julia
extension_from_mime(mime::MIME[, default::T=""])::Union{String,T}
```

Return the most common file extension used for files of the given MIME type.

# Examples:
```julia
extension_from_mime(MIME"application/json"()) == ".json"
extension_from_mime(MIME"text/html"()) == ".html"
extension_from_mime(MIME"text/blablablaa"()) == ""
extension_from_mime(MIME"text/blablablaa"(), ".bin") == ".bin"
```
"""
function extension_from_mime(mime::MIME, default="")
    exs = get(_mime2ext, string(mime), nothing)
    if exs === nothing || isempty(exs)
        default
    else
        "." * first(exs)
    end
end




"""
```julia
compressible_from_mime(mime::MIME)::Bool
```

Whether a file of the given MIME type can/should be gzipped.

# Examples:
```julia
compressible_from_mime(MIME"text/html"()) == true
compressible_from_mime(MIME"image/png"()) == false
compressible_from_mime(MIME"text/blablablaa"()) == false
```
"""
function compressible_from_mime(mime::MIME)
    c = get(_mimedb, string(mime), nothing)
    if c === nothing
        false
    else
        get(c, "compressible", false)
    end
end



"""
```julia
charset_from_mime(mime::MIME)::String
```

The default charset associated with this type, if any. If not known, text MIMEs default to "UTF-8". Possible values are: $(Set([get(x, "charset", nothing) for x in (_mimedb |> values)]) |> collect |> string).

# Examples:
```julia
charset_from_mime(MIME"application/json"()) == "UTF-8"
charset_from_mime(MIME"application/x-bogus"()) == nothing
charset_from_mime(MIME"text/blablablaa"()) == "UTF-8" # because it is a `text/` mime
charset_from_mime(MIME"text/blablablaa"(), "LATIN-1") == "LATIN-1"
```
"""
function charset_from_mime(mime::MIME)
    fallback() = istextmime(mime) ? "UTF-8" : nothing
    c = get(_mimedb, string(mime), nothing)
    if c === nothing
        fallback()
    else
        get(fallback, c, "charset")::Union{String,Nothing}
    end
end


function charset_from_mime(mime::MIME, default)
    c = get(_mimedb, string(mime), nothing)
    if c === nothing
        default
    else
        get(c, "charset", default)
    end
end



"""
```julia
contenttype_from_mime(mime::MIME)::String
```

Turn a MIME into a Content-Type header value, which might include the `charset` parameter.

# Examples:
```julia
contenttype_from_mime(MIME"application/json"()) == "application/json; charset=utf-8"
contenttype_from_mime(MIME"application/x-bogus"()) == "application/x-bogus"
```

# See also:
[`charset_from_mime`](@ref)
"""
contenttype_from_mime(mime::MIME) = let c = charset_from_mime(mime)
    c === nothing ? string(mime) : "$(string(mime)); charset=$(lowercase(c))"
end


end