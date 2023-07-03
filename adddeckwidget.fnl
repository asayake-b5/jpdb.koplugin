(local InputContainer (require :ui/widget/container/inputcontainer))
(local Button-Dialog (require :ui/widget/buttondialog))
(local UIManager (require :ui/uimanager))
(local _ (require :gettext))
(local logger (require :logger))
(local JPDBClient (require :JPDBClient))

(local AddDeckWidget (InputContainer:extend {}))

(fn AddDeckWidget.close [self]
  (UIManager:close self.button_dialog)
  (UIManager:close self.popup_dict))

(fn AddDeckWidget.makeButtonAdd [self text]
  {:text (_ text)
   :callback (fn []
               (JPDBClient:addToDeck self.vid self.sid)
               (self:close))})

(fn AddDeckWidget.makeButtonGrade [self text grade]
  {:text (_ text)
   :callback (fn []
               (JPDBClient:addToDeck self.vid self.sid)
               (JPDBClient:review self.vid self.sid grade)
               (self:close))})

;;TODO also unhighlight? but to be honest kinda whatetever
;;TODO FORQ: https://github.com/max-kamps/jpd-breader/blob/087472413f37965e11ad735e348420b806b6c0c7/src/background/backend.ts#L210
(fn AddDeckWidget.init [self popup_dict vid sid]
  ;; (set self.client (JPDBClient:init))
  (logger.info vid)
  (logger.info sid)
  (set self.vid vid)
  (set self.sid sid)
  (set self.popup_dict popup_dict)
  (set self.button_dialog
       (Button-Dialog:new {:buttons [[(AddDeckWidget:makeButtonAdd :Add)
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
                                     ]}))
  (UIManager:show self.button_dialog))

AddDeckWidget
