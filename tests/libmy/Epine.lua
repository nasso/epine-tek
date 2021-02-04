local tek = require "../../init"

-- name the project (the given name will appear in the header)
tek:project "libmy" {"libmy.so", "hello"}

-- the first target will be the default one
-- its name will be replaced by the $(NAME) variable in the generated Makefile
tek:shared "libmy.so" {
    language = "C"
}

-- some random binary that says hello using the libmy
tek:binary "hello" {
    language = "C",
    prerequisites = {"libmy.so"},
    srcs = {"main.c"},
    libs = {"my"}
}

-- don't forget to generate and return the Makefile to Epine!
return tek:make()
