#!/bin/bash

# ==================================================================================
# Multi-Platform Repository Auto-Clone Script
# Copyright © $(date +%Y) Antonin Nvh - https://codequantum.io
# ==================================================================================

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Script version
VERSION="2.1.0"

# Set default log file
LOG_FILE="autoclone_$(date +%Y%m%d_%H%M%S).log"

# Verbose mode flag
VERBOSE=false

# Test mode flag
TEST_MODE=false

# Non-interactive mode flag
NON_INTERACTIVE=false

# Output directory
OUTPUT_DIR="./repositories"

# Default protocol (ssh or https)
PROTOCOL="ssh"

# Platforms array
declare -A PLATFORMS
declare -A PLATFORM_TOKENS
declare -A PLATFORM_USERNAMES

# Log function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Always add to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Display in terminal based on level
    case $level in
        "INFO")
            $VERBOSE && echo -e "${GREEN}[$timestamp] ${RESET}$message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] ERROR: ${RESET}$message" >&2
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] WARNING: ${RESET}$message" >&2
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] SUCCESS: ${RESET}$message"
            ;;
        *)
            $VERBOSE && echo -e "${CYAN}[$timestamp] ${RESET}$message"
            ;;
    esac
}

# Function to display script banner
show_banner() {
    echo -e "\n${BLUE}${BOLD}====================================================${RESET}"
    echo -e "${GREEN}${BOLD}    Multi-Platform Repository Auto-Cloning Script v${VERSION}${RESET}"
    echo -e "${CYAN}        Copyright © $(date +%Y) Antonin Nvh${RESET}"
    echo -e "${CYAN}        https://codequantum.io${RESET}"
    echo -e "${BLUE}${BOLD}====================================================${RESET}"

    log "INFO" "Script started"
    if $TEST_MODE; then
        echo -e "${YELLOW}${BOLD}TEST MODE ENABLED - No repositories will be cloned${RESET}\n"
        log "INFO" "Test mode enabled"
    fi
}

# Usage information
show_usage() {
    echo -e "${YELLOW}${BOLD}Multi-Platform Repository Auto-Clone Script v${VERSION}${RESET}"
    echo -e "${CYAN}Copyright © $(date +%Y) Antonin Nvh - https://codequantum.io${RESET}\n"
    echo -e "${BOLD}Usage:${RESET} $0 [options] [output_directory]"
    echo -e "\n${BOLD}Options:${RESET}"
    echo -e "  ${BOLD}-h, --help${RESET}              Show this help message"
    echo -e "  ${BOLD}-v, --verbose${RESET}           Enable verbose output"
    echo -e "  ${BOLD}-t, --test${RESET}              Run in test mode (no actual cloning)"
    echo -e "  ${BOLD}-l, --log FILE${RESET}          Specify custom log file"
    echo -e "  ${BOLD}-n, --non-interactive${RESET}   Run in non-interactive mode (requires platform arguments)"
    echo -e "  ${BOLD}-p, --platform TYPE${RESET}     Specify platform to clone from (github, gitlab, bitbucket, azure, etc.)"
    echo -e "  ${BOLD}-u, --username USER${RESET}     Username for the specified platform"
    echo -e "  ${BOLD}-k, --token TOKEN${RESET}       Authentication token for the specified platform"
    echo -e "  ${BOLD}--https${RESET}                 Use HTTPS instead of SSH for cloning"
    echo -e "\n${BOLD}Examples:${RESET}"
    echo -e "  # Interactive mode (recommended):"
    echo -e "  $0 --verbose ~/projects"
    echo -e "\n  # Non-interactive mode with specific platforms:"
    echo -e "  $0 --non-interactive --platform github --username johndoe --token ghp_1234abcd \\"
    echo -e "     --platform gitlab --username johndoe --token glpat-abcd1234 ~/projects"
    echo -e "\n  # Use HTTPS instead of SSH:"
    echo -e "  $0 --https ~/projects"
}

