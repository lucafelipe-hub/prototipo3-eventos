local Eventos = {
    oyentes = {}
}

function Eventos.suscribir(nombreEvento, callback)
    if not Eventos.oyentes[nombreEvento] then
        Eventos.oyentes[nombreEvento] = {}
    end
    table.insert(Eventos.oyentes[nombreEvento], callback)
end

function Eventos.disparar(nombreEvento, ...)
    if Eventos.oyentes[nombreEvento] then
        for _, callback in ipairs(Eventos.oyentes[nombreEvento]) do
            callback(...)
        end
    end
end

function Eventos.limpiar()
    Eventos.oyentes = {}
end

return Eventos