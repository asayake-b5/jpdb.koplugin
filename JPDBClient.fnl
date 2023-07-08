(local JPDBClient {:client nil})

(local http (require :socket.http))
(local socket (require :socket))
(local socketutil (require :socketutil))
(local json (require :rapidjson))
(local ltn12 (require :ltn12))
(local logger (require :logger))
(local config (require :config))
(local htmlparser (require :htmlparser))

(fn JPDBClient.init [self path]
  (tset (require :socket.http) :TIMEOUT 1))

(fn JPDBClient.ping [self]
  (let [res (self.client:ping {})]
    (print res.status)
    res.status))

;;TODO
(fn make_request [api_key])
(fn make_payload [])

(fn sortJPDBTable [xpointers]
  (var (keys len) (values {} 0))
  (each [k _ (pairs xpointers)] (set len (+ len 1))
    (tset keys len k))
  ;;TODO maybe don't bother sorting, it might not actually be important to have them in order as long as we have a consistency
  keys)

(fn JPDBClient.makeJPDBArray [xPointers]
  (var array [])
  (each [_ value (ipairs (sortJPDBTable xPointers))]
    (table.insert array (. xPointers value)))
  array)

(fn JPDBClient.addToDeck [self vid sid]
  (let [output-sink {}
        json-payload (json.encode {:id config.deck_id
                                   :vocabulary (setmetatable [(setmetatable [vid
                                                                             sid]
                                                                            {:__jsontype :array})]
                                                             {:__jsontype :array})})
        request {:headers {:Accept :application/json
                           :Authorization (.. "Bearer " config.api_key)
                           :Content-Type :application/json}
                 :method :POST
                 :sink (ltn12.sink.table output-sink)
                 :source (ltn12.source.string json-payload)
                 :url "https://jpdb.io/api/v1/deck/add-vocabulary"}]
    (local (code headers status) (socket.skip 1 (http.request request)))
    (local result (json.decode (table.concat output-sink)))
    (logger.info result)))

(fn JPDBClient.set-sentence [self vid sid sentence]
  (let [output-sink {}
        json-payload (json.encode {: vid
                                   : sid
                                   : sentence

                                   })
        request {:headers {:Accept :application/json
                           :Authorization (.. "Bearer " config.api_key)
                           :Content-Type :application/json}
                 :method :POST
                 :sink (ltn12.sink.table output-sink)
                 :source (ltn12.source.string json-payload)
                 :url "https://jpdb.io/api/v1/set-card-sentence"}]
    (local (code headers status) (socket.skip 1 (http.request request)))
    (local result (json.decode (table.concat output-sink)))
    (logger.info result)))

(fn JPDBClient.parseXPointers [self xPointers]
  (local xp-array (JPDBClient.makeJPDBArray xPointers))
  (local sorted (sortJPDBTable xPointers))
  (let [output-sink {}
        json-payload (json.encode {:text (setmetatable xp-array
                                                       {:__jsontype :array})
                                   :token_fields (setmetatable [:vocabulary_index
                                                                :position
                                                                :length]
                                                               {:__jsontype :array})
                                   :position_length_encoding :utf16
                                   :vocabulary_fields (setmetatable [:vid
                                                                     :sid
                                                                     :spelling
                                                                     :reading
                                                                     :meanings
                                                                     :frequency_rank
                                                                     :card_state]
                                                                    {:__jsontype :array})})
        request {:headers {:Accept :application/json
                           :Authorization (.. "Bearer " config.api_key)
                           :Content-Type :application/json}
                 :method :POST
                 :sink (ltn12.sink.table output-sink)
                 :source (ltn12.source.string json-payload)
                 :url "https://jpdb.io/api/v1/parse"}]
    (local (code headers status) (socket.skip 1 (http.request request)))
    (local result (json.decode (table.concat output-sink)))
    ;; (logger.info result)
    (local return {})
    (each [i xp (ipairs sorted)]
      (let [vocab_list result.vocabulary
            xp_tokens (?. result.tokens i)
            processed_tokens (icollect [_ token (ipairs xp_tokens)]
                               [(?. result.vocabulary (+ (?. token 1) 1))
                                ;lua arrays starting at 1 moment
                                (?. token 2)
                                (?. token 3)])]
        (tset return xp processed_tokens)))
    (when (not (= (next return) nil))
      return)))

(fn table-contains [table value]
  (each [_ v (ipairs table)]
    (when (= v value) true))
  false)

;;TODO refactor? lol
;;maybe some trick if the redundant/locked are stuck in first position like I think it is
;;eg if len 2 2 else 1
(fn JPDBClient.parse-state [jpdb_state]
  (when (not= (type jpdb_state) :userdata) ;;This is like a null test
    ;; (if (= (length state) 2)
    ;; (. state 2)
    (. jpdb_state (length jpdb_state))
    ;; )
    ))

(local grade-to-jpdb {:nothing :1
                      :something :2
                      :hard :3
                      :good :4
                      :easy :5
                      :pass :p
                      :fail :f
                      :known :k
                      :unknown :n
                      :never_forget :w
                      :blacklist :-1})

(fn JPDBClient.request-review [self vid sid]
  (let [output-sink {}
        payload ""
        request {:headers {:Accept "*/*" :Cookie (.. :sid= config.sid)}
                 :method :GET
                 :sink (ltn12.sink.table output-sink)
                 :source (ltn12.source.string payload)
                 :url (string.format "https://jpdb.io/review?c=vf%%2C%s%%2C%s"
                                     vid sid)}]
    (local (code headers status) (socket.skip 1 (http.request request)))
    ;; (logger.info request)
    ;; (logger.info code)
    ;; (logger.info headers)
    ;; (logger.info status)
    output-sink))

(fn JPDBClient.get-review-no [self vid sid]
  (local html (table.concat (self:request-review vid sid)))
  ;; (logger.info html)
  (local root (htmlparser.parse html))
  ;; (logger.info root)
  (local elements (root:select "form[action^=\"/review\"] > input[type=\"hidden\"][name=\"r\"]"))
  ;;TODO redo this, add all to table, assert all equal, etc
  (var review-no nil)
  (each [k v (pairs elements)]
    (set review-no (?. v.attributes :value))
    )
  review-no
  )

(fn JPDBClient.send-review [self vid sid review-no grade]
  (logger.info :send-review)
  (logger.info review-no)
  (logger.info grade)

  (let [output-sink {}
        payload (string.format "c=vf%%2C%s%%2C%s&r=%s&g=%s" vid sid review-no grade)
        request {:headers {:Accept "*/*"
                           :Content-Type :application/x-www-form-urlencoded
                           :Cookie (.. :sid= config.sid)}
                 :method :POST
                 :sink (ltn12.sink.table output-sink)
                 :source (ltn12.source.string payload)
                 :url "https://jpdb.io/review"}]
    (local (code headers status) (socket.skip 1 (http.request request)))
    (logger.info request)
    (logger.info code)
    (logger.info headers)
    (logger.info status)
    ))

(fn JPDBClient.review [self vid sid grade]
  (var review-no (self:get-review-no vid sid))
  (when review-no
    (self:send-review vid sid review-no (?. grade-to-jpdb grade)))
  )

JPDBClient