# Process command line arguments
process_args() {
    local current_platform=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -t|--test)
                TEST_MODE=true
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -n|--non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            -p|--platform)
                current_platform="$2"
                PLATFORMS["$current_platform"]=0
                shift 2
                ;;
            -u|--username)
                if [ -z "$current_platform" ]; then
                    echo -e "${RED}Error: --username must follow --platform${RESET}"
                    exit 1
                fi
                PLATFORM_USERNAMES["$current_platform"]="$2"
                shift 2
                ;;
            -k|--token)
                if [ -z "$current_platform" ]; then
                    echo -e "${RED}Error: --token must follow --platform${RESET}"
                    exit 1
                fi
                PLATFORM_TOKENS["$current_platform"]="$2"
                shift 2
                ;;
            --https)
                PROTOCOL="https"
                shift
                ;;
            *)
                # Assume it's the output directory
                OUTPUT_DIR="$1"
                shift
                ;;
        esac
    done

    # Validate non-interactive mode parameters
    if $NON_INTERACTIVE; then
        if [ ${#PLATFORMS[@]} -eq 0 ]; then
            echo -e "${RED}Error: Non-interactive mode requires at least one platform${RESET}"
            show_usage
            exit 1
        fi

        # Check if each platform has username and token
        for platform in "${!PLATFORMS[@]}"; do
            if [ -z "${PLATFORM_USERNAMES[$platform]}" ] || [ -z "${PLATFORM_TOKENS[$platform]}" ]; then
                echo -e "${RED}Error: Platform '$platform' is missing username or token${RESET}"
                show_usage
                exit 1
            fi
        done
    fi

    log "INFO" "Parameters processed. Output directory: $OUTPUT_DIR, Protocol: $PROTOCOL"
}

# Interactive platform selection
select_platforms() {
    echo -e "\n${CYAN}${BOLD}Available platforms:${RESET}"
    echo -e "  1) GitHub"
    echo -e "  2) GitLab"
    echo -e "  3) Bitbucket"
    echo -e "  4) Azure DevOps"
    echo -e "  5) Add custom Git hosting platform"

    local done_selecting=false

    while ! $done_selecting; do
        echo -e "\n${YELLOW}Select platforms to clone from (comma-separated numbers, e.g., '1,2'):${RESET}"
        read -r platform_selection

        IFS=',' read -ra SELECTIONS <<< "$platform_selection"

        for selection in "${SELECTIONS[@]}"; do
            case $selection in
                1)
                    PLATFORMS["github"]=0
                    echo -e "${GREEN}Added GitHub${RESET}"
                    ;;
                2)
                    PLATFORMS["gitlab"]=0
                    echo -e "${GREEN}Added GitLab${RESET}"
                    ;;
                3)
                    PLATFORMS["bitbucket"]=0
                    echo -e "${GREEN}Added Bitbucket${RESET}"
                    ;;
                4)
                    PLATFORMS["azure"]=0
                    echo -e "${GREEN}Added Azure DevOps${RESET}"
                    ;;
                5)
                    echo -e "${YELLOW}Enter custom platform name (e.g., 'gitea'):${RESET}"
                    read -r custom_platform
                    if [ -n "$custom_platform" ]; then
                        PLATFORMS["$custom_platform"]=0
                        echo -e "${GREEN}Added $custom_platform${RESET}"
                    fi
                    ;;
                *)
                    echo -e "${RED}Invalid selection: $selection${RESET}"
                    ;;
            esac
        done

        # Show selected platforms
        echo -e "\n${CYAN}${BOLD}Selected platforms:${RESET}"
        for platform in "${!PLATFORMS[@]}"; do
            echo -e "  - $platform"
        done

        # Ask if done selecting
        echo -e "\n${YELLOW}Add more platforms? (y/n):${RESET}"
        read -r add_more
        if [[ "$add_more" != "y" && "$add_more" != "Y" ]]; then
            done_selecting=true
        fi
    done

    # Ask for protocol preference
    echo -e "\n${YELLOW}Select protocol for cloning:${RESET}"
    echo -e "  1) SSH (default)"
    echo -e "  2) HTTPS"
    read -r protocol_selection

    if [[ "$protocol_selection" == "2" ]]; then
        PROTOCOL="https"
        echo -e "${GREEN}Using HTTPS protocol${RESET}"
    else
        PROTOCOL="ssh"
        echo -e "${GREEN}Using SSH protocol${RESET}"
    fi

    log "INFO" "Selected platforms: ${!PLATFORMS[*]}, Protocol: $PROTOCOL"
}

# Collect credentials for each platform
collect_credentials() {
    for platform in "${!PLATFORMS[@]}"; do
        echo -e "\n${CYAN}${BOLD}Enter credentials for $platform:${RESET}"

        # Get username
        echo -e "${YELLOW}Username:${RESET}"
        read -r username
        PLATFORM_USERNAMES["$platform"]="$username"

        # Get token (hiding input)
        echo -e "${YELLOW}Access Token:${RESET}"
        read -rs token
        PLATFORM_TOKENS["$platform"]="$token"
        echo -e "${GREEN}Token received${RESET}"

        log "INFO" "Collected credentials for $platform user: $username"
    done
}

