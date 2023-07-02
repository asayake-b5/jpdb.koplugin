(local _ (require :gettext))
(local logger (require :logger))
(local XPointer {})

;; (let [(start end) (string.find xpointer "DocFragment[" 1 true)
;;       (start_e end_e) (string.find xpointer "]/" end true)
;;       ]
;; (logger.info (string.match (string.match xpointer "DocFragment%[%d+%]") "%d+"))
;;   (logger.info start)
;;   (logger.info end)
;;   (logger.info start_e)
;;   (logger.info end_e)
;;   (logger.info (string.sub xpointer end start_e))
;; )

;;TODO handle images and stuff
;;note: if is image, docfragment will never have ps apprently?

;;NOTE: getTextFromXPointers dies if the outter bound (second arg) doesn't exist, so first
;;HOWEVER we need to get the text from the last p (because getTextFromXPointers is exclusive), so we can just grab the next docfragment
;;(works even if next one is image, we can crop to like /body/docfragment[n+1])

(fn XPointer.getP [xpointer]
  (string.match (string.match xpointer "p%[%d+%]") "%d+"))

(fn XPointer.getDocFragment [xpointer]
  (string.match (string.match xpointer "DocFragment%[%d+%]") "%d+"))

(fn XPointer.createWithDocFragment [ref new-df]
  (string.gsub ref "DocFragment%[%d+%]" (.. "DocFragment[" new-df "]")))

(fn XPointer.createWithP [ref new-p]
  (string.gsub ref "p%[%d+%]" (.. "p[" new-p "]")))

(fn XPointer.trim [xpointer]
  (string.gsub xpointer "(p%[%d+%]).*" "%1"))

;;TODO what if we have empty xpointers? may be an issue, or not
;;TODO seems to be fucky wucky if p is 1 (0->1 returns nil) but might not be a problem depending on how we use the function
;;     maybe YOLO p==1 -> return true
;;     TODO actually getTextFromXPointer might be enough
;;     FIXME redo this
(fn XPointer.xpointer-exists-p [xpointer document]
  (local xpointer (XPointer.trim xpointer))
  (let [p (tonumber (XPointer.getP xpointer))
        pm1 (- p 1)
        text (document:getTextFromXPointers (XPointer.createWithP xpointer pm1)
                                            xpointer)]
    (or (not (= nil text)) (= 1 p))))

(fn XPointer.xpointer-is-img-p [xpointer]
  (not= nil (string.find xpointer :img)))

;; (fn XPointer.decrement [xpointer]
;;   (let [p (tonumber (XPointer.getP xpointer))
;;         pm1 (- p 1)
;;         ]
;;     (XPointer.createWithP xpointer pm1)
;;     )
;;   )

