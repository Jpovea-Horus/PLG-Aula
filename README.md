# PLG-Aula
Este plugin permite gestionar dispositivos relacionados con sensores de movimiento, automatizando acciones como activar/desactivar luces, controlar un termostato, y mucho más.

## Descripción 
El plugin proporciona configuraciones para integrar sensores de movimiento y dispositivos como actuadores y termostatos. Con este sistema, es posible automatizar tareas como:
- Activar dispositivos al detectar movimiento.
- Ajustar la temperatura de un ambiente mediante un termostato.

## Características:
## Sensores de Movimiento:
Permite configurar sensores de movimiento principales o secundarios los cuales detectan movimiento para que al desactivarse, los actuadores se apaguen. 
### Actuadores: Configura dispositivos que se activan o desactivan cuando se cumplen ciertas condiciones. 
### Termostato: Permite ajustar los SetPoints del termostato para controlar la temperatura del ambiente. 
### Modo Automático: Configura si ciertos dispositivos deben activarse automáticamente con base en el estado de los sensores. 

## Configuración El plugin requiere una configuración inicial con varios parámetros que se describen a continuación.
- itemId Sensor de Movimiento Principal (opcional): El itemId del sensor de movimiento principal. 
- itemId Sensor de Movimiento Secundario (opcional): El itemId del sensor de movimiento secundario. 
- itemId Actuadores On (opcional): El itemId de los dispositivos que se activarán cuando se detecte movimiento. 
- itemId Actuadores Off (opcional): El itemId de los dispositivos que se desactivarán. 
- itemId Actuadores Master Switch (opcional): El itemId del interruptor principal para activar o desactivar dispositivos.

- deviceId Termostato (opcional): El deviceId del termostato para ajustar la temperatura. 
- SetPoint On Termostato (opcional): El valor de SetPoint para cuando el termostato se encienda.
- Modo Encendido Termostato (opcional): Indica si se debe activar el termostato al detectar movimiento. 
- Modo SetPoint (opcional): Indica si el SetPoint debe ajustarse cuando se pasa al modo libre. 
- Modo Disparador Luces (opcional): Indica si las luces deben activarse al detectar movimiento. 
- Modo Disparador Master Switch (opcional): Indica si el Master Switch debe activarse al detectar movimiento. 
- Tiempo Sensor de Scanner (requerido): El tiempo estimado de escaneo después de desactivar el sensor de movimiento.

- Password (requerido): La contraseña para la configuración del plugin.