# Function to validate API tokens
validate_token() {
    local platform=$1
    local username=$2
    local token=$3

    echo -e "${YELLOW}Testing $platform authentication...${RESET}"

    case $platform in
        "github")
            local response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $token" \
                "https://api.github.com/user")

            if [ "$response" -eq 200 ]; then
                echo -e "${GREEN}$platform authentication successful ✓${RESET}"
                log "SUCCESS" "$platform token is valid"
                return 0
            else
                echo -e "${RED}$platform authentication failed (HTTP $response) ✗${RESET}"
                log "ERROR" "$platform token validation failed with HTTP code $response"
                return 1
            fi
            ;;
        "gitlab")
            local response=$(curl -s -o /dev/null -w "%{http_code}" --header "Authorization: Bearer $token" \
                "https://gitlab.com/api/v4/user")

            if [ "$response" -eq 200 ]; then
                echo -e "${GREEN}$platform authentication successful ✓${RESET}"
                log "SUCCESS" "$platform token is valid"
                return 0
            else
                echo -e "${RED}$platform authentication failed (HTTP $response) ✗${RESET}"
                log "ERROR" "$platform token validation failed with HTTP code $response"
                return 1
            fi
            ;;
        "bitbucket")
            local response=$(curl -s -o /dev/null -w "%{http_code}" --user "$username:$token" \
                "https://api.bitbucket.org/2.0/user")

            if [ "$response" -eq 200 ]; then
                echo -e "${GREEN}$platform authentication successful ✓${RESET}"
                log "SUCCESS" "$platform token is valid"
                return 0
            else
                echo -e "${RED}$platform authentication failed (HTTP $response) ✗${RESET}"
                log "ERROR" "$platform token validation failed with HTTP code $response"
                return 1
            fi
            ;;
        "azure")
            local response=$(curl -s -o /dev/null -w "%{http_code}" --header "Authorization: Basic $(echo -n ":$token" | base64)" \
                "https://dev.azure.com/$username/_apis/projects?api-version=6.0")

            if [ "$response" -eq 200 ] || [ "$response" -eq 203 ]; then
                echo -e "${GREEN}$platform authentication successful ✓${RESET}"
                log "SUCCESS" "$platform token is valid"
                return 0
            else
                echo -e "${RED}$platform authentication failed (HTTP $response) ✗${RESET}"
                log "ERROR" "$platform token validation failed with HTTP code $response"
                return 1
            fi
            ;;
        *)
            echo -e "${YELLOW}No validation method for $platform, assuming token is valid${RESET}"
            log "WARNING" "No validation method for $platform, assuming token is valid"
            return 0
            ;;
    esac
}

