(local Dispatcher (require :dispatcher))
(local InfoMessage (require :ui/widget/infomessage))
(local UIManager (require :ui/uimanager))
(local Widget-container (require :ui/widget/container/widgetcontainer))
(local DictQuickLookup (require :ui/widget/dictquicklookup))
(local KoptInterface (require :document/koptinterface))
(local _ (require :gettext))
(local logger (require :logger))
(local client (require :JPDBClient))
(local ReaderUI (require :apps/reader/readerui))
(local Screen (. (require :device) :screen))
(local LineWidget (require :ui/widget/linewidget))
(local Geom (require :ui/geometry))
(local Blitbuffer (require :ffi/blitbuffer))
(local HorizontalGroup (require :ui/widget/horizontalgroup))
(local dictionary (require :dictionary))
(local xp (require :XPointers))
(local Deinflector (require :deinflector))
(local SingleInstanceDeinflector (Deinflector:new {}))

(local Jpdb (Widget-container:extend {:is_doc_only false
                                      :name :jpdb
                                      :deinflector SingleInstanceDeinflector
                                      :xp-buffer {}
                                      :currentPage nil}))

(fn Jpdb.onDispatcherRegisterActions [self]
  (Dispatcher:registerAction :helloworld_action
                             {:category :none
                              :event :HelloWorld
                              :general true
                              :title (_ "Hello World")}))

(fn Jpdb.addToMainMenu [self menu-items]
  (set menu-items.hello_world
       {:callback (fn []
                    (UIManager:show (InfoMessage:new {:text (_ "Helugin worienild")})))
        :sorting_hint :more_tools
        :text (_ "Hello World")}))

;; TODO functionnal program this, with function, id etc parameters
(fn add_to_deck_thing [popup_dict]
  {:callback (fn []
               (UIManager:show (InfoMessage:new {:text (_ (.. :helugin
                                                              popup_dict.word))})))
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

;;TODO change this to put it in the onWordLookup
(fn new_tweak_buttons_func [self popup_dict buttons]
  (var entry (dictionary.find (?. self.xp-buffer
                                    (xp.trim self.ui.highlight.selected_text_start_xpointer))
                                (self.deinflector:deinflect popup_dict.word)))
  (table.insert popup_dict.results 2 (. popup_dict.results 1))
  ;; Duplicate dict to n2
  ;;FIXME doesn't work when only one dict available
  ;;works if you press the thing instead of the button which is just locked, maybe something is doable to unclog it
  (tset popup_dict.results 2 (dictionary.JPDBToDict entry))
  ;;   ;; (logger.info (self.ui.highlight:getSelectedWordContext 15 ) ;;be careful, returns 2 thinigies?
  ;;   ;; )
  ;;   ;;   if not settings.enabled and not is_manual then return end
  ;;   ;; if self.widget and self.widget.current_lookup_word == word then return true end
  ;;   ;; local prev_context
  ;;   ;; local next_context
  ;;   ;; if settings.with_context and self.ui.highlight then
  ;;   ;;     prev_context, next_context = self.ui.highlight:getSelectedWordContext(15)
  ;; (set popup_dict.text_widget.text_widget.text :testest)
  ;;FIXME slight improvement to the number of dicts, update it by parsing it (it's like "1/2" etc)
  ;; (when popup_dict.displaynb
  ;;   (popup_dict.displaynb_text:setText (+ 1 (tonumber popup_dict.displaynb))))
  (local add_to_deck (add_to_deck_thing popup_dict (?. (?. entry 1) 1) (?. (?. entry 1) 2)))
  (local review (review_thing popup_dict))
      (table.insert buttons 1 [add_to_deck review])
  ;; (popup_dict:update)
  )

(fn Jpdb.onReaderReady [self]
  ;; self.ui.menu:registerToMainMenu(self)
  (self.view:registerViewModule :jpdb self))

(fn Jpdb.init [self]
  (client:init self.path)
  (self.onDispatcherRegisterActions)
  ;; (Hello:debuggingstuff)
  (self.ui.menu:registerToMainMenu self)
  (set DictQuickLookup.tweak_buttons_func (partial new_tweak_buttons_func self)))

(fn Jpdb.get-page-XPointers [self page]
  (xp.list-xpointers-between (self.document:getPageXPointer page)
                             (self.document:getPageXPointer (+ 1 page))
                             self.ui.document))

(fn Jpdb.fill-XPointers-text [self table]
  (each [key value (pairs table)]
    (tset table key (xp.getTextFromXPointer key self.ui.document))))

(fn Jpdb.parsePage [self page]
  (local aa (xp.list-xpointers-between (self.document:getXPointer)
                                       (self.document:getPageXPointer (+ 1 page))
                                       self.ui.document))
  (self:fill-XPointers-text aa)
  (logger.info aa)
  (client:parseXPointers aa))

(fn Jpdb.merge-xparser-tables [self table]
  (each [k v (pairs table)]
    (tset self.xp-buffer k v)))

;;TODO  maybe parse a few pages at once, etc
(fn Jpdb.onPageUpdate [self page]
  (set self.currentPage page)
  (self:merge-xparser-tables (self:parsePage page))
  (logger.info self.xp-buffers))

;; TODO later ignore for now
;; (fn Jpdb.onPosUpdate [self pos]
;;   ;; (logger.info "new pos")
;;   ;; (logger.info pos)
;;   ;; (logger.info "self.view.doc")
;;   (logger.info (self.ui.document:getTextFromPositions {:x 0 :y 0} {
;;                                                                    :x (Screen:getWidth) :y (Screen:getHeight)
;;                                                                    } true))
;;   ;; (logger.info (self.ui.document:getXPointer))
;;   ;;something with xpointer?
;;   ;;getPageXPointer ?
;;   ;;gettertfromXPointer ?
;;   ;;gettextfrompoisitons?
;;   ;; (logger.info (self.view.document:findText "時間"))
;;   )

(fn Jpdb.paintRect [self bb x y v jpdb-state]
  (var lighten-factor nil)
  (var underline nil)
  ;; (when (= nil lighten-factor) (logger.info "nil"))
  (match jpdb-state
    :known (lua :return)
    :never-forget (lua :return)
    :blacklisted (lua :return)
    :failed (set underline true)
    :due (set underline true)
    :new (set lighten-factor 0.6)
    :learning (set lighten-factor 0.3))
  (when (not= nil underline)
    (self.view:drawHighlightRect bb x y v :underscore :underline))
  (when (not= nil lighten-factor)
    (set self.view.highlight.lighten_factor lighten-factor)
    (self.view:drawHighlightRect bb x y v :lighten)))

(fn Jpdb.paintTo [self bb x y]
  (each [xpointer words (pairs self.xp-buffer)]
    ;; (dictionary.JPDBToDict (. words 1))
    ;;TODO (when xpointer in page etc)
    ;;isXPointerInCurrentPage = function() --[[..skipped..]] end --[[function: 0x7f71499d7270]],
    (each [i word (ipairs words)]
      (let [start (?. word 2)
            len (?. word 3)
            token (?. word 1)
            jpdb_state (client.parse-state (?. token 7))
            (beg_xp end_xp) (xp.fromUtfPos start len xpointer self.document)]
        (local rect
               (self.ui.document:getScreenBoxesFromPositions beg_xp end_xp true))
        (when rect
          (each [_ v (ipairs rect)]
            (self:paintRect bb x y v jpdb_state)))))))

Jpdb
