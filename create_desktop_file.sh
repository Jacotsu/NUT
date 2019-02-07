#!/usr/bin/env bash
usage="$(basename "$0") [-h] {nut_install_path} -- Install nut's desktop file
so that it shows in the DE menu
where:
-h  show this help text"

if [ "$#" -lt "1" ]; then
    echo "$usage" >&2
    exit 1
fi

while getopts ':h:' option; do
    case "$option" in
        h) echo "$usage"
            exit
            ;;
        \?) printf "illegal option: -%s\n" "$OPTARG" >&2
            echo "$usage" >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

TMP_FILE="/tmp/nut.desktop"
echo "[Desktop Entry]
Version=1.0
Name=Nut nutrition
Comment=Track your nutrition
Terminal=false
StartupWMClass=NutNutrition
Type=Application
Keywords=nut;nutrition;calories
X-Desktop-File-Install-Version=0.24" >"$TMP_FILE"

NUTPATH=$(realpath "$1")
desktop-file-install --dir ~/.local/share/applications \
    --set-key=TryExec \
    --set-value="$NUTPATH/nut.tcl" \
    --set-key=Exec \
    --set-value="bash -c \"cd $NUTPATH && $NUTPATH/nut.tcl\"" \
    --set-key=Icon \
    --set-value="$NUTPATH/nuticon.png" \
    "$TMP_FILE"
rm "$TMP_FILE"