# Function to clone repositories from GitHub
fetch_github_repos() {
    local username="${PLATFORM_USERNAMES["github"]}"
    local token="${PLATFORM_TOKENS["github"]}"
    local page=1
    local per_page=100
    local repos=()
    local response
    local repo_count=0
    local username_response

    echo -e "${YELLOW}${BOLD}Fetching GitHub repositories for $username...${RESET}"
    log "INFO" "Fetching GitHub repositories for $username"

    # Get user info
    username_response=$(curl -s -H "Authorization: token $token" "https://api.github.com/user")
    display_name=$(echo "$username_response" | jq -r '.name // .login')

    echo -e "${CYAN}Authenticated as:${RESET} $display_name"
    log "INFO" "GitHub authenticated as: $display_name"

    # Create github directory
    mkdir -p github || { log "ERROR" "Failed to create github directory"; return 1; }

    # Fetch user repositories with pagination
    while true; do
        echo -e "${CYAN}Fetching page $page...${RESET}"
        log "INFO" "Fetching GitHub repos page $page"

        response=$(curl -s -H "Authorization: token $token" \
            "https://api.github.com/user/repos?page=$page&per_page=$per_page&type=all&sort=updated")

        # Check if response is empty or has an error
        if [ "$(echo "$response" | jq '. | length')" == "0" ]; then
            log "INFO" "No more GitHub repositories found on page $page"
            break
        fi

        if [ "$(echo "$response" | jq 'has("message")')" == "true" ]; then
            error_msg=$(echo "$response" | jq -r '.message')
            echo -e "${RED}${BOLD}Error from GitHub API:${RESET} $error_msg"
            log "ERROR" "GitHub API error: $error_msg"
            break
        fi

        # Process repos on this page
        while read -r repo_url; do
            # Use SSH or HTTPS URL based on preference
            if [ "$PROTOCOL" == "https" ]; then
                repo_url=$(echo "$repo_url" | jq -r '.clone_url')
            else
                repo_url=$(echo "$repo_url" | jq -r '.ssh_url')
            fi
            repo_name=$(echo "$repo_url" | jq -r '.name')
            repos+=("$repo_url|$repo_name")
        done < <(echo "$response" | jq -c '.[]')

        # Move to next page
        ((page++))
    done

    echo -e "${GREEN}${BOLD}Found ${#repos[@]} GitHub repositories${RESET}"
    log "INFO" "Found ${#repos[@]} GitHub repositories"

    # Clone repositories
    cd github || { log "ERROR" "Failed to change to github directory"; return 1; }

    for repo_info in "${repos[@]}"; do
        # Parse repo info
        IFS='|' read -r repo_url repo_name <<< "$repo_info"

        echo -e "\n${MAGENTA}${BOLD}Processing GitHub repository:${RESET} $repo_name"
        log "INFO" "Processing GitHub repository: $repo_name"

        if $TEST_MODE; then
            echo -e "${YELLOW}TEST MODE:${RESET} Would clone $repo_name from $repo_url"
            log "INFO" "TEST MODE: Would clone $repo_name"
            ((repo_count++))
        else
            # Actually clone the repository
            echo -e "${CYAN}Cloning:${RESET} $repo_url"
            if git clone "$repo_url" "$repo_name"; then
                echo -e "${GREEN}Successfully cloned:${RESET} $repo_name"
                log "SUCCESS" "Cloned GitHub repository: $repo_name"
                ((repo_count++))
            else
                echo -e "${RED}Failed to clone:${RESET} $repo_name"
                log "ERROR" "Failed to clone GitHub repository: $repo_name"
            fi
        fi
    done

    cd .. || { log "ERROR" "Failed to change back from github directory"; return 1; }

    # Update platform count
    PLATFORMS["github"]=$repo_count

    echo -e "${GREEN}${BOLD}Cloned $repo_count GitHub repositories${RESET}"
    log "INFO" "Cloned $repo_count GitHub repositories"
}

# Function to clone repositories from GitLab
fetch_gitlab_repos() {
    local username="${PLATFORM_USERNAMES["gitlab"]}"
    local token="${PLATFORM_TOKENS["gitlab"]}"
    local page=1
    local per_page=100
    local repos=()
    local response
    local repo_count=0
    local username_response

    echo -e "\n${YELLOW}${BOLD}Fetching GitLab repositories for $username...${RESET}"
    log "INFO" "Fetching GitLab repositories for $username"

    # Get user info
    username_response=$(curl -s --header "Authorization: Bearer $token" "https://gitlab.com/api/v4/user")
    display_name=$(echo "$username_response" | jq -r '.name // .username')

    echo -e "${CYAN}Authenticated as:${RESET} $display_name"
    log "INFO" "GitLab authenticated as: $display_name"

    # Create gitlab directory
    mkdir -p gitlab || { log "ERROR" "Failed to create gitlab directory"; return 1; }

    # Fetch user repositories with pagination
    while true; do
        echo -e "${CYAN}Fetching page $page...${RESET}"
        log "INFO" "Fetching GitLab repos page $page"

        response=$(curl -s --header "Authorization: Bearer $token" \
            "https://gitlab.com/api/v4/projects?membership=true&page=$page&per_page=$per_page&order_by=updated_at")

        # Check if response is empty or has an error
        if [ "$(echo "$response" | jq '. | length')" == "0" ]; then
            log "INFO" "No more GitLab repositories found on page $page"
            break
        fi

        if [ "$(echo "$response" | jq 'has("message")')" == "true" ]; then
            error_msg=$(echo "$response" | jq -r '.message')
            echo -e "${RED}${BOLD}Error from GitLab API:${RESET} $error_msg"
            log "ERROR" "GitLab API error: $error_msg"
            break
        fi

        # Process repos on this page
        while read -r project; do
            # Use SSH or HTTPS URL based on preference
            local repo_url
            local repo_name

            if [ "$PROTOCOL" == "https" ]; then
                repo_url=$(echo "$project" | jq -r '.http_url_to_repo')
            else
                repo_url=$(echo "$project" | jq -r '.ssh_url_to_repo')
            fi

            repo_name=$(echo "$project" | jq -r '.name')
            repos+=("$repo_url|$repo_name")

        done < <(echo "$response" | jq -c '.[]')

        # Move to next page
        ((page++))
    done

    echo -e "${GREEN}${BOLD}Found ${#repos[@]} GitLab repositories${RESET}"
    log "INFO" "Found ${#repos[@]} GitLab repositories"

    # Clone repositories
    cd gitlab || { log "ERROR" "Failed to change to gitlab directory"; return 1; }

    for repo_info in "${repos[@]}"; do
        # Parse repo info
        IFS='|' read -r repo_url repo_name <<< "$repo_info"

        echo -e "\n${MAGENTA}${BOLD}Processing GitLab repository:${RESET} $repo_name"
        log "INFO" "Processing GitLab repository: $repo_name"

        if $TEST_MODE; then
            echo -e "${YELLOW}TEST MODE:${RESET} Would clone $repo_name from $repo_url"
            log "INFO" "TEST MODE: Would clone $repo_name"
            ((repo_count++))
        else
            # Actually clone the repository
            echo -e "${CYAN}Cloning:${RESET} $repo_url"
            if git clone "$repo_url" "$repo_name"; then
                echo -e "${GREEN}Successfully cloned:${RESET} $repo_name"
                log "SUCCESS" "Cloned GitLab repository: $repo_name"
                ((repo_count++))
            else
                echo -e "${RED}Failed to clone:${RESET} $repo_name"
                log "ERROR" "Failed to clone GitLab repository: $repo_name"
            fi
        fi
    done

    cd .. || { log "ERROR" "Failed to change back from gitlab directory"; return 1; }

    # Update platform count
    PLATFORMS["gitlab"]=$repo_count

    echo -e "${GREEN}${BOLD}Cloned $repo_count GitLab repositories${RESET}"
    log "INFO" "Cloned $repo_count GitLab repositories"
}

