#!/bin/bash

# Directory containing the videos
input_dir="source_video"

# Output directory for the converted videos (optional)
output_dir="video"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Iterate through each .mov file in the input directory
for input_file in "$input_dir"/*.mov; do
	# Check if the file exists (e.g., if there are no .mov files, the loop won't run)
	if [[ ! -f "$input_file" ]]; then continue; fi

	# Get the base name of the file (without extension)
	base_name=$(basename "$input_file" .mov)

	# Define the output file path (converted video)
	output_file="$output_dir/$base_name.mp4"

	# Run FFmpeg command to convert the video
	ffmpeg -i "$input_file" -vf "scale=1280:-1" -c:v libx264 -preset slow -crf 22 -an "$output_file"

	# Check if the conversion was successful
	if [ $? -eq 0 ]; then
		echo "Successfully converted $input_file to $output_file"
	else
		echo "Failed to convert $input_file"
	fi
done
