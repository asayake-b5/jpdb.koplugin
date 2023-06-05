(local Dispatcher (require :dispatcher))
(local InfoMessage (require :ui/widget/infomessage))
(local UIManager (require :ui/uimanager))
(local Widget-container (require :ui/widget/container/widgetcontainer))
(local DictQuickLookup (require :ui/widget/dictquicklookup))
(local _ (require :gettext))
(local logger (require :logger))
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
                    (UIManager:show (InfoMessage:new {:text (_ "Helugin worienild")})))
        :sorting_hint :more_tools
        :text (_ "Hello World")}))

;; TODO functionnal program this, with function, id etc parameters
(fn add_to_deck_thing [popup_dict]
  {:callback (fn []
               (UIManager:show (InfoMessage:new {:text (_ (.. :helugin
                                                              popup_dict.word))}))
               (logger.info :hi))
   :font_bold true
   :id :add_to_deck
   :text (_ "Add to deck")})

(fn review_thing [popup_dict]
  {:id :review
   :text (_ :Review)
   :font_bold true
   :callback (fn []
               (UIManager:show (InfoMessage:new {:text (_ "Helugin wori")}))
               (each [k v (ipairs popup_dict.window_list)] (logger.info k)))
   :hold_callback (fn [])
   ;;UIManager:show(self:show_config_widget(popup_dict)) end,
   })

(fn new_tweak_buttons_func [popup_dict buttons]
  (local add_to_deck (add_to_deck_thing popup_dict))
  (local review (review_thing popup_dict))
  (let [parsed (client:parse popup_dict.word)
        dict_title (. (. popup_dict.results popup_dict.dict_index) :dict)]
    (logger.info parsed)
    (when parsed
      (popup_dict.dict_title:setTitle (.. dict_title "(Top " parsed.rank ", "
                                          (. parsed.state 1) ")"))
      (table.insert buttons 1 [add_to_deck review]))))

(fn Hello.init [self]
  (client:init self.path)
  (self.onDispatcherRegisterActions)
  (self.ui.menu:registerToMainMenu self)
  (set DictQuickLookup.tweak_buttons_func new_tweak_buttons_func))

Hello
