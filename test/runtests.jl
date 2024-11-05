using Test
using MIMEs

sub(s) = SubString(s, 1)

@test mime_from_path("a/foo.txt") === MIME"text/plain"()
@test mime_from_path(sub("a/foo.txt")) === MIME"text/plain"()
@test mime_from_path("a/fo🌟oê.txt") === MIME"text/plain"()
@test mime_from_path("a/foo.txt") === MIME"text/plain"()
@test mime_from_path("a/foo.json") === MIME"application/json"()
@test mime_from_extension(".json") === MIME"application/json"()
@test mime_from_extension("json") === MIME"application/json"()
@test mime_from_extension("JSON") === MIME"application/json"()
@test mime_from_extension(sub("JSON")) === MIME"application/json"()
@test extension_from_mime(MIME"application/json"()) == ".json"
@test extension_from_mime(MIME"application/x-asfdafd"()) == ""
@test extension_from_mime(MIME"application/x-asfdafd"(), ".a") == ".a"


@test charset_from_mime(MIME"application/x-asfdafd"()) == nothing
@test charset_from_mime(MIME"text/x-asfdafd"()) == "UTF-8"
@test charset_from_mime(MIME"text/plain"()) == "UTF-8"
@test charset_from_mime(MIME"text/html"()) == "UTF-8"
@test contenttype_from_mime(MIME"application/x-asfdafd"()) == "application/x-asfdafd"
@test contenttype_from_mime(MIME"text/html"()) == "text/html; charset=utf-8"
@test contenttype_from_mime(MIME"text/asdfasdfasdf"()) == "text/asdfasdfasdf; charset=utf-8"

@test mime_from_extension("js") == MIME"text/javascript"()
@test charset_from_mime(mime_from_extension("js")) == "UTF-8"
@test mime_from_extension("jl") == MIME"text/julia"()
@test charset_from_mime(mime_from_extension("jl")) == "UTF-8"

@test compressible_from_mime(MIME"text/html"())
@test compressible_from_mime(MIME"text/css"())
@test !compressible_from_mime(MIME"text/x-sadfa"())

@test contenttype_from_mime(MIME"application/json"()) == "application/json; charset=utf-8"
@test contenttype_from_mime(MIME"application/x-bogus"()) == "application/x-bogus"
@test contenttype_from_mime(mime_from_extension(".png", MIME"application/octet-stream"())) == "image/png"

# from https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
const mdn = Dict(
    ".bin" => "application/octet-stream",
    ".bmp" => "image/bmp",
    ".css" => "text/css",
    ".csv" => "text/csv",
    ".eot" => "application/vnd.ms-fontobject",
    ".gz" => "application/gzip",
    ".gif" => "image/gif",
    ".htm" => "text/html",
    ".html" => "text/html",
    ".ico" => "image/vnd.microsoft.icon",
    ".jpeg" => "image/jpeg",
    ".jpg" => "image/jpeg",
    ".js" => "text/javascript",
    ".json" => "application/json",
    ".jsonld" => "application/ld+json",
    ".mjs" => "text/javascript",
    ".mp3" => "audio/mpeg",
    ".mp4" => "video/mp4",
    ".mp4s" => "application/mp4",
    ".mpeg" => "video/mpeg",
    ".ogx" => "application/ogg",
    ".otf" => "font/otf",
    ".png" => "image/png",
    ".pdf" => "application/pdf",
    ".rtf" => "application/rtf",
    ".sh" => "application/x-sh",
    ".svg" => "image/svg+xml",
    ".tar" => "application/x-tar",
    ".tif" => "image/tiff",
    ".tiff" => "image/tiff",
    ".ttf" => "font/ttf",
    ".txt" => "text/plain",
    ".weba" => "audio/webm",
    ".webm" => "video/webm",
    ".webp" => "image/webp",
    ".woff" => "font/woff",
    ".woff2" => "font/woff2",
    ".xhtml" => "application/xhtml+xml",
    ".xml" => "application/xml",
    ".xul" => "application/vnd.mozilla.xul+xml",
    ".zip" => "application/zip",
    ".wasm" => "application/wasm",
)

for (ex, ms) in mdn
    @test mime_from_extension(ex) === MIME(ms)
end


# Mismatched with MDN, but that's fine:
# ".aac" => "audio/aac",
# ".wav" => "audio/wav",
# ".oga" => "audio/ogg", ".ogv" => "video/ogg",
# ".opus" => "audio/opus",
