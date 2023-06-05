local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local Widget_container = require("ui/widget/container/widgetcontainer")
local DictQuickLookup = require("ui/widget/dictquicklookup")
local _ = require("gettext")
local logger = require("logger")
local client = require("JPDBClient")
local Hello = Widget_container:extend({name = "hello", is_doc_only = false})
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
    UIManager:show(InfoMessage:new({text = _(("helugin" .. popup_dict.word))}))
    return logger.info("hi")
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
  logger.info(parsed)
  if parsed then
    do end (popup_dict.dict_title):setTitle((dict_title .. "(Top " .. parsed.rank .. ", " .. parsed.state[1] .. ")"))
    return table.insert(buttons, 1, {add_to_deck, review})
  else
    return nil
  end
end
Hello.init = function(self)
  client:init(self.path)
  self.onDispatcherRegisterActions()
  do end (self.ui.menu):registerToMainMenu(self)
  DictQuickLookup.tweak_buttons_func = new_tweak_buttons_func
  return nil
end
return Hello
