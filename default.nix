{ ... }:
let

  # Get the packages
  pkgs = import <nixpkgs> {};

  # Author
  author = "luis-caldas";

  # Phone
  phone = "alioth";

  # Apps
  apks = {};

  # The temporary folder for the directory structure
  temporary = "struct";
  sample = "sample";

  # Magisk names
  magisk = {
    path = "META-INF/com/google/android";
    binary = "update-binary";
    script = "updater-script";
    prop = "module.prop";
    md5 = "module.md5";
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
  version = "2";

  # Get all the files that we will need
  srcs = [

    # Magisk file
    (builtins.fetchGit { name = "magisk"; url = "https://github.com/topjohnwu/Magisk"; })

    # My Certificates
    (builtins.fetchGit { name = "certs"; url = "https://github.com/${author}/mypub"; })

    # Boot animation creator
    (builtins.fetchGit { name = "anim"; url = "https://github.com/${author}/mybootanim"; })

    # Font Files
    "${pkgs.courier-prime}/share/fonts"

    # Projects
    ./assets

  ];

  # Needed build packages
  nativeBuildInputs = [
    # Certificate tools
    pkgs.openssl
    # Boot animation
    (pkgs.python3.withPackages (package: with package; [ wand ]))
    # Hashing
    pkgs.rhash
    # Zipping
    pkgs.p7zip
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

    # Naming
    module=cert
    mkdir "$TMPDIR/${temporary}/$module"
    cd "$TMPDIR/${temporary}/$module"

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

    # Naming
    module=fonts
    mkdir "$TMPDIR/${temporary}/$module"
    cd "$TMPDIR/${temporary}/$module"

    # Generate the folder structure
    folders="system/fonts"
    mkdir -p "$folders"
    folders_product="system/product/fonts"
    mkdir -p "$folders_product"

    # Copy the files over
    fonts_path="$TMPDIR/fonts/truetype"

    # Font information
    extension="ttf"
    possible=("Regular" "Bold" "Italic" "BoldItalic")

    # Direct
    direct=(
      "AndroidClock"
      "ComingSoon"
      "CutiveMono"
      "DroidSans"
      "DroidSansMono"
    )

    # Product
    product=(
      "Lato"
      "Rubik"
    )

    # All others
    others=(
      "Roboto" "RobotoFlex" "RobotoStatic"
      "CarroisGothicSC"
      "DancingScript"
      "DroidSans"
      "NotoSerif"
      "SourceSansPro"
    )

    # Copy all the direct files
    for each_font in "''${direct[@]}"; do
      cp "$fonts_path/"*"-Regular.ttf" "$folders/$each_font.$extension"
    done

    # Copy all the other files
    for each_font in "''${others[@]}"; do
      # Iterate types
      for each_type in "''${possible[@]}"; do
        cp "$fonts_path/"*"-$each_type.ttf" "$folders/$each_font-$each_type.$extension"
      done
    done

    # All the fonts in the product folder
    for each_font in "''${product[@]}"; do
      # Iterate types
      for each_type in "''${possible[@]}"; do
        cp "$fonts_path/"*"-$each_type.ttf" "$folders_product/$each_font-$each_type.$extension"
      done
    done

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

    # Naming
    module=sounds
    assets_name=zelda-sounds
    mkdir "$TMPDIR/${temporary}/$module"
    cd "$TMPDIR/${temporary}/$module"

    # Generate the folder structure
    folders="system/product/media/audio"
    mkdir -p "$folders"/{notifications,alarms,ringtones}

    # Copy the files over
    fonts_path="$TMPDIR/assets/$assets_name"
    cp "$fonts_path"/notifications/* "$folders/notifications/."
    cp "$fonts_path"/other/* "$folders/alarms/."
    cp "$fonts_path"/other/* "$folders/ringtones/."

    # Scripts
    cp "$TMPDIR/assets/$assets_name/"*.sh .

    # Create the prop file
    cp "${
      createProp
        "Majora's Sounds"
        "sounds"
        "Majora's Masks System Sounds"
        version
    }" "${magisk.prop}"

    ##################
    # Boot Animation #
    ##################

    # Naming
    module=anim
    mkdir "$TMPDIR/${temporary}/$module"
    cd "$TMPDIR/${temporary}/$module"

    # Compile the boot animation
    python "$TMPDIR/$module/scaler.py" android | grep -i done

    # Generate the folder structure
    folders="system/product/media"
    mkdir -p "$folders"

    # Copy the result to structure
    cp "$TMPDIR/$module/dist/android/${phone}/"*.zip "$folders/bootanimation.zip"

    # Create the prop file
    cp "${
      createProp
        "Bootloader Animation"
        "anim"
        "Custom Bootloader Animation"
        version
    }" "${magisk.prop}"

  '';

  # Zip Everything
  installPhase = ''

    # Create the output folder
    mkdir "$out"

    # Iterate over all the modules
    for each_module in "$TMPDIR/${temporary}"/*; do

      # Extract the name
      module_name="$(basename "$each_module")"

      # Add the needed files
      cp -r "$TMPDIR/${sample}"/* "$each_module/."

      # Go into the module folder
      cd "$each_module"

      # Hash all the files
      rhash --exclude=md5 -p '%m  %p\n' -r . > ${magisk.md5}

      # Zip the folder
      7z a -tzip -mx0 "$out/$module_name.zip" "$each_module"/* | grep archive

    done

  '';

}