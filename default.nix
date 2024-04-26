{ ... }:
let

  # Get the packages
  pkgs = import <nixpkgs> {};

  # Author
  author = "luis-caldas";

  # The temporary folder for the directory structure
  temporary = "struct";
  sample = "sample";

  # Magisk names
  magisk = {
    path = "META-INF/com/google/android";
    binary = "update-binary";
    script = "updater-script";
    prop = "module.prop";
  };

  # Function to create a prop file
  createProp = name: id: description: version: pkgs.writeText name ''
    id=${id}
    name=${name}
    version=v${version}
    versionCode=${version}
    author=${author}
    description=${description}
  '';

in

# Whole derivation
pkgs.stdenv.mkDerivation rec {

  # Information
  pname = "android-modules";
  version = "1";

  # Get all the files that we will need
  srcs = [

    # Magisk file
    (builtins.fetchGit { name = "magisk"; url = "https://github.com/topjohnwu/Magisk"; })

    # My Certificates
    (builtins.fetchGit { name = "certs"; url = "https://github.com/${author}/mypub"; })

    # Font Files
    "${pkgs.courier-prime}/share/fonts"

    # Projects
    ./assets

  ];

  # Needed build packages
  nativeBuildInputs = [
    pkgs.openssl
    pkgs.p7zip
    pkgs.zip
  ];

  # See all sources
  sourceRoot = ".";

  # Organise the files into the folder
  buildPhase = ''

    # Create the folder for all modules
    mkdir "$TMPDIR/${temporary}"

    # Go to it
    cd "$TMPDIR/${temporary}"

    # Create the META structure
    folders="$TMPDIR/${sample}/${magisk.path}"
    mkdir -p "$folders"

    # Copy the files
    cp "$TMPDIR/magisk/scripts/module_installer.sh" "$folders/${magisk.binary}"
    chmod u+x "$folders/${magisk.binary}"
    echo "#MAGISK" > "$folders/${magisk.script}"

    ###############
    # Certificate #
    ###############

    module=cert

    mkdir $module
    cd $module

    # Path to the certificate
    cert_path="$TMPDIR/certs/ssl/ca.pem"

    # Get the new name of the file
    cert_hash="$(openssl x509 -inform PEM -subject_hash_old -in "$cert_path" -noout)"

    # Generate the folder structure
    folders="system/etc/security/cacerts"
    mkdir -p "$folders"

    # Generate the new cert and copy it
    new_cert="$folders/$cert_hash.0"
    cp "$cert_path" "$new_cert"
    openssl x509 -noout -text -fingerprint -in "$new_cert" >> "$new_cert"

    # Scripts
    ${pkgs.tree}/bin/tree $TMPDIR/assets/
    cp "$TMPDIR/assets/$module/"*.sh .

    # Create the prop file
    cp "${
      createProp
        "Certificate Authority"
        "cert"
        "Root Certificate Authority"
        version
    }" "${magisk.prop}"

    #########
    # Fonts #
    #########

    # module=cert

    # mkdir $module
    # cd $module

    # # Generate the folder structure
    # folders="system/fonts"
    # mkdir -p "$folders"

    # Create the prop file
    cp "${
      createProp
        "Good Fonts"
        "fonts"
        "Good Fonts Replacement"
        version
    }" "${magisk.prop}"

    ##########
    # Sounds #
    ##########


    ##################
    # Boot Animation #
    ##################


  '';

  # Zip Everything
  installPhase = ''

    # Create the output folder
    mkdir "$out"

    # Iterate over all the modules
    for each_module in "$TMPDIR/${temporary}"/*; do

      # Extract the name
      module_name="$(basename "$each_module")"

      echo $module_name

      # Add the needed files
      cp -r "$TMPDIR/${sample}"/* "$each_module/."

      # TODO generate the MD5

      # Zip the folder
      cd "$each_module"
      #zip -r "$out/$module_name" .
      7z a -tzip -mx0 "$out/$module_name.zip" "$each_module"/*

    done

    # Iterate the output and list contents
    for each_zip in "$out"/*.zip; do

      7z l "$each_zip"

    done

  '';

}