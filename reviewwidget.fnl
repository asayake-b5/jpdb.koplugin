(local InputContainer (require :ui/widget/container/inputcontainer))
(local Button-Dialog (require :ui/widget/buttondialog))
(local UIManager (require :ui/uimanager))
(local _ (require :gettext))
(local logger (require :logger))
(local JPDBClient (require :JPDBClient))

(local ReviewWidget (InputContainer:extend {}))

(fn ReviewWidget.close [self]
  (UIManager:close self.button_dialog)
  (UIManager:close self.popup_dict))

(fn ReviewWidget.makeButton [self text grade]
  {:text (_ text)
   :callback (fn []
               (JPDBClient:review self.vid self.sid grade)
               (self:close))})

;;TODO blacklist button?
;;TODO never forget button
(fn ReviewWidget.init [self popup_dict vid sid]
  ;; (set self.client (JPDBClient:init))
  (set self.vid vid)
  (set self.sid sid)
  (set self.popup_dict popup_dict)
  (set self.button_dialog
       (Button-Dialog:new {:buttons [[(ReviewWidget:makeButton :Nothing
                                                               :nothing)
                                      (ReviewWidget:makeButton :Something
                                                               :something)]
                                     [(ReviewWidget:makeButton :Hard :hard)
                                      (ReviewWidget:makeButton :Good :good)
                                      (ReviewWidget:makeButton :Easy :easy)]
                                     [(ReviewWidget:makeButton "Never Forget"
                                                               :never_forget)
                                      (ReviewWidget:makeButton :Blacklist
                                                               :blacklist)]]}))
  (UIManager:show self.button_dialog))

ReviewWidget
