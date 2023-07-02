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
(local xp (require :XPointers))

(local Hello (Widget-container:extend {:is_doc_only false
                                       :name :jpdb
                                       :xp-buffer {}
                                       :currentPage nil}))

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
(fn new_tweak_buttons_func [popup_dict buttons]
  (local add_to_deck (add_to_deck_thing popup_dict))
  (local review (review_thing popup_dict))
  ;; (Hello:debuggingstuff)
  (let [parsed (client:parse popup_dict.word)
        dict_title (. (. popup_dict.results popup_dict.dict_index) :dict)]
    ;; (logger.info parsed)
    (when parsed
      (popup_dict.dict_title:setTitle (.. dict_title "(Top " parsed.rank ", "
                                          (. parsed.state 1) ")"))
      (table.insert buttons 1 [add_to_deck review]))))

(fn Hello.onReaderReady [self]
  ;; (logger.info self.view)
  ;; (logger.info "self.view.doc")
  ;; (logger.info (self.document.findText)))
  ;; (logger.info "self.ui.document.info")
  ;; (logger.info self.ui.document.info))
  ;; self.ui.menu:registerToMainMenu(self)
  (self.view:registerViewModule :jpdb self))

(fn Hello.init [self]
  (client:init self.path)
  (self.onDispatcherRegisterActions)
  ;; (Hello:debuggingstuff)
  (self.ui.menu:registerToMainMenu self)
  (set DictQuickLookup.tweak_buttons_func new_tweak_buttons_func))

(fn Hello.get-page-XPointers [self page]
  (xp.list-xpointers-between (self.document:getPageXPointer page)
                             (self.document:getPageXPointer (+ 1 page))
                             self.ui.document))

(fn Hello.fill-XPointers-text [self table]
  (each [key value (pairs table)]
    (tset table key (xp.getTextFromXPointer key self.ui.document))))

(fn Hello.parsePage [self page]
  (local aa (xp.list-xpointers-between (self.document:getXPointer)
                                       (self.document:getPageXPointer (+ 1 page))
                                       self.ui.document))
  (self:fill-XPointers-text aa)
  (logger.info aa)
  (client:parseXPointers aa))

(fn Hello.merge-xparser-tables [self table]
  ;; (logger.info :xparsertable)
  ;; (logger.info table)
  (each [k v (pairs table)]
    (tset self.xp-buffer k v)))

