local JPDBClient = {client = nil}
local http = require("socket.http")
local socket = require("socket")
local socketutil = require("socketutil")
local logger = require("logger")
local json = require("rapidjson")
local ltn12 = require("ltn12")
local logger0 = require("logger")
local config = require("config")
JPDBClient.init = function(self, path)
  require("socket.http")["TIMEOUT"] = 1
  local Spore = require("Spore")
  self.client = Spore.new_from_spec((path .. "/jpdb_api.json"), {})
  local config0 = require("config")
  do end (self.client):enable("Auth.Bearer", {bearer_token = config0.api_key})
  return (self.client):enable("Format.JSON")
end
JPDBClient.ping = function(self)
  local res = (self.client):ping({})
  print(res.status)
  return res.status
end
local function make_request(api_key)
end
local function make_payload()
end
JPDBClient.parse = function(self, text)
  local output_sink = {}
  local json_payload = json.encode({text = text, token_fields = json.array(), vocabulary_fields = setmetatable({"vid", "sid", "frequency_rank", "card_state"}, {__jsontype = "array"})})
  local request = {headers = {Accept = "application/json", Authorization = ("Bearer " .. config.api_key), ["Content-Type"] = "application/json"}, method = "POST", sink = ltn12.sink.table(output_sink), source = ltn12.source.string(json_payload), url = "https://jpdb.io/api/v1/parse"}
  logger0.info(json_payload)
  local code, headers, status = socket.skip(1, http.request(request))
  logger0.info(string.format("AnkiConnect#post_request: code: %s, header: %s, status: %s\n", code, headers, status))
  local result = json.decode(table.concat(output_sink))
  logger0.info(result.vocabulary[1])
  local r
  local _2_
  do
    local t_1_
    do
      local t_3_ = result.vocabulary
      if (nil ~= t_3_) then
        t_3_ = (t_3_)[1]
      else
      end
      t_1_ = t_3_
    end
    if (nil ~= t_1_) then
      t_1_ = (t_1_)[3]
    else
    end
    _2_ = t_1_
  end
  local _7_
  do
    local t_6_
    do
      local t_8_ = result.vocabulary
      if (nil ~= t_8_) then
        t_8_ = (t_8_)[1]
      else
      end
      t_6_ = t_8_
    end
    if (nil ~= t_6_) then
      t_6_ = (t_6_)[2]
    else
    end
    _7_ = t_6_
  end
  local _12_
  do
    local t_11_
    do
      local t_13_ = result.vocabulary
      if (nil ~= t_13_) then
        t_13_ = (t_13_)[1]
      else
      end
      t_11_ = t_13_
    end
    if (nil ~= t_11_) then
      t_11_ = (t_11_)[4]
    else
    end
    _12_ = t_11_
  end
  local _17_
  do
    local t_16_
    do
      local t_18_ = result.vocabulary
      if (nil ~= t_18_) then
        t_18_ = (t_18_)[1]
      else
      end
      t_16_ = t_18_
    end
    if (nil ~= t_16_) then
      t_16_ = (t_16_)[1]
    else
    end
    _17_ = t_16_
  end
  r = {rank = _2_, sid = _7_, state = _12_, vid = _17_}
  logger0.info(r)
  if not (next(r) == nil) then
    return r
  else
    return nil
  end
end
return JPDBClient
