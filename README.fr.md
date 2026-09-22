# KeyTrace

[简体中文](README.md) | [繁體中文](README.zh-Hant.md) | [English](README.en.md) | [日本語](README.ja.md) | [Español](README.es.md) | **Français** | [Deutsch](README.de.md)

Outil local pour macOS qui enregistre l’activité du clavier et de la souris et exporte des vidéos animées avec une carte de chaleur 3D.

Adapté des fonctionnalités et des idées de [xuhk/XAssistant](https://github.com/xuhk/XAssistant), réimplémenté nativement en Swift. Cette version macOS est non officielle et n’est pas affiliée à l’auteur original. Aucun code ni élément graphique du projet Windows n’a été copié. Distribué sous [licence MIT](LICENSE).

Désactivez **Afficher les textes de la vidéo** pour masquer titres, dates et notes, tout en conservant les libellés et compteurs des touches. Le dernier appui s’enfonce plus fermement et remonte lentement sans prolonger la durée choisie. Les statistiques s’ouvrent sur le bureau actuel et l’écran du pointeur depuis la barre des menus.

## Fonctionnalités

- Enregistrement en arrière-plan depuis la barre des menus, statistiques quotidiennes et carte de chaleur du clavier.
- Détection des claviers intégrés et externes, dispositions MacBook et Mac avec pavé numérique, sélection manuelle possible.
- Choix du début et de la fin, avec raccourcis vers le premier enregistrement et l’heure actuelle.
- Export des appuis animés et des cartes cumulatives en MP4 1080p à 30 images/s dans Téléchargements, avec compression automatique des temps morts.
- Inclusion ou exclusion de la souris ; vitesses de 0.5× à 1024×, dont 128× / 256× / 512×.
- Échelle des couleurs dynamique selon le maximum cumulé courant, ou fixe selon le maximum final de la période sélectionnée.
- Affichage de la carte finale pendant cinq secondes avec une rotation lente de la caméra.
- Son synchronisé à chaque appui, timbre distinct par touche physique et choix entre clavier, mécanique, doux ou silencieux.

## Installation

Version publiée **v1.0.0** ; app **1.0.0, build 16**. Nécessite **Apple Silicon (arm64), macOS 13+**. Intel non pris en charge. **Signature ad hoc, sans notarisation Apple ; une mise à jour peut nécessiter une nouvelle autorisation.**

Téléchargez le [ZIP de l’app](https://github.com/nope-gao/KeyTrace/releases/download/v1.0.0/KeyTrace-arm64.zip) et [SHA256SUMS](https://github.com/nope-gao/KeyTrace/releases/download/v1.0.0/SHA256SUMS) depuis la [version publiée](https://github.com/nope-gao/KeyTrace/releases/tag/v1.0.0), puis vérifiez avec la commande ci-dessous. Le Source code ZIP automatique n’est pas l’app. Décompressez et déplacez **KeyTrace.app** dans `~/Applications` avant de l’ouvrir.

```bash
# In the folder containing the downloaded ZIP and SHA256SUMS
awk '$2 == "KeyTrace-arm64.zip"' SHA256SUMS | shasum -a 256 -c -
```

Installation par terminal de cette version précise, sans `/latest` :

```bash
curl -fsSL https://raw.githubusercontent.com/nope-gao/KeyTrace/v1.0.0/install.sh -o /tmp/keytrace-install.sh
bash /tmp/keytrace-install.sh --version v1.0.0
```

L’installateur vérifie SHA-256, version et signature sans sudo. Il s’arrête si l’app tourne, ne modifie pas un paquet identique et refuse une signature incompatible avant remplacement. Pour migrer, quittez et sauvegardez l’ancienne app, remplacez-la manuellement et autorisez à nouveau. Les enregistrements restent conservés.

Si macOS bloque le premier lancement, vérifiez la provenance puis utilisez **Réglages Système → Confidentialité et sécurité → Ouvrir quand même** uniquement pour cette app. Ne désactivez ni Gatekeeper, ni SIP, ni les protections globales. Arrêtez si la politique de votre Mac interdit une exception.

Dans **Confidentialité et sécurité → Surveillance de l’entrée**, ajoutez l’app depuis son emplacement installé et autorisez-la, puis quittez et relancez. Reprenez si elle est en pause. Tapez et cliquez : vérifiez que l’heure du dernier événement et les compteurs augmentent. Le bouton activé ne suffit pas. Après une mise à jour, quittez, supprimez l’ancienne entrée et ajoutez la nouvelle app. Au besoin, utilisez la réinitialisation limitée à cette app ci-dessous, puis autorisez manuellement.

```bash
tccutil reset ListenEvent app.keytrace.mac
```

KeyTrace utilise un dossier de données distinct et n’importe pas automatiquement les enregistrements d’autres apps. Autorisez Surveillance de l’entrée lors de la première installation.

## Durée fixe

Choisissez **Durée fixe** pour définir la durée totale, **60 secondes (1 minute)** par défaut, avec les **5 secondes finales de rotation**. Les actions sont automatiquement accélérées ou ralenties après suppression des pauses. Durée possible : 6–86400 secondes.

## Langue de l’interface

Le réglage initial est **Suivre le système**. L’application parcourt la liste ordonnée des langues préférées de macOS et choisit une langue prise en charge : **简体中文, 繁體中文, English, 日本語, Español, Français, Deutsch**. Elle utilise l’anglais si aucune ne correspond. Vous pouvez choisir une langue ou revenir au système en bas de la fenêtre ; le choix est enregistré.

L’interface, les menus, les messages déjà affichés, les dates et nombres, les étiquettes de souris, les noms des touches de fonction et les sous-titres suivent ce choix. Les lettres conservent la disposition physique ANSI. La vidéo garde la langue choisie au début de l’export, durant lequel le changement manuel est désactivé. macOS contrôle la langue de ses propres autorisations et des détails des erreurs système.

## Son de la vidéo

Choisissez **Frappes de clavier** (par défaut), **Mécanique**, **Frappes douces** ou **Silencieux**. Chaque touche physique possède un timbre court et distinct, déclenché uniquement à l’appui et aligné sur la première image montrant cet appui. À grande vitesse, les sons rapprochés se superposent. Exclure la souris exclut aussi ses clics. Le dernier appui produit un son plus grave dont la courte résonance peut se prolonger au début des cinq secondes de rotation finale.

Le son est synthétisé localement. Aucun microphone, enregistrement réel du clavier ou fichier sonore externe n’est utilisé. Les vidéos sonores contiennent une piste AAC à 48 kHz ; le mode Silencieux ne crée aucune piste audio.

## Compiler les sources

```bash
xcode-select --install
bash build.sh
```

Les compilations locales utilisent une signature ad hoc ; remplacer l’app peut nécessiter une nouvelle autorisation.

## Utilisation

Sélectionnez la période, la vitesse, la souris, l’échelle de chaleur et le son, puis cliquez sur **Exporter vers Téléchargements**. Une activité sans enregistrement ne peut pas être récupérée.

## Données locales et confidentialité

Les données sont stockées dans `~/Library/Application Support/KeyTrace/`. L’application ne les téléverse pas et n’inclut aucune télémétrie. Le programme d’installation contacte GitHub pour télécharger les versions.

La lecture animée nécessite les heures d’appui et de relâchement, les identifiants des touches physiques, les informations d’appareil et l’ordre des événements. Les noms d’applications, Bundle ID et durées d’utilisation sont également enregistrés. L’application ne lit pas le texte final des méthodes de saisie, les titres de fenêtres, les adresses web ou les coordonnées de la souris. **L’ordre des touches peut néanmoins révéler le texte saisi. Les enregistrements sont sensibles : ne publiez pas le dossier de données.**

La pause arrête les nouveaux événements et les statistiques de durée, mais conserve l’historique. Les données locales sont en clair, sans suppression automatique. Quittez l’app avant de mettre les données, caches et vidéos inutiles à la Corbeille.

`~/Library/Application Support/KeyTrace/` · `~/Library/Caches/KeyTrace/VideoJobs/` · `~/Downloads/KeyTrace-*.mp4`

## Limites connues

- Principalement adapté à ANSI. ISO/JIS ne sont pas entièrement pris en charge ; la détection automatique ne couvre pas nécessairement tous les appareils tiers.
- Les touches Fn, multimédias et la saisie sécurisée peuvent ne pas être intégralement enregistrées. Touch ID n’est pas traité comme une touche ordinaire.
- L’identification de l’appareil source peut être limitée avec plusieurs claviers. Les répétitions automatiques lors d’un appui prolongé ne comptent pas comme des appuis distincts.
- Les vidéos sont produites directement avec SceneKit, Metal et AVFoundation ; Blender n’est pas requis.
