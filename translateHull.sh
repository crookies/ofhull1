#!/bin/bash
# -----------------------------------------------------------------------------
# Script to extract the Draft (T) from initialConditions and translate a mesh.
# -----------------------------------------------------------------------------

# --- 1. Define File Paths ---
# Assuming initialConditions is in 'system' and the STL is in 'constant/triSurface'
IC_FILE="system/initialConditions"
INPUT_STL="constant/triSurface/source_hull.stl"
OUTPUT_STL="constant/triSurface/sink_hull.stl"



# Check file existence
if [ ! -f "$IC_FILE" ]; then
    echo "Error: Initial conditions file not found at $IC_FILE"
    exit 1
fi
if [ ! -f "$INPUT_STL" ]; then
    echo "Error: Input STL file not found at $INPUT_STL"
    exit 1
fi

# --- 2. Extract the Draft (T) Value, ignoring comments ---

# Awk logic:
# 1. Use a flag (in_comment) to track if we are inside a /* ... */ block.
# 2. Skip printing or processing if inside a comment block.
# 3. For uncommented lines, match the key 'T' (allowing leading spaces).
# 4. Print the value (second field) and strip the semicolon.
T_DRAFT=$(awk '
    # Logic to track multi-line /* ... */ comments
    /^\/\*/ { in_comment = 1; next }
    in_comment && /\*\// { in_comment = 0; next }
    in_comment { next }

    # Logic to skip single-line // comments
    /^\/\// { next }

    # Match the 'T' key and extract its value (second field)
    /^[[:space:]]*T[[:space:]]/ {
        # Print the second field and then exit awk immediately
        gsub(";", "", $2); # Clean up the semicolon from the value
        print $2;
        exit;
    }
' "$IC_FILE")

# Check if the value was successfully extracted
if [ -z "$T_DRAFT" ]; then
    echo "Error: Could not reliably extract 'T' (Draft) parameter from $IC_FILE. Check its format."
    exit 1
fi

echo "Successfully extracted Draft (T): $T_DRAFT"

# --- 3. Define the Translation Vector ---
# The required translation is a negative value of T along the Z-axis.
TRANSLATION_VECTOR="(0 0 -$T_DRAFT)"

echo "Translation vector: $TRANSLATION_VECTOR"

# --- 4. Perform the Mesh Translation ---
echo "Translating mesh $INPUT_STL to $OUTPUT_STL..."
surfaceTransformPoints -translate "$TRANSLATION_VECTOR" "$INPUT_STL" "$OUTPUT_STL"

if [ $? -eq 0 ]; then
    echo "--- SUCCESS ---"
    echo "Mesh successfully translated by $T_DRAFT in the negative Z direction."
else
    echo "--- ERROR ---"
    echo "surfaceTransformPoints failed. Check OpenFOAM environment setup."
fi