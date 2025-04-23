#!/bin/bash

# Script to move an exercise from active to retired

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 exercise_name"
    exit 1
fi

EXERCISE_NAME="$1"
ACTIVE_DIR="exercises/active"
RETIRED_DIR="exercises/retired"

if [ ! -d "$ACTIVE_DIR/$EXERCISE_NAME" ]; then
    echo "Error: Exercise $EXERCISE_NAME does not exist in active directory."
    exit 1
fi

# Create retired directory if it doesn't exist
mkdir -p "$RETIRED_DIR"

# Add timestamp to README.md
if [ -f "$ACTIVE_DIR/$EXERCISE_NAME/README.md" ]; then
    echo -e "\n## Completed\nRetired on: $(date)" >> "$ACTIVE_DIR/$EXERCISE_NAME/README.md"
fi

# Move the exercise
mv "$ACTIVE_DIR/$EXERCISE_NAME" "$RETIRED_DIR/"

echo "Exercise $EXERCISE_NAME has been retired."
echo "You can activate it again with: ./scripts/activate.sh $EXERCISE_NAME"
