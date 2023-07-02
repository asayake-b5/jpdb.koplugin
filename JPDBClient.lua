local JPDBClient = {client = nil}
local http = require("socket.http")
local socket = require("socket")
local socketutil = require("socketutil")
local json = require("rapidjson")
local ltn12 = require("ltn12")
local logger = require("logger")
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
local function sortJPDBTable(xpointers)
  local keys, len = {}, 0
  for k, _ in pairs(xpointers) do
    len = (len + 1)
    do end (keys)[len] = k
  end
  return keys
end
JPDBClient.makeJPDBArray = function(xPointers)
  local array = {}
  for _, value in ipairs(sortJPDBTable(xPointers)) do
    table.insert(array, xPointers[value])
  end
  return array
end
JPDBClient.parseXPointers = function(self, xPointers)
  local xp_array = JPDBClient.makeJPDBArray(xPointers)
  local sorted = sortJPDBTable(xPointers)
  local output_sink = {}
  local json_payload = json.encode({text = setmetatable(xp_array, {__jsontype = "array"}), token_fields = setmetatable({"vocabulary_index", "position", "length"}, {__jsontype = "array"}), position_length_encoding = "utf16", vocabulary_fields = setmetatable({"vid", "sid", "spelling", "reading", "meanings", "frequency_rank", "card_state"}, {__jsontype = "array"})})
  local request = {headers = {Accept = "application/json", Authorization = ("Bearer " .. config.api_key), ["Content-Type"] = "application/json"}, method = "POST", sink = ltn12.sink.table(output_sink), source = ltn12.source.string(json_payload), url = "https://jpdb.io/api/v1/parse"}
  local code, headers, status = socket.skip(1, http.request(request))
  local result = json.decode(table.concat(output_sink))
  local _return = {}
  for i, xp in ipairs(sorted) do
    local vocab_list = result.vocabulary
    local xp_tokens
    do
      local t_1_ = result.tokens
      if (nil ~= t_1_) then
        t_1_ = (t_1_)[i]
      else
      end
      xp_tokens = t_1_
    end
    local processed_tokens
    do
      local tbl_17_auto = {}
      local i_18_auto = #tbl_17_auto
      for _, token in ipairs(xp_tokens) do
        local val_19_auto
        local _4_
        do
          local t_3_ = result.vocabulary
          if (nil ~= t_3_) then
            local function _6_()
              local t_5_ = token
              if (nil ~= t_5_) then
                t_5_ = (t_5_)[1]
              else
              end
              return t_5_
            end
            t_3_ = (t_3_)[(_6_() + 1)]
          else
          end
          _4_ = t_3_
        end
        local _10_
        do
          local t_9_ = token
          if (nil ~= t_9_) then
            t_9_ = (t_9_)[2]
          else
          end
          _10_ = t_9_
        end
        local function _13_()
          local t_12_ = token
          if (nil ~= t_12_) then
            t_12_ = (t_12_)[3]
          else
          end
          return t_12_
        end
        val_19_auto = {_4_, _10_, _13_()}
        if (nil ~= val_19_auto) then
          i_18_auto = (i_18_auto + 1)
          do end (tbl_17_auto)[i_18_auto] = val_19_auto
        else
        end
      end
      processed_tokens = tbl_17_auto
    end
    _return[xp] = processed_tokens
  end
  if not (next(_return) == nil) then
    return _return
  else
    return nil
  end
end
JPDBClient.parse = function(self, text)
  local output_sink = {}
  local json_payload = json.encode({text = text, token_fields = json.array(), vocabulary_fields = setmetatable({"vid", "sid", "frequency_rank", "card_state"}, {__jsontype = "array"})})
  local request = {headers = {Accept = "application/json", Authorization = ("Bearer " .. config.api_key), ["Content-Type"] = "application/json"}, method = "POST", sink = ltn12.sink.table(output_sink), source = ltn12.source.string(json_payload), url = "https://jpdb.io/api/v1/parse"}
  local code, headers, status = socket.skip(1, http.request(request))
  local result = json.decode(table.concat(output_sink))
  local r
  local _18_
  do
    local t_17_
    do
      local t_19_ = result.vocabulary
      if (nil ~= t_19_) then
        t_19_ = (t_19_)[1]
      else
      end
      t_17_ = t_19_
    end
    if (nil ~= t_17_) then
      t_17_ = (t_17_)[3]
    else
    end
    _18_ = t_17_
  end
  local _23_
  do
    local t_22_
    do
      local t_24_ = result.vocabulary
      if (nil ~= t_24_) then
        t_24_ = (t_24_)[1]
      else
      end
      t_22_ = t_24_
    end
    if (nil ~= t_22_) then
      t_22_ = (t_22_)[2]
    else
    end
    _23_ = t_22_
  end
  local _28_
  do
    local t_27_
    do
      local t_29_ = result.vocabulary
      if (nil ~= t_29_) then
        t_29_ = (t_29_)[1]
      else
      end
      t_27_ = t_29_
    end
    if (nil ~= t_27_) then
      t_27_ = (t_27_)[4]
    else
    end
    _28_ = t_27_
  end
  local _33_
  do
    local t_32_
    do
      local t_34_ = result.vocabulary
      if (nil ~= t_34_) then
        t_34_ = (t_34_)[1]
      else
      end
      t_32_ = t_34_
    end
    if (nil ~= t_32_) then
      t_32_ = (t_32_)[1]
    else
    end
    _33_ = t_32_
  end
  r = {rank = _18_, sid = _23_, state = _28_, vid = _33_}
  if not (next(r) == nil) then
    return r
  else
    return nil
  end
end
local function table_contains(table, value)
  for _, v in ipairs(table) do
    if (v == value) then
    else
    end
  end
  return false
end
JPDBClient["parse-state"] = function(jpdb_state)
  if (type(jpdb_state) ~= "userdata") then
    return jpdb_state[#jpdb_state]
  else
    return nil
  end
end
return JPDBClient
