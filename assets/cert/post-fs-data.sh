#!/system/bin/sh

# Module location
MODDIR=${0%/*}

# Globals
APEX_CERT_FOLDER="/apex/com.android.conscrypt/cacerts"
SYST_CERT_FOLDER="/system/etc/security/cacerts"
TEMP_CERT_FOLDER="/data/local/tmp/certificate-copy"

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
set_context "$SYST_CERT_FOLDER" "${MODDIR}$SYST_CERT_FOLDER"

# Android 14 support
# Since Magisk ignore /apex for module file injections, use non-Magisk way
if [ -d "$APEX_CERT_FOLDER" ]; then

    # Create the temporary folder
    rm -f "$TEMP_CERT_FOLDER"
    mkdir -p -m 700 "$TEMP_CERT_FOLDER"
    mount -t tmpfs tmpfs "$TEMP_CERT_FOLDER"

    # Copy the certificates
    cp -f "$APEX_CERT_FOLDER"/* "$TEMP_CERT_FOLDER"
    cp -f "${MODDIR}$SYST_CERT_FOLDER"/* "$TEMP_CERT_FOLDER"

    # Do the same as in Magisk module
    chown -R 0:0 "$TEMP_CERT_FOLDER"
    set_context "$APEX_CERT_FOLDER" "$TEMP_CERT_FOLDER"

    # Mount directory inside APEX if it is valid, and remove temporary one.
    mount --bind "$TEMP_CERT_FOLDER" "$APEX_CERT_FOLDER"

    # Iterate all the PIDs and remount
    for pid in 1 $(pgrep zygote) $(pgrep zygote64); do
        nsenter --mount=/proc/"$pid"/ns/mnt -- \
            /bin/mount --bind "$TEMP_CERT_FOLDER" "$APEX_CERT_FOLDER"
    done

    # Unmount and remove the folders
    umount "$TEMP_CERT_FOLDER"
    rmdir "$TEMP_CERT_FOLDER"

fi