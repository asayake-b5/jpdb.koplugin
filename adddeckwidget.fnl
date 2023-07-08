(local InputContainer (require :ui/widget/container/inputcontainer))
(local Button-Dialog (require :ui/widget/buttondialog))
(local Input-Dialog (require :ui/widget/inputdialog))
(local Vertical-Group (require :ui/widget/verticalgroup))
(local Font (require :ui/font))
(local Input-Text (require :ui/widget/inputtext))
(local Frame-Container (require :ui/widget/container/centercontainer))
(local UIManager (require :ui/uimanager))
(local Size (require :ui/size))
(local Blitbuffer (require :ffi/blitbuffer))
(local _ (require :gettext))
(local logger (require :logger))
(local JPDBClient (require :JPDBClient))

(local AddDeckWidget (InputContainer:extend {}))

(fn AddDeckWidget.close [self]
  (UIManager:close self.button-dialog)
  (UIManager:close self.popup_dict))

(fn AddDeckWidget.send-sentence [self]
  (let [sentence (self.button-dialog:getInputText)]
        (when sentence
          (JPDBClient:set-sentence self.vid self.sid sentence))))

(fn AddDeckWidget.makeButtonAdd [self text]
  {:text (_ text)
   :callback (fn []
               (JPDBClient:addToDeck self.vid self.sid)
               (self:send-sentence)
               (self:close))})

(fn AddDeckWidget.makeButtonGrade [self text grade]
  {:text (_ text)
   :callback (fn []
               (JPDBClient:addToDeck self.vid self.sid)
               (JPDBClient:review self.vid self.sid grade)
               (self:send-sentence)
               (self:close))})

;;TODO also unhighlight? but to be honest kinda whatetever
;;TODO FORQ: https://github.com/max-kamps/jpd-breader/blob/087472413f37965e11ad735e348420b806b6c0c7/src/background/backend.ts#L210
;;TODO how do close verticalgroup when clicking outside?
;;TODO uhhhh you know, message above the textbox, when the sentence is too long
;;TODO or at least preemptive message box and no sending when attempting to
(fn AddDeckWidget.init [self popup_dict vid sid sentence]
  ;; (set self.client (JPDBClient:init))
  (logger.info vid)
  (set self.vid vid)
  (set self.sid sid)
  (set self.sentence sentence)
  (set self.popup_dict popup_dict)
  (set self.button-dialog
       (Input-Dialog:new {:title (_ "Add To Deck")
                          :input self.sentence
                          :input_hint (_ :Sentence)
                          :description (_ "Add sentence (empty for no)")
                          :buttons [[(AddDeckWidget:makeButtonAdd :Add)
                                     (AddDeckWidget:makeButtonAdd "Add and FORQ (huge TODO)")]
                                    [(AddDeckWidget:makeButtonGrade :Add/Nothing
                                                                    :nothing)
                                     (AddDeckWidget:makeButtonGrade :Add/Something
                                                                    :something)]
                                    [(AddDeckWidget:makeButtonGrade :Add/Hard
                                                                    :hard)
                                     (AddDeckWidget:makeButtonGrade :Add/Good
                                                                    :good)
                                     (AddDeckWidget:makeButtonGrade :Add/Easy
                                                                    :easy)]
                                    [{:text (_ :Cancel)
                                      :callback (fn [] (self:close))}
                                     {:text (_ "Clear Sentence")
                                      :callback (fn []
                                                  (self.button-dialog:setInputText ""))}]]}))
  (UIManager:show self.button-dialog))

AddDeckWidget
