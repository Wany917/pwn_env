#!/bin/bash

# Script to move an exercise from retired to active

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 exercise_name"
    exit 1
fi

EXERCISE_NAME="$1"
ACTIVE_DIR="exercises/active"
RETIRED_DIR="exercises/retired"

if [ ! -d "$RETIRED_DIR/$EXERCISE_NAME" ]; then
    echo "Error: Exercise $EXERCISE_NAME does not exist in retired directory."
    exit 1
fi

# Create active directory if it doesn't exist
mkdir -p "$ACTIVE_DIR"

# Add reactivation note to README.md
if [ -f "$RETIRED_DIR/$EXERCISE_NAME/README.md" ]; then
    echo -e "\n## Reactivated\nReactivated on: $(date)" >> "$RETIRED_DIR/$EXERCISE_NAME/README.md"
fi

# Move the exercise
mv "$RETIRED_DIR/$EXERCISE_NAME" "$ACTIVE_DIR/"

echo "Exercise $EXERCISE_NAME has been activated."
echo "You can retire it again with: ./scripts/retire.sh $EXERCISE_NAME"
