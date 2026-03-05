local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local T = new_set()

local chrome = require("wildest.renderer.chrome")

local function make_ctx()
  return { width = 40, selected = 0, total = 10, page_start = 0, page_end = 9, result = {} }
end

T["resolve_chrome_lines"] = new_set()

T["resolve_chrome_lines"]["string component padded to width"] = function()
  local lines, hls, count = chrome.resolve_chrome_lines({ "hello" }, make_ctx(), 20, "Normal")
  expect.equality(count, 1)
  expect.equality(#lines, 1)
  expect.equality(lines[1], "hello" .. string.rep(" ", 15))
  expect.equality(hls[1].base_hl, "Normal")
  expect.equality(#hls[1].spans, 0)
end

T["resolve_chrome_lines"]["function returning string resolved correctly"] = function()
  local fn = function()
    return "status"
  end
  local lines, hls, count = chrome.resolve_chrome_lines({ fn }, make_ctx(), 10, "Normal")
  expect.equality(count, 1)
  expect.equality(lines[1], "status" .. string.rep(" ", 4))
  expect.equality(hls[1].base_hl, "Normal")
end

T["resolve_chrome_lines"]["function returning nil skipped"] = function()
  local fn = function()
    return nil
  end
  local lines, _, count = chrome.resolve_chrome_lines({ fn }, make_ctx(), 10, "Normal")
  expect.equality(count, 0)
  expect.equality(#lines, 0)
end

T["resolve_chrome_lines"]["function returning empty string skipped"] = function()
  local fn = function()
    return ""
  end
  local lines, _, count = chrome.resolve_chrome_lines({ fn }, make_ctx(), 10, "Normal")
  expect.equality(count, 0)
  expect.equality(#lines, 0)
end

T["resolve_chrome_lines"]["function returning chunk array builds spans"] = function()
  local fn = function()
    return { { "foo", "HlA" }, { "bar", "HlB" } }
  end
  local lines, hls, count = chrome.resolve_chrome_lines({ fn }, make_ctx(), 10, "Normal")
  expect.equality(count, 1)
  expect.equality(lines[1]:sub(1, 6), "foobar")
  expect.equality(#hls[1].spans, 2)
  expect.equality(hls[1].spans[1][1], 0)
  expect.equality(hls[1].spans[1][2], 3)
  expect.equality(hls[1].spans[1][3], "HlA")
  expect.equality(hls[1].spans[2][1], 3)
  expect.equality(hls[1].spans[2][2], 3)
  expect.equality(hls[1].spans[2][3], "HlB")
end

T["resolve_chrome_lines"]["table with value string works"] = function()
  local lines, _, count =
    chrome.resolve_chrome_lines({ { value = "test" } }, make_ctx(), 10, "Normal")
  expect.equality(count, 1)
  expect.equality(lines[1]:sub(1, 4), "test")
end

T["resolve_chrome_lines"]["table with value function works"] = function()
  local lines, _, count = chrome.resolve_chrome_lines(
    { {
      value = function()
        return "dynamic"
      end,
    } },
    make_ctx(),
    10,
    "Normal"
  )
  expect.equality(count, 1)
  expect.equality(lines[1]:sub(1, 7), "dynamic")
end

T["resolve_chrome_lines"]["pre_hook and post_hook called"] = function()
  local called = { pre = false, post = false }
  local comp = {
    value = "test",
    pre_hook = function()
      called.pre = true
    end,
    post_hook = function()
      called.post = true
    end,
  }
  chrome.resolve_chrome_lines({ comp }, make_ctx(), 10, "Normal")
  expect.equality(called.pre, true)
  expect.equality(called.post, true)
end

T["resolve_chrome_lines"]["post_hook called even when value is nil"] = function()
  local called = { post = false }
  local comp = {
    value = function()
      return nil
    end,
    post_hook = function()
      called.post = true
    end,
  }
  chrome.resolve_chrome_lines({ comp }, make_ctx(), 10, "Normal")
  expect.equality(called.post, true)
end

T["resolve_chrome_lines"]["empty components returns 0 lines"] = function()
  local lines, hls, count = chrome.resolve_chrome_lines({}, make_ctx(), 10, "Normal")
  expect.equality(count, 0)
  expect.equality(#lines, 0)
  expect.equality(#hls, 0)
end

T["resolve_chrome_lines"]["nil components returns 0 lines"] = function()
  local lines, hls, count = chrome.resolve_chrome_lines(nil, make_ctx(), 10, "Normal")
  expect.equality(count, 0)
  expect.equality(#lines, 0)
  expect.equality(#hls, 0)
end

T["resolve_chrome_lines"]["multiple components correct count"] = function()
  local lines, _, count =
    chrome.resolve_chrome_lines({ "line1", "line2", "line3" }, make_ctx(), 10, "Normal")
  expect.equality(count, 3)
  expect.equality(#lines, 3)
end

T["resolve_chrome_lines"]["skipped components reduce count"] = function()
  local lines, _, count = chrome.resolve_chrome_lines({
    "line1",
    function()
      return nil
    end,
    "line3",
  }, make_ctx(), 10, "Normal")
  expect.equality(count, 2)
  expect.equality(#lines, 2)
  expect.equality(lines[1]:sub(1, 5), "line1")
  expect.equality(lines[2]:sub(1, 5), "line3")
end

T["resolve_chrome_lines"]["chunk array with empty hl skips span"] = function()
  local fn = function()
    return { { "foo", "" }, { "bar", "HlB" } }
  end
  local _, hls, _ = chrome.resolve_chrome_lines({ fn }, make_ctx(), 10, "Normal")
  -- Empty hl should be skipped, only HlB span present
  expect.equality(#hls[1].spans, 1)
  expect.equality(hls[1].spans[1][3], "HlB")
end

return T
