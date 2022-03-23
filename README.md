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

This package uses the popular [jshttp/mime-db](https://github.com/jshttp/mime-db) database, made available [using Artifacts](https://github.com/fonsp/MIMEs/blob/main/Artifacts.toml). This database is an aggregation of the following sources:

- https://hg.nginx.org/nginx/raw-file/default/conf/mime.types
- https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types
- https://www.iana.org/assignments/media-types/media-types.xhtml


The function implementations, including resolution for conflicting extensions (nginx > apache > mime-db > IANA), is based on [jshttp/mime-types](https://github.com/jshttp/mime-types).

The database parsing and processing happens during precompilation, lookups are very fast.

# See also

* [tkf/MIMEFileExtensions.jl](https://github.com/tkf/MIMEFileExtensions.jl): Similar smaller package for MIME <-> extension conversion, based on the Apache database.
* [JuliaIO/FileType.jl](https://github.com/JuliaIO/FileType.jl): File type (including MIME) detection based also on the file content.
