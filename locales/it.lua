local Translations = {
    error = {
        already_in_race = "Stai gia partecipanto ad una sfida",
        failed_to_find_a_waypoint = "Non trovo nessun waypoint nelle vicinanze",
        race_already_started = "La gara e gia iniziata",
        not_enough_money = "Non hai abbastanza soldi per parteciapre",
        you_have_no_invites = "Nessun Head 2 Heads a cui partecipare",
        invite_gone = "Invito inviato "
    },
    success = {
        race_go = "VIA!",
    },
    info = {
        loser = "Ritenta sarai piu fortunato",
        winner = "Hai vinto!",
        you_got_an_invite = "Sei stato sfidato a Head 2 Head"
    },
    menu = {
        title = "Head 2 Head",
        setup = "Setup",
        join = "Partecipa"
    }
}
Lang = Locale:new({phrases = Translations, warnOnMissing = true})

-- Maintained by Coffeelot and Brains74