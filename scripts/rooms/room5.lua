---@diagnostic disable: param-type-mismatch
--    module require
local params = ... or {}
local _core = require("core")
local _logger = require("logging")
local _timer = require("timer")
local _json = require("json")
local _storage = require("storage")

---- Función para registrar mensajes
local function Registro(Mensaje, color)
    local prefix = "[Horus Smart] - " --"[Horus Desarrollo] Energy"
    if color then
        _logger.info(prefix .. "\27[" .. color .. "m" .. Mensaje .. "\27[0m")
    else
        _logger.info(prefix .. Mensaje)
    end
end

--    variable locales
local rojo = 31
local verde = 32
local amarillo = 33

local ACCION_SCAN = 10
local ACCION_LIBRE = 0
local ACCION_AUTOOFF = 20
local ACCION_OCUPADO = 100
local ACCION_PABIERTA = 40
local ACCION_CICLO_APAGADO = 60

local MODO_APAGADO = "Apagado"
local MODO_AUTO = "Auto"

local thermostat = _storage.get_table("TERMOSTATO_M5")
local SetPointOn = _storage.get_number("SETPOINTON_M5")
local SensorMovbatt = _storage.get_table("SENSOR_MOV_BATT_M5")
local SensorMovElec = _storage.get_table("SENSOR_MOV_ELEC_M5")
local devicesOn = _storage.get_table("ACTUADORES_ON_M5") or {}
local devicesOff = _storage.get_table("ACTUADORES_OFF_M5") or {}
local masterSwitch = _storage.get_table("MASTERSWITCH_ON_M5") or {}
local ModoDispLuces = _storage.get_string("MODODISPLUCES_M5") or false
local ModoThermoInit = _storage.get_string("MOTIONACTIVATOR_M5") or false
local ModoMasterSwitch = _storage.get_string("MODOMASTERSWITCH_M5") or false

-- No usados en plugins de Aula no lleva puerta ni SetPointOFF
-- local ModoSetpoint = _storage.get_string("MODOSETPOINT_M5") or false
-- local SetPointOff = _storage.get_number("SETPOINTOFF_M5")
-- local sensor_puerta = _storage.get_string("SENSOR_PUERTA_M5")
-- local ModoOffPuertaAbierta = _storage.get_string("OFFPUERTAABIERTA_M5") or false

local ModoPluginStatus = _storage.get_string("ModoId5")
local AccionPluginStatus = _storage.get_string("AccionTextoId5")
local EstadoPluginStatus = _storage.get_string("EstadoTextoId5")
local modeButton = (_core.get_item(ModoPluginStatus))

local data = {}
    data.modo = _storage.get_string("Modo5")
    data.type = _storage.get_string("type5")
    data.accion = _storage.get_number("accion5")
    data.TimerID = _storage.get_string("TimerID5")
    data.counting = _storage.get_string("Counting5")
    data.scancycle = _storage.get_string("scanCycle5")
    data.remaining = _storage.get_string("remaining5")
    data.statustext = _storage.get_string("statusText5")
    data.acciontext = _storage.get_string("accionTexto5")
    data.timeraccion = _storage.get_string("timerAccion5")
    data.TimerIdTick = _storage.get_string("TimerIdTick5")
    data.dueTimestamp = _storage.get_number("dueTimestamp5")
    data.timerduration = _storage.get_number("TimerDuration5")
    data.Remaining_ant = _storage.get_number("Remaining_ant5")
    data.previousTimer = _storage.get_number("previousTimer5")
    data.settingAccionId = _storage.get_string("settinAccion5")

--    Tiempos del Plugin Ocupación
local Tiempo_ocupacion = 600    -- (600 * 2) Tiempo total 1200 = 20 minutos
local Tiempo_apagado = 30       -- 10 seg PRODUCCIÓN // se cambia a 30 por error de apagado
local TiempoLibre = 10          -- 10 seg PRODUCCIÓN

local TiempoScaner = math.floor((_storage.get_number("TIEMPOSCAN_M5"))/2) -- tiempo a la mitad ejecurar los tiempo del programa
local TiempoSenMov =  math.abs(Tiempo_ocupacion-TiempoScaner)             -- Tiempo Real de escaner a libre
local TiempoScanLibre = Tiempo_apagado + TiempoLibre                      -- Tiempo Tomado como Scaner Libre

