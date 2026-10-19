local Eventos = require("eventos")

-- Objetos e imágenes (ajustados con hitbox interna)
local avion = { x = 370, y = 500, anchoVisual = 60, altoVisual = 60, velocidad = 300, vida = 100 }
local enemigos = {}
local disparos = {}

local imgAvion, imgEnemigo
local sndDisparo, sndMoneda, sndDerrota, sndVictoria

-- Estado de UI y Juego
local puntos = 0
local estadoJuego = "JUGANDO"
local tiempoFlashDano = 0
local textoFeedback = "¡Usa FLECHAS para moverte y ESPACIO para disparar!"
local colorFeedback = {1, 1, 1}

local function reiniciarJuego()
    avion.x = 370
    avion.y = 500
    avion.vida = 100
    puntos = 0
    estadoJuego = "JUGANDO"
    tiempoFlashDano = 0
    textoFeedback = "¡Juego reiniciado! ¡Buena suerte!"
    colorFeedback = {1, 1, 1}
    disparos = {}
    enemigos = {}

    for i = 1, 5 do
        table.insert(enemigos, { x = math.random(50, 700), y = math.random(-400, -50), velocidad = math.random(120, 220), ancho = 45, alto = 45 })
    end
end

function love.load()
    -- Cargar Imágenes
    imgAvion = love.graphics.newImage("avion.png")
    imgEnemigo = love.graphics.newImage("enemigo.png")

    -- Cargar Sonidos
    sndDisparo = love.audio.newSource("disparo.mp3", "static")
    sndMoneda = love.audio.newSource("moneda.mp3", "static")
    sndDerrota = love.audio.newSource("derrota.mp3", "static")
    sndVictoria = love.audio.newSource("victoria.mp3", "static")

    -- SUSCRIPCIÓN A EVENTOS
    Eventos.suscribir("jugador_disparo", function()
        if sndDisparo then sndDisparo:clone():play() end
    end)

    Eventos.suscribir("enemigo_destruido", function(pts)
        puntos = puntos + pts
        if sndMoneda then sndMoneda:clone():play() end
        textoFeedback = "¡Enemigo destruido! +" .. pts .. " pts"
        colorFeedback = {0.2, 1, 0.2}
        
        if puntos >= 1000 and estadoJuego == "JUGANDO" then
            Eventos.disparar("juego_victoria")
        end
    end)

    Eventos.suscribir("jugador_dano", function(dano)
        avion.vida = math.max(0, avion.vida - dano)
        tiempoFlashDano = 0.2
        textoFeedback = "¡Impacto recibido! -" .. dano .. " HP"
        colorFeedback = {1, 0.2, 0.2}

        if avion.vida <= 0 and estadoJuego == "JUGANDO" then
            Eventos.disparar("juego_derrota")
        end
    end)

    Eventos.suscribir("juego_derrota", function()
        estadoJuego = "GAME_OVER"
        if sndDerrota then sndDerrota:play() end
    end)

    Eventos.suscribir("juego_victoria", function()
        estadoJuego = "VICTORIA"
        if sndVictoria then sndVictoria:play() end
    end)

    -- Crear enemigos iniciales
    reiniciarJuego()
end

