
local _M = {}

_M.VERSION = "1.1.1"
_M.DEFAULT_PASSWORD = "horus123"
_M.STORAGE_ACCOUNT_KEY = "account"

_M.ACTUADORES_ON= ... or {}
_M.ACTUADORES_OFF= ... or {}
_M.MASTERSWITCH_ON= ... or {}
_M.SENSOR_MOV_BATT = ... or {}
_M.SENSOR_MOV_ELEC = ... or {}
_M.SENSOR_PUERTA = ... or {}
_M.TERMOSTATO = ... or {}
_M.SETPOINTON = 24 or {}          -- normalmente: 24
_M.SETPOINTOFF = 0 or {}          -- normalmente: 25°
_M.OFFPUERTAABIERTA = ... or "no"
_M.MODOSETPOINT = ... or "no"
_M.MODODISPLUCES =  ... or "no"
_M.MODOMASTERSWITCH = ... or "no"
_M.MOTIONACTIVATOR = ... or "no"
_M.TIEMPOSCAN = ... or 900
_M.CREDENTIALS = "true"

return _M