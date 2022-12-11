# Head 2 Head racing 👥
Simple and easy 1v1 racing for QBCore. Challange friends and foes without need for any ids, names or setting up a track. The scripts adds an option in qb-radialmenu that opens up new venues for racing. You can either set up for free, or use the pre-set buy-ins (can be changed in config). 

This is how it works:
You open radialmenu, pick the Head 2 Head option and then choose to setup using either no money or a buy in. Everyone close to you, and in a driver seat, will get an invite. First person to accept takes on the challange. A 5 second countdown starts, but no one is locked in place or whatever. This is all about impromptu racing, and race etiquettue. You'll both get a waypoint randomly chosen for you. First there wins. Easy as. The money is taken from the players upon race starting and given to winner when the winner reaches the goal.

Some "limitations" to the positioning system: It check's linear distance to the goal so it might be a bit off sometimes. Also if you get to far apart (outside each others render boxes) we can't track your distance. The postionign will say "-/2" when this is the case. But honestly, if you're taking different routes etc, isn't it more fun to not know? 😏

# Preview 📽
[![YOUTUBE VIDEO](http://img.youtube.com/vi/n4FP3FsSSQI/0.jpg)](https://youtu.be/n4FP3FsSSQI)



# Developed by Coffeelot and Wuggie
[More scripts by us](https://github.com/stars/Coffeelot/lists/cw-scripts)  👈

**Support, updates and script previews**:

[![Join The discord!](https://cdn.discordapp.com/attachments/977876510620909579/1013102122985857064/discordJoin.png)](https://discord.gg/FJY4mtjaKr )

**All our scripts are and will remain free**. If you want to support what we do, you can buy us a coffee here:

[![Buy Us a Coffee](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg)](https://www.buymeacoffee.com/cwscriptbois )

# Features 🌟
- No-fuzz racing
- Betting
- Built in high beam flashing cause it looks cool
- Position tracking
- Two modes: Head2Head (random location. Race there) and Outrun (challenger is mouse, the one who accepts is the cat. Let the chase begin)

# Planned features 🤔
- [Racing App](https://github.com/Coffeelot/cw-racingapp) implementation (like needing a fob to use and menus being available from fob)
- 
- Ghosting, like in our [Racing App](https://github.com/Coffeelot/cw-racingapp). Maybe.

# Not happening ⛔
- More racers than 2
- Adding this to any phone or laptop script

# Config 🔧
**Debug**: Activate debug mode. Can be activated in game with /cwdebughead2head
**SoloRace**: used for debugging. Enables so the race starts with only 1 person. 
**MinimumDistance**:  This is the minimum distance away a randomly selected waypoint can be (so you dont end up only racing around the corner)
**FlareTime**: How long the flares are lit up
**FinishModel**: What model to use for waypoint
**InviteDistance**: How far the invite is sent
**MoneyType**: What type of money to use (cash/bank/crypto)
**BuyIns**: The values you can pick from in the menu
**InviteTimer**: How long until the invite is considered old
**Finishes**: List of Vec3s with the possible locations you can end up having to drive to

## Menu
![Image](https://media.discordapp.net/attachments/1002191366610243674/1048994231169056909/image.png?width=794&height=670)
