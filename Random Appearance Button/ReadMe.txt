This mod adds a Random Appearance button (which makes default-looking soldiers and is configurable) and a Totally Random button (if you want to make zany clown soldiers). It has a set of checkboxes to lock traits, as depicted in the screenshots.

Check off the attributes you want to lock (prevent from changing) then click a button to roll the dice. The panel is hidden by default; click the Toggle Options button to reveal and rehide them.

* The Random Appearance button * generates a 'reasonable looking soldier' as requested by users. Most of the chances are based on the game's default chances for props, but these are all configurable in XComRandomAppearanceButton.ini if you'd like to tweak them.

That file ought to be here: ...\Steam\SteamApps\workshop\content\268500\634268994\Config

* The Totally Random button * does just what it says and will result in clowns at least half of the time. (It will respect the checkboxes.)

* * * CAVEATS * * *

Note that - just as the default UI is - this mod is constrained by whatever armor your soldier is wearing prior to coming into Customization.

Voice and Attitude aren't currently rolled for; they could be but it didn't make sense to me. If you all disagree and really want them on there, let me know. :) (1000 users in and nobody has asked for this, so it seems you all agree with me.)

Switching the soldier's gender effectively generates a new soldier, preserving the settings for the previous gender; this is just how XCOM 2 handles it, not the mod. You can freely toggle between genders: each keeps their own distinct looks. (Not much benefit here but no harm, as far as I can tell.)

* * * UPCOMING FEATURES * * *

BY REQUEST, AN UNDO BUTTON: I'm currently working on an Undo/Rollback button which is about halfway there. (It works but doesn't respect the checkboxes; making it respect the checkboxes has me refactoring a LOT of my stuff which is taking time.)

* * * KNOWN COMPATIBILITIES * * *

Anarchy's Children DLC. (This DLC is not required.)

Capnbubs Accessories Pack - also one of my personal favorites.
http://steamcommunity.com/sharedfiles/filedetails/?id=618977388

Military Camouflage Patterns - another of my personal favs.
http://steamcommunity.com/sharedfiles/filedetails/?id=619706632

Full Character Customization From Start.
http://steamcommunity.com/sharedfiles/filedetails/?id=620530611

Custom Face Paints
http://steamcommunity.com/sharedfiles/filedetails/?id=619525059

Free the Hood (allows the deep hood and similar hats to be coupled with upper and lower face props freely).
http://steamcommunity.com/sharedfiles/filedetails/?id=625349228

Menace Tattoo Pack
http://steamcommunity.com/sharedfiles/filedetails/?id=620514823

Ink and Paint
http://steamcommunity.com/sharedfiles/filedetails/?id=620051852

Symmetrical Kevlar Arms mods: these ones get a lil weird once in a while, resulting in fem arms on male soldiers, even during the opening mission...but that's sufferable for symmetrical arms. Note that you'll need to adjust the INI if you want these arms to be used by the Random Apperance button. (Totally Random will use them.)
http://steamcommunity.com/sharedfiles/filedetails/?id=626636844
http://steamcommunity.com/sharedfiles/filedetails/?id=628236543

Some VPs *do* work, like the Quiet & Venom Snake, and the Mute VP, both of which I use and enjoy.

My other two mods work with it. :)
http://steamcommunity.com/sharedfiles/filedetails/?id=630738292
http://steamcommunity.com/sharedfiles/filedetails/?id=635123932

* * * REPORTED INCOMPATIBILITIES * * *

The "Playable Advent" mod apparently prevents my buttons from appearing. Hypothesis: that mod overrides the UICustomize_Menu class, or its superclass; OR it pushes the default customize screen off of the screen stack and replaces it with its own. (I haven't looked.)

* * *  KNOWN ISSUES AND BUGS.  * * *

VOICE PACKS DON'T ALWAYS LIKE IT. Some custom Voice Packs actually conflict with this mod, as reported by several users. If it doesn't work for you, try loading it up without voice pack mods. This doesn't yet make any sense to me, so it would be valuable if you could tell me which VP(s) you have that seems to conflict (make the buttons not appear or not work). Thanks!

SLOW DOWN. The mod will experience some intense slowdown if you have a lot of mods that add props. This is 'normal' but undesirable; I've yet to even come close to a fix for this, unfortunately.

WHILE IN A SUBMENU. If you click one of the buttons while editting a specific trait with the UI (e.g. if you're in the eye color chooser and click Random Appearance) it 1. won't change the appearance and 2. will likely kick the camera in the teeth and you'll be stuck at the submenu's zoom. WORKAROUND: don't do it. If you did it, back out and dive back in.

4:3 RESOLUTIONS. The mod doesn't always work for 4:3 resolutions, due to where the panel has been placed on screen. In my testing, the buttons are a little cut off...others have told me they just don't see the buttons. I have some ideas on how to fix this now, but they require a lot of background work and testing. Sorry, I'm still new here.

PROPS THAT JUST DON'T GO TOGETHER. Some mods add new props that just don't work with props from other mods; my mod will still randomly plop them together sometimes because it's all about clipping and aesthetics, and XCOM provices me facilities to easily handle neither. Sorry. :) Use the lock checkboxes liberally! Or don't...sometimes I'll find some really interesting combos this way, especially with Free the Hood and Capnbubs.