# Function to clone repositories from Bitbucket
fetch_bitbucket_repos() {
    local username="${PLATFORM_USERNAMES["bitbucket"]}"
    local token="${PLATFORM_TOKENS["bitbucket"]}"
    local page=1
    local page_size=100
    local repos=()
    local response
    local repo_count=0

    echo -e "\n${YELLOW}${BOLD}Fetching Bitbucket repositories for $username...${RESET}"
    log "INFO" "Fetching Bitbucket repositories for $username"

    # Create bitbucket directory
    mkdir -p bitbucket || { log "ERROR" "Failed to create bitbucket directory"; return 1; }

    # Fetch user repositories with pagination
    local next_url="https://api.bitbucket.org/2.0/repositories/$username?pagelen=$page_size&sort=-updated_on"

    while [ -n "$next_url" ]; do
        echo -e "${CYAN}Fetching page $page...${RESET}"
        log "INFO" "Fetching Bitbucket repos page $page"

        response=$(curl -s --user "$username:$token" "$next_url")

        # Check if response has an error
        if [ "$(echo "$response" | jq 'has("error")')" == "true" ]; then
            error_msg=$(echo "$response" | jq -r '.error.message')
            echo -e "${RED}${BOLD}Error from Bitbucket API:${RESET} $error_msg"
            log "ERROR" "Bitbucket API error: $error_msg"
            break
        fi

        # Process repos on this page
        while read -r value; do
            local repo_url
            local repo_name

            repo_name=$(echo "$value" | jq -r '.name')

            if [ "$PROTOCOL" == "https" ]; then
                repo_url=$(echo "$value" | jq -r '.links.clone[] | select(.name=="https") | .href')
            else
                repo_url=$(echo "$value" | jq -r '.links.clone[] | select(.name=="ssh") | .href')
            fi

            repos+=("$repo_url|$repo_name")

        done < <(echo "$response" | jq -c '.values[]')

        # Get next page URL
        next_url=$(echo "$response" | jq -r '.next // ""')

        # Move to next page
        ((page++))
    done

    echo -e "${GREEN}${BOLD}Found ${#repos[@]} Bitbucket repositories${RESET}"
    log "INFO" "Found ${#repos[@]} Bitbucket repositories"

    # Clone repositories
    cd bitbucket || { log "ERROR" "Failed to change to bitbucket directory"; return 1; }

    for repo_info in "${repos[@]}"; do
        # Parse repo info
        IFS='|' read -r repo_url repo_name <<< "$repo_info"

        echo -e "\n${MAGENTA}${BOLD}Processing Bitbucket repository:${RESET} $repo_name"
        log "INFO" "Processing Bitbucket repository: $repo_name"

        if $TEST_MODE; then
            echo -e "${YELLOW}TEST MODE:${RESET} Would clone $repo_name from $repo_url"
            log "INFO" "TEST MODE: Would clone $repo_name"
            ((repo_count++))
        else
            # Actually clone the repository
            echo -e "${CYAN}Cloning:${RESET} $repo_url"
            if git clone "$repo_url" "$repo_name"; then
                echo -e "${GREEN}Successfully cloned:${RESET} $repo_name"
                log "SUCCESS" "Cloned Bitbucket repository: $repo_name"
                ((repo_count++))
            else
                echo -e "${RED}Failed to clone:${RESET} $repo_name"
                log "ERROR" "Failed to clone Bitbucket repository: $repo_name"
            fi
        fi
    done

    cd .. || { log "ERROR" "Failed to change back from bitbucket directory"; return 1; }

    # Update platform count
    PLATFORMS["bitbucket"]=$repo_count

    echo -e "${GREEN}${BOLD}Cloned $repo_count Bitbucket repositories${RESET}"
    log "INFO" "Cloned $repo_count Bitbucket repositories"
}

