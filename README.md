# ClassicQuestLog

The 1.x quest log, back in WoW Forever: Era's own window and art, or the 3.x **double pane** (on by default), in place of the map's quest panel.

**FR** — Le journal de quêtes 1.x, de retour dans WoW Forever : la fenêtre et l'art d'Era, ou le **double volet** 3.x (activé par défaut), à la place du panneau de quêtes de la carte.

- **Ouverture** : la **touche du journal de quêtes** (L par défaut, ou celle que tu lui as donnée) et le **micro-bouton du journal** l'ouvrent et le ferment, **en combat aussi** (c'est une fenêtre de l'addon, rien de protégé). `/cql` aussi.
- **Le double volet 3.x, activé par défaut** : la liste à gauche, la quête choisie à droite, le bouton **Afficher la carte**, et en bas **Abandonner**, **Partager**, **Suivre** et **Fermer**. Sa case radio **Double volet**, en haut de la fenêtre (ou dans les options), revient à la fenêtre 1.x d'une colonne, et c'est gardé.
- **La liste** :
  - les **catégories** se replient une à une, ou toutes avec l'onglet **Tout** (fenêtre 1.x) ;
  - les quêtes sont dans la **couleur de leur difficulté 1.x**, avec leur **étiquette** (Terminée, Élite, Donjon, Groupe, Journalière…) ;
  - le **nombre de membres du groupe** qui l'ont (leurs noms entiers, prénom et nom, dans l'infobulle) ;
  - le **niveau** de la quête si le réglage du jeu l'affiche ;
  - une **coche** sur les quêtes suivies (**Maj + clic** ou **Suivre**) ;
  - le compteur **Quêtes : 16/40**.
- **La page de la quête** : objectifs, temps restant, argent requis, description, **récompenses** (au choix, reçues, argent, expérience), avec leur infobulle et leur lien dans le chat (**Maj + clic**).
- **Abandonner** : la confirmation du jeu, avec les objets que la quête emporte.
- **Partager** : le bouton **Partager** du jeu est cliqué pour toi (le jeu interdit à un addon de partager une quête). Il est sur le panneau de quêtes de la carte : la carte s'ouvre, la quête est partagée et la carte se referme **dans le même clic**, sans jamais s'afficher, et l'on peut partager quête après quête. Ce n'est pas possible en combat ni avec la carte déjà ouverte, et un message le dit alors.
- **La fenêtre** :
  - elle se **déplace** par son haut et s'**agrandit ou se réduit** en glissant la **poignée de son coin bas-droit** (toute la fenêtre à l'échelle, l'art garde ses proportions ; clic droit sur la poignée : sa taille d'origine) ; sa place et sa taille sont gardées ;
  - **Échap** la ferme, et la fenêtre d'un donneur de quêtes aussi, comme en 1.x.
- **Ce qui reste au jeu** : la touche de la carte (M), les clics sur le suivi des quêtes et le panneau de quêtes de la carte.
- **Options** : Échap > Options > AddOns > ClassicQuestLog. On y trouve le double volet et un bouton qui remet la taille et la place d'origine.
- **Commandes** :
  - `/cql` (ou `/classicquestlog`) ouvre ou ferme le journal ;
  - `/cql options` ouvre sa page d'options ;
  - `/cql reset` remet sa taille et sa place d'origine.
- **Avec Clara** : Clara Combo Points contient déjà ce journal (son module Journal de quêtes).
  - Tant que le journal de Clara est activé, ClassicQuestLog **reste éteint**, et une ligne dans le chat le dit.
  - Décoche la case **Journal de quêtes** de Clara, puis fais `/reload`, pour utiliser celui-ci.
- Les réglages sont gardés dans `ClassicQuestLogDB`, pour tout le compte.

**EN**
- **Opening**: the **quest log key** (L by default, or yours) and the **quest log micro button** open and shut it, **in combat too** (the addon's own window, nothing protected). `/cql` as well.
- **The 3.x double pane, on by default**: the list on the left, the picked quest on the right, the **Show Map** button, and **Abandon**, **Share**, **Track** and **Close** at the foot. Its **Double pane** radio, at the top of the window (or in the options), goes back to the one-column 1.x window, kept.
- **The list**:
  - **headers** fold one by one, or all with the **All** tab (1.x window);
  - quests are in their **1.x difficulty color**, with their **tag** (Complete, Elite, Dungeon, Group, Daily…);
  - the **number of party members** on each quest (their whole names, first name and surname, in its tooltip);
  - the quest's **level** when the game's setting shows it;
  - a **check** on watched quests (**shift-click** or **Track**);
  - the **Quests: 16/40** count.
- **The quest's page**: objectives, time left, required money, description, **rewards** (choices, items, money, experience), with their tooltip and chat link (**shift-click**).
- **Abandon**: the game's own prompt, naming the items the quest takes with it.
- **Share**: the game's own **Share** button is pressed for you (the game lets no addon share a quest). It is on the map's quest panel: the map opens, the quest is shared and the map shuts **within the same click**, never drawn, quest after quest. It cannot be done in combat or with the map already open: a message then says so.
- **The window**:
  - it **moves** by its top and grows or shrinks by the **grip on its bottom right corner** (the whole window scaled, the art keeps its shape; right-click the grip: its first size); its place and size are kept;
  - **Escape** closes it, and so does a quest giver's window, as in 1.x.
- **Left to the game**: the world map's key (M), the tracker's clicks and the map's quest panel.
- **Options**: Esc > Options > AddOns > ClassicQuestLog. They hold the double pane and a button that puts its first size and place back.
- **Commands**:
  - `/cql` (or `/classicquestlog`) opens or shuts the quest log;
  - `/cql options` opens its options page;
  - `/cql reset` puts its first size and place back.
- **With Clara**: Clara Combo Points has this same quest log built in (its Quest log module).
  - While Clara's is on, ClassicQuestLog **stays off**, and a chat line says so.
  - Untick Clara's **Quest log** box, then `/reload`, to use this one.
- Settings are kept in `ClassicQuestLogDB`, for the whole account.

The window's art is Era's own (1.x and 3.x quest log sheets), bundled in `media/`: the WoW Forever client's copies are near-black stand-ins.

## 1.0.3

- **Community fixes** (the same as Clara Combo Points', one copy running at a time): a community chat the game failed to join at the login joined again; the Guild & Communities window shows who is online in a community (the game's window never asked for its members' presence). Appear Offline on Battle.net still hides a player from the communities: the player's choice.

- **Correctifs des communautés** (les mêmes que ceux de Clara Combo Points, une seule copie tourne à la fois) : un chat de communauté que le jeu n'a pas rejoint à la connexion est rejoint à nouveau ; la fenêtre Guilde & Communautés montre qui est en ligne dans une communauté (la fenêtre du jeu ne demandait jamais la présence de ses membres). « Apparaître hors ligne » sur Battle.net cache toujours un joueur des communautés : c'est son choix.
