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

# Copy the certificate to the old folder
cp "${MODDIR}$SYST_CERT_FOLDER"/* "$SYST_CERT_FOLDER"/.

# Update the context
set_context "$SYST_CERT_FOLDER" "$SYST_CERT_FOLDER"

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

    # First we get the Zygote process(es), which launch each app
    ZYGOTE_PID=$(pidof zygote || true)
    ZYGOTE64_PID=$(pidof zygote64 || true)
    # N.b. some devices appear to have both!

    # Apps inherit the Zygote's mounts at startup, so we inject here to ensure
    # all newly started apps will see these certs straight away:
    for Z_PID in 1 "$ZYGOTE_PID" "$ZYGOTE64_PID"; do
        if [ -n "$Z_PID" ]; then
            nsenter --mount=/proc/"$Z_PID"/ns/mnt -- \
                /bin/mount --bind "$TEMP_CERT_FOLDER" "$APEX_CERT_FOLDER"
        fi
    done

    # Then we inject the mount into all already running apps, so they
    # too see these CA certs immediately:

    # Get the PID of every process whose parent is one of the Zygotes:
    APP_PIDS=$(
        echo "$ZYGOTE_PID $ZYGOTE64_PID" | \
        xargs -n1 ps -o 'PID' -P | \
        grep -v PID
    )

    # Inject into the mount namespace of each of those apps:
    for PID in $APP_PIDS; do
        nsenter --mount=/proc/"$PID"/ns/mnt -- \
            /bin/mount --bind "$TEMP_CERT_FOLDER" "$APEX_CERT_FOLDER"s &
    done

fi