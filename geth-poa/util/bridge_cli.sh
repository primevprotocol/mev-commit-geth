#!/bin/bash
set -e

show_usage() {
    echo "Usage: $0 [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  bridge-to-mev-commit  [Sepolia URL] [MEV-Commit Chain URL]  Bridge tokens to MEV-Commit Chain"
    echo "  bridge-to-sepolia     [MEV-Commit Chain URL] [Sepolia URL]  Bridge tokens to Sepolia"
    echo ""
}

confirm_operation() {
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
}

bridge_to_mev_commit() {
    sepolia_url=$1
    mev_commit_chain_url=$2

    confirm_operation "Sepolia" "mev-commit chain" "$sepolia_url" "$mev_commit_chain_url"
    echo "Bridging to MEV-Commit Chain..."
}

bridge_to_sepolia() {
    mev_commit_chain_url=$1
    sepolia_url=$2

    confirm_operation "mev-commit chain" "Sepolia" "$mev_commit_chain_url" "$sepolia_url"
    echo "Bridging to Sepolia..."
}

# Check if at least 2 arguments are provided
if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

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
