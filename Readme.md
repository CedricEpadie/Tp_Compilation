##  Faire le make du projet
```
make
```

##  compiler un des fichier de test contenu dans le dossier 'tests'
```
make test FILE=nom du fichier         // où x est une variable qui va de 1 à 10 . 
```
-   un fichier 'output.c' est crée et vous pouvez voir le code C resultant.

##  Executer le code C correspondant à notre fichier test compilé
```
make exec
```


## 🧩 Comment fonctionne notre compilateur ?

### 🔧 Pourquoi deux fichiers `.l` et `.y` ?

Notre compilateur est divisé en **deux grandes parties** :

1. **Le lecteur** du code source (`langage.l`)
2. **Le traducteur** du code en langage C (`langage.y`)

---

### 🔹 `langage.l` – Le “lecteur” du code

#### 📌 À quoi ça sert ?

Ce fichier sert à **lire le code source écrit dans notre langage** (avec des mots-clés en français), et à le **découper en éléments compréhensibles** : mots-clés, nombres, variables, symboles...

> 📖 tel un surligneur qui dit : « ceci est un mot-clé », « ceci est un nombre », « ceci est un nom de variable ».

#### 🔍 Que fait-il exactement ?

- Il reconnaît les **mots-clés** comme `pour`, `si`, `afficher`, `lire`, etc.
- Il identifie les **symboles** comme `+`, `==`, `=`, `(`, `)`, etc.
- Il détecte les **nombres** et les **noms de variables** (`a`, `somme`, etc.)
- Il **ignore** les espaces, tabulations, sauts de ligne
- Il **signale les caractères invalides** (exemple : `@`, `#`, etc.)

---

### 🔸 `langage.y` – Le “cerveau” qui comprend la logique

#### 📌 À quoi ça sert ?

Ce fichier permet de **comprendre la structure logique des instructions** du programme et de **générer automatiquement du code en langage C**.

> 🧠 C’est comme un traducteur de phrases : il comprend la grammaire, l’ordre des mots, et produit une version en C.

#### 🧱 Que fait-il ?

- Il comprend les **structures** comme :
  - Affectation : `a = 5 + 3;`
  - Condition : `si (a > 5) alors ... fsi`
  - Boucle : `pour (...) faire ... fpour`
  - `selon`, `afficher`, `lire`, etc.
- Il **vérifie la syntaxe** du programme
- Il **génère du code C équivalent**
- En cas d’erreur, il signale précisément la ligne et le symbole fautif :