local Tiempo1 = TiempoScaner - TiempoScanLibre                            -- Tiempo siguiente al sensor movimiento
local Tiempo2 = Tiempo_ocupacion - (Tiempo_apagado + TiempoLibre)              -- Ciclo Scan 2 (-Tiempo1)

local umbralTime1 = 0                   -- Luego usado para ecuaciones

Registro("----------------------------------")
Registro("Manejo de Tiempos Reales/2 Aul5: ",verde)
Registro("Tiempo aul Tt: ".. ((TiempoSenMov + TiempoScaner)).."   |-| Tiempo Sensor Movimiento " .. (TiempoSenMov))
Registro("Tiempo Scaner: ".. (Tiempo1).." |-| Tiempo Scaner Libre: ".. (Tiempo2))
if ModoMasterSwitch and ModoDispLuces ~= nil then
Registro("Modo Thermostat: " ..ModoThermoInit.." |-| Modo Disp Luces: " .. ModoDispLuces .. "  |-| Modo Master Swiches: ".. ModoMasterSwitch)
end
Registro("----------------------------------")

local function setItemValue(itemId, value)
    local success, result = xpcall(
        function()
            return _core.set_item_value(itemId, value)
        end,
        function(err)
            Registro("Error al establecer el valor del ítem " .. itemId .. ": " .. (err or "Error desconocido"), rojo)
            return err -- Importante: devolver el error para xpcall
        end
    )
    if not success then
        Registro("Error en el manejador de errores para " .. itemId .. ": " .. (result or "Error desconocido"), rojo)
    else
        Registro("Estado del sistema: " .. _json.encode(value)) -- "device: " .. itemId .. 
    end
end

---- estasdos del plugin (libre, Ocupado)
function Libre()
    Rutina_Apagado()
    CancelTimer()
    Registro("funcion Libre", verde)
    ActualizarAccion(ACCION_LIBRE)
    Validar("timerAccion5", "Libre")
    StartTimer(TiempoLibre)
end
function Occupied()
    Registro("funcion ocupado", verde)
    CancelTimer()
    ActualizarAccion(ACCION_OCUPADO)
    Validar("timerAccion5", "Ocupado")
    Validar("scanCycle5", "Ocupado")
    Rutina_Encendido()
end

-- Funciones Actuadores Dispositivos
function ShutdownActuator(item_id)
    Registro(" evento apagado de actuadores", verde)
    local actuadores_on
    for i in ipairs(item_id) do
        actuadores_on = _core.get_item(item_id[i])
        -- _logger.info("id_actuadores: " .. actuadores_on.name)
        -- _logger.info("id_actuadores: " .. actuadores_on.id)
        Registro("id_actuadores: "..actuadores_on.name.." - Id: "..actuadores_on.id)
        _core.set_item_value(item_id[i], false)
    end
end
function PowerOnActuator(item_id)
    Registro("evento Encendido de actuadores", verde)
    local actuadores_on
    for i in ipairs(item_id) do
        actuadores_on = _core.get_item(item_id[i])
        -- _logger.info("id_actuadores: " .. actuadores_on.name)
        -- _logger.info("id_actuadores: " .. actuadores_on.id)
        Registro("id_actuadores: "..actuadores_on.name.." - Id: "..actuadores_on.id)
        _core.set_item_value(item_id[i], true)
    end
end

function ThermostatPower(item_id, value)
    
    _core.set_item_value(item_id, value)
    _timer.set_timeout(2000, "HUB:aul.aula_inteligente/scripts/rooms/thermostat",
    { itemId = item_id, itemValue = value })
end
function SetPointTermostato(item_id, value)
    Registro("Thermostat: " .. thermostat.mode.name .. ": " .. thermostat.setpoint._id, rojo)
    _timer.set_timeout(2000, "HUB:aul.aula_inteligente/scripts/rooms/thermostat",
    { itemId = item_id, itemValue = value })
end
function SetFanTermostato(item_id, value)
    Registro("Thermostat: " .. thermostat.mode.name .. ": " .. thermostat.setpoint._id, amarillo)
    _timer.set_timeout(2000, "HUB:aul.aula_inteligente/scripts/rooms/thermostat",
    { itemId = item_id, itemValue = value })
end

