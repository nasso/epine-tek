local tek = require "../../init"

tek:project "libjzon" {"libjzon.a"}
tek:name "libjzon.a"

tek:static "libjzon" {
    libs = {tek:ref "libmy"}
}

tek:binary "unit_tests" {
    srcs = {find "./tests/*.c"},
    libs = {tek:ref "libjzon", tek:ref "libmy", "criterion"}
}

tek:pull "libmy" {
    git = "git@github.com:nasso/libmy"
}

return tek:make()