;;TODO  maybe parse a few pages at once, etc
(fn Hello.onPageUpdate [self page]
  ;; (logger.info self.ui.highlight)
  ;; (logger.info "new page")
  ;; (logger.info page)
  (set self.currentPage page)
  ;; (logger.info :self.view.doc)
  ;; (logger.info (self.view.document:findText self.ui.doc_settings))
  ;; (local res (self.ui.document:getTextFromPositions {:x 0 :y 0} {
  ;;                                                                  :x (Screen:getWidth) :y (Screen:getHeight)
  ;;                                                                  } true))
  ;; (local res
  ;;        (self.ui.document:getTextFromPositions {:x 0 :y 0} {:x (Screen:getWidth)
  ;;                                               :y (Screen:getHeight)}))
  ;; (local res (KoptInterface:getNativeTextBoxes self.ui.document page))
  ;; (local page_boxes ( self.ui.document:getTextBoxes page))
  ;; (logger.info res)
  ;; (logger.info self.view)
  ;; (logger.info page_boxes)
  ;; (logger.info (self.ui.document:getTextBoxes self.ui.document page))
  ;; (logger.info (self.ui.document:getPageXPointer (+ 1 page)))
  ;; (logger.info (self.ui.document:getXPointer))
  ;; ;; (logger.info (self.ui.document:getTextFromXPointers (self.ui.document:getPageXPointer page) (self.ui.document:getPageXPointer (+ 1 page))))
  ;; (logger.info (self.ui.document:getTextFromXPointers "/body/DocFragment[12]/body/div/p[47]/text().53"
  ;;                                                     "/body/DocFragment[13]"))
  ;; (logger.info (self.ui.document:getTextFromXPointers "/body/DocFragment[12]/body/div/p[52]"
  ;;                                                     "/body/DocFragment[12]/body/div/p[53]"))
  ;; (logger.info :myshittest)
  ;; (logger.info (self.ui.document:getTextFromXPointers "/body/DocFragment[12]/body/div/p[1200]" "/body/DocFragment[12]/body/div/p[1202]"))
  ;; ;; (self.ui.document:getPosFromXPointer "/body/DocFragment[12]/body/div/p[15]/text().7")
  ;; ;; (self.ui.document:getPosFromXPointer "/body/DocFragment[12]/body/div/p[15]/text().7")
  ;; (logger.info (self.ui.document:getPosFromXPointer "/body/DocFragment[12]/body/div/p[15]/text().6"))
  ;; (logger.info (self.ui.document:getPosFromXPointer "/body/DocFragment[12]/body/div/p[15]/text().7"))
  ;; (logger.info (self.ui.document:getPosFromXPointer "/body/DocFragment[12]/body/div/p[15]/text().5"))
  ;; (local (pos1 pos2) (self.ui.document:getPosFromXPointer "/body/DocFragment[12]/body/div/p[15]/text().4"))
  ;; (local pos4 (self.ui.document:highlightXPointer "/body/DocFragment[12]/body/div/p[15]/text().5"))
  ;; (local pos2 (self.ui.document:getPosFromXPointer "/body/DocFragment[12]/body/div/p[15]/text().5"))
  ;; (logger.info :screenpos)
  ;; (logger.info pos1)
  ;; (logger.info pos2)
  ;; (logger.info :DocFbqa-tragment)
  ;; (xp.getDocFragment (self.ui.document:getXPointer))
  ;; (logger.info (xp.xpointer-exists-p (self.ui.document:getXPointer)
  ;;                                    self.ui.document))
  ;; (logger.info (xp.xpointer-exists-p "/body/DocFragment[15]/body/div/p[14]"
  ;;                                    self.ui.document))
  ;; (logger.info (xp.xpointer-exists-p "/body/DocFragment[12]/body/div/p[52]"
  ;;                                    self.ui.document))
  ;; (logger.info :trim)
  ;; (logger.info (xp.trim "/body/DocFragment[13]/body/div/p[2]/text().53"))
  ;; (logger.info (. aa "/body/DocFragment[12]/body/div/p[52]"))
  ;; (logger.info (xp.createWithDocFragment (self.ui.document:getXPointer) 16))
  ;; (logger.info (xp.createWithP (self.ui.document:getXPointer) 16))
  ;; (logger.info (self.ui.document:getWordBoxesFromPositions))
  ;; (logger.info pos2)
  ;; (logger.info (self.ui.document:getTextFromPositions {:x  0 :y 0}
  ;;           {:x (Screen:getWidth) :y (Screen:getHeight)}  true))
  ;; (local aa (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[12]/body/div/p[15]/text().4"
  ;;                                                         "/body/DocFragment[12]/body/div/p[15]/text().6"
  ;;                                                         false))
  ;; (local aa2 (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[12]/body/div/p[15]/text().1"
  ;;                                                          "/body/DocFragment[12]/body/div/p[15]/text().2"
  ;;                                                          false))
  ;; (tset self.view.highlight.temp page [aa aa2])
  ;; (set self.view.highlight.temp_drawer :lighten)
  ;; (table.insert (. self.view.highlight.temp page) aa2)
  ;; (set self.view.highlight.temp_drawer :invert)
  ;; (logger.info self.ui.highlight.temp)
  ;; (logger.info (self.ui.document:getPageBoxesFromPositions page "/body/DocFragment[12]/body/div/p[15]/text().1" "/body/DocFragment[12]/body/div/p[15]/text().2"))
  ;; (logger.info self.ui.document.getScreenBoxesFromPositions)
  ;; (logger.info (self.ui.document:getScreenBoxesFromPositions [pos1 pos2] [pos3 pos4] true))
  ;; )
  ;; (logger.info self.ui.geometry)
  ;;   (local line-widget
  ;;        (LineWidget:new {:background Blitbuffer.COLOR_LIGHT_GRAY :style "solid"
  ;;                          :dimen (Geom:new {:h 100
  ;;                                            :w 12})}))
  ;; (table.insert self.wordsOnPage
  ;;      (Widget-container:new {1 line-widget
  ;;                             :dimen (Geom:new {:h 100
  ;;                                               :w 12
  ;;                                               :x 133
  ;;                                               :y 100})}))
  ;; (table.insert self.wordsOnPage (HorizontalGroup:new [
  ;;                                                     test
  ;;                                                     ]))
  (self:merge-xparser-tables (self:parsePage page))
  (logger.info self.xp-buffers))

