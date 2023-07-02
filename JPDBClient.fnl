(local JPDBClient {:client nil})

(local http (require :socket.http))
(local socket (require :socket))
(local socketutil (require :socketutil))
(local json (require :rapidjson))
(local ltn12 (require :ltn12))
(local logger (require :logger))
(local config (require :config))

(fn JPDBClient.init [self path]
  (tset (require :socket.http) :TIMEOUT 1)
  (local Spore (require :Spore))
  (set self.client (Spore.new_from_spec (.. path :/jpdb_api.json) {}))
  (local config (require :config))
  (self.client:enable :Auth.Bearer {:bearer_token config.api_key})
  (self.client:enable :Format.JSON))

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

;;TODO refactor OR NOT because maybe we can save everything
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
    ;; (logger.info json-payload)
    (local (code headers status) (socket.skip 1 (http.request request)))
    ;;     (logger.info (string.format "AnkiConnect#post_request: code: %s, header: %s, status: %s
    ;; " code headers status))
    (local result (json.decode (table.concat output-sink)))
    ;; (logger.info (. result.vocabulary 1))
    ;; (logger.info result)
    ;; (logger.info result.vocabulary)
    (local return {})
    (each [i xp (ipairs sorted)]
      (let [vocab_list result.vocabulary
            xp_tokens (?. result.tokens i)
            processed_tokens (icollect [_ token (ipairs xp_tokens)]
                               [
                                (?. result.vocabulary (+ (?. token 1) 1)) ;lua arrays starting at 1 moment
                                (?. token 2)
                                (?. token 3)
                                ]

                              )
            ]
        (tset return xp processed_tokens)))
    ;; (logger.info :return)
    ;; (logger.info return)
    ;; (local r {:rank (?. (?. result.vocabulary 1) 3)
    ;;           :sid (?. (?. result.vocabulary 1) 2)
    ;;           :state (?. (?. result.vocabulary 1) 4)
    ;;           :vid (?. (?. result.vocabulary 1) 1)})
    ;; (logger.info r)
    (when (not (= (next return) nil))
      return)))

(fn JPDBClient.parse [self text]
  (let [output-sink {}
        json-payload (json.encode {: text
                                   :token_fields (json.array)
                                   :vocabulary_fields (setmetatable [:vid
                                                                     :sid
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
    ;; (logger.info json-payload)
    (local (code headers status) (socket.skip 1 (http.request request)))
    ;;     (logger.info (string.format "AnkiConnect#post_request: code: %s, header: %s, status: %s
    ;; " code headers status))
    (local result (json.decode (table.concat output-sink)))
    ;; (logger.info (. result.vocabulary 1))
    (local r {:rank (?. (?. result.vocabulary 1) 3)
              :sid (?. (?. result.vocabulary 1) 2)
              :state (?. (?. result.vocabulary 1) 4)
              :vid (?. (?. result.vocabulary 1) 1)})
    ;; (logger.info r)
    (when (not (= (next r) nil))
      r)))

(fn table-contains [table value]
  (each [_ v (ipairs table)]
    (when (= v value)
      true)
  )
  false
  )

;;TODO refactor? lol
;;maybe some trick if the redundant/locked are stuck in first position like I think it is
;;eg if len 2 2 else 1
(fn JPDBClient.parse-state [jpdb_state]
  (when (~= (type jpdb_state) "userdata") ;;This is like a null test
  ;; (if (= (length state) 2)
      ;; (. state 2)
      (. jpdb_state (length jpdb_state))
      ;; )

    )
  )

JPDBClient
