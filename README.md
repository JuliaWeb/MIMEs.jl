# MIMEs.jl
A small package to transform between file extensions and MIME types, with bonus features.

# Examples
```julia
julia> using MIMEs

julia> m = mime_from_extension(".json")
MIME type application/json

julia> extension_from_mime(m)
".json"

julia> compressible_from_mime(m) # whether content of this MIME can/should be gzipped
true

julia> charset_from_mime(m)
"UTF-8"

julia> contenttype_from_mime(m) # the Content-Type HTTP header
"application/json; charset=utf-8"
```

# Implementation

This package uses the popular [jshttp/mime-db](https://github.com/jshttp/mime-db) database. This database is an aggregation of the following sources:

- https://hg.nginx.org/nginx/raw-file/default/conf/mime.types
- https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types
- https://www.iana.org/assignments/media-types/media-types.xhtml


The function implementations, including resolution for conflicting extensions (nginx > apache > mime-db > IANA), is based on [jshttp/mime-types](https://github.com/jshttp/mime-types).

The database is parsed and processed by us, and written directly to the source code (see #3). This means that the package has no dependencies, and loads very fast: 

```julia
julia> @time import MIMEs; MIMEs.mime_from_path("a/foo.txt")
  0.023083 seconds (36.38 k allocations: 3.107 MiB, 39.83% compilation time)
```

# See also

* [tkf/MIMEFileExtensions.jl](https://github.com/tkf/MIMEFileExtensions.jl): Similar smaller package based on the Apache database, for MIME <-> extension conversion only. MIMEs.jl also contains additional MIME-related queries useful for writing servers.
* [JuliaIO/FileType.jl](https://github.com/JuliaIO/FileType.jl): File type (including MIME) detection based also on the file content.

# Future development & scope

Future goals of MIMEs.jl:
- All things MIME! If you are writing a web application in Julia and you are missing MIME-related functionality, let us know! Issues and Pull Requests are welcome.
- This package will be regularly updated to match the (monthly) updates to [jshttp/mime-db](https://github.com/jshttp/mime-db). Right now this is involves manually running the update script, but we might automate this in the future. See #1
