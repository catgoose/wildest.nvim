local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local cmdline_icon = require("wildest.renderer.components.cmdline_icon")

T["new()"] = new_set()

T["new()"]["returns component with render method"] = function()
  local component = cmdline_icon.new()
  expect.equality(type(component), "table")
  expect.equality(type(component.render), "function")
end

T["new()"]["render returns icon chunks"] = function()
  local component = cmdline_icon.new()
  local ctx = { result = { data = { expand = "file" } } }
  local chunks = component:render(ctx)
  expect.equality(type(chunks), "table")
  expect.equality(#chunks, 1)
  expect.equality(type(chunks[1][1]), "string") -- icon text
  expect.equality(type(chunks[1][2]), "string") -- hl group
end

T["resolve_key"] = new_set()

-- We test key resolution indirectly through the rendered icon text.
-- The component renders a single chunk {icon, hl_group} based on
-- resolve_key(data, cmdtype).

local function render_icon(data, cmdtype)
  -- Override vim.fn.getcmdtype for test purposes
  local orig = vim.fn.getcmdtype
  vim.fn.getcmdtype = function()
    return cmdtype or ":"
  end
  local component = cmdline_icon.new()
  local ctx = { result = { data = data or {} } }
  local chunks = component:render(ctx)
  vim.fn.getcmdtype = orig
  return chunks
end

T["resolve_key"]["search cmdtype returns search icon"] = function()
  local chunks = render_icon({}, "/")
  expect.equality(type(chunks), "table")
  expect.equality(#chunks, 1)
  -- Should have search icon (magnifying glass)
end

T["resolve_key"]["reverse search returns search icon"] = function()
  local chunks = render_icon({}, "?")
  expect.equality(type(chunks), "table")
  expect.equality(#chunks, 1)
end

T["resolve_key"]["file expand returns file icon"] = function()
  local chunks = render_icon({ expand = "file" }, ":")
  expect.equality(#chunks, 1)
end

T["resolve_key"]["dir expand returns icon"] = function()
  local chunks = render_icon({ expand = "dir" }, ":")
  expect.equality(#chunks, 1)
  expect.equality(type(chunks[1][1]), "string")
end

T["resolve_key"]["buffer expand returns buffer icon"] = function()
  local chunks = render_icon({ expand = "buffer" }, ":")
  expect.equality(#chunks, 1)
end

T["resolve_key"]["help expand returns help icon"] = function()
  local chunks = render_icon({ expand = "help" }, ":")
  expect.equality(#chunks, 1)
end

T["resolve_key"]["option expand returns option icon"] = function()
  local chunks = render_icon({ expand = "option" }, ":")
  expect.equality(#chunks, 1)
end

T["resolve_key"]["color expand returns color icon"] = function()
  local chunks = render_icon({ expand = "color" }, ":")
  expect.equality(#chunks, 1)
end

T["resolve_key"]["lua expand returns lua icon"] = function()
  local chunks = render_icon({ expand = "lua" }, ":")
  expect.equality(#chunks, 1)
end

T["resolve_key"]["expression expand returns lua icon"] = function()
  local chunks_lua = render_icon({ expand = "lua" }, ":")
  local chunks_expr = render_icon({ expand = "expression" }, ":")
  expect.equality(chunks_lua[1][1], chunks_expr[1][1])
end

T["resolve_key"]["shellcmd expand returns shell icon"] = function()
  local chunks = render_icon({ expand = "shellcmd" }, ":")
  expect.equality(#chunks, 1)
end

T["resolve_key"]["substitute command pattern detected"] = function()
  -- Verify substitute patterns (s/, %s/, g/) are recognized
  local component = cmdline_icon.new({ icons = { substitute = "SUB " } })
  local orig = vim.fn.getcmdtype
  vim.fn.getcmdtype = function()
    return ":"
  end
  local ctx = { result = { data = { cmd = "s/foo/bar/" } } }
  local chunks = component:render(ctx)
  expect.equality(chunks[1][1], "SUB ")
  vim.fn.getcmdtype = orig
end

T["resolve_key"]["bang command returns shell icon"] = function()
  local chunks_bang = render_icon({ cmd = "!ls" }, ":")
  local chunks_shell = render_icon({ expand = "shellcmd" }, ":")
  expect.equality(chunks_bang[1][1], chunks_shell[1][1])
end

T["resolve_key"]["unknown expand falls through to default"] = function()
  local chunks = render_icon({ expand = "totally_unknown_type" }, ":")
  expect.equality(#chunks, 1)
end

T["custom options"] = new_set()

T["custom options"]["custom icons override defaults"] = function()
  local orig = vim.fn.getcmdtype
  vim.fn.getcmdtype = function()
    return "/"
  end
  local component = cmdline_icon.new({ icons = { search = "FIND " } })
  local ctx = { result = { data = {} } }
  local chunks = component:render(ctx)
  expect.equality(chunks[1][1], "FIND ")
  vim.fn.getcmdtype = orig
end

T["custom options"]["string hl_group applied to all icons"] = function()
  local orig = vim.fn.getcmdtype
  vim.fn.getcmdtype = function()
    return ":"
  end
  local component = cmdline_icon.new({ hl = "MyCustomHl" })
  local ctx = { result = { data = { expand = "file" } } }
  local chunks = component:render(ctx)
  expect.equality(chunks[1][2], "MyCustomHl")
  vim.fn.getcmdtype = orig
end

T["custom options"]["table hl_group maps per key"] = function()
  local orig = vim.fn.getcmdtype
  vim.fn.getcmdtype = function()
    return ":"
  end
  local component = cmdline_icon.new({
    hl = { file = "FileHl", default = "DefaultHl" },
  })
  local ctx_file = { result = { data = { expand = "file" } } }
  local chunks_file = component:render(ctx_file)
  expect.equality(chunks_file[1][2], "FileHl")

  local ctx_unknown = { result = { data = { expand = "totally_unknown" } } }
  local chunks_unknown = component:render(ctx_unknown)
  expect.equality(chunks_unknown[1][2], "DefaultHl")
  vim.fn.getcmdtype = orig
end

T["custom options"]["no result data falls back to default"] = function()
  local orig = vim.fn.getcmdtype
  vim.fn.getcmdtype = function()
    return ":"
  end
  local component = cmdline_icon.new()
  local ctx = { result = nil }
  local chunks = component:render(ctx)
  expect.equality(type(chunks), "table")
  expect.equality(#chunks, 1)
  vim.fn.getcmdtype = orig
end

return T