---- funcion de Rutinas de acciones de encendido y apagado Luces - Thermo y Enc Total/Apag Total
function RoutineOnLuces(item_id)
    local id = {}
    local mode = _storage.get_string("Modo5")
        if mode == MODO_AUTO then
            if ModoDispLuces == "si" or ModoMasterSwitch == "si" then 
                for i in ipairs(item_id) do
                    id = _core.get_item(item_id[i])
                end
                _logger.info("valor de los dispositivos: " .. tostring(id.value))
                if id.value ~= true then
                    PowerOnActuator(item_id)
                end
                return
            end
        end
        if mode ~= MODO_AUTO then
            for i in ipairs(item_id) do
                id = _core.get_item(item_id[i])
            end
            _logger.info("valor de los dispositivos: " .. tostring(id.value))
            Registro("no se enciende ningun dispositivo", amarillo)
            return
        end
    return false
end
function RoutineOffLuces(item_id)
    local id = {}
    local mode = _storage.get_string("Modo5")
    if mode ~= MODO_APAGADO then
        for i in ipairs(item_id) do
            id = _core.get_item(item_id[i])
        end
        _logger.info("valor de los dispositivos: " .. tostring(id.value))
        if id.value == true then
            ShutdownActuator(item_id)
        else
            ShutdownActuator(item_id)
        end
        return
    end
end

function Rutina_On_Thermo()
    local mode = _storage.get_string("Modo5")
    if data.modo == "Auto" then
        if thermostat ~= nil and ModoThermoInit == "si" then
            Registro("Thermo On: ",rojo)
                if thermostat.mode.value ~= "cool" then
                    ThermostatPower(thermostat.mode._id, "cool")
                end
                if thermostat.setpoint.value ~= SetPointOn then
                    SetPointTermostato(thermostat.setpoint._id, SetPointOn)
                end
        else
            Registro("no tiene termostato o no está activo modo thermo inicial", amarillo)
        end
    end
    return mode
end
function Rutina_Off_Thermo()
    local mode = _storage.get_string("Modo5")
    if data.modo ~= "Apagado" then
        if thermostat ~= nil then
            ThermostatPower(thermostat.mode._id, "off")
            Registro("Thermo: Off")
        else
            Registro("no tiene termostato", amarillo)
        end
    end
    return mode
end

function Rutina_Encendido()
    -- Registro("Rurina Encendido Ttal ON")
    if data.modo ~= "Apagado" then
        RoutineOnLuces(masterSwitch)
        RoutineOnLuces(devicesOn)
        Rutina_On_Thermo()
    end
end
function Rutina_Apagado()
    -- Registro("Rurina Apagado Ttal Off")
    if data.modo ~= "Apagado" then
        RoutineOffLuces(masterSwitch)
        RoutineOffLuces(devicesOff)
        RoutineOffLuces(devicesOn)
        Rutina_Off_Thermo()
    end
end

--- verification and validation functions of the variables
function Validar(variable, newvalue)
    local value
    if newvalue ~= nil or newvalue ~= value then
        if (type(newvalue) == "number") then
            value = _storage.get_number(variable)
            _storage.set_number(variable, newvalue)
        end
        if (type(newvalue) == "string") then
            value = _storage.get_string(variable)
            _storage.set_string(variable, newvalue)
        end
        return true
    else
        value = _storage.get_string(variable)
        Registro("no se encontro cambio en la variable: " .. variable, amarillo)
        return false
    end
end

function VariablesDeInicio(variable, defaultValue)
    local value
    if (type(defaultValue) == "number") then
        value = _storage.get_number(variable)
        if value == nil then
            _storage.set_number(variable, defaultValue)
            value = _storage.get_number(variable)
            return value
        else
            return value
        end
    end
    if (type(defaultValue) == "string") then
        value = _storage.get_string(variable)
        if value == nil then
            Registro("secarga valor por defaul", amarillo)
            _storage.set_string(variable, defaultValue)
            value = _storage.get_string(variable)
            return value
        else
            return value
        end
    end
end

