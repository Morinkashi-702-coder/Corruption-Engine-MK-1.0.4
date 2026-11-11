-- Neuroses stage script - VERSIÓN CORREGIDA 2026-02-17

function onCreate()
    -- Hide the extra character slots by hiding their groups
    -- These groups contain the bf3, bf4, dad3, dad4 characters
    
    -- Usar hasExtraCharacter para verificar existencia de forma segura
    if hasExtraCharacter('bf3') then
        setProperty('bf3.visible', false)
    end
    
    if hasExtraCharacter('bf4') then
        setProperty('bf4.visible', false)
    end
    
    if hasExtraCharacter('dad3') then
        setProperty('dad3.visible', false)
    end
    
    if hasExtraCharacter('dad4') then
        setProperty('dad4.visible', false)
    end
end

function onUpdate(elapsed)
    -- Keep them hidden throughout the song
end

function onUpdatePost(elapsed)
    -- Additional updates if needed
end