function love.update(dt)
    if estadoJuego ~= "JUGANDO" then return end

    if tiempoFlashDano > 0 then
        tiempoFlashDano = tiempoFlashDano - dt
    end

    -- Movimiento del jugador
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        avion.x = math.max(0, avion.x - avion.velocidad * dt)
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        avion.x = math.min(800 - avion.anchoVisual, avion.x + avion.velocidad * dt)
    end

    -- Mover disparos
    for i = #disparos, 1, -1 do
        local d = disparos[i]
        d.y = d.y - 450 * dt
        if d.y < -10 then table.remove(disparos, i) end
    end

    -- Mover y verificar enemigos
    for i, e in ipairs(enemigos) do
        e.y = e.y + e.velocidad * dt
        if e.y > 600 then
            e.y = math.random(-200, -50)
            e.x = math.random(50, 700)
        end

        -- HITBOX DE DISPARO A ENEMIGO
        for j = #disparos, 1, -1 do
            local d = disparos[j]
            if d.x > e.x + 5 and d.x < e.x + e.ancho - 5 and d.y > e.y + 5 and d.y < e.y + e.alto - 5 then
                table.remove(disparos, j)
                e.y = math.random(-200, -50)
                e.x = math.random(50, 700)
                Eventos.disparar("enemigo_destruido", 100)
            end
        end

        -- HITBOX DE ENEMIGO A JUGADOR
        local avionHitboxX = avion.x + 30
        local avionHitboxY = avion.y + 5
        local avionHitboxAncho = avion.anchoVisual - 10
        local avionHitboxAlto = avion.altoVisual - 10

        if e.x < avionHitboxX + avionHitboxAncho and e.x + e.ancho > avionHitboxX and
           e.y < avionHitboxY + avionHitboxAlto and e.y + e.alto > avionHitboxY then
            e.y = math.random(-200, -50)
            e.x = math.random(50, 700)
            Eventos.disparar("jugador_dano", 20)
        end
    end
end

function love.keypressed(key)
    if estadoJuego == "JUGANDO" then
        if key == "space" then
            table.insert(disparos, { x = avion.x + (avion.anchoVisual / 2), y = avion.y })
            Eventos.disparar("jugador_disparo")
        end
    else
        -- Reiniciar con la tecla R o Espacio cuando el juego haya terminado
        if key == "r" or key == "space" or key == "return" then
            reiniciarJuego()
        end
    end
end

function love.mousepressed(x, y, button)
    -- Reiniciar con clic del mouse si hace clic en el botón de Reiniciar
    if estadoJuego ~= "JUGANDO" and button == 1 then
        if x >= 300 and x <= 500 and y >= 340 and y <= 390 then
            reiniciarJuego()
        end
    end
end

function love.draw()
    if tiempoFlashDano > 0 then
        love.graphics.clear(0.4, 0.1, 0.1)
    else
        love.graphics.clear(0.1, 0.1, 0.18)
    end

    -- Dibujar Jugador (Imagen más pequeña y subida en Y para encajar justo en la hitbox)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(imgAvion, avion.x - 3, avion.y - 18, 0, 0.10, 0.10)

    -- Dibujar Disparos
    love.graphics.setColor(1, 1, 0)
    for _, d in ipairs(disparos) do
        love.graphics.circle("fill", d.x, d.y, 5)
    end

    -- Dibujar Enemigos
    love.graphics.setColor(1, 1, 1)
    for _, e in ipairs(enemigos) do
        love.graphics.draw(imgEnemigo, e.x - 5, e.y - 5, 0, 0.11, 0.11)
    end

    -- INTERFAZ DE USUARIO (UI)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 800, 60)

    -- Barra de vida
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 20, 20, 200, 20)
    love.graphics.setColor(1 - (avion.vida/100), avion.vida/100, 0.2)
    love.graphics.rectangle("fill", 20, 20, math.max(0, avion.vida * 2), 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. avion.vida, 25, 22)

    -- Puntos
    love.graphics.print("PUNTOS: " .. puntos, 250, 22)

    -- Feedback
    love.graphics.setColor(colorFeedback)
    love.graphics.print(textoFeedback, 380, 22)

    -- Pantallas Finales
    if estadoJuego == "GAME_OVER" or estadoJuego == "VICTORIA" then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, 800, 600)

        if estadoJuego == "GAME_OVER" then
            love.graphics.setColor(1, 0.2, 0.2)
            love.graphics.printf("¡GAME OVER!", 0, 220, 800, "center")
        else
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.printf("¡VICTORIA!", 0, 220, 800, "center")
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Puntuación Final: " .. puntos, 0, 270, 800, "center")

        -- Botón de Reiniciar
        love.graphics.setColor(0.2, 0.6, 1)
        love.graphics.rectangle("fill", 300, 340, 200, 50, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("REINICIAR (R)", 300, 355, 200, "center")
    end

    love.graphics.setColor(1, 1, 1)
end