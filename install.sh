#!/bin/sh
# Install the mumon program on Linux or macOS, then the Mumon browser.
#
#   curl -fsSL https://raw.githubusercontent.com/cyberkunju/mumon-build/main/install.sh | sh
#
# Downloads the newest mumon program for this OS and CPU (mumon-cli-<os>-<arch>,
# from this repository's releases) to ~/.local/bin/mumon, and runs
# `mumon install` when a package key is set (MUMON_PACKAGE_KEY, or package.key
# in ~/.config/mumon on Linux, ~/Library/Application Support/mumon on macOS).
# Linux: the browser needs the libraries a Firefox needs (GTK 3, ...); Xvfb is
# used for the browser lane when it is installed.
set -eu

repo="cyberkunju/mumon-build"
case "$(uname -s)" in
  Linux) os=linux; keydir="${XDG_CONFIG_HOME:-$HOME/.config}/mumon" ;;
  Darwin) os=macos; keydir="$HOME/Library/Application Support/mumon" ;;
  *) echo "mumon: unsupported OS $(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64 | amd64) arch=x86_64 ;;
  arm64 | aarch64) arch=arm64 ;;
  *) echo "mumon: unsupported CPU $(uname -m)" >&2; exit 1 ;;
esac
asset="mumon-cli-$os-$arch"

# The highest-numbered build-N release that has this program fully uploaded
# (by build number, not the API's order).
url=$(curl -fsSL -H "Accept: application/vnd.github+json" -H "User-Agent: mumon-install" \
    "https://api.github.com/repos/$repo/releases?per_page=30" | tr ',' '\n' | awk -v asset="$asset" '
  BEGIN { best = -1 }
  /"tag_name":/ {
    tag = $0; sub(/.*"tag_name": *"/, "", tag); sub(/".*/, "", tag)
    n = -1; draft = 0
    if (match(tag, /^build-[0-9]+-/)) n = substr(tag, 7, RLENGTH - 7) + 0
  }
  /"draft": *true/ { draft = 1 }
  /"state":/ { st = $0; sub(/.*"state": *"/, "", st); sub(/".*/, "", st) }
  /"browser_download_url":/ {
    u = $0; sub(/.*"browser_download_url": *"/, "", u); sub(/".*/, "", u)
    if (n >= 0 && !draft && st == "uploaded" && u ~ ("/" asset "$") && n > best) { best = n; found = u }
  }
  END { print found }')
[ -n "$url" ] || { echo "mumon: no published mumon program ($asset) in $repo" >&2; exit 1; }

bin="$HOME/.local/bin"
mkdir -p "$bin"
echo "downloading the mumon program: $url"
curl -fsSL -H "User-Agent: mumon-install" -o "$bin/mumon.part" "$url"
chmod +x "$bin/mumon.part"
mv -f "$bin/mumon.part" "$bin/mumon"
case ":$PATH:" in
  *":$bin:"*) ;;
  *) echo "add $bin to your PATH (for example in ~/.profile): export PATH=\"$bin:\$PATH\"" ;;
esac

if [ -n "${MUMON_PACKAGE_KEY:-}" ] || [ -f "$keydir/package.key" ]; then
  "$bin/mumon" install
  echo "done: try  mumon verify"
else
  echo "mumon is installed. Put the package key in $keydir/package.key (or MUMON_PACKAGE_KEY), then run: mumon install"
fi