# Function to clone repositories from Azure DevOps
fetch_azure_repos() {
    local username="${PLATFORM_USERNAMES["azure"]}"
    local token="${PLATFORM_TOKENS["azure"]}"
    local repos=()
    local response
    local repo_count=0

    echo -e "\n${YELLOW}${BOLD}Fetching Azure DevOps repositories for $username...${RESET}"
    log "INFO" "Fetching Azure DevOps repositories for $username"

    # Create azure directory
    mkdir -p azure || { log "ERROR" "Failed to create azure directory"; return 1; }

    # First, get all projects
    echo -e "${CYAN}Fetching projects...${RESET}"
    projects_response=$(curl -s --header "Authorization: Basic $(echo -n ":$token" | base64)" \
        "https://dev.azure.com/$username/_apis/projects?api-version=6.0")

    # Check if response has an error
    if [ "$(echo "$projects_response" | jq 'has("count")')" != "true" ]; then
        error_msg=$(echo "$projects_response" | jq -r '.message // "Unknown error"')
        echo -e "${RED}${BOLD}Error from Azure DevOps API:${RESET} $error_msg"
        log "ERROR" "Azure DevOps API error: $error_msg"
        return 1
    fi

    # Process all projects
    while read -r project; do
        project_name=$(echo "$project" | jq -r '.name')
        project_id=$(echo "$project" | jq -r '.id')

        echo -e "${CYAN}Fetching repositories for project:${RESET} $project_name"

        # Get all repositories for this project
        repos_response=$(curl -s --header "Authorization: Basic $(echo -n ":$token" | base64)" \
            "https://dev.azure.com/$username/$project_name/_apis/git/repositories?api-version=6.0")

        if [ "$(echo "$repos_response" | jq 'has("count")')" != "true" ]; then
            echo -e "${YELLOW}No repositories found or error for project:${RESET} $project_name"
            continue
        fi

        # Process all repositories in this project
        while read -r repo; do
            repo_name=$(echo "$repo" | jq -r '.name')

            if [ "$PROTOCOL" == "https" ]; then
                repo_url=$(echo "$repo" | jq -r '.remoteUrl')
            else
                # Azure DevOps SSH URL format: git@ssh.dev.azure.com:v3/{username}/{project}/{repo}
                repo_url="git@ssh.dev.azure.com:v3/$username/$project_name/$repo_name"
            fi

            repos+=("$repo_url|$repo_name|$project_name")

        done < <(echo "$repos_response" | jq -c '.value[]')

    done < <(echo "$projects_response" | jq -c '.value[]')

    echo -e "${GREEN}${BOLD}Found ${#repos[@]} Azure DevOps repositories${RESET}"
    log "INFO" "Found ${#repos[@]} Azure DevOps repositories"

    # Clone repositories
    cd azure || { log "ERROR" "Failed to change to azure directory"; return 1; }

    for repo_info in "${repos[@]}"; do
        # Parse repo info
        IFS='|' read -r repo_url repo_name project_name <<< "$repo_info"

        # Create project directory
        mkdir -p "$project_name" || { log "ERROR" "Failed to create project directory: $project_name"; continue; }

        echo -e "\n${MAGENTA}${BOLD}Processing Azure DevOps repository:${RESET} $project_name/$repo_name"
        log "INFO" "Processing Azure DevOps repository: $project_name/$repo_name"

        # Change to project directory
        cd "$project_name" || { log "ERROR" "Failed to change to project directory: $project_name"; continue; }

        if $TEST_MODE; then
            echo -e "${YELLOW}TEST MODE:${RESET} Would clone $repo_name from $repo_url"
            log "INFO" "TEST MODE: Would clone $repo_name"
            ((repo_count++))
        else
            # Actually clone the repository
            echo -e "${CYAN}Cloning:${RESET} $repo_url"
            if git clone "$repo_url" "$repo_name"; then
                echo -e "${GREEN}Successfully cloned:${RESET} $repo_name"
                log "SUCCESS" "Cloned Azure DevOps repository: $project_name/$repo_name"
                ((repo_count++))
            else
                echo -e "${RED}Failed to clone:${RESET} $repo_name"
                log "ERROR" "Failed to clone Azure DevOps repository: $project_name/$repo_name"
            fi
        fi

        # Go back to azure directory
        cd .. || { log "ERROR" "Failed to change back from project directory: $project_name"; }
    done

    cd .. || { log "ERROR" "Failed to change back from azure directory"; return 1; }

    # Update platform count
    PLATFORMS["azure"]=$repo_count

    echo -e "${GREEN}${BOLD}Cloned $repo_count Azure DevOps repositories${RESET}"
    log "INFO" "Cloned $repo_count Azure DevOps repositories"
}

