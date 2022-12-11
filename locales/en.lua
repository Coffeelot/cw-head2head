local Translations = {
    error = {
        already_in_race = "You're already in a race",
        failed_to_find_a_waypoint = "Could not find a good waypoint",
        race_already_started = "Race has already started",
        not_enough_money = "Not enough money to join",
        you_have_no_invites = "No Head 2 Heads to join",
        invite_gone = "The invite is gone"
    },
    success = {
        race_go = "GO!",
    },
    info = {
        loser = "Better luck next time",
        winner = "Winner!",
        you_got_an_invite = "You've been challenged to a Head 2 Head",
        you_got_an_invite_outrun = "You've been challenged to an Outrun race"
    },
    menu = {
        title = "Head 2 Head",
        title_outrun = "Outrun",
        setup = "Setup",
        join = "Join"
    }
}
Lang = Locale:new({phrases = Translations, warnOnMissing = true})