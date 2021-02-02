local cc = require "@nasso/epine-cc/v0.1.1-alpha"

local function prefix(t, p)
    local pt = {}

    for i, v in ipairs(t) do
        pt[i] = tostring(p) .. tostring(v)
    end

    return pt
end

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

    self.cc.cflags = {"-Wall", "-Wextra", "-pedantic", "$(if DEBUG,-g3)"}

    return self
end

---

function Tek.new()
    return Tek()
end

function Tek:tests(flag)
    self._tests = flag ~= false
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
                language = cfg.language,
                type = cfg.type,
                prerequisites = cfg.prerequisites,
                srcs = cfg.srcs or {find "./src/*.c"},
                incdirs = cfg.incdirs or {"include"},
                libs = cfg.libs,
                libdirs = cfg.libdirs or {".", "./lib"},
                defines = cfg.defines,
                cflags = cfg.cflags
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
    local unit_tests_override = false
    local fclean_list = {}
    local static_lib_names = {}
    local static_lib_incdirs = {}

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

        -- collect info about static libraries for tests
        if target.cfg.type == "static" then
            static_lib_names[#static_lib_names + 1] = name

            if target.cfg.incdirs then
                static_lib_incdirs[#static_lib_incdirs + 1] = target.cfg.incdirs
            end
        end

        unit_tests_override = unit_tests_override or name == "unit_tests"
        fclean_list[#fclean_list + 1] = name

        mk[#mk + 1] = {
            epine.br,
            self.cc:target(name) {
                type = target.cfg.type,
                prerequisites = target.cfg.prerequisites,
                srcs = target.cfg.srcs,
                incdirs = target.cfg.incdirs,
                libs = target.cfg.libs,
                libdirs = target.cfg.libdirs,
                defines = target.cfg.defines,
                cflags = target.cfg.cflags
            }
        }
    end

    if self._tests and not unit_tests_override then
        -- unit tests for all the static libraries
        mk[#mk + 1] = {
            epine.br,
            self.cc:binary "unit_tests" {
                prerequisites = static_lib_names,
                srcs = {find "./tests/*.c"},
                incdirs = static_lib_incdirs,
                libs = {prefix(static_lib_names, ":"), "criterion"},
                libdirs = {"."}
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
