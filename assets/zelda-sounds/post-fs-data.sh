#!/system/bin/sh

# Module location
MODDIR=${0%/*}

# Globals
AUDIO_FOLDER="/system/product/media/audio"

# SELinux
SELINUX_DEFAULT_CONTEXT="u:object_r:system_file:s0"

# SELinux function
set_context() {

    # Check if SELinux is enforcing
    if [ "$(getenforce)" = "Enforcing" ]; then

        # Get the default context for the given path files
        selinux_context=$(ls -Zd "$1" | awk '{print $1}')

        # Change the permission
        if [ -n "$selinux_context" ] && [ "$selinux_context" != "?" ]; then
            chcon -R "$selinux_context" "$2"
        else
            chcon -R "$SELINUX_DEFAULT_CONTEXT" "$2"
        fi
    fi
}

# Set the context for the all the new files
set_context "$AUDIO_FOLDER" "${MODDIR}$AUDIO_FOLDER"
