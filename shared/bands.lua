RadioBands = {}

local MAX_PRESET <const> = 3
local KEY_FORMAT <const> = '%.3f/%d'

local reserved <const> = {}
local byFrequency <const> = {}
local presets <const> = {}

--- Snaps a frequency to the configured step, or refuses it.
---@param value any The raw frequency in MHz.
---@return number? frequency The frequency on the grid, or nil when unusable.
function RadioBands.normalize(value)
  if type(value) ~= 'number' or value ~= value then
    return nil
  end

  local range <const> = FrequencyConfig.range
  local step <const> = FrequencyConfig.step
  local snapped <const> = math.floor(value / step + 0.5) * step
  local frequency <const> = math.floor(snapped * 1000 + 0.5) / 1000

  if frequency < range.min or frequency > range.max then
    return nil
  end

  return frequency
end

--- Checks that a reserved band definition is usable.
---@param definition any The raw definition.
---@return string? fault What is wrong with it, or nil when it is valid.
local function validate(definition)
  if type(definition) ~= 'table' then
    return 'must be a table'
  end

  if not RadioBands.normalize(definition.frequency) then
    return 'frequency must sit inside the configured range'
  end

  if type(definition.label) ~= 'string' or definition.label == '' then
    return 'label must be a non-empty string'
  end

  if type(definition.job) ~= 'string' or definition.job == '' then
    return 'job must be a non-empty string'
  end

  if definition.preset ~= nil
    and (math.type(definition.preset) ~= 'integer' or definition.preset < 1 or definition.preset > MAX_PRESET) then
    return ('preset must be an integer between 1 and %d'):format(MAX_PRESET)
  end

  if definition.preset and presets[definition.preset] then
    return ('preset %d is already used'):format(definition.preset)
  end

  if definition.channels ~= nil and type(definition.channels) ~= 'table' then
    return 'channels must be a list of names'
  end

  return nil
end

for index, definition in ipairs(FrequencyConfig.reserved) do
  local fault <const> = validate(definition)

  if fault then
    Siku.print.error(T('band_invalid', index, fault))
  else
    local band <const> = {
      frequency = RadioBands.normalize(definition.frequency),
      label = definition.label,
      job = definition.job,
      preset = definition.preset,
      channels = {},
    }

    for i = 1, #(definition.channels or {}) do
      band.channels[i] = tostring(definition.channels[i])
    end

    if #band.channels == 0 then
      band.channels[1] = band.label
    end

    if byFrequency[band.frequency] then
      Siku.print.error(T('band_duplicate', band.frequency))
    else
      reserved[#reserved + 1] = band
      byFrequency[band.frequency] = band

      if band.preset then
        presets[band.preset] = band
      end
    end
  end
end

--- The reserved band on a frequency.
---@param frequency number The frequency on the grid.
---@return table? band { frequency, label, job, preset, channels }, or nil when open.
function RadioBands.reserved(frequency)
  return byFrequency[frequency]
end

--- How many channels a frequency carries.
---@param frequency number The frequency on the grid.
---@return number count At least one.
function RadioBands.channelCount(frequency)
  local band <const> = byFrequency[frequency]

  if band then
    return #band.channels
  end

  local open <const> = FrequencyConfig.open

  if open.mode == 'channels' and math.type(open.count) == 'integer' and open.count > 1 then
    return open.count
  end

  return 1
end

--- Whether a channel number exists on a frequency.
---@param frequency number The frequency on the grid.
---@param channel any The channel number.
---@return boolean valid Whether the channel exists.
function RadioBands.hasChannel(frequency, channel)
  return math.type(channel) == 'integer' and channel >= 1 and channel <= RadioBands.channelCount(frequency)
end

--- The name of a channel on a frequency.
---@param frequency number The frequency on the grid.
---@param channel number The channel number.
---@return string? label The channel name, or nil when the frequency has a single channel.
function RadioBands.channelLabel(frequency, channel)
  local band <const> = byFrequency[frequency]

  if band then
    return band.channels[channel]
  end

  if RadioBands.channelCount(frequency) > 1 then
    return ('CH %d'):format(channel)
  end

  return nil
end

--- The key naming the room everyone on a frequency and channel shares.
---@param frequency number The frequency on the grid.
---@param channel number The channel number.
---@return string key The room key.
function RadioBands.roomKey(frequency, channel)
  return KEY_FORMAT:format(frequency, channel)
end

--- The band behind a preset key.
---@param index number The preset, 1 to 3.
---@return table? band The reserved band, or nil when the key is free.
function RadioBands.preset(index)
  return presets[index]
end

--- Every reserved band, in configuration order.
---@return table bands The list of bands.
function RadioBands.list()
  return reserved
end

--- What the interface needs to know about the frequencies.
---@return table frequencies { range, step, open, reserved }.
function RadioBands.describe()
  local bands <const> = {}

  for i = 1, #reserved do
    local band <const> = reserved[i]

    bands[i] = {
      frequency = band.frequency,
      label = band.label,
      job = band.job,
      preset = band.preset,
      channels = band.channels,
    }
  end

  return {
    range = { min = FrequencyConfig.range.min, max = FrequencyConfig.range.max },
    step = FrequencyConfig.step,
    open = { mode = FrequencyConfig.open.mode, count = RadioBands.channelCount(0) },
    reserved = bands,
  }
end