---- Actualiza el estado y los textos asociados según el valor proporcionado.
function ActualizarAccion(s)
    Registro("ActualizarAccion", verde)

    local AccionTextoId = _storage.get_string("AccionTextoId5")
    local EstadoTextoId = _storage.get_string("EstadoTextoId5")
    local curValue = _storage.get_number("accion5")

    if tonumber(s) ~= tonumber(curValue) then
        Registro("curValue: " .. curValue .. ", s: " .. s, amarillo)
        -- Actualiza la acción según el valor proporcionado
        Validar("accion5", s)
        
        -- Mapeo de valores de acción a textos asociados.
        local textMapping = {
            [ACCION_LIBRE] = "Libre",
            [ACCION_PABIERTA] = "Puerta Abierta", -- Borrar
            [ACCION_SCAN] = "Scan",
            [ACCION_OCUPADO] = "Ocupado"
        }

        -- Obtiene el texto asociado al valor de acción actual.
        local accionText = textMapping[s]

        -- Si hay un texto asociado, actualiza el texto correspondiente.
        if accionText then
            Validar("accionTexto5", accionText)
            setItemValue(AccionTextoId, accionText)
        end
    end

    -- Verifica el valor de acción para actualizar el estado general
    if tonumber(s) ~= -2 then
        local statusText = tonumber(s) == 0 and "Libre" or "Ocupado"

        Validar("statusText5", statusText)
        setItemValue(EstadoTextoId, statusText)
    end

    return true
end

function EventMovimiento(Sensor)
    Registro("Evento de movimiento", amarillo)
    local motion = _storage.get_string("motion5")
    if Sensor ~= nil then
        Registro("sensor: " .. _json.encode(Sensor), amarillo)
        for i in ipairs(Sensor) do -- Rutina FOR : conocer estado de SM
            local sensor_id = _core.get_item(Sensor[i])
            if sensor_id.value == true then
                local tiempoRestante5 = Tiempo1 - math.abs(data.previousTimer or 0)
                -- Registro("time Restante: " .. tiempoRestante5)
                if motion ~= nil then -- Conocer estado de SM
                    local securityThreat = _storage.get_string("securityThreat5")
                    setItemValue(motion, true)
                    setItemValue(securityThreat, true)
                end

                if _storage.get_number("accion5") == ACCION_SCAN then
                    Registro("Evento Scan >>> Ocupado por movimiento",rojo)
                    CancelTimer()
                    ActualizarAccion(ACCION_OCUPADO)
                    Validar("timerAccion5", "Ocupado")
                    Validar("scanCycle5", "Ocupado")
                    return
                end

                if _storage.get_number("accion5") == ACCION_LIBRE then
                    CancelTimer()
                    Rutina_On_Thermo()
                    ActualizarAccion(ACCION_OCUPADO)
                    Validar("timerAccion5", "Ocupado")
                    Validar("scanCycle5", "Ocupado")
                end

                if _storage.get_number("accion5") == ACCION_CICLO_APAGADO then
                    CancelTimer()
                    ActualizarAccion(ACCION_OCUPADO)
                    Validar("timerAccion5","Ocupado")
                    Validar("scanCycle5", "Ocupado")
                    if _storage.get_string("Mode5") ~= MODO_APAGADO then
                            Registro("on actuadores", amarillo)
                            RoutineOnLuces(masterSwitch)
                            RoutineOnLuces(devicesOn)
                            Rutina_On_Thermo()
                    end
                    return
                end
                if ValidateRemainingTime(20) then
                    Registro("ValidateRemainingTime(20)", amarillo)
                    if _storage.get_number("accion5") == ACCION_AUTOOFF then
                        CancelTimer()
                        ActualizarAccion(ACCION_SCAN)
                        Validar("timerAccion5", "Scan")
                        StartTimer(Tiempo1)
                        return
                    end
                end

            end
            if sensor_id.value == false then
                if motion ~= nil then
                    local securityThreat = _storage.get_string("securityThreat5")
                    setItemValue(motion, false)
                    setItemValue(securityThreat, false)
                end

                if _storage.get_number("accion5") == ACCION_OCUPADO then
                    CancelTimer()
                    ActualizarAccion(ACCION_SCAN)
                    Validar("timerAccion5", "Scan")
                    Validar("scanCycle5", "scan_One")
                    StartTimer(Tiempo1)
                    return
                end
            end
        end
    end
end

function EventoMovDeLibre()
    CancelTimer()
    ActualizarAccion(ACCION_CICLO_APAGADO)
    Validar("timerAccion5", "CicloApagado")
    Validar("scanCycle5", "CicloApagado")
    Registro("Tiempo_apagado: " .. Tiempo_apagado, amarillo)
    StartTimer(Tiempo_apagado)
    CicloApagado()
end

