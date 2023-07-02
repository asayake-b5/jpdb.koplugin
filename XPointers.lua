local _ = require("gettext")
local logger = require("logger")
local XPointer = {}
XPointer.getP = function(xpointer)
  return string.match(string.match(xpointer, "p%[%d+%]"), "%d+")
end
XPointer.getDocFragment = function(xpointer)
  return string.match(string.match(xpointer, "DocFragment%[%d+%]"), "%d+")
end
XPointer.createWithDocFragment = function(ref, new_df)
  return string.gsub(ref, "DocFragment%[%d+%]", ("DocFragment[" .. new_df .. "]"))
end
XPointer.createWithP = function(ref, new_p)
  return string.gsub(ref, "p%[%d+%]", ("p[" .. new_p .. "]"))
end
XPointer.trim = function(xpointer)
  return string.gsub(xpointer, "(p%[%d+%]).*", "%1")
end
XPointer["xpointer-exists-p"] = function(xpointer, document)
  local xpointer0 = XPointer.trim(xpointer)
  local p = tonumber(XPointer.getP(xpointer0))
  local pm1 = (p - 1)
  local text = document:getTextFromXPointers(XPointer.createWithP(xpointer0, pm1), xpointer0)
  return (not (nil == text) or (1 == p))
end
XPointer["xpointer-is-img-p"] = function(xpointer)
  return (nil ~= string.find(xpointer, "img"))
end
XPointer["increment-naive"] = function(xpointer)
  local p = tonumber(XPointer.getP(xpointer))
  local pp1 = (p + 1)
  return XPointer.createWithP(xpointer, pp1)
end
XPointer.increment = function(xpointer, document)
  local next = XPointer["increment-naive"](xpointer)
  if XPointer["xpointer-exists-p"](next, document) then
    return next
  else
    return nil
  end
end
XPointer["list-in-doc-fragment-from-xp"] = function(xpointer, document)
  local next = xpointer
  while not (nil == next) do
    next = XPointer.increment(next, document)
  end
  return nil
end
XPointer["same-docFragment-p"] = function(x1, x2)
  local doc1 = tonumber(XPointer.getDocFragment(x1))
  local doc2 = tonumber(XPointer.getDocFragment(x2))
  return (doc1 == doc2)
end
XPointer["list-xpointers-sameDoc"] = function(start, _end)
  local _return = {}
  do
    local start_p = tonumber(XPointer.getP(start))
    local end_p = tonumber(XPointer.getP(_end))
    for i = start_p, end_p, 1 do
      local next = XPointer.createWithP(start, i)
      do end (_return)[next] = {}
    end
  end
  return _return
end
XPointer["get-next-docfragment"] = function(xpointer)
  local current_doc = XPointer.getDocFragment(xpointer)
  return (1 + current_doc)
end
XPointer.getTextFromXPointer = function(xpointer, document)
  local next = XPointer.increment(xpointer, document)
  if (next ~= nil) then
    return document:getTextFromXPointers(xpointer, next)
  else
    return document:getTextFromXPointers(xpointer, ("/body/DocFragment[" .. (1 + XPointer.getDocFragment(xpointer)) .. "]"))
  end
end
XPointer["list-xpointers-differentDoc"] = function(start, _end, document)
  local done_3f = false
  local next = start
  local _return = {}
  local end_doc = XPointer.getDocFragment(_end)
  while not done_3f do
    _return[next] = {}
    next = XPointer["increment-naive"](next)
    if not XPointer["xpointer-exists-p"](next, document) then
      if (end_doc == XPointer.getDocFragment(next)) then
        done_3f = true
      else
        if XPointer["xpointer-is-img-p"](_end) then
          done_3f = true
        else
          local next_doc = (1 + XPointer.getDocFragment(next))
          next = XPointer.createWithP(XPointer.createWithDocFragment(next, next_doc), 1)
        end
      end
    else
    end
  end
  return _return
end
XPointer["list-xpointers-between"] = function(start, _end, document)
  local start0 = XPointer.trim(start)
  local _end0 = XPointer.trim(_end)
  if XPointer["same-docFragment-p"](start0, _end0) then
    return XPointer["list-xpointers-sameDoc"](start0, _end0)
  else
    return XPointer["list-xpointers-differentDoc"](start0, _end0, document)
  end
end
XPointer.append = function(xpointer, part, number)
  return (XPointer.trim(xpointer) .. "/text()[" .. part .. "]." .. number)
end
XPointer.split = function(xpointer, document)
  local offset = 1
  local i = 1
  local done = false
  while not done do
    local new_xp = (XPointer.trim(xpointer) .. "/text()[" .. i .. "]")
    local text = document.getTextFromXPointer(new_xp)
    logger.info(new_xp)
    logger.info(text)
    i = (1 + i)
    if (nil == text) then
      done = true
    else
    end
  end
  return nil
end
XPointer.fromUtfPos = function(beg, len, base_xp, document)
  local start = XPointer.trim(base_xp)
  local saw_rb = nil
  for i = 0, beg do
    saw_rb = nil
    start = document:getNextVisibleChar(start)
    while string.find(start, "ruby/rt") do
      saw_rb = "true"
      start = document:getNextVisibleChar(start)
      logger.info(start)
      logger.info(document:getTextFromXPointers(start, document:getNextVisibleChar(start)))
    end
    if saw_rb then
      logger.info("hi")
      start = document:getNextVisibleChar(start)
      start = document:getNextVisibleChar(start)
    else
    end
  end
  local a = start
  for i = 0, (len - 1) do
    saw_rb = nil
    start = document:getNextVisibleChar(start)
    while string.find(start, "ruby/rt") do
      start = document:getNextVisibleChar(start)
    end
    while (nil == document:getTextFromXPointers(start, document:getNextVisibleChar(start))) do
      saw_rb = "true"
      start = document:getNextVisibleChar(start)
    end
    if saw_rb then
      logger.info("hi")
      start = document:getNextVisibleChar(start)
      start = document:getNextVisibleChar(start)
    else
    end
  end
  local b = start
  return a, b
end
return XPointer
