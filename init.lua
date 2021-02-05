local array = require "array"
local cc = require "@nasso/epine-cc/v0.2.0-alpha6"

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
    self._pulls = {}
    self._allowlist = {}
    self._default = {}
    self._name = nil
    self._projectname = nil
    self._tests = true
    self.paths = {
        incdirs = "./include",
        libs = "./lib",
        srcs = "./src",
        tests_bin = "./unit_tests",
        tests_srcs = "./tests"
    }
    self.actions = {
        all = "all",
        clean = "clean",
        fclean = "fclean",
        pull = "pull",
        re = "re",
        tests_run = "tests_run"
    }
    self.cc = cc.new()
    self.cleanlist = {}

    return self
end

---

function Tek.new()
    return Tek()
end

function Tek:clean(...)
    array.append(self.cleanlist, {...})
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

function Tek:target(name, target_name)
    target_name = target_name or name

    return function(cfg)
        -- first target is $(NAME)
        if #self._targets == 0 then
            self._name = target_name
        end

        self._targets[#self._targets + 1] = {
            name = name,
            target_name = target_name,
            cfg = {
                type = cfg.type,
                language = cfg.language or "C",
                prerequisites = cfg.prerequisites,
                srcs = cfg.srcs or {find(self.paths.srcs .. "/*.c")},
                incdirs = cfg.incdirs or {self.paths.incdirs},
                defines = cfg.defines,
                libs = cfg.libs or {},
                libdirs = cfg.libdirs or {"."},
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
    local target_name = name

    if not string.match(name, "%.%w*$") then
        target_name = name .. ".a"
    end

    return function(cfg)
        cfg.type = "static"
        self:target(name, target_name)(cfg)
    end
end

function Tek:shared(name)
    local target_name = name

    if not string.match(name, "%.%w*$") then
        target_name = name .. ".so"
    end

    return function(cfg)
        cfg.type = "shared"
        self:target(name, target_name)(cfg)
    end
end

function Tek:ref(name)
    local function searcher(v)
        return v.name == name
    end

    return function()
        local targ = array.find(self._targets, searcher)
        local pull = self._pulls[name]

        assert(targ or pull, "could not find " .. name)
        assert(not targ ~= not pull, "ambiguous reference to " .. name)

        if targ then
            local info = {
                target = targ.target_name,
                incdirs = targ.cfg.incdirs
            }

            if targ.cfg.type ~= "binary" then
                info.libname = ":" .. targ.target_name
            end

            return info
        else
            local path = self.paths.libs .. "/" .. name

            return {
                path = path,
                target = path .. "/" .. pull.target,
                incdirs = path .. "/" .. pull.incdirs,
                libname = ":" .. path .. "/" .. pull.target
            }
        end
    end
end

function Tek:pull(name)
    assert(type(name) == "string", "name must be a string")
    assert(not self._pulls[name], name .. " is already being pulled")

    return function(cfg)
        self._pulls[name] = {
            git = cfg.git,
            target = cfg.target or name .. ".a",
            incdirs = cfg.incdirs or "include",
            branch = cfg.branch or "master",
            tag = cfg.tag
        }
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
        action(self.actions.all) {
            prerequisites = {fconcat(self._default)}
        }
    }

    for _, target in ipairs(self._targets) do
        local name = target.name
        local target_name = target.target_name

        if target_name == self._name then
            target_name = "$(NAME)"
        end

        fclean_list[#fclean_list + 1] = target_name

        local libs = {}

        for _, v in ipairs(target.cfg.libs or {}) do
            -- simple strings are "system libs"
            if type(v) == "string" then
                libs[#libs + 1] = {
                    prereqs = {},
                    incdirs = {},
                    lname = v,
                    ldirs = {}
                }
            elseif type(v) == "function" then
                local info = v()

                local lib = {
                    incdirs = info.incdirs or {},
                    lname = info.libname or {},
                    ldirs = info.libdir or {}
                }

                if target.cfg.type ~= "static" then
                    lib.prereqs = info.target or {}
                else
                    lib.prereqs = info.path or {}
                end

                libs[#libs + 1] = lib
            else
                error("invalid lib: " .. tostring(v))
            end
        end

        mk[#mk + 1] = {
            epine.br,
            self.cc:target(target_name) {
                type = target.cfg.type,
                lang = target.cfg.language,
                prerequisites = array.uniques(
                    array.flatten {
                        array.mapf(libs, "prereqs"),
                        target.cfg.prerequisites
                    }
                ),
                srcs = target.cfg.srcs,
                cppflags = array.uniques(
                    array.flatten {
                        flatpre(target.cfg.incdirs or {}, "-I"),
                        flatpre(array.mapf(libs, "incdirs"), "-I"),
                        flatpre(target.cfg.defines or {}, "-D"),
                        target.cfg.cppflags
                    }
                ),
                cflags = target.cfg.cflags,
                cxxflags = target.cfg.cxxflags,
                ldlibs = array.uniques(
                    array.flatten {
                        flatpre(array.mapf(libs, "lname"), "-l"),
                        target.cfg.ldlibs
                    }
                ),
                ldflags = array.uniques(
                    array.flatten {
                        flatpre(target.cfg.libdirs or {}, "-L"),
                        flatpre(array.mapf(libs, "ldirs"), "-L"),
                        target.cfg.ldflags
                    }
                )
            }
        }
    end

    local cleanactions = {
        rm(self.cc.cleanlist),
        rm(self.cleanlist),
        array.unmap(
            self._pulls,
            function(k, v)
                return make("-C", self.paths.libs .. "/" .. k, "fclean")
            end
        )
    }

    mk[#mk + 1] = {
        epine.br,
        action(self.actions.tests_run) {
            prerequisites = {self.paths.tests_bin},
            self.paths.tests_bin .. " $(ARGS)"
        },
        epine.br,
        action(self.actions.clean) {cleanactions},
        epine.br,
        action(self.actions.fclean) {
            prerequisites = {self.actions.clean},
            rm(fclean_list),
            rm(self.paths.tests_bin)
        },
        epine.br,
        action(self.actions.re) {
            prerequisites = {self.actions.fclean, self.actions.all}
        }
    }

    -- pulled libs
    if next(self._pulls) ~= nil then
        mk[#mk + 1] = {
            epine.br,
            epine.comment " libs",
            action(self.actions.pull) {
                array.unmap(
                    self._pulls,
                    function(k, v)
                        local path = self.paths.libs .. "/" .. k

                        return {
                            rm("-r", "'" .. path .. "'"),
                            "git clone " .. v.git .. " '" .. path .. "'",
                            rm("-r", "'" .. path .. "/.git'")
                        }
                    end
                )
            },
            epine.br,
            target(self.paths.libs) {"mkdir -p $@"}
        }
    end

    for k, v in pairs(self._pulls) do
        local path = self.paths.libs .. "/" .. k

        mk[#mk + 1] = {
            epine.br,
            target(path) {
                "$(error $@ wasn't found! don't forget to `make pull`)"
            },
            target(path .. "/%") {
                -- TODO: use order_only_prerequisites when it's a thing
                prerequisites = {"|", path},
                make("-C", path, "$*"),
                make("-C", path, "clean")
            }
        }
    end

    return mk
end

return Tek()