-- evento dado por accionamiento de movimiento y swiches
function EventoActuadores(Actuador)
    Registro("_______ evento de Actuadores_______", amarillo)
    if not Actuador then return end

    local tiempoRestante5 = Tiempo1 - math.abs(data.previousTimer or 0)
    -- Registro("time Restante: " .. tiempoRestante5)

    Registro("Divice : " .. _json.encode(Actuador), rojo)

    for _, id in ipairs(Actuador) do
        local actuador_id = _core.get_item(id)
        Registro("value Actuador: " .. _json.encode(actuador_id.value) .. ", " .. _json.encode(data.modo))

        if actuador_id.value == true then
            if _storage.get_number("accion5") == ACCION_SCAN then
                Registro("disparo de Actuador", amarillo)
                return
            end

            if _storage.get_number("accion5") == ACCION_LIBRE then
                Registro("Scan por disparo de Actuador", amarillo)
                CancelTimer()
                ActualizarAccion(ACCION_SCAN)
                Validar("timerAccion5", "Scan")
                Validar("scanCycle5", "scan_Two")
                StartTimer(Tiempo2)
                return
            end 

            if _storage.get_number("accion5") == ACCION_AUTOOFF then
                Registro("Activado en Auto Off", amarillo)
                return
            end

            if _storage.get_number("accion5") == ACCION_CICLO_APAGADO then
                Registro("Activado en Ciclo Apagado", amarillo)
                return
            end
        end
    end
    return true
end

function CicloApagado()
    Registro("#5",rojo)
        if (_storage.get_number("accion5") == ACCION_SCAN) and (_storage.get_string("Modo5") ~= MODO_APAGADO) then
                    RoutineOffLuces(devicesOn)
                    RoutineOffLuces(devicesOff)
        end
        CancelTimer()
        ActualizarAccion(ACCION_CICLO_APAGADO)
        Validar("timerAccion5", "CicloApagado")
        Validar("scanCycle5", "CicloApagado")
        Registro("#5",rojo)
        Registro("Tiempo_apagado: " .. Tiempo_apagado, amarillo)
        StartTimer(Tiempo_apagado)
end

---- funciones de tipo timer
function TimerHoy()
    local DateNow = os.date("%H:%M:%S", os.time())
    local currentTime = os.time() -- Obtén el timestamp actual
    local currentHour = tonumber(os.date("%H", currentTime)) -- Extrae la hora (0-23)

    Registro("Hora Actual: " .. DateNow)
    if currentHour >= 6 and currentHour < 18 then
        EstadoDia = "Dia"
    else
        EstadoDia = "Noche"
    end
    -- Registro(EstadoDia)
end

function StartTimer(timerduration)
    local counting = VariablesDeInicio("Counting5", "0")
    if counting == '1' then -- se dejan las comillas para no reemplazar este valor en las demas paginas del code Python
        return false
    end
    Validar("TimerDuration5", timerduration)
    return StartTimeralways()
end

function StartTimeralways()
    local duration = VariablesDeInicio("TimerDuration5", 30)
    local dueTimestamp1 = os.time() + duration
    Validar("dueTimestamp5", dueTimestamp1)
    local status = RemainingUpgrade()
    Validar("Counting5", '1') -- se dejan las comillas para no reemplazar este valor en las demas paginas del code Python
    if data.TimerID ~= "" and status then
        local timerID = data.TimerID
        _storage.set_string("TimerID5", tostring(timerID))
        _timer.set_timeout_with_id(10000, tostring(timerID),
            "HUB:aul.aula_inteligente/scripts/rooms/room5",
            { arg_name = "timer" })
        return true
    else
        Registro("timer sin id")
        local timerID = _timer.set_timeout(10000, "HUB:aul.aula_inteligente/scripts/rooms/room5",
            { arg_name = "timer" })
        _storage.set_string("TimerID5", tostring(timerID))
        return true
    end
    Registro("----------------------------------",amarillo)
end

function TiempoTranscurrido()
    local Timerload = _storage.get_string("remaining5") or 0

    if Timerload == "0" or Timerload == 0 then
        return 0
    elseif string.len(Timerload) < 12 then
        local minutos = tonumber(string.sub(Timerload, 6, 7))
        local segundo = tonumber(string.sub(Timerload, 9, 10))
        minutos = minutos * 60
        segundo = minutos + segundo
        return segundo
    else
        local horas = tonumber(string.sub(Timerload, 2, 3))
        local minutos = tonumber(string.sub(Timerload, 5, 6))
        local segundos = tonumber(string.sub(Timerload, 8, 9))
        horas = horas * 3600
        minutos = minutos * 60
        segundos = horas + minutos + segundos
        return segundos
    end
