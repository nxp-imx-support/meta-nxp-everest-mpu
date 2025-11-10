#!/bin/bash

FILE="/etc/xdg/weston/weston.ini"
SECTION="[shell]"
SETTING="panel-position=none"

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "Error: File $FILE not found."
    exit 2
fi

# If no argument is passed, default to --remove
if [ "$#" -eq 0 ]; then
    echo "No argument provided. Defaulting to --remove."
    ACTION="--remove"
else
    ACTION="$1"
fi

case "$ACTION" in
    --remove)
        if grep -q "^$SETTING\$" "$FILE"; then
            echo "'$SETTING' already exists in $FILE."
        else
            echo "Adding '$SETTING' to first $SECTION section..."
            awk -v section="$SECTION" -v setting="$SETTING" '
                BEGIN { added=0 }
                $0 == section && !added {
                    print $0
                    print setting
                    added=1
                    next
                }
                { print }
            ' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"
            echo "Added successfully."
        fi
        ;;
    --add)
        if grep -q "^$SETTING\$" "$FILE"; then
            echo "Removing '$SETTING' from first $SECTION section..."
            awk -v section="$SECTION" -v setting="$SETTING" '
                BEGIN { in_section=0; removed=0 }
                $0 == section && !removed {
                    print $0
                    in_section=1
                    next
                }
                in_section && $0 == setting && !removed {
                    removed=1
                    next
                }
                in_section && /^\[.*\]/ {
                    in_section=0
                }
                { print }
            ' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"
            echo "Removed successfully."
        else
            echo "'$SETTING' not found in $FILE."
        fi
        ;;
    *)
        echo "Invalid argument: $ACTION"
        echo "Usage: $0 [--add]"
        exit 1
        ;;
esac

# Restart Weston to apply changes
echo "Restarting Weston..."
systemctl restart weston
echo "Weston restarted."

gui_guider > /dev/null &
