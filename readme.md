# Multi-Platform Repository Auto-Clone Script

**Version: 2.1.0**

*[English](#english) | [Français](#français)*

---

<a id="english"></a>
## 🇬🇧 English

A powerful bash script that automatically clones all your repositories from multiple Git platforms (GitHub, GitLab, Bitbucket, Azure DevOps, and custom providers) in one operation.

### Features

- **Multi-Platform Support**: Clone repositories from GitHub, GitLab, Bitbucket, Azure DevOps, and custom Git providers
- **Flexible Authentication**: Uses API tokens for secure authentication
- **Protocol Options**: Choose between SSH and HTTPS protocols for cloning
- **Organized Structure**: Repositories are organized by platform and project
- **Interactive or Automated**: Run interactively or non-interactively for automation
- **Test Mode**: Verify configuration without actually cloning repositories
- **Detailed Logging**: Comprehensive logging with timestamps and colored output

### Prerequisites

The script requires the following dependencies:
- `git`
- `jq` (for JSON processing)
- `curl` (for API requests)

### Installation

1. Download the script:
```bash
curl -O https://codequantum.io/tools/auto-clone.sh
```

2. Make it executable:
```bash
chmod +x auto-clone.sh
```

### Usage

#### Interactive Mode (Recommended)

Simply run the script and follow the prompts:

```bash
./auto-clone.sh [output_directory]
```

The script will:
1. Ask you which platforms to clone from
2. Prompt for credentials for each platform
3. Clone all repositories from the selected platforms

#### Non-Interactive Mode

For automation or scripting:

```bash
./auto-clone.sh --non-interactive \
  --platform github --username your_username --token your_token \
  --platform gitlab --username your_username --token your_token \
  [output_directory]
```

#### Additional Options

```
-h, --help              Show help message
-v, --verbose           Enable verbose output
-t, --test              Run in test mode (no actual cloning)
-l, --log FILE          Specify custom log file
--https                 Use HTTPS instead of SSH for cloning
```

### Authentication

You'll need authentication tokens for each platform:

- **GitHub**: Create a Personal Access Token at GitHub → Settings → Developer settings → Personal access tokens
- **GitLab**: Create a Personal Access Token at GitLab → User Settings → Access Tokens
- **Bitbucket**: Create an App Password at Bitbucket → Personal settings → App passwords
- **Azure DevOps**: Create a Personal Access Token at Azure DevOps → User settings → Personal access tokens

### Examples

Clone all GitHub repositories:

```bash
./auto-clone.sh --non-interactive --platform github --username johndoe --token ghp_1234abcd ~/github-repos
```

Test configuration without cloning:

```bash
./auto-clone.sh --test --verbose
```

Clone using HTTPS instead of SSH:

```bash
./auto-clone.sh --https
```

### Troubleshooting

- Check the log file (default: `autoclone_YYYYMMDD_HHMMSS.log`) for detailed information
- Run with `--verbose` for additional output
- Ensure your tokens have sufficient permissions (typically "repo" scope)
- For SSH issues, verify your SSH keys are properly configured

---

<a id="français"></a>
## 🇫🇷 Français

Un puissant script bash qui clone automatiquement tous vos dépôts depuis plusieurs plateformes Git (GitHub, GitLab, Bitbucket, Azure DevOps et autres fournisseurs personnalisés) en une seule opération.

### Fonctionnalités

- **Support Multi-Plateformes** : Clone les dépôts depuis GitHub, GitLab, Bitbucket, Azure DevOps et autres fournisseurs Git personnalisés
- **Authentification Flexible** : Utilise des tokens API pour une authentification sécurisée
- **Options de Protocole** : Choisissez entre les protocoles SSH et HTTPS pour le clonage
- **Structure Organisée** : Les dépôts sont organisés par plateforme et par projet
- **Interactif ou Automatisé** : Exécutez en mode interactif ou non-interactif pour l'automatisation
- **Mode Test** : Vérifiez la configuration sans réellement cloner les dépôts
- **Journalisation Détaillée** : Journalisation complète avec horodatage et sortie colorée

### Prérequis

Le script nécessite les dépendances suivantes :
- `git`
- `jq` (pour le traitement JSON)
- `curl` (pour les requêtes API)

### Installation

1. Téléchargez le script :
```bash
curl -O https://codequantum.io/tools/auto-clone.sh
```

2. Rendez-le exécutable :
```bash
chmod +x auto-clone.sh
```

### Utilisation

#### Mode Interactif (Recommandé)

Exécutez simplement le script et suivez les instructions :

```bash
./auto-clone.sh [répertoire_de_sortie]
```

Le script va :
1. Vous demander quelles plateformes utiliser pour le clonage
2. Vous demander les identifiants pour chaque plateforme
3. Cloner tous les dépôts des plateformes sélectionnées

#### Mode Non-Interactif

Pour l'automatisation ou le scripting :

```bash
./auto-clone.sh --non-interactive \
  --platform github --username votre_utilisateur --token votre_token \
  --platform gitlab --username votre_utilisateur --token votre_token \
  [répertoire_de_sortie]
```

#### Options Supplémentaires

```
-h, --help              Affiche le message d'aide
-v, --verbose           Active la sortie détaillée
-t, --test              Exécute en mode test (sans clonage réel)
-l, --log FICHIER       Spécifie un fichier journal personnalisé
--https                 Utilise HTTPS au lieu de SSH pour le clonage
```

### Authentification

Vous aurez besoin de tokens d'authentification pour chaque plateforme :

- **GitHub** : Créez un Personal Access Token dans GitHub → Paramètres → Paramètres développeur → Tokens d'accès personnels
- **GitLab** : Créez un Personal Access Token dans GitLab → Paramètres utilisateur → Jetons d'accès
- **Bitbucket** : Créez un App Password dans Bitbucket → Paramètres personnels → Mots de passe d'application
- **Azure DevOps** : Créez un Personal Access Token dans Azure DevOps → Paramètres utilisateur → Jetons d'accès personnels

### Exemples

Cloner tous les dépôts GitHub :

```bash
./auto-clone.sh --non-interactive --platform github --username johndoe --token ghp_1234abcd ~/github-repos
```

Tester la configuration sans cloner :

```bash
./auto-clone.sh --test --verbose
```

Cloner en utilisant HTTPS au lieu de SSH :

```bash
./auto-clone.sh --https
```

### Dépannage

- Consultez le fichier journal (par défaut : `autoclone_AAAAMMJJ_HHMMSS.log`) pour des informations détaillées
- Exécutez avec `--verbose` pour une sortie supplémentaire
- Assurez-vous que vos tokens disposent des permissions suffisantes (généralement l'étendue "repo")
- Pour les problèmes SSH, vérifiez que vos clés SSH sont correctement configurées

---

## Copyright

Copyright © 2025 Antonin Nvh - [CodeQuantum](https://codequantum.io)