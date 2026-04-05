# git-zshaliases

Collection d’alias et de petites commandes Zsh orientées productivité, principalement pour Git, mais aussi pour quelques usages utilitaires du terminal.

Le but de ce repository est de centraliser des helpers shell simples, lisibles, et facilement réutilisables d’une machine à l’autre, sans dépendre d’un framework Zsh complet.

## Contenu du repository

Le repository charge automatiquement tous les scripts présents dans le dossier `.zshaliases/` via le `.zshrc`.

Structure actuelle :

- `.zshrc` : source automatiquement tous les scripts de `~/.zshaliases`
- `cpuserdir.sh` : copie les scripts du repository dans `~/.zshaliases` puis recharge le shell
- `.zshaliases/gsall.sh` : affiche l’état Git de tous les repositories présents dans un dossier
- `.zshaliases/gg.sh` : affiche un graphe Git lisible
- `.zshaliases/gsc.sh` : raccourci pour créer et switcher sur une branche Git
- `.zshaliases/nscan.sh` : scanne les processus Node.js en cours
- `.zshaliases/helloworld.sh` : script décoratif de bienvenue dans le terminal

## Philosophie

Ce repository privilégie :

- des scripts shell simples
- une installation locale sans dépendance lourde
- des commandes lisibles et modifiables
- des alias utiles au quotidien pour du multi-repo et du développement full stack

Ce n’est pas un plugin manager Zsh. C’est une boîte à outils personnelle, modulaire et portable.

## Installation

### 1. Cloner le repository

```bash
git clone <repo-url> git-zshaliases
cd git-zshaliases
```

### 2. Copier les alias dans le dossier utilisateur

```bash
sh cpuserdir.sh
```

Cela copie le contenu de `.zshaliases/` dans `~/.zshaliases` puis recharge `~/.zshrc`.

### 3. Vérifier le chargement automatique

Le `.zshrc` fourni contient cette logique :

```sh
for f in "$HOME"/.zshaliases/*.sh; do
  [ -f "$f" ] || continue
  source "$f"
done
```

Elle permet de charger automatiquement chaque script shell contenu dans `~/.zshaliases`.

## Commandes disponibles

### `gsall`

Affiche un état Git consolidé pour tous les repositories trouvés dans un dossier racine.

C’est la commande principale du repository pour travailler sur plusieurs projets en parallèle.

#### Fonctionnalités

- scan des sous-dossiers contenant un `.git`
- affichage du nom du repo, de son chemin et de sa branche courante
- détection de l’upstream
- calcul du `ahead / behind`
- affichage des changements staged et non staged
- résumé final par catégories
- liens cliquables VS Code vers les repositories quand possible
- mode `fetch`
- mode `pull --ff-only`
- mode `brief`
- mode `verbose`
- possibilité de masquer le header

#### Usage

```bash
gsall
gsall .
gsall ~/projects
gsall ~/projects --fetch
gsall ~/projects --pull
gsall ~/projects --brief
gsall ~/projects --verbose
gsall ~/projects --staged
gsall ~/projects --no-header
```

#### Options

- `-h`, `--help` : affiche l’aide
- `-s`, `--staged` : n’affiche que les changements staged
- `-f`, `--fetch` : exécute un `git fetch` sur chaque repo
- `-p`, `--pull` : exécute un `git pull --ff-only` sur chaque repo
- `-b`, `--brief` : affiche uniquement le résumé
- `-v`, `--verbose` : affiche tous les repos, même les clean
- `-n`, `--no-header` : masque le header ASCII

#### Notes

- `--brief` et `--verbose` sont exclusifs
- `--fetch` et `--pull` sont exclusifs
- l’argument de dossier est optionnel et vaut `.` par défaut
- la commande attend un dossier contenant directement plusieurs repositories Git

---

### `gg`

Affiche un graphe Git formaté, lisible et compact.

#### Usage

```bash
gg
gg 50
gg --help
```

#### Comportement

- profondeur par défaut : `25`
- affiche le graphe, les décorations, les branches, l’auteur et les dates
- utile pour visualiser rapidement l’historique local

---

### `gsc`

Raccourci pour créer et switcher sur une branche avec `git switch -c`.

#### Usage

```bash
gsc feature/my-branch
gsc -f feature/my-branch
gsc --force feature/my-branch
```

#### Options

- `-f`, `--force` : passe `-f` à `git switch`
- `-h`, `--help` : affiche l’aide

#### Notes

La commande valide le nom de branche avant exécution.

---

### `nscan`

Scanne les processus Node.js en cours d’exécution sur la machine et affiche leurs principales informations.

#### Informations affichées

- PID
- port écouté
- dossier de travail
- présence ou non du mode debug
- commande de lancement

#### Usage

```bash
nscan
nscan --help
```

Cette commande est utile pour retrouver rapidement quel service Node tourne, sur quel port, et depuis quel dossier.

---

### `helloworld.sh`

Script purement décoratif chargé au démarrage du shell.

Il affiche un ASCII art coloré et un message de bienvenue dans le terminal.

Ce script n’a pas d’utilité fonctionnelle critique, mais participe à l’identité visuelle de l’environnement shell.

## Prérequis

Selon les scripts utilisés, certains outils système peuvent être nécessaires :

- `zsh`
- `git`
- `python3` pour certains encodages d’URL dans `gsall`
- `lsof`, `ps`, `awk`, `grep`
- VS Code si vous voulez profiter des liens `vscode://file/...`

## Limites actuelles

- `gsall` ne scanne que les sous-dossiers directs du dossier racine
- un repository imbriqué plus profondément ne sera pas détecté
- les scripts sont pensés pour un environnement Unix / macOS / Linux
- le repository est orienté usage personnel, pas packaging multi-OS avancé

## Personnalisation

Le système est volontairement simple :

- ajoutez un fichier `.sh` dans `~/.zshaliases`
- il sera automatiquement chargé au prochain shell
- vous pouvez modifier ou compléter les scripts selon vos besoins

Exemple :

```sh
# ~/.zshaliases/myalias.sh
unalias myalias 2>/dev/null
myalias() {
  echo "hello"
}
```

## Objectif du projet

Ce repository sert à garder un environnement shell cohérent, reproductible et pratique, avec des helpers maison adaptés à une utilisation quotidienne orientée :

- multi-repositories Git
- développement Node.js
- navigation rapide dans les projets
- confort d’usage terminal

## Évolutions possibles

Quelques pistes naturelles d’amélioration :

- scan récursif des repositories pour `gsall`
- meilleure gestion des erreurs Git réseau
- ajout d’options de filtrage par repo
- sortie plus scriptable pour intégration CI ou agents IA
- séparation plus nette entre scripts utilitaires et scripts purement visuels

## Licence

Usage personnel par défaut, à adapter selon votre besoin.
