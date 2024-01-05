#!/bin/bash
set -e

# Define the configuration file path
config_file=".bridge_config"

# Function to print usage information
show_usage() {
    echo "Usage: $0 [command] [arguments] [options]"
    echo ""
    echo "Commands:"
    echo "  bridge-to-mev-commit [L1 URL] [MEV-Commit Chain URL]  Bridge tokens to MEV-Commit Chain"
    echo "    Example: $0 bridge-to-mev-commit http://l1-url http://mev-commit-chain-url"
    echo ""
    echo "  bridge-to-l1 [MEV-Commit Chain URL] [L1 URL]  Bridge tokens to L1"
    echo "    Example: $0 bridge-to-l1 http://mev-commit-chain-url http://l1-url"
    echo ""
    echo "  init <L1 Router> <MEV-Commit Chain Router> <L1 Chain ID>"
    echo "    Initialize configuration with specified router addresses and chain ID"
    echo "    Example: $0 init 0xL1RouterAddress 0xMEVCommitChainRouter 5"
    echo ""
    echo "Options:"
    echo "  -y, --yes   Automatically answer 'yes' to all prompts"
    echo "    Example: $0 bridge-to-mev-commit http://l1-url http://mev-commit-chain-url -y"
    echo ""
}

# Function for user confirmation
confirm_operation() {
    if [ "$skip_confirmation" = false ]; then
        local source_chain=$1
        local destination_chain=$2
        local source_url=$3
        local destination_url=$4

        echo "You are about to bridge from $source_chain (source) to $destination_chain (destination)."
        echo "Source URL: $source_url"
        echo "Destination URL: $destination_url"
        read -p "Are you sure you want to proceed? (y/n): " answer
        if [ "$answer" != "y" ]; then
            echo "Operation cancelled."
            exit 1
        fi
    fi
}

# Bridge to MEV-Commit Chain
bridge_to_mev_commit() {
    confirm_operation "L1" "MEV-Commit Chain" "$1" "$2"
    echo "Bridging to MEV-Commit Chain..."
    # Add specific logic for bridging to MEV-Commit Chain
}

# Bridge to L1
bridge_to_l1() {
    confirm_operation "MEV-Commit Chain" "L1" "$1" "$2"
    echo "Bridging to L1..."
    # Add specific logic for bridging to L1
}

# Function to initialize and save configuration
init_config() {

    local l1_router=$1
    local mev_commit_chain_router=$2
    local l1_chain_id=$3

    # Confirmation prompt
    if [ "$skip_confirmation" = false ]; then
        echo "You are about to initialize the configuration with the following settings:"
        echo "L1 Router: $l1_router"
        echo "MEV-Commit Chain Router: $mev_commit_chain_router"
        echo "L1 Chain ID: $l1_chain_id"
        read -p "Are you sure you want to proceed? (y/n): " answer
        if [ "$answer" != "y" ]; then
            echo "Operation cancelled."
            exit 1
        fi
    fi

    # Create JSON config and save to file
    jq -n \
        --arg l1_router "$l1_router" \
        --arg mev_commit_chain_router "$mev_commit_chain_router" \
        --arg l1_chain_id "$l1_chain_id" \
        '{l1_router: $l1_router, mev_commit_chain_router: $mev_commit_chain_router, l1_chain_id: $l1_chain_id}' \
        > "$config_file"

    echo "Configuration initialized and saved."
}

# Function to load configuration from JSON file
load_config() {
    if [ -f "$config_file" ]; then
        l1_router=$(jq -r '.l1_router' "$config_file")
        mev_commit_chain_router=$(jq -r '.mev_commit_chain_router' "$config_file")
        l1_chain_id=$(jq -r '.l1_chain_id' "$config_file")
    else
        echo "Error: Configuration file not found. Please run the init command first."
        exit 1
    fi
}

# Parse global options for --yes
skip_confirmation=false
if [[ "$4" == "-y" || "$4" == "--yes" ]]; then
    skip_confirmation=true
    set -- "$1" "$2" "$3" # Rebuild positional parameters without the --yes flag
fi

# Main command switch
command=$1
case "$command" in
    init)
        if [ $# -ne 4 ]; then
            echo "Error: Incorrect number of arguments for init command."
            show_usage
            exit 1
        fi
        init_config "$2" "$3" "$4"
        ;;
    bridge-to-mev-commit)
        if [ $# -ne 3 ]; then
            echo "Error: Incorrect number of arguments for bridging to MEV-Commit Chain."
            show_usage
            exit 1
        fi
        bridge_to_mev_commit "$2" "$3"
        ;;
    bridge-to-l1)
        if [ $# -ne 3 ]; then
            echo "Error: Incorrect number of arguments for bridging to L1."
            show_usage
            exit 1
        fi
        bridge_to_l1 "$2" "$3"
        ;;
    -h|--help)
        show_usage
        ;;
    *)
        echo "Unknown command: $command"
        show_usage
        exit 1
        ;;
esac
