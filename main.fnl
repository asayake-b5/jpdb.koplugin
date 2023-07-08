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
(local AddToDeckWidget (require :adddeckwidget))
(local ReviewWidget (require :reviewwidget))
(local util (require :frontend/util))

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
(fn add_to_deck_thing [popup_dict vid sid sentence]
  {:callback (fn []
               (UIManager:show (AddToDeckWidget:init popup_dict vid sid
                                                     sentence)))
   :font_bold true
   :id :add_to_deck
   :text (_ "Add to deck")})

(fn review_thing [popup_dict vid sid]
  {:id :review
   :text (_ :Review)
   :font_bold true
   :callback (fn []
               (UIManager:show (ReviewWidget:init popup_dict vid sid)))
   :hold_callback (fn [])
   ;;UIManager:show(self:show_config_widget(popup_dict)) end,
   })

(fn split-up [sentence]
    (local indices [1])
    (local result [])
    (let [chars (util.splitToChars sentence)]
      (each [k v (ipairs chars)]
        (when (or (= v "？") (= v "。") (= v "！"))
          (table.insert indices k)
          )

      )
      (each [i start (ipairs indices) &until (= i (length indices))]
        (let [end (. indices (+ i 1))
              start (if (> 1 i) (+ 1 start) start)
              ]
          (table.insert result (table.concat chars "" (+ 1 start) end))
          )

        )
      result

    ;; (each [sub (string.gmatch sentence "([^？]+)")]
    ;; (logger.info (util.splitToChars sentence))
    ;; (logger.info (table.concat (util.splitToChars sentence))))
  ))


;;TODO trim sentence (especially quote characters and stuff)
;;TODO if sentence is super short add sentence after?
(fn compute-sentence [xpointer selected-text document]
  (let [sentence (xp.getTextFromXPointer xpointer document)
        sentences (split-up sentence)]
    (each [_ s (ipairs sentences)]
    (when (string.find s selected-text)
      (lua "return s")
      )
    ))
  ;; :baba
    ;; (each [sub ( util.splitToChars sentence)]
    ;;   (logger.info sub)))
  ;; (let [sentence (?. )])
  "")

;;TODO if word is blacklist make word be remove from blacklist etc
;;TODO same with never forget
;;TODO reparse Xpointer after having done a review (to update the change)
;;TODO or edit the thing manually YOLO style
(fn new_tweak_buttons_func [self popup_dict buttons]
  ;;TODO WHEN FOUND ETC GREY THE BUTTONS AND STUFF IDK
  (let [xpointer (xp.trim self.ui.highlight.selected_text_start_xpointer)
        entries (?. self.xp-buffer xpointer)
        deinflected (self.deinflector:deinflect popup_dict.word)
        entry (dictionary.find entries deinflected)
        subentry (?. entry 1)
        vid (?. subentry 1)
        sid (?. subentry 2)
        selected-text self.ui.highlight.selected_text.text
        sentence (compute-sentence xpointer selected-text self.ui.document)
        add-to-deck-btn (add_to_deck_thing popup_dict vid sid sentence)
        review-btn (review_thing popup_dict vid sid)]
    (logger.info sentence)
    (table.insert popup_dict.results 2 (. popup_dict.results 1))
    ;; Duplicate dict to n2
    ;;FIXME doesn't work when only one dict available
    ;;works if you press the thing instead of the button which is just locked, maybe something is doable to unclog it
    (tset popup_dict.results 2 (dictionary.JPDBToDict entry))
    (table.insert buttons 1 [add-to-deck-btn review-btn]))
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
  ;; (popup_dict:update)
  )

(fn Jpdb.onReaderReady [self]
  ;; self.ui.menu:registerToMainMenu(self)
  (self.view:registerViewModule :jpdb self))

(fn Jpdb.init [self]
  ;; (client:init self.path)
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
  (logger.info :parse)
  (logger.info aa)
  (self:fill-XPointers-text aa)
  (client:parseXPointers aa))

(fn Jpdb.merge-xparser-tables [self table1 table2]
  (each [k v (pairs table1)]
    (tset table2 k v)))

(fn Jpdb.xpointers-parsed? [self xpointers]
  (each [k _ (pairs xpointers)]
    (when (= nil (?. self.xp-buffer k))
      (lua "return xpointers")))
  true)

(fn Jpdb.page-parsed? [self page]
  (self:xpointers-parsed? (self:get-page-XPointers page)))

(fn Jpdb.length-xps [xpointers]
  (/ (accumulate [sum 0 k v (pairs xpointers)]
       (+ sum (string.len v))) 3)
  ;;DIVIDING by 3 for some utf16thingbsidk
  )

(fn Jpdb.get-a-bunch-of-pages [self page xpointers]
  (var p (+ 1 page))
  (while (< (self.length-xps xpointers) 3000)
    (var xp (self:get-page-XPointers p))
    (self:fill-XPointers-text xp)
    (self:merge-xparser-tables xp xpointers)
    (set p (+ 1 p)))
  ;; (logger.info xpointers)
  (client:parseXPointers xpointers))

;; Maybe useless but important for the painto fix
(fn Jpdb.onCloseDocument [self]
  (tset self :currentPage nil)
  (tset self :xp-buffer {}))

(fn Jpdb.xp-buf-len [self]
  (var i 0)
  (each [_ (pairs self.xp-buffer)] (set i (+ i 1)))
  i)

(fn Jpdb.cleanup-buffer [self]
  (when (> 300 (self:xp-buf-len))
    (set self.xp-buffer {})))

(fn Jpdb.onPageUpdate [self page]
  (let [page_xp (self:page-parsed? page)]
    (when (not= true page_xp)
      (self:cleanup-buffer)
      (logger.info :hiOnPageUpdate)
      ;; (logger.info page_xp)
      (self:fill-XPointers-text page_xp)
      (self:merge-xparser-tables (self:get-a-bunch-of-pages page page_xp)
                                 self.xp-buffer)))
  (set self.currentPage page))

(fn Jpdb.paintRect [self bb x y v jpdb-state]
  (var lighten-factor nil)
  (var underline nil)
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
    (when (self.ui.document:isXPointerInCurrentPage xpointer)
      (each [i word (ipairs words)]
        (let [start (?. word 2)
              len (?. word 3)
              token (?. word 1)
              jpdb_state (client.parse-state (?. token 7))
              (beg_xp end_xp) (xp.fromUtfPos start len xpointer self.document)]
          (local rect
                 (self.ui.document:getScreenBoxesFromPositions beg_xp end_xp
                                                               true))
          (when rect
            (each [_ v (ipairs rect)]
              (self:paintRect bb x y v jpdb_state))))))))

Jpdb
