local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h") .. "/scripts/screenshots"
local configs = dofile(script_dir .. "/configs.lua")

-- Seed for reproducibility in tests
math.randomseed(12345)

-- Valid values for validation
local valid_pipelines = {
  ["cmdline_fuzzy"] = true,
  ["search"] = true,
  ["lua"] = true,
  ["help_fuzzy"] = true,
  ["history"] = true,
}

local valid_renderers_prefix = {
  "theme:", "wildmenu", "border_theme", "palette", "mux",
}

local valid_left_components = {
  [" "] = true,
  ["devicons"] = true,
  ["kind_icon"] = true,
  ["arrows"] = true,
}

-- random_scene() ---------------------------------------------------------------

T["random_scene()"] = new_set()

T["random_scene()"]["returns table with label"] = function()
  local scene = configs.random_scene("Test")
  expect.equality(type(scene), "table")
  expect.equality(scene.label, "Test")
end

T["random_scene()"]["always includes a pipeline"] = function()
  for _ = 1, 50 do
    local scene = configs.random_scene("S")
    expect.equality(type(scene.pipeline), "table")
    expect.equality(#scene.pipeline >= 1, true)
    for _, p in ipairs(scene.pipeline) do
      expect.equality(valid_pipelines[p], true)
    end
  end
end

T["random_scene()"]["always includes a renderer"] = function()
  for _ = 1, 50 do
    local scene = configs.random_scene("S")
    expect.equality(type(scene.renderer), "string")
    local matched = false
    for _, prefix in ipairs(valid_renderers_prefix) do
      if scene.renderer == prefix or scene.renderer:sub(1, #prefix) == prefix then
        matched = true
        break
      end
    end
    expect.equality(matched, true)
  end
end

T["random_scene()"]["wildmenu recipe has correct fields"] = function()
  -- Generate many scenes and find a wildmenu one
  local found = false
  for _ = 1, 200 do
    local scene = configs.random_scene("S")
    if scene.renderer == "wildmenu" then
      found = true
      expect.equality(scene.highlighter, "basic")
      expect.equality(scene.separator, " | ")
      expect.equality(scene.left, { "arrows" })
      expect.equality(scene.right, { "arrows_right", " ", "index" })
      break
    end
  end
  expect.equality(found, true)
end

T["random_scene()"]["palette recipe has palette config"] = function()
  local found = false
  for _ = 1, 200 do
    local scene = configs.random_scene("S")
    if scene.renderer == "palette" then
      found = true
      expect.equality(type(scene.palette), "table")
      expect.equality(scene.palette.title, " Wildest ")
      expect.equality(scene.palette.prompt_prefix, " : ")
      expect.equality(scene.palette.prompt_position, "top")
      expect.equality(scene.left, { " " })
      break
    end
  end
  expect.equality(found, true)
end

T["random_scene()"]["mux recipe has mode entries"] = function()
  local found = false
  for _ = 1, 200 do
    local scene = configs.random_scene("S")
    if scene.renderer == "mux" then
      found = true
      expect.equality(type(scene.mux), "table")
      expect.equality(type(scene.mux[":"]), "table")
      expect.equality(type(scene.mux["/"]), "table")
      expect.equality(scene.mux["/"].renderer, "wildmenu")
      -- colon renderer should be a theme
      expect.equality(scene.mux[":"].renderer:sub(1, 6), "theme:")
      break
    end
  end
  expect.equality(found, true)
end

T["random_scene()"]["gradient recipe has gradient fields"] = function()
  local found = false
  for _ = 1, 200 do
    local scene = configs.random_scene("S")
    if scene.highlighter == "gradient" then
      found = true
      expect.equality(scene.highlights, false)
      expect.equality(type(scene.gradient_colors), "table")
      expect.equality(#scene.gradient_colors > 0, true)
      expect.equality(scene.left, { " " })
      break
    end
  end
  expect.equality(found, true)
end

T["random_scene()"]["border_custom recipe has custom_highlights"] = function()
  local found = false
  for _ = 1, 200 do
    local scene = configs.random_scene("S")
    if scene.renderer == "border_theme" then
      found = true
      expect.equality(scene.border, "rounded")
      expect.equality(type(scene.custom_highlights), "table")
      -- Should have WildestDefault at minimum
      expect.equality(type(scene.custom_highlights.WildestDefault), "table")
      break
    end
  end
  expect.equality(found, true)
end

T["random_scene()"]["theme recipe uses non-auto themes"] = function()
  for _ = 1, 50 do
    local scene = configs.random_scene("S")
    if scene.renderer and scene.renderer:sub(1, 6) == "theme:" then
      local theme = scene.renderer:sub(7)
      expect.no_equality(theme, "auto")
    end
  end
end

T["random_scene()"]["produces variety across calls"] = function()
  local renderers = {}
  for _ = 1, 100 do
    local scene = configs.random_scene("S")
    renderers[scene.renderer] = true
  end
  -- Should see at least 3 distinct renderer types
  local count = 0
  for _ in pairs(renderers) do
    count = count + 1
  end
  expect.equality(count >= 3, true)
end

-- random_scenes() --------------------------------------------------------------

T["random_scenes()"] = new_set()

T["random_scenes()"]["returns correct number of scenes"] = function()
  local scenes = configs.random_scenes(10)
  expect.equality(#scenes, 10)
end

T["random_scenes()"]["returns empty table for n=0"] = function()
  local scenes = configs.random_scenes(0)
  expect.equality(#scenes, 0)
end

T["random_scenes()"]["labels are sequential"] = function()
  local scenes = configs.random_scenes(5)
  for i, scene in ipairs(scenes) do
    expect.equality(scene.label, "Scene " .. i)
  end
end

T["random_scenes()"]["all scenes are valid"] = function()
  local scenes = configs.random_scenes(20)
  for _, scene in ipairs(scenes) do
    expect.equality(type(scene.pipeline), "table")
    expect.equality(type(scene.renderer), "string")
    expect.equality(type(scene.label), "string")
  end
end

return T
