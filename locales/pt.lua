local Translations = {
    error = {
        already_in_race = "Tu já estás em uma corrida",
        failed_to_find_a_waypoint = "Não consegui-o encontrar um bom waypoint",
        race_already_started = "A corrida já começou",
        not_enough_money = "Não tens dinheiro suficiente",
        you_have_no_invites = "Nao existe corredores para se juntar",
        invite_gone = "O Convite expirou"
    },
    success = {
        race_go = "GO!",
    },
    info = {
        loser = "Perdeu! Melhor sorte para a proxima vez",
        winner = "Ganhou!",
        you_got_an_invite = "Foste desafiado a fazer uma corrida 1x1",
        you_got_an_invite_outrun = "Foste desafiado para uma corrida de ultrapassagem"
    },
    menu = {
        title = "1 x 1",
        title_outrun = "Ultrapassagem",
        setup = "Criar",
        join = "juntar-se"
    }
}
Lang = Locale:new({phrases = Translations, warnOnMissing = true})