end

function CancelTimer()
    local counting = VariablesDeInicio("Counting5", "0")
    if counting == "0" then
        return false
    end
    if data.TimerID ~= "" then
        local timerID = data.TimerID
        _storage.set_string("TimerID5", tostring(timerID))
        if timerID then
            if _timer.exists(tostring(timerID)) then
                _timer.cancel(tostring(timerID))
            end
        else
            Registro("timerID does  not exist", amarillo)
        end
    end
    Remaining_ant = 0
    Validar("Counting5", "0")
    Validar("dueTimestamp5", 0)
    Validar("remaining5", "0")
    Validar("TimerDuration5", 0)
    return true
end

function TimerRemaining(timer)
    local _horas = ""
    local _minutos = ""
    local horas = math.floor(timer / 3600)
    timer = timer - (horas * 3600)
    local minutos = math.floor(timer / 60)
    timer = timer - (minutos * 60)
    local segundos = timer or "0"
    if horas < 10 then
        _horas = "0" .. horas
    end
    if minutos < 10 then
        _minutos = "0" .. minutos
    else
        _minutos = tostring(minutos)
    end
    if segundos < 10 then
        segundos = "0" .. segundos
    else
        segundos = tostring(segundos)
    end
    return (_horas .. ":" .. _minutos .. ":" .. segundos)
end

function RemainingUpgrade()
    local dueTimestamp1 = VariablesDeInicio("dueTimestamp5", 0)
    local remaining = tonumber(dueTimestamp1) - os.time()
    if remaining < 0 then
        remaining = 0
    end
    local restante = TimerRemaining(remaining)
    Remaining_ant = remaining
    Validar("remaining5", "TR" .. restante)
    return remaining > 0
end

function ValidateRemainingTime(time)
    local timercompare = _storage.get_number("TimerDuration5") or 0
    local TimerRemaining = TiempoTranscurrido()
    if tonumber(timercompare) - TimerRemaining >= tonumber(time) then
        return true
    else
        return false
    end
end
---- Main and Tick5 :: Funiciones principales
function Main()
    local TimerRemainingV = TiempoTranscurrido()
    local EstadoAccion = _json.encode(data.scancycle)

    local TiempPrevio = _json.encode(data.previousTimer)
    local TiempoRemanente = _json.encode(TimerRemainingV)
    
    Registro("::: Manejos Internos ::: Aul5",verde)
    -- Registro("timerId: " .. _json.encode(data.TimerID),verde)
    TimerHoy()
    Registro("Tiempo Scaner= ".. Tiempo1)
    Registro("Tiempo TiempoScanH= ".. Tiempo2)
    Registro("Modo plugin: " .. _json.encode(data.modo).." |-| plugin status and TimerAccion5: " .. data.acciontext,amarillo)
    Registro("ScanCycle1: " .. _json.encode(data.scancycle),verde)
    Registro("TiempoAnterior_5: " .. _json.encode(data.previousTimer),amarillo)
    Registro("TiempoPosterior_5: " .. _json.encode(TimerRemainingV),amarillo)
    Registro("Tiempo Umbral: " .. math.abs(TiempPrevio - TiempoRemanente),rojo)
    Registro("Tiempo faltante= ".. TimerRemainingV)
    Registro("----------------------------------")

    -- No mover: calculo de tiempos e intervalos
    if TimerRemainingV - data.previousTimer >= 10 then
        Registro("TimerRemainingV: " .. TimerRemainingV, amarillo)
        Registro("plugin status: " .. "acciontext: " .. data.acciontext .. ", statustext: " .. data.statustext,amarillo)
        Registro("timerduration: " .. data.timerduration .. ", timeraccion: " .. data.timeraccion, amarillo)
    end

    Validar("previousTimer5", tonumber(TimerRemainingV))

    if data.accion == 100 or data.accion == 0 then
        Validar("TimerDuration5", 0)
    else
        if TimerRemainingV > 0 then
            CancelTimer()
            StartTimer(TimerRemainingV)
        end
    end

    -- Estados de los tiempos
    if     EstadoAccion == '"scan_One"' then
        umbralTime1 = Tiempo1 - TimerRemainingV
        Registro("Tiempo Scaneado Uno: " .. (umbralTime1),amarillo)
    elseif EstadoAccion == '"scan_Two"' then
        umbralTime1 = Tiempo_ocupacion - TimerRemainingV
        Registro("Tiempo Scaneado Dos: " .. (umbralTime1),verde)
    end
    Registro("----------------------------------")
end

function Tick5()
    
    local counting = VariablesDeInicio("Counting5", "0")
    local timerAccion = VariablesDeInicio("timerAccion5", "0")

    if counting == "0" then
        Registro("contador es false")
        return false
    end
    local status = RemainingUpgrade()
    if (status == true) then
        if params.timerId ~= nil then
            local timerID = tostring(params.timerId)
            _timer.set_timeout_with_id(10000, tostring(params.timerId),
            "HUB:aul.aula_inteligente/scripts/rooms/room5",
            { arg_name = "main" })
            if (timerID ~= "") then
                -- _logger.info("TimerID: " .. timerID)
                _storage.set_string("TimerID5", tostring(timerID))
                return true
            end
            return
        end
    end
    -- tiempo finalizado
    Registro("Tiempo Accion: " .. _json.encode(timerAccion))
    Remaining_ant = 0
    Validar("Counting5", "0")
    Validar("dueTimestamp5", "0")
    Validar("remaining5", "0")

    if timerAccion == "Scan" then
        Registro("#5",rojo)
        CicloApagado()
    elseif timerAccion == "CicloApagado" then
        Libre()
    elseif timerAccion == "Libre" then
        Validar("scanCycle5", "Libre")
        CancelTimer()
    end

    return true
end

-- funcion principal
-- if sensor_puerta ~= nil then
--     if params._id == sensor_puerta and params.event == "item_updated" then
--         EventoPuerta()
--     end
-- end
if ModoPluginStatus then
    if modeButton.value ~= "" and modeButton.value ~= data.modo then
    Registro("Modo Int: " .. data.modo)
    Registro("Modo Button Inicial: " .. modeButton.value)
    CancelTimer()
    ActualizarAccion(ACCION_SCAN)
    Validar("Modo5", tostring(modeButton.value)) --Actualiza estado del aul con respecto al cambio de estado en web
    Validar("scanCycle5", "scan_One")
    Validar("timerAccion5", "Scan")
    Registro(("Actualizado Modo plugin modeButt: " .. modeButton.value),verde)
    Registro(("Actualizado Modo plugin Data Int: " .. data.modo),verde)
    Registro("Modo successful change ",verde)
    StartTimer(Tiempo1)
    Registro("----------------------------------")
    end
end
if AccionPluginStatus then
    local EstadoTexto = _core.get_item(tostring(EstadoPluginStatus))
    local AccionButton = _core.get_item(tostring(AccionPluginStatus))

    if EstadoTexto and EstadoTexto.value and AccionButton and AccionButton.value then
        if AccionButton.value == "Libre" and EstadoTexto.value == "Ocupado" then
            Registro("Acción cambió con éxito", "verde")
            Validar("scanCycle5", "LibreForzado")
            Libre()
        end
    else
        Registro("Error: EstadoTexto o AccionButton no tienen valores válidos.", "rojo")
    end
end
if SensorMovbatt ~= nil  and params.event == "item_updated" then
for i in pairs(SensorMovbatt) do
        if params._id == SensorMovbatt[i] then
            EventMovimiento(SensorMovbatt)
        end
    end
end 
if SensorMovElec ~= nil  and params.event == "item_updated" then
    for i in pairs(SensorMovElec) do
        if params._id == SensorMovElec[i]then
            EventMovimiento(SensorMovElec)
        end
    end
end
if devicesOn ~= nil and params.event == "item_updated" then
    for _, id in ipairs(devicesOn) do
        -- Registro("Revisando ID: " .. id)
        if params._id == id then
            Registro("Activado por ID: " .. id)
            EventoActuadores({id})
            break
        end
    end
end
if devicesOff ~= nil and params.event == "item_updated" then 
    for _, id in ipairs(devicesOff) do
        -- Registro("Revisando ID: " .. id)
        if params._id == id then
            Registro("Activado por ID: " .. id)
            EventoActuadores({id})
            break
        end
    end
end
if masterSwitch ~= nil and params.event == "item_updated" then
    for _, id in ipairs(masterSwitch) do
        -- Registro("Revisando ID: " .. id)
        if params._id == id then
            Registro("Activado por ID: " .. id)
            EventoActuadores({id})
            break
        end
    end
end
if params.arg_name == "timer" then
    Tick5()
else
    Main()
end