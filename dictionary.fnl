(local logger (require :logger))
(local Dictionary {})

(fn Dictionary.make-top [top]
  (when top
    (string.format " - Top %s - " top)))

(fn Dictionary.make-status [status]
  (when status
    (when (not= (type status) :userdata) ;;This is like a null test
      (table.concat status ", "))))

(fn Dictionary.make-word [kanji furi]
  (string.format "%s [ %s ]" kanji furi))

(fn Dictionary.make-title [top status]
  (let [top (Dictionary.make-top top)
        status (Dictionary.make-status status)]
    (string.format "JPDB %s %s" top status)))

(fn Dictionary.make-definition [definitions]
  (logger.info definitions)
  (when definitions
    (var def "")
    (each [i v (ipairs definitions)]
      (set def (.. def "\n" (tostring i) ". " v)))
    (string.sub def 2)))

(fn Dictionary.find [entries deinflections]
  ;; (logger.info entries)
  ;; (logger.info deinflections)
  (when entries
    (when deinflections
      (each [i_e entry (ipairs entries)]
        (var token (?. entry 1))
        (var kanji (?. token 3))
        (var furi (?. token 4))
        (each [i_d deinflection (ipairs deinflections)]
          (var d (?. deinflection :term))
          (when (or (= kanji d) (= furi d))
            (lua "return entry")
            ))))))

;;TODO maybe do some stuff with parts of speech etc?
(fn Dictionary.JPDBToDict [entry]
  ;; (logger.info entry)
  (let [token (?. entry 1)
        ;; ;;TODO verify order is correct maybe it's sid vid but I doubt it
        ;; vid (?. token 1)
        ;; sid (?. token 2)
        kanji (?. token 3)
        furi (?. token 4)
        definitions (?. token 5)
        top (?. token 6)
        status (?. token 7)]
    {:definition (Dictionary.make-definition definitions)
     :dict (Dictionary.make-title top status)
     :word (Dictionary.make-word kanji furi)}))

Dictionary
