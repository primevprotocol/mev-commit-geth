#!/bin/bash
set -e

# Define the configuration file path
config_file=".bridge_config"

# Function to print usage information
show_usage() {
    echo "Usage: $0 [command] [arguments] [options]"
    echo ""
    echo "Commands:"
    echo "  bridge-to-mev-commit <amount> <dest_addr> <private_key>"
    echo "    Bridge tokens to MEV-Commit Chain. Requires the amount to bridge, destination account, and private key."
    echo "    Example: $0 bridge-to-mev-commit 100 0x123... 0xABC..."
    echo ""
    echo "  bridge-to-l1 <amount> <dest_addr> <private_key>"
    echo "    Bridge tokens to L1. Requires the amount to bridge, destination account, and private key."
    echo "    Example: $0 bridge-to-l1 100 0x456... 0xDEF..."
    echo ""
    echo "  init <L1 Router> <MEV-Commit Chain Router> <L1 Chain ID> <MEV-Commit Chain ID> <L1 URL> <MEV-Commit URL>"
    echo "    Initialize configuration with specified hyperlane router addresses, chain IDs, and URLs."
    echo "    Example: $0 init 0xc20B3C7852FA81f36130313220890eA7Ea5F5B0e 0x4b2DC8A5C4da51f821390AbD2B6fe8122BC6fA97 11155111 17864 https://ethereum-sepolia.publicnode.com http://localhost:8545"
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
        local source_url=$5
        local dest_url=$6
        local source_router=$7
        local dest_router=$8
        local amount=$9
        local dest_address=${10} # Arguments after $9 must be accessed with braces

        echo "You are about to bridge..."
        echo "From $source_chain_name (ID: $source_chain_id, URL: $source_url, Router: $source_router)"
        echo "To $dest_chain_name (ID: $dest_chain_id, URL: $dest_url, Router: $dest_router)"
        echo "Amount to bridge: $amount"
        echo "Destination address: $dest_address"
        read -p "Are you sure you want to proceed with the bridging operation? (y/n): " answer
        if [ "$answer" != "y" ]; then
            echo "Operation cancelled."
            exit 1
        fi
    fi
}

check_config_loaded() {
    local config_vars=("l1_router" "mev_commit_chain_router" "l1_chain_id" "mev_commit_chain_id" "l1_url" "mev_commit_url")

    for var in "${config_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: Configuration for '$var' not loaded."
            echo "Please run the init command to set up the necessary configuration."
            exit 1
        fi
    done
}

# Bridge to MEV-Commit Chain
bridge_to_mev_commit() {
    local amount=$1
    local dest_address=$2
    local private_key=$3

    check_config_loaded

    bridge_confirmation \
        "L1" \
        "MEV-Commit Chain" \
        "$l1_chain_id" \
        "$mev_commit_chain_id" \
        "$l1_url" \
        "$mev_commit_url" \
        "$l1_router" \
        "$mev_commit_chain_router" \
        "$amount" \
        "$dest_address"

    echo "Bridging to MEV-Commit Chain..."
    echo "Amount: $amount"
    echo "Destination Address: $dest_address"
    echo "Using L1 Router: $l1_router"
    echo "Using MEV-Commit Chain Router: $mev_commit_chain_router"
    echo "L1 Chain ID: $l1_chain_id"
    echo "MEV-Commit Chain ID: $mev_commit_chain_id"
    echo "L1 URL: $l1_url"
    echo "MEV-Commit URL: $mev_commit_url"

    dest_init_balance=$(cast balance --rpc-url $mev_commit_url $dest_address)

    cast call --rpc-url $l1_url $l1_router "quoteGasPayment(uint32)" $mev_commit_chain_id
    # Above returns 1 wei, therefore ether value is 1 wei larger than value function argument
    # TODO: Do addition here, also input address as bytes
    cast send \
        --rpc-url $l1_url \
        --private-key $private_key \
        $l1_router "transferRemote(uint32,bytes32,uint256)" \
        $mev_commit_chain_id \
        "0x000000000000000000000000a43b806d2f09ae94dfa38bc00d6f75426d274540" \
        "5000000000000000" \
        --value 5000000000000001wei

    # Block until dest balance is incremented
    max_retries=30
    retry_count=0
    while [ $(printf '%d' "$(cast balance --rpc-url "$mev_commit_url" "$dest_address")") -eq $(printf '%d' "$dest_init_balance") ]
    do
        echo "Waiting for destination balance to increment..."
        sleep 5
        retry_count=$((retry_count + 1))
        if [ "$retry_count" -ge "$max_retries" ]; then
            echo "Maximum retries reached"
            exit 1
        fi
    done
    echo "Bridge operation completed successfully."
    exit 0
}


# Bridge to L1
bridge_to_l1() {
    local amount=$1
    local dest_address=$2
    local private_key=$3

    check_config_loaded

    bridge_confirmation \
        "MEV-Commit Chain" \
        "L1" \
        "$mev_commit_chain_id" \
        "$l1_chain_id" \
        "$mev_commit_url" \
        "$l1_url" \
        "$mev_commit_chain_router" \
        "$l1_router" \
        "$amount" \
        "$dest_address"

    echo "Bridging to L1..."
    echo "Amount: $amount"
    echo "Destination Address: $dest_address"
    echo "Using MEV-Commit Chain Router: $mev_commit_chain_router"
    echo "Using L1 Router: $l1_router"
    echo "MEV-Commit Chain ID: $mev_commit_chain_id"
    echo "L1 Chain ID: $l1_chain_id"
    echo "MEV-Commit URL: $mev_commit_url"
    echo "L1 URL: $l1_url"

    dest_init_balance=$(cast balance --rpc-url $l1_url $dest_address)

    cast call --rpc-url $mev_commit_url $mev_commit_chain_router "quoteGasPayment(uint32)" $l1_chain_id
    # Above returns 0 wei, therefore ether value is same as function argument
    # TODO: Do addition here, also input address as bytes
    cast send \
        --rpc-url $mev_commit_url \
        --private-key $private_key \
        $mev_commit_chain_router "transferRemote(uint32,bytes32,uint256)" \
        $l1_chain_id \
        "0x000000000000000000000000a43b806d2f09ae94dfa38bc00d6f75426d274540" \
        "5000000000000000" \
        --value 5000000000000000wei
    
    # Block until dest balance is incremented
    max_retries=30
    retry_count=0
    while [ $(printf '%d' "$(cast balance --rpc-url "$l1_url" "$dest_address")") -eq $(printf '%d' "$dest_init_balance") ]
    do
        echo "Waiting for destination balance to increment..."
        sleep 5
        retry_count=$((retry_count + 1))
        if [ "$retry_count" -ge "$max_retries" ]; then
            echo "Maximum retries reached"
            exit 1
        fi
    done
    echo "Bridge operation completed successfully."
    exit 0
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