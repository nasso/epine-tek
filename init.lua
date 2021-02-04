local array = require "array"
local cc = require "@nasso/epine-cc/v0.2.0-alpha3"

local function epitech_header(projectname, description)
    description = description or "Makefile automatically generated using Epine!"

    return {
        epine.comment("#"),
        epine.comment("# EPITECH PROJECT, " .. os.date("%Y")),
        epine.comment("# " .. projectname),
        epine.comment("# File description:"),
        epine.comment("# " .. description),
        epine.comment("#")
    }
end

local function flatpre(t, pre)
    return array.flatmap(
        t,
        function(v)
            return tostring(pre) .. tostring(v)
        end
    )
end

---

local Tek = {}
Tek.__index = Tek

Tek.mt = {}
Tek.mt.__index = Tek.mt
setmetatable(Tek, Tek.mt)

-- constructor
function Tek.mt.__call(_)
    local self = setmetatable({}, Tek)

    self._targets = {}
    self._allowlist = {}
    self._default = {}
    self._name = nil
    self._projectname = nil
    self._tests = true
    self.cc = cc.new()

    return self
end

---

function Tek.new()
    return Tek()
end

function Tek:project(name)
    self._projectname = name

    return function(...)
        self:default(...)
    end
end

function Tek:default(...)
    for _, v in ipairs({...}) do
        if type(v) == "table" then
            for _, vv in ipairs(v) do
                self:default(vv)
            end
        else
            self._default[#self._default + 1] = v
        end
    end
end

function Tek:target(name)
    return function(cfg)
        -- first target is $(NAME)
        if #self._targets == 0 then
            self._name = name
        end

        self._targets[#self._targets + 1] = {
            name = name,
            cfg = {
                type = cfg.type,
                language = cfg.language or "C",
                prerequisites = cfg.prerequisites,
                srcs = cfg.srcs or {find "./src/*.c"},
                incdirs = cfg.incdirs or {"include"},
                libs = cfg.libs or {},
                libdirs = cfg.libdirs or {".", "./lib"},
                cflags = cfg.cflags or {"-Wall", "-Wextra", "$(if DEBUG,-g3)"},
                cxxflags = cfg.cxxflags or
                    {"-Wall", "-Wextra", "$(if DEBUG,-g3)"},
                ldflags = cfg.ldflags or {"-Wl,-rpath ."}
            }
        }
    end
end

function Tek:binary(name)
    return function(cfg)
        cfg.type = "binary"
        self:target(name)(cfg)
    end
end

function Tek:static(name)
    return function(cfg)
        cfg.type = "static"
        self:target(name)(cfg)
    end
end

function Tek:shared(name)
    return function(cfg)
        cfg.type = "shared"
        self:target(name)(cfg)
    end
end

function Tek:check()
    return pcall(
        function()
            assert(self._projectname, "tek:project wasn't called")
            assert(
                self._default,
                "no target! try adding one with tek:binary or tek:static"
            )
        end
    )
end

function Tek:make()
    assert(self:check())

    -- generate the makefile
    local fclean_list = {}

    local mk = {
        epitech_header(self._projectname),
        epine.br,
        epine.var("NAME", self._name),
        epine.br,
        action "all" {
            prerequisites = {fconcat(self._default)}
        }
    }

    for _, target in ipairs(self._targets) do
        local name = target.name

        if name == self._name then
            name = "$(NAME)"
        end

        fclean_list[#fclean_list + 1] = name

        mk[#mk + 1] = {
            epine.br,
            self.cc:target(name) {
                type = target.cfg.type,
                lang = target.cfg.language,
                prerequisites = target.cfg.prerequisites,
                srcs = target.cfg.srcs,
                cppflags = {
                    flatpre(target.cfg.incdirs or {}, "-I"),
                    flatpre(target.cfg.defines or {}, "-D"),
                    target.cfg.cppflags
                },
                cflags = target.cfg.cflags,
                cxxflags = target.cfg.cxxflags,
                ldlibs = {
                    flatpre(target.cfg.libs or {}, "-l"),
                    target.cfg.ldlibs
                },
                ldflags = {
                    flatpre(target.cfg.libdirs or {}, "-L"),
                    target.cfg.ldflags
                }
            }
        }
    end

    mk[#mk + 1] = {
        epine.br,
        action "tests_run" {
            prerequisites = {"unit_tests"},
            "./unit_tests $(ARGS)"
        },
        epine.br,
        action "clean" {
            rm(self.cc.cleanlist)
        },
        epine.br,
        action "fclean" {
            rm(self.cc.cleanlist),
            rm(fclean_list),
            rm("unit_tests")
        },
        epine.br,
        action "re" {
            prerequisites = {"fclean", "all"}
        }
    }

    return mk
end

return Tek()
