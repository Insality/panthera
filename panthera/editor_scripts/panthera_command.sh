#!/bin/bash

# Panthera Editor Port
PORT=16114

CURRENT_DIR=$(pwd)

# Check if the port is open
if nc -z localhost "$PORT" &>/dev/null; then
	# The port is open and we ready to send commands
	echo "Panthera port $PORT is open, sending command..."
	echo "Current dir: $CURRENT_DIR"
	echo "Args: $@"

	# Send command to Panthera
	command_type=$1
	# The $2 is a relative path to the file, concat it with current dir
	path="$CURRENT_DIR$2"

	if [ "$command_type" == "open" ]; then
		# Open animation file
		JSON_PAYLOAD="{\"command\": \"open\", \"path\": \"$path\"}"
		echo "Send command: $JSON_PAYLOAD"
		echo "$JSON_PAYLOAD" | nc -w 5 localhost "$PORT" &
	elif [ "$command_type" == "create" ]; then
		# Create gui file
		JSON_PAYLOAD="{\"command\": \"create\", \"path\": \"$path\"}"
		echo "Send command: $JSON_PAYLOAD"
		echo "$JSON_PAYLOAD" | nc -w 5 localhost "$PORT" &
	fi
else
	echo "Port $PORT is closed."
	# Panthera is not found
	echo "Panthera should be started first."
	echo "If you don't have Panthera, download it at:"
	echo "Download Panthera at: https://github.com/Insality/panthera"
fi