-- Neuroses stage script - VERSIÓN CORREGIDA 2026-02-17
-- Script mejorado para manejar correctamente los slots extras bf3, bf4, dad3, dad4

function onCreate()
    debugPrint("=== NEUROSES STAGE LOADED ===", "00FF00")
    
    -- Verificar cuáles personajes extras existen
    local hasBf3 = hasExtraCharacter('bf3')
    local hasBf4 = hasExtraCharacter('bf4')
    local hasDad3 = hasExtraCharacter('dad3')
    local hasDad4 = hasExtraCharacter('dad4')
    
    if hasBf3 then
        debugPrint("✓ BF3 detectado", "00FFFF")
    else
        debugPrint("✗ BF3 no encontrado", "FF8800")
    end
    
    if hasBf4 then
        debugPrint("✓ BF4 detectado", "00FFFF")
    else
        debugPrint("✗ BF4 no encontrado", "FF8800")
    end
    
    if hasDad3 then
        debugPrint("✓ DAD3 detectado", "FF0000")
    else
        debugPrint("✗ DAD3 no encontrado", "FF8800")
    end
    
    if hasDad4 then
        debugPrint("✓ DAD4 detectado", "FF0000")
    else
        debugPrint("✗ DAD4 no encontrado", "FF8800")
    end
    
    -- OPCIÓN 1: Ocultar los personajes extras
    -- (Descomenta si quieres usar esta opción)
    
    --[[
    if hasBf3 then
        setProperty('bf3.visible', false)
        debugPrint("BF3 ocultado", "FFFF00")
    end
    
    if hasBf4 then
        setProperty('bf4.visible', false)
        debugPrint("BF4 ocultado", "FFFF00")
    end
    
    if hasDad3 then
        setProperty('dad3.visible', false)
        debugPrint("DAD3 ocultado", "FFFF00")
    end
    
    if hasDad4 then
        setProperty('dad4.visible', false)
        debugPrint("DAD4 ocultado", "FFFF00")
    end
    --]]
    
    -- OPCIÓN 2: Dejar visibles pero ajustar su apariencia
    
    if hasBf3 then
        -- BF3 está parcialmente transparente
        setProperty('bf3.alpha', 0.8)
        debugPrint("BF3 alpha ajustada a 0.8", "FFFF00")
    end
    
    if hasBf4 then
        setProperty('bf4.alpha', 0.7)
        debugPrint("BF4 alpha ajustada a 0.7", "FFFF00")
    end
    
    if hasDad3 then
        setProperty('dad3.alpha', 0.8)
        debugPrint("DAD3 alpha ajustada a 0.8", "FFFF00")
    end
    
    if hasDad4 then
        setProperty('dad4.alpha', 0.7)
        debugPrint("DAD4 alpha ajustada a 0.7", "FFFF00")
    end
    
    debugPrint("=== NEUROSES STAGE READY ===", "00FF00")
end

function onBeat(beat)
    -- Los personajes extras bailan automáticamente
    -- si están usando la configuración por defecto
    
    -- Aquí puedes agregar lógica personalizada si quieres
    if beat % 4 == 0 then
        if hasExtraCharacter('bf3') then
            characterDance('bf3')
        end
        
        if hasExtraCharacter('dad3') then
            characterDance('dad3')
        end
    end
end

function onUpdate(elapsed)
    -- Actualizar lógica cada frame si es necesario
    -- Mantener posiciones o efectos especiales
end

function onUpdatePost(elapsed)
    -- Código que se ejecuta después de la actualización principal
end

-- Manejo de eventos desde el gráfico de la canción
function onEvent(name, value1, value2)
    if name == "move_extra_characters" then
        -- Ejemplo: mover personajes extras a posiciones específicas
        if hasExtraCharacter('bf3') then
            doTweenX('bf3_move', 'bf3', tonumber(value1), 1, 'easeInOutQuad')
        end
    end
    
    if name == "toggle_extra_characters" then
        -- Mostrar/ocultar personajes extras
        local visible = (value1 == '1')
        
        if hasExtraCharacter('bf3') then
            setProperty('bf3.visible', visible)
        end
        if hasExtraCharacter('bf4') then
            setProperty('bf4.visible', visible)
        end
        if hasExtraCharacter('dad3') then
            setProperty('dad3.visible', visible)
        end
        if hasExtraCharacter('dad4') then
            setProperty('dad4.visible', visible)
        end
    end
end

-- Opcional: Callback cuando se completa un tween
function onTweenCompleted(tag, vars)
    if tag == 'bf3_move' then
        debugPrint("BF3 ha llegado a su posición", "00FF00")
    end
end
