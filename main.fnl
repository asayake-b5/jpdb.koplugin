(local Dispatcher (require :dispatcher))
(local Info-message (require :ui/widget/infomessage))
(local UIManager (require :ui/uimanager))
(local Widget-container (require :ui/widget/container/widgetcontainer))
(local Dict-quick-lookup (require :ui/widget/dictquicklookup))
(local _ (require :gettext))
(local logger (require :logger))
(local config (require :config))
(local client (require :JPDBClient))

(local Hello (Widget-container:extend {:is_doc_only false :name :hello}))

(fn Hello.onDispatcherRegisterActions [self]
  (Dispatcher:registerAction :helloworld_action
                             {:category :none
                              :event :HelloWorld
                              :general true
                              :title (_ "Hello World")}))

(fn Hello.addToMainMenu [self menu-items]
  (set menu-items.hello_world
       {:callback (fn []
                    (UIManager:show (Info-message:new {:text (_ "Helugin worienild")})))
        :sorting_hint :more_tools
        :text (_ "Hello World")}))

;; local oldtweak = DictQuickLookup.tweak_buttons_func or function()
;;         logger.info("nothing")
;;     end
;;     DictQuickLookup.tweak_buttons_func = function(popup_dict, buttons)
;;         oldtweak(popup_dict, buttons)
;;         logger.info(popup_dict.definition)
;;         logger.info(popup_dict.displayword)
;;         logger.info(popup_dict.word)
;;         logger.info(popup_dict.results)
;;         self.add_to_deck = {
;;             id = "add_to_deck",
;;             text = _("Add to Deck"),
;;             font_bold = true,
;;             callback = function()
;;                 UIManager:show(InfoMessage:new {
;;                     text = _("Helugin" .. popup_dict.word),
;;                 })
;;                 logger.info("hi")
;;                 -- logger.info(DictQuickLookup)
;;             end,
;;             -- hold_callback = function() UIManager:show(self:show_config_widget(popup_dict)) end,
;;         }
;;         self.review = {
;;             id = "review",
;;             text = _("Review"),
;;             font_bold = true,
;;             callback = function()
;;                 UIManager:show(InfoMessage:new {
;;                     text = _("Helugin worienild"),
;;                 })
;;                 for k, v in ipairs(popup_dict.window_list) do
;;                     logger.info(k)
;;                 end
;;             end,
;;             -- hold_callback = function() UIManager:show(self:show_config_widget(popup_dict)) end,
;;         }

;;         -- popup_dict.dict_title:setTitle(config.api_key .. config.deck_id)
;;         -- TODO do better see ankoconnect plugin getting the proper word from the dict query headline
;;         -- popup_dict.results[index or something?]
;;         -- TODO some couroutine stuff to make it faster/async and not bother dict appearing
;;         local parsed = client:parse(popup_dict.word)
;;         logger.info(popup_dict.results[popup_dict.dict_index].dict)
;;         local dict_title = popup_dict.results[popup_dict.dict_index].dict
;;         -- popup_dict.dict_title:setTitle(popup_dict.dict_title[popup_dict.dict_index] .. parsed.rank)
;;         -- popup_dict.dict_title:setTitle(popup_dict.word)
;;         -- TODO iterate through stuff to give all the states, make a function or something I dunno
;;         popup_dict.dict_title:setTitle(dict_title .. " (Top " .. parsed.rank .. ", " .. parsed.state[1] .. ")")

;;         table.insert(buttons, 1, { self.add_to_deck, self.review })
;;     end


(fn Hello.init [self]
  (do
    ;; (client.init self.path)
    (self.onDispatcherRegisterActions)
    (self.ui.menu:registerToMainMenu self)))

Hello
