#!/bin/sh
set -eu

project_dir="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)/app}"
icon_dir="$project_dir/KanjiCrossword/Assets.xcassets/AppIcon.appiconset"
source_icon="$icon_dir/AppIcon-1024.png"

if [ ! -f "$source_icon" ]; then
  echo "Missing source app icon: $source_icon" >&2
  exit 1
fi

generate_icon() {
  output_name="$1"
  output_size="$2"
  /usr/bin/sips -z "$output_size" "$output_size" "$source_icon" --out "$icon_dir/$output_name" >/dev/null
}

generate_icon Icon-20.png 20
generate_icon Icon-20@2x.png 40
generate_icon Icon-20@3x.png 60
generate_icon Icon-29.png 29
generate_icon Icon-29@2x.png 58
generate_icon Icon-29@3x.png 87
generate_icon Icon-40.png 40
generate_icon Icon-40@2x.png 80
generate_icon Icon-40@3x.png 120
generate_icon Icon-60@2x.png 120
generate_icon Icon-60@3x.png 180
generate_icon Icon-76.png 76
generate_icon Icon-76@2x.png 152
generate_icon Icon-83.5@2x.png 167