;;NOTE can create wrong xpaths (that don't exist in the document)
(fn XPointer.increment-naive [xpointer]
  (let [p (tonumber (XPointer.getP xpointer))
        pp1 (+ p 1)]
    (XPointer.createWithP xpointer pp1)))

(fn XPointer.increment [xpointer document]
  (local next (XPointer.increment-naive xpointer))
  (if (XPointer.xpointer-exists-p next document)
      next
      nil))

(fn XPointer.list-in-doc-fragment-from-xp [xpointer document]
  (var next xpointer)
  (while (not (= nil next))
    (set next (XPointer.increment next document))))

(fn XPointer.same-docFragment-p [x1 x2]
  (let [doc1 (tonumber (XPointer.getDocFragment x1))
        doc2 (tonumber (XPointer.getDocFragment x2))]
    (= doc1 doc2)))

(fn XPointer.list-xpointers-sameDoc [start end]
  (var return {})
  (let [start_p (tonumber (XPointer.getP start))
        end_p (tonumber (XPointer.getP end))]
    (for [i start_p end_p 1]
      (local next (XPointer.createWithP start i))
      (tset return next {})))
  return)

(fn XPointer.get-next-docfragment [xpointer]
  (let [current_doc (XPointer.getDocFragment xpointer)]
    (+ 1 current_doc)))

(fn XPointer.getTextFromXPointer [xpointer document]
  (local next (XPointer.increment xpointer document))
  (if (not= next nil)
      (document:getTextFromXPointers xpointer next)
      (document:getTextFromXPointers xpointer
                                     (.. "/body/DocFragment["
                                         (+ 1
                                            (XPointer.getDocFragment xpointer))
                                         "]")))
  ;; (let [text (document:getTextFromXPointers xpointer (XPointer.))])
  )

;; (fn XPointer.get-next-p-docfragment [xpointer document max]
;;   (var done? false)
;;   (var next (XPointer.getDocFragment xpointer))

;;   (while (not done?)
;;     (if (XPointer.xpointer-is-img-p next document)
;;         (set next (XPointer.get-next-docfragment xpointer))
;;         ()
;;         )
;;     )
;;   )

(fn XPointer.list-xpointers-differentDoc [start end document]
  (var done? false)
  (var next start)
  (var return {})
  (local end_doc (XPointer.getDocFragment end))
  (while (not done?)
    (tset return next [])
    (set next (XPointer.increment-naive next))
    (when (not (XPointer.xpointer-exists-p next document))
      (if (= end_doc (XPointer.getDocFragment next))
          (set done? true)
          (if (XPointer.xpointer-is-img-p end)
              (set done? true)
              (let [next_doc (+ 1 (XPointer.getDocFragment next))]
                (set next (XPointer.createWithP (XPointer.createWithDocFragment next
                                                                                next_doc)
                                                1)))))))
  return)

;;FIXME doesn't work kinda
;;also I think useless now
(fn XPointer.list-xpointers-between [start end document]
  (let [start (XPointer.trim start)
        end (XPointer.trim end)]
    (if (XPointer.same-docFragment-p start end)
        (XPointer.list-xpointers-sameDoc start end)
        (XPointer.list-xpointers-differentDoc start end document))))

(fn XPointer.append [xpointer part number]
  (.. (XPointer.trim xpointer) "/text()[" part "]." number)
  ;;Trimming just in case but shouldn't be needed
  )

(fn XPointer.split [xpointer document]
  (var offset 1)
  (var i 1)
  (var done false)
  (while (not done)
    (let [new_xp (.. (XPointer.trim xpointer) "/text()[" i "]")
          text (document.getTextFromXPointer new_xp)]
      (logger.info new_xp)
      (logger.info text)
      (set i (+ 1 i))
      (when (= nil text)
        (set done true)))))

;;TODO ugly as fuck
(fn XPointer.fromUtfPos [beg len base_xp document]
  ;; (logger.info :fromUtf)
  ;; (logger.info beg)
  ;; (logger.info len)
  (var start (XPointer.trim base_xp))
  (var saw_rb nil)
  (for [i 0 beg]
    (set saw_rb nil)
    (set start (document:getNextVisibleChar start))
    ;; (while (string.find start "/ruby.*/rt")
    (while (string.find start :ruby/rt)
      (set saw_rb :true)
      (set start (document:getNextVisibleChar start))
      (logger.info start)
      (logger.info (document:getTextFromXPointers start (document:getNextVisibleChar start))))
    (when saw_rb
      (logger.info :hi)
      (set start (document:getNextVisibleChar start))
      (set start (document:getNextVisibleChar start))
      )
    )


    ;; (while (= nil (document:getTextFromXPointers start (document:getNextVisibleChar start)) )
      ;; (logger.info :hi)
      ;; (set start (document:getNextVisibleChar start)))
  ;; )
  (var a start)
  (for [i 0 (- len 1)]
    (set saw_rb nil)
    (set start (document:getNextVisibleChar start))
    (while (string.find start :ruby/rt)
      (set start (document:getNextVisibleChar start)))
    (while (= nil (document:getTextFromXPointers start (document:getNextVisibleChar start)) )
      (set saw_rb :true)
      (set start (document:getNextVisibleChar start)))
    (when saw_rb
      (logger.info :hi)
      (set start (document:getNextVisibleChar start))
      (set start (document:getNextVisibleChar start))
      )

    )
  (var b start)
  (values a b))

XPointer
