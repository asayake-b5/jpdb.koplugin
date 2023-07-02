local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local Widget_container = require("ui/widget/container/widgetcontainer")
local DictQuickLookup = require("ui/widget/dictquicklookup")
local KoptInterface = require("document/koptinterface")
local _ = require("gettext")
local logger = require("logger")
local client = require("JPDBClient")
local ReaderUI = require("apps/reader/readerui")
local Screen = (require("device")).screen
local LineWidget = require("ui/widget/linewidget")
local Geom = require("ui/geometry")
local Blitbuffer = require("ffi/blitbuffer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local xp = require("XPointers")
local Hello = Widget_container:extend({name = "jpdb", ["xp-buffer"] = {}, currentPage = nil, is_doc_only = false})
Hello.onDispatcherRegisterActions = function(self)
  return Dispatcher:registerAction("helloworld_action", {category = "none", event = "HelloWorld", general = true, title = _("Hello World")})
end
Hello.addToMainMenu = function(self, menu_items)
  local function _1_()
    return UIManager:show(InfoMessage:new({text = _("Helugin worienild")}))
  end
  menu_items.hello_world = {callback = _1_, sorting_hint = "more_tools", text = _("Hello World")}
  return nil
end
local function add_to_deck_thing(popup_dict)
  local function _2_()
    return UIManager:show(InfoMessage:new({text = _(("helugin" .. popup_dict.word))}))
  end
  return {callback = _2_, font_bold = true, id = "add_to_deck", text = _("Add to deck")}
end
local function review_thing(popup_dict)
  local function _3_()
    UIManager:show(InfoMessage:new({text = _("Helugin wori")}))
    for k, v in ipairs(popup_dict.window_list) do
      logger.info(k)
    end
    return nil
  end
  local function _4_()
  end
  return {id = "review", text = _("Review"), font_bold = true, callback = _3_, hold_callback = _4_}
end
local function new_tweak_buttons_func(popup_dict, buttons)
  local add_to_deck = add_to_deck_thing(popup_dict)
  local review = review_thing(popup_dict)
  local parsed = client:parse(popup_dict.word)
  local dict_title = popup_dict.results[popup_dict.dict_index].dict
  if parsed then
    do end (popup_dict.dict_title):setTitle((dict_title .. "(Top " .. parsed.rank .. ", " .. parsed.state[1] .. ")"))
    return table.insert(buttons, 1, {add_to_deck, review})
  else
    return nil
  end
end
Hello.onReaderReady = function(self)
  return (self.view):registerViewModule("jpdb", self)
end
Hello.init = function(self)
  client:init(self.path)
  self.onDispatcherRegisterActions()
  do end (self.ui.menu):registerToMainMenu(self)
  DictQuickLookup.tweak_buttons_func = new_tweak_buttons_func
  return nil
end
Hello["get-page-XPointers"] = function(self, page)
  return xp["list-xpointers-between"]((self.document):getPageXPointer(page), (self.document):getPageXPointer((1 + page)), self.ui.document)
end
Hello["fill-XPointers-text"] = function(self, table)
  for key, value in pairs(table) do
    table[key] = xp.getTextFromXPointer(key, self.ui.document)
  end
  return nil
end
Hello.parsePage = function(self, page)
  local aa = xp["list-xpointers-between"]((self.document):getXPointer(), (self.document):getPageXPointer((1 + page)), self.ui.document)
  self["fill-XPointers-text"](self, aa)
  logger.info(aa)
  return client:parseXPointers(aa)
end
Hello["merge-xparser-tables"] = function(self, table)
  for k, v in pairs(table) do
    self["xp-buffer"][k] = v
  end
  return nil
end
Hello.onPageUpdate = function(self, page)
  self.currentPage = page
  self["merge-xparser-tables"](self, self:parsePage(page))
  return logger.info(self["xp-buffers"])
end
Hello.onWordLookedUp = function(self, word, title, is_manual)
  return logger.info("wordLookedUp")
end
local function test2return()
  return "one", "two"
end
Hello.paintRect = function(self, bb, x, y, v, jpdb_state)
  local lighten_factor = nil
  local underline = nil
  do
    local _6_ = jpdb_state
    if (_6_ == "known") then
      return
    elseif (_6_ == "never-forget") then
      return
    elseif (_6_ == "blacklisted") then
      return
    elseif (_6_ == "failed") then
      underline = true
    elseif (_6_ == "due") then
      underline = true
    elseif (_6_ == "new") then
      lighten_factor = 0.6
    elseif (_6_ == "learning") then
      lighten_factor = 0.3
    else
    end
  end
  if (nil ~= underline) then
    do end (self.view):drawHighlightRect(bb, x, y, v, "underscore", "underline")
  else
  end
  if (nil ~= lighten_factor) then
    self.view.highlight.lighten_factor = lighten_factor
    return (self.view):drawHighlightRect(bb, x, y, v, "lighten")
  else
    return nil
  end
end
Hello.paintTo = function(self, bb, x, y)
  logger.info((self["xp-buffer"])["/body/DocFragment[15]/body/div/p[9]"])
  logger.info((self.document):getHTMLFromXPointer("/body/DocFragment[15]/body/div/p[9]"))
  local start = "/body/DocFragment[15]/body/div/p[9]"
  for i = 0, 60 do
    logger.info(i)
    start = (self.ui.document):getNextVisibleChar(start)
    while string.find(start, "ruby/rt") do
      start = (self.ui.document):getNextVisibleChar(start)
    end
    logger.info(start)
    logger.info((self.document):getTextFromXPointers(start, (self.ui.document):getNextVisibleChar(start)))
  end
  for xpointer, words in pairs(self["xp-buffer"]) do
    for i, word in ipairs(words) do
      local start0
      do
        local t_10_ = word
        if (nil ~= t_10_) then
          t_10_ = (t_10_)[2]
        else
        end
        start0 = t_10_
      end
      local len
      do
        local t_12_ = word
        if (nil ~= t_12_) then
          t_12_ = (t_12_)[3]
        else
        end
        len = t_12_
      end
      local token
      do
        local t_14_ = word
        if (nil ~= t_14_) then
          t_14_ = (t_14_)[1]
        else
        end
        token = t_14_
      end
      local jpdb_state
      local function _17_()
        local t_16_ = token
        if (nil ~= t_16_) then
          t_16_ = (t_16_)[7]
        else
        end
        return t_16_
      end
      jpdb_state = client["parse-state"](_17_())
      local beg_xp, end_xp = xp.fromUtfPos(start0, len, xpointer, self.document)
      local rect = (self.ui.document):getScreenBoxesFromPositions(beg_xp, end_xp, true)
      if rect then
        for _0, v in ipairs(rect) do
          self:paintRect(bb, x, y, v, jpdb_state)
        end
      else
      end
    end
  end
  return nil
end
return Hello
