#!/bin/bash
set -e

# Function to print usage information
show_usage() {
    echo "Usage: $0 [command] [arguments] [options]"
    echo ""
    echo "Commands:"
    echo "  bridge-to-mev-commit [Sepolia URL] [MEV-Commit Chain URL] Bridge tokens to MEV-Commit Chain"
    echo "  bridge-to-sepolia [MEV-Commit Chain URL] [Sepolia URL] Bridge tokens to Sepolia"
    echo ""
    echo "Options:"
    echo "  -y, --yes   Automatically answer 'yes' to all prompts"
    echo ""
}

# Function for user confirmation
confirm_operation() {
    if [ "$skip_confirmation" = false ]; then
        local source_chain=$1
        local destination_chain=$2
        local source_url=$3
        local destination_url=$4

        echo "You are about to bridge from $source_chain to $destination_chain."
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
    confirm_operation "Sepolia" "MEV-Commit Chain" "$1" "$2"
    echo "Bridging to MEV-Commit Chain..."
    # Add specific logic for bridging to MEV-Commit Chain
}

# Bridge to Sepolia
bridge_to_sepolia() {
    confirm_operation "MEV-Commit Chain" "Sepolia" "$1" "$2"
    echo "Bridging to Sepolia..."
    # Add specific logic for bridging to Sepolia
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
    bridge-to-mev-commit)
        if [ $# -ne 3 ]; then
            echo "Error: Incorrect number of arguments for bridging to MEV-Commit Chain."
            show_usage
            exit 1
        fi
        bridge_to_mev_commit "$2" "$3"
        ;;
    bridge-to-sepolia)
        if [ $# -ne 3 ]; then
            echo "Error: Incorrect number of arguments for bridging to Sepolia."
            show_usage
            exit 1
        fi
        bridge_to_sepolia "$2" "$3"
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
