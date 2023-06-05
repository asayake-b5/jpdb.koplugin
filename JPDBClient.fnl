(local JPDBClient {:client nil})

(local http (require :socket.http))
(local socket (require :socket))
(local socketutil (require :socketutil))
(local logger (require :logger))
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
(fn make_request [api_key ])
(fn make_payload [ ])

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
    (logger.info json-payload)
    (local (code headers status) (socket.skip 1 (http.request request)))
    (logger.info (string.format "AnkiConnect#post_request: code: %s, header: %s, status: %s
" code headers status))
    (local result (json.decode (table.concat output-sink)))
    (logger.info (. result.vocabulary 1))
    (local r {:rank (?. (?. result.vocabulary 1) 3)
              :sid (?. (?. result.vocabulary 1) 2)
              :state (?. (?. result.vocabulary 1) 4)
              :vid (?. (?. result.vocabulary 1) 1)})
    (logger.info r)
    (when (not (= (next r) nil))
r
      )
    ))

JPDBClient
