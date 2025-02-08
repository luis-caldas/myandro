#!/system/bin/sh

# Module location
MODDIR=${0%/*}

# Props
PROPS_NAME="build.prop"
PROPS_FOLDER="/system"

# Paths
REAL_PROPS_FILE="$PROPS_FOLDER/$PROPS_NAME"
FAKE_PROPS_LOCATION="${MODDIR}${PROPS_FOLDER}"
FAKE_PROPS_FILE="${FAKE_PROPS_LOCATION}/$PROPS_NAME"

# If exists
if [ -f "$REAL_PROPS_FILE" ]; then

    # Copy original
    mkdir -p "$FAKE_PROPS_LOCATION"
    cp -a "$REAL_PROPS_FILE" "$FAKE_PROPS_FILE"

    # Update it
    sed -i 's/lineage_//g' "$FAKE_PROPS_FILE"
    sed -i '/^ro.lineage/d' "$FAKE_PROPS_FILE"

fi