# Function to clone from custom Git provider
fetch_custom_repos() {
    local platform=$1
    local username="${PLATFORM_USERNAMES[$platform]}"
    local token="${PLATFORM_TOKENS[$platform]}"
    local repo_count=0

    echo -e "\n${YELLOW}${BOLD}Setting up custom Git platform: $platform${RESET}"
    log "INFO" "Setting up custom Git platform: $platform"

    # Create platform directory
    mkdir -p "$platform" || { log "ERROR" "Failed to create $platform directory"; return 1; }
    cd "$platform" || { log "ERROR" "Failed to change to $platform directory"; return 1; }

    # For custom platforms, we'll prompt for manual repository entry
    echo -e "${CYAN}${BOLD}For custom platform $platform, you'll need to enter repositories manually.${RESET}"
    echo -e "${CYAN}Enter one repository URL per line. Leave empty to finish.${RESET}"

    local repos=()
    while true; do
        echo -e "${YELLOW}Enter repository URL (empty to finish):${RESET}"
        read -r repo_url

        if [ -z "$repo_url" ]; then
            break
        fi

        echo -e "${YELLOW}Enter repository name:${RESET}"
        read -r repo_name

        if [ -z "$repo_name" ]; then
            repo_name=$(basename "$repo_url" .git)
        fi

        repos+=("$repo_url|$repo_name")
    done

    echo -e "${GREEN}${BOLD}Added ${#repos[@]} $platform repositories${RESET}"
    log "INFO" "Added ${#repos[@]} $platform repositories manually"

    # Clone repositories
    for repo_info in "${repos[@]}"; do
        # Parse repo info
        IFS='|' read -r repo_url repo_name <<< "$repo_info"

        echo -e "\n${MAGENTA}${BOLD}Processing $platform repository:${RESET} $repo_name"
        log "INFO" "Processing $platform repository: $repo_name"

        if $TEST_MODE; then
            echo -e "${YELLOW}TEST MODE:${RESET} Would clone $repo_name from $repo_url"
            log "INFO" "TEST MODE: Would clone $repo_name"
            ((repo_count++))
        else
            # Actually clone the repository
            echo -e "${CYAN}Cloning:${RESET} $repo_url"

            # For custom platforms, we might need to add credentials if using HTTPS
            if [[ "$repo_url" == https://* ]] && [ -n "$username" ] && [ -n "$token" ]; then
                # Insert credentials into the URL
                repo_url=${repo_url/https:\/\//https:\/\/$username:$token@}
                echo -e "${CYAN}Added credentials to HTTPS URL${RESET}"
            fi

            if git clone "$repo_url" "$repo_name"; then
                echo -e "${GREEN}Successfully cloned:${RESET} $repo_name"
                log "SUCCESS" "Cloned $platform repository: $repo_name"
                ((repo_count++))
            else
                echo -e "${RED}Failed to clone:${RESET} $repo_name"
                log "ERROR" "Failed to clone $platform repository: $repo_name"
            fi
        fi
    done

    cd .. || { log "ERROR" "Failed to change back from $platform directory"; return 1; }

    # Update platform count
    PLATFORMS["$platform"]=$repo_count

    echo -e "${GREEN}${BOLD}Cloned $repo_count $platform repositories${RESET}"
    log "INFO" "Cloned $repo_count $platform repositories"
}

# Check for required dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${RESET}"
    log "INFO" "Checking dependencies"

    local missing_deps=false

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}${BOLD}Error: jq is required but not installed.${RESET}"
        echo -e "${CYAN}Install with:${RESET}"
        echo -e "  - Debian/Ubuntu: ${BOLD}sudo apt-get install jq${RESET}"
        echo -e "  - macOS: ${BOLD}brew install jq${RESET}"
        echo -e "  - CentOS/RHEL: ${BOLD}sudo yum install jq${RESET}"
        log "ERROR" "Missing dependency: jq"
        missing_deps=true
    else
        echo -e "${GREEN}jq is installed ✓${RESET}"
        log "INFO" "jq is installed"
    fi

    if ! command -v git &> /dev/null; then
        echo -e "${RED}${BOLD}Error: git is required but not installed.${RESET}"
        log "ERROR" "Missing dependency: git"
        missing_deps=true
    else
        echo -e "${GREEN}git is installed ✓${RESET}"
        log "INFO" "git is installed"
    fi

    if ! command -v curl &> /dev/null; then
        echo -e "${RED}${BOLD}Error: curl is required but not installed.${RESET}"
        log "ERROR" "Missing dependency: curl"
        missing_deps=true
    else
        echo -e "${GREEN}curl is installed ✓${RESET}"
        log "INFO" "curl is installed"
    fi

    if $missing_deps; then
        return 1
    else
        return 0
    fi
}

# Print summary
print_summary() {
    local total_count=0
    local elapsed=$(($(date +%s) - start_time))

    # Format elapsed time
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))

    echo -e "\n${BLUE}${BOLD}====================================================${RESET}"
    echo -e "${GREEN}${BOLD}Cloning process completed!${RESET}"

    # Show counts for each platform
    for platform in "${!PLATFORMS[@]}"; do
        local count="${PLATFORMS[$platform]}"
        echo -e "${CYAN}$platform repositories:${RESET} ${BOLD}$count${RESET}"
        total_count=$((total_count + count))
    done

    echo -e "${CYAN}Total repositories:${RESET} ${BOLD}$total_count${RESET}"
    echo -e "${CYAN}Time elapsed:${RESET} ${BOLD}${minutes}m ${seconds}s${RESET}"
    echo -e "${CYAN}All repositories saved in:${RESET} ${BOLD}$(pwd)${RESET}"
    echo -e "${CYAN}Log file:${RESET} ${BOLD}$LOG_FILE${RESET}"
    echo -e "${CYAN}Copyright © $(date +%Y) Antonin Nvh - https://codequantum.io${RESET}"
    echo -e "${BLUE}${BOLD}====================================================${RESET}"

    log "INFO" "Process completed. Total: $total_count"
    log "INFO" "Time elapsed: ${minutes}m ${seconds}s"
}

# Main execution
start_time=$(date +%s)

# Process command line arguments
process_args "$@"

# Display banner
show_banner

# Check dependencies
check_dependencies || {
    echo -e "${RED}${BOLD}Missing required dependencies. Exiting.${RESET}";
    exit 1;
}

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR" || {
    echo -e "${RED}${BOLD}Failed to create output directory: $OUTPUT_DIR${RESET}";
    exit 1;
}
cd "$OUTPUT_DIR" || {
    echo -e "${RED}${BOLD}Failed to change to output directory: $OUTPUT_DIR${RESET}";
    exit 1;
}

# Interactive mode to select platforms and collect credentials
if ! $NON_INTERACTIVE; then
    select_platforms
    collect_credentials
fi

# Validate tokens for each platform
for platform in "${!PLATFORMS[@]}"; do
    validate_token "$platform" "${PLATFORM_USERNAMES[$platform]}" "${PLATFORM_TOKENS[$platform]}" || {
        echo -e "${YELLOW}${BOLD}Warning: $platform token validation failed, but proceeding anyway...${RESET}"
        log "WARNING" "$platform token validation failed, but proceeding anyway"
    }
done

# Clone repositories from each platform
for platform in "${!PLATFORMS[@]}"; do
    case $platform in
        "github")
            fetch_github_repos
            ;;
        "gitlab")
            fetch_gitlab_repos
            ;;
        "bitbucket")
            fetch_bitbucket_repos
            ;;
        "azure")
            fetch_azure_repos
            ;;
        *)
            # For custom platforms
            fetch_custom_repos "$platform"
            ;;
    esac
done

# Print summary
print_summary

log "INFO" "Script finished successfully"
exit 0