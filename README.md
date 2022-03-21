# MIMEs.jl
A small package to transform between file extensions and MIME types.

# Examples
```julia
julia> using MIMEs

julia> m = mime_from_extension(".json")
MIME type application/json

julia> extension_from_mime(m)
".json"

julia> contenttype_from_mime(m)
"application/json; charset=utf-8"
```

# Implementation

This package uses the [jshttp/mime-db](https://github.com/jshttp/mime-db) database, made available [using Artifacts](https://github.com/fonsp/MIMEs/blob/main/Artifacts.toml). The function implementations, including resolution for conflicting extensions, is based on [jshttp/mime-types](https://github.com/jshttp/mime-types).

The database parsing and processing happens during precompilation, lookups are very fast.
