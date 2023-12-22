##!/bin/sh

# Check the folder name to be used
TRACE_FOLDER="traces"

# Check if the folder exists, if not, create it
if [ ! -d "$TRACE_FOLDER" ]; then
    mkdir "$TRACE_FOLDER"
fi

# Get the number of the last trace file
LAST_TRACE=$(ls -v "$TRACE_FOLDER" | grep "trace_without_tx_" | tail -n 1 | awk -F '_' '{print $4}' | awk -F '.' '{print $1}')

# If no file exists, set the default value to 0
if [ -z "$LAST_TRACE" ]; then
    LAST_TRACE=0
fi

# Determine the number for the next trace file
NEXT_TRACE=$((LAST_TRACE + 1))

# Create the name for the trace file
TRACE_FILE="$TRACE_FOLDER/trace_without_tx_$NEXT_TRACE.out"

# Create the trace file and execute the commands
curl 172.13.0.100:8080/start-trace
curl 172.13.0.100:8080/stop-trace
curl 172.13.0.100:8080/read-trace > "$TRACE_FILE"

# Print the iteration information to the console
echo "Created trace file: $TRACE_FILE"
