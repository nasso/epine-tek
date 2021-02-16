# epine-tek

Simple Epine module for C/C++ projects at [Epitech].

## Example usage

```lua
local tek = require "@nasso/epine-tek/v0.2.0-alpha"

--       project name//default targets
tek:project "libjzon" {"libjzon.a"}

-- binary name ("$(NAME)" in the generated Makefile)
tek:name "libjzon.a"

-- a static library (the .a suffix is added automatically)
tek:static "libjzon" {
    libs = {tek:ref "libmy"}
}

-- the unit tests binary
tek:binary "unit_tests" {
    srcs = {find "./tests/*.c"},
    libs = {tek:ref "libjzon", tek:ref "libmy", "criterion"}
}

-- a target for a library that is pulled from a git repository
tek:pull "libmy" {
    git = "git@github.com:nasso/libmy"
}

return tek:make()
```

[Epitech]: https://www.epitech.eu