;; TODO later ignore for now
;; (fn Hello.onPosUpdate [self pos]
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

(fn Hello.onWordLookedUp [self word title is_manual]
  (logger.info :wordLookedUp)
  ;; (logger.info word)
  ;; (logger.info title)
  ;; (logger.info self.ui.highlight)
  ;; (logger.info (self.ui.highlight:getSelectedWordContext 15 ) ;;be careful, returns 2 thinigies?
  ;; )
  ;;   if not settings.enabled and not is_manual then return end
  ;; if self.widget and self.widget.current_lookup_word == word then return true end
  ;; local prev_context
  ;; local next_context
  ;; if settings.with_context and self.ui.highlight then
  ;;     prev_context, next_context = self.ui.highlight:getSelectedWordContext(15)
  ;; end
  )

(fn test2return []
  (values :one :two))

(fn Hello.paintRect [self bb x y v jpdb-state]
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

(fn Hello.paintTo [self bb x y]
  ;; (logger.info :hi)
  ;; (logger.info (self.document:getCurrentPos))
  ;; (logger.info bb)
  ;; (logger.info x)
  ;; (logger.info y)
  ;; (logger.info :getpos)
  ;; (local (spos0 spos02)
  ;;        (self.ui.document:getPosFromXPointer "/body/DocFragment[15]/body/div/p[13]/text()[1].5"))
  ;; (local (spos1 spos12)
  ;;        (self.ui.document:getPosFromXPointer "/body/DocFragment[15]/body/div/p[13]/text()[1].6"))
  ;; (local (spos0 spos02)
  ;;        (self.document:getPosFromXPointer "/body/DocFragment[15]/body/div/p[13]/text()[1].5"))
  ;; (local (spos1 spos12)
  ;;        (self.document:getPosFromXPointer "/body/DocFragment[15]/body/div/p[13]/text()[1].7"))
  ;; (logger.info :spos)
  ;; (logger.info spos0)
  ;; (logger.info spos02)
  ;; (logger.info spos1)
  ;; (local aa2 (self.ui.document:getScreenBoxesFromPositions (.. spos0 " " spos02) (.. spos1 " " spos12)))
  ;; (logger.info (self.ui.document:getScreenBoxesFromPositions spos02 spos12 true))
  ;; (logger.info (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[15]/body/div/p[14]/text()[1].1"
  ;;                                                            "/body/DocFragment[15]/body/div/p[14]/text()[1].2"
  ;;                                                            true))
  ;; (logger.info (self.ui.document:getScreenPositionFromXPointer "/body/DocFragment[15]/body/div/p[12]/text()[1].0"))
  ;; (logger.info (self.ui.document:getScreenPositionFromXPointer "/body/DocFragment[15]/body/div/p[12]/text()[1].1"))
  ;; (logger.info (self.ui.document:getScreenPositionFromXPointer "/body/DocFragment[15]/body/div/p[12]/text()[1].2"))
  ;; (logger.info :segments)
  ;; (logger.info aa2)
  ;; (local rect (self.view:pageToScreenTransform self.currentPage (. aa2 1)))
  ;; (local aa3 (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[12]/body/div/p[16]/text().3"
  ;;                                                          "/body/DocFragment[12]/body/div/p[16]/text().4"
  ;;                                                          false))
  ;; (local aa3 (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[15]/body/div/p[12]/text()[1].1"
  ;;                                                          "/body/DocFragment[15]/body/div/p[12]/text()[1].5"
  ;;                                                          true))
  ;; (local rect2 (self.view:pageToScreenTransform self.currentPage (. aa3 1)))
  ;; (local aa4 (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[12]/body/div/p[16]/text().9"
  ;;                                                          "/body/DocFragment[12]/body/div/p[16]/text().11"
  ;;                                                          false))
  ;; (local rect3 (self.view:pageToScreenTransform self.currentPage (. aa4 1)))
  ;; (logger.info :aa2rect)
  ;; (logger.info aa2)
  ;; (logger.info rect)
  ;; (logger.info rect2)
  ;; (when rect2
  ;; (logger.info rect.x)
  ;; (logger.info rect.y)
  ;; (logger.info rect.w)
  ;; (logger.info rect.h)
  ;; (set self.view.highlight.lighten_factor 0.3)
  ;; (self.view:drawHighlightRect bb x y rect :underscore :underline)
  ;; (set self.view.highlight.lighten_factor 0.1)
  ;; (self.view:drawHighlightRect bb x y rect2 :lighten :underline)
  ;; (set self.view.highlight.lighten_factor 0.6)
  ;; (self.view:drawHighlightRect bb x y rect3 :lighten :underline))
  ;; (logger.info self.wordsOnPage)
  ;; (logger.info self.xp-buffer)
  (logger.info (. self.xp-buffer "/body/DocFragment[15]/body/div/p[9]"))
  (logger.info (self.document:getHTMLFromXPointer "/body/DocFragment[15]/body/div/p[9]"))
  ;;    (logger.info (self.document:getTextFromXPointers "/body/DocFragment[15]/body/div/p[6]/text()[1].23" "/body/DocFragment[15]/body/div/p[6]/text()[1].24"))
  (var start "/body/DocFragment[15]/body/div/p[9]")
  (for [i 0 60]
    (logger.info i)
    (set start (self.ui.document:getNextVisibleChar start))
    (while (string.find start :ruby/rt)
      (set start (self.ui.document:getNextVisibleChar start)))
    (logger.info start)
    (logger.info (self.document:getTextFromXPointers start (self.ui.document:getNextVisibleChar start))))
  (each [xpointer words (pairs self.xp-buffer)]
    ;; (logger.info xpointer)
    ;;TODO (when xpointer in page etc)
    ;; (logger.info :word)
    ;; (logger.info word)
    (each [i word (ipairs words)]
      ;; (logger.info :new)
      ;; (logger.info i)
      ;; (logger.info word)
      (let [start (?. word 2)
            len (?. word 3)
            token (?. word 1)
            jpdb_state (client.parse-state (?. token 7))
            ;; beg_xp (xp.append xpointer 1 start) ;;TODO remake that, since signature changed
            ;; end_xp (xp.append xpointer 1 (+ start len))]
            (beg_xp end_xp) (xp.fromUtfPos start len xpointer self.document)]
        ;; (logger.info start)
        ;; (logger.info jpdb_state)
        ;; (logger.info len)
        ;; (logger.info beg_xp)
        ;; (logger.info end_xp)
        (local rect
               (self.ui.document:getScreenBoxesFromPositions beg_xp end_xp true))
        (when rect
          ;;   ;; (logger.info :hi)
          ;;   ;; (logger.info rect)
          (each [_ v (ipairs rect)]
            (self:paintRect bb x y v jpdb_state))
          ;; (word:paintTo bb x y)
          ;; (word:paintTo bb x y)
          ;; (bb:paintBorder 100 100 100 100 12 (Blitbuffer.gray 0.2) 1)
          ;; (bb:dimRect 100 100 100 100)
          ;; (logger.info (xp.fromUtfPos start len xpointer self.document ))
          )))
    ;; (local rect2
    ;;        (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[15]/body/div/p[14]/text().1"
    ;;                                                      "/body/DocFragment[15]/body/div/p[14]/text().5" true))
    ;; (local rect2
    ;;        (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[15]/body/div/p[56]/text()[2].1"
    ;;                                                      "/body/DocFragment[15]/body/div/p[56]/text()[2].31" true))
    ;; (local rect2
    ;;        (self.ui.document:getScreenBoxesFromPositions "/body/DocFragment[15]/body/div/p[66]/text()[1].0"
    ;;                                                      "/body/DocFragment[15]/body/div/p[66]/text()[2].1" true))
    ;; (logger.info :bab)
    ;; (logger.info (test2return))
    ;; (logger.info (self.document:getTextFromXPointer "/body/DocFragment[15]/body/div/p[14]/text()[1][1]"))
    ;; ;; (logger.info (self.document:getNextVisibleChar "/body/DocFragment[15]/body/div/p[14]/text()[2].8"))
    ;; (logger.info (self.document:getNextVisibleChar "/body/DocFragment[15]/body/div/p[66]/ruby/rb/text().0"))
    ;; (logger.info (self.document:getTextFromXPointer "/body/DocFragment[15]/body/div/p[14]/text()[2].9"))
    ;; (logger.info (self.document:getHTMLFromXPointer "/body/DocFragment[15]/body/div/p[14]"))
    ;; (logger.info self.currentPage)
    ;; (logger.info (self.document:getPageXPointer self.currentPage))
    ;; (logger.info (self.document:getHTMLFromXPointer (xp.trim (self.document:getPageXPointer self.currentPage))))
    ;; (xp.split "/body/DocFragment[15]/body/div/p[14]/nstnistnstu" self.document)
    ;;   (each [_ v (ipairs rect2)]
    ;;          (set self.view.highlight.lighten_factor 0.1)
    ;;   (self.view:drawHighlightRect bb x y v :underscore)
    ;;     )
    ;; (logger.info self.ui.highlight)
    ))

Hello
