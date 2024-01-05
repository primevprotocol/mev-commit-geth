#!/bin/bash
set -e

# Define the configuration file path
config_file=".bridge_config"

# Function to print usage information
show_usage() {
    echo "Usage: $0 [command] [arguments] [options]"
    echo ""
    echo "Commands:"
    echo "  bridge-to-mev-commit <amount> <dest_account> <private_key>"
    echo "    Bridge tokens to MEV-Commit Chain. Requires the amount to bridge, destination account, and private key."
    echo "    Example: $0 bridge-to-mev-commit 100 0x123... 0xABC..."
    echo ""
    echo "  bridge-to-l1 <amount> <dest_account> <private_key>"
    echo "    Bridge tokens to L1. Requires the amount to bridge, destination account, and private key."
    echo "    Example: $0 bridge-to-l1 100 0x456... 0xDEF..."
    echo ""
    echo "  init <L1 Router> <MEV-Commit Chain Router> <L1 Chain ID> <MEV-Commit Chain ID> <L1 URL> <MEV-Commit URL>"
    echo "    Initialize configuration with specified hyperlane router addresses, chain IDs, and URLs."
    echo "    Example: $0 init 0x1234 0x5678 123 345 http://l1-url http://mev-commit-chain-url"
    echo ""
    echo "Options:"
    echo "  -y, --yes   Automatically answer 'yes' to all prompts"
    echo "    Example: $0 bridge-to-mev-commit 100 0x123... 0xABC... -y"
    echo ""
}

# Function for user confirmation
bridge_confirmation() {
    if [ "$skip_confirmation" = false ]; then
        local source_chain_name=$1
        local dest_chain_name=$2
        local source_chain_id=$3
        local dest_chain_id=$4
        local amount=$5
        local dest_account=$6

        echo "You are about to bridge from $source_chain_name (ID: $source_chain_id) to $dest_chain_name (ID: $dest_chain_id)."
        echo "Amount to bridge: $amount"
        echo "Destination account: $dest_account"
        read -p "Are you sure you want to proceed? (y/n): " answer
        if [ "$answer" != "y" ]; then
            echo "Operation cancelled."
            exit 1
        fi
    fi
}


# Bridge to MEV-Commit Chain
bridge_to_mev_commit() {
    local amount=$1
    local dest_account=$2
    local private_key=$3

    # Ensure configuration is loaded
    if [ -z "$l1_router" ] || [ -z "$mev_commit_chain_id" ] || [ -z "$l1_url" ]; then
        echo "Error: Configuration not loaded. Run the init command first."
        exit 1
    fi

    bridge_confirmation "L1" "MEV-Commit Chain" "$l1_chain_id" "$mev_commit_chain_id" "$amount" "$dest_account"
    echo "Bridging to MEV-Commit Chain..."
    echo "Amount: $amount"
    echo "Destination Account: $dest_account"
    echo "Using L1 Router: $l1_router"
    echo "Using MEV-Commit Chain ID: $mev_commit_chain_id"
    # Add specific logic for bridging to MEV-Commit Chain
}


# Bridge to L1
bridge_to_l1() {
    local amount=$1
    local dest_account=$2
    local private_key=$3

    # Ensure configuration has loaded neccessary vars
    if [ -z "$mev_commit_chain_router" ] || [ -z "$l1_chain_id" ] || [ -z "$mev_commit_url" ]; then
        echo "Error: Configuration not loaded. Run the init command first."
        exit 1
    fi

    bridge_confirmation "MEV-Commit Chain" "L1" "$mev_commit_chain_id" "$l1_chain_id" "$amount" "$dest_account"
    echo "Bridging to L1..."
    echo "Amount: $amount"
    echo "Destination Account: $dest_account"
    echo "Using MEV-Commit Chain Router: $mev_commit_chain_router"
    echo "Using L1 Chain ID: $l1_chain_id"
    # Add specific logic for bridging to L1
}


# Function to initialize and save configuration
init_config() {
    local l1_router=$1
    local mev_commit_chain_router=$2
    local l1_chain_id=$3
    local mev_commit_chain_id=$4
    local l1_url=$5
    local mev_commit_url=$6

    # Confirmation prompt
    if [ "$skip_confirmation" = false ]; then
        echo "You are about to initialize the configuration with the following settings:"
        echo "L1 Router: $l1_router"
        echo "MEV-Commit Chain Router: $mev_commit_chain_router"
        echo "L1 Chain ID: $l1_chain_id"
        echo "MEV-Commit Chain ID: $mev_commit_chain_id"
        echo "L1 URL: $l1_url"
        echo "MEV-Commit URL: $mev_commit_url"
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
        --arg mev_commit_chain_id "$mev_commit_chain_id" \
        --arg l1_url "$l1_url" \
        --arg mev_commit_url "$mev_commit_url" \
        '{l1_router: $l1_router, mev_commit_chain_router: $mev_commit_chain_router, l1_chain_id: $l1_chain_id, mev_commit_chain_id: $mev_commit_chain_id, l1_url: $l1_url, mev_commit_url: $mev_commit_url}' \
        > "$config_file"

    echo "Configuration initialized and saved."
}


# Function to load configuration from JSON file
load_config() {
    if [ -f "$config_file" ]; then
        l1_router=$(jq -r '.l1_router' "$config_file")
        mev_commit_chain_router=$(jq -r '.mev_commit_chain_router' "$config_file")
        l1_chain_id=$(jq -r '.l1_chain_id' "$config_file")
        mev_commit_chain_id=$(jq -r '.mev_commit_chain_id' "$config_file")
        l1_url=$(jq -r '.l1_url' "$config_file")
        mev_commit_url=$(jq -r '.mev_commit_url' "$config_file")
    else
        echo "Error: Configuration file not found. Please run the init command first."
        exit 1
    fi
}


# Check if the first argument is 'init'. If not, load configuration.
if [[ "$1" != "init" ]]; then
    load_config
fi

# Check if the last argument is --yes or -y
skip_confirmation=false
if [[ "${@: -1}" == "--yes" || "${@: -1}" == "-y" ]]; then
    skip_confirmation=true
    set -- "${@:1:$#-1}"  # Remove the last argument
fi

# Main command switch
command=$1
shift  # Shift to get the next set of parameters after the command

case "$command" in
    init)
        if [ $# -ne 6 ]; then
            echo "Error: Incorrect number of arguments for init command."
            show_usage
            exit 1
        fi
        init_config "$1" "$2" "$3" "$4" "$5" "$6"
        ;;
    bridge-to-mev-commit)
        if [ $# -ne 3 ]; then
            echo "Error: Incorrect number of arguments for bridging to MEV-Commit Chain."
            show_usage
            exit 1
        fi
        bridge_to_mev_commit "$1" "$2" "$3"
        ;;
    bridge-to-l1)
        if [ $# -ne 3 ]; then
            echo "Error: Incorrect number of arguments for bridging to L1."
            show_usage
            exit 1
        fi
        bridge_to_l1 "$1" "$2" "$3"
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