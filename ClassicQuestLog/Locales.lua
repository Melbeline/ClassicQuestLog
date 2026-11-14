-- ClassicQuestLog - its texts: English, French and German (the game's own words elsewhere: Quest Log, Abandon...)
local ADDON, ns = ...

local L = {
  QL_DUAL = "Double pane",
  QL_SW_DUAL = "Double pane (the 3.x shape: the list on the left, the quest on the right)",
  QL_GRIP = "Drag: bigger or smaller. Right-click: its first size.",
  QL_NOT_IN_GROUP = "You are not in a party.",
  QL_CLOSE_MAP = "Close the world map, then share again.",
  QL_SHARE_FROM_MAP = "This quest could not be shared from here. Share it from the world map.",
  ABOUT = "The 1.x quest log (Era's art) in place of the map's quest panel: opened by the quest log key and the quest log micro button, in combat too. Headers folded one by one or all at once, quests in their difficulty color with their tags, the party on each quest, watched quests checked (shift-click or Track Quest), the page with objectives, description and rewards; Abandon, Share and Close. Moved by its top, bigger or smaller by the grip on its corner, closed by Escape and by a quest giver's window.",
  RESET_PLACE = "First size and place",
  HINT = "/cql opens or shuts the quest log · /cql options: this page · /cql reset: its first size and place. The world map's key (M), the tracker's clicks and the map's quest panel stay the game's.",
  CLARA = "ClassicQuestLog: Clara Combo Points' own quest log is on (the same one); ClassicQuestLog stays off. Turn Clara's off (its Quest log box) to use this one.",
}

local locale = GetLocale and GetLocale() or "enUS"
if locale == "frFR" then
  L.QL_DUAL = "Double volet"
  L.QL_SW_DUAL = "Double volet (la forme 3.x : la liste à gauche, la quête à droite)"
  L.QL_GRIP = "Glisser : agrandir ou réduire. Clic droit : sa taille d'origine."
  L.QL_NOT_IN_GROUP = "Vous n'êtes pas dans un groupe."
  L.QL_CLOSE_MAP = "Fermez la carte du monde, puis partagez de nouveau."
  L.QL_SHARE_FROM_MAP = "Cette quête n'a pas pu être partagée d'ici. Partagez-la depuis la carte du monde."
  L.ABOUT = "Le journal de quêtes 1.x (l'art d'Era) à la place du panneau de quêtes de la carte : ouvert par la touche du journal de quêtes et le micro-bouton du journal, en combat aussi. Les catégories repliées une à une ou toutes à la fois, les quêtes dans la couleur de leur difficulté avec leurs étiquettes, le groupe sur chaque quête, les quêtes suivies cochées (Maj + clic ou Suivre la quête), la page avec objectifs, description et récompenses ; Abandonner, Partager et Fermer. Déplacé par son haut, agrandi ou réduit par la poignée de son coin, fermé par Échap et par la fenêtre d'un donneur de quêtes."
  L.RESET_PLACE = "Taille et place d'origine"
  L.HINT = "/cql ouvre ou ferme le journal · /cql options : cette page · /cql reset : sa taille et sa place d'origine. La touche de la carte (M), les clics sur le suivi des quêtes et le panneau de quêtes de la carte restent ceux du jeu."
  L.CLARA = "ClassicQuestLog : le journal de quêtes de Clara Combo Points est activé (le même) ; ClassicQuestLog reste éteint. Désactive celui de Clara (sa case Journal de quêtes) pour utiliser celui-ci."
elseif locale == "deDE" then
  L.QL_DUAL = "Doppelte Ansicht"
  L.QL_SW_DUAL = "Doppelte Ansicht (die 3.x-Form: die Liste links, die Quest rechts)"
  L.QL_GRIP = "Ziehen: größer oder kleiner. Rechtsklick: Ursprungsgröße."
  L.QL_NOT_IN_GROUP = "Du bist in keiner Gruppe."
  L.QL_CLOSE_MAP = "Schließ die Weltkarte und teile dann erneut."
  L.QL_SHARE_FROM_MAP = "Diese Quest konnte hier nicht geteilt werden. Teile sie über die Weltkarte."
  L.ABOUT = "Das 1.x-Questlog (Eras Grafik) statt des Questbereichs der Karte: geöffnet mit der Questlog-Taste und dem Questlog-Mikroknopf, auch im Kampf. Kategorien einzeln oder alle auf einmal eingeklappt, Quests in der Farbe ihrer Schwierigkeit mit ihren Kennzeichen, die Gruppe auf jeder Quest, verfolgte Quests abgehakt (Umschalt-Klick oder Quest verfolgen), die Seite mit Zielen, Beschreibung und Belohnungen; Abbrechen, Teilen und Schließen. Verschoben an seinem oberen Rand, größer oder kleiner über den Griff in seiner Ecke, geschlossen mit Escape und vom Fenster eines Questgebers."
  L.RESET_PLACE = "Ursprungsgröße und -platz"
  L.HINT = "/cql öffnet oder schließt das Questlog · /cql options: diese Seite · /cql reset: Ursprungsgröße und -platz. Die Kartentaste (M), die Klicks in der Questverfolgung und der Questbereich der Karte bleiben die des Spiels."
  L.CLARA = "ClassicQuestLog: Das Questlog von Clara Combo Points ist an (dasselbe); ClassicQuestLog bleibt aus. Schalte das von Clara aus (sein Kästchen Questlog), um dieses zu nutzen."
end

ns.L = L
