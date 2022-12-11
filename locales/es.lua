local Translations = {
    error = {
        already_in_race = "Ya estas en una carrera",
        failed_to_find_a_waypoint = "No se pudo encontrar un buen punto",
        race_already_started = "Ya la carrera ha empezado",
        not_enough_money = "No tienes suficiente dinero",
        you_have_no_invites = "No te han invitado a una carrera Mano a Mano",
        invite_gone = "la invitacion se ha expirado"
    },
    success = {
        race_go = "VAMOS!",
    },
    info = {
        loser = "Mejor suerte en la proxima",
        winner = "Felicidades, Has Ganado!",
        you_got_an_invite = "Has sido retado a una carrera Mano a Mano",
        you_got_an_invite_outrun = "Has sido retado a una carrera de Gato y Raton"
    },
    menu = {
        title = "Mano a Mano",
        title_outrun = "Gato y Raton",
        setup = "Organizar",
        join = "Unirse"
    }
}
Lang = Locale:new({phrases = Translations, warnOnMissing = true})

-- Maintained by DaurysOG