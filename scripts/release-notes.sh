#!/usr/bin/env bash
# Writes the CHANGELOG.md section of one version to RELEASE_NOTES.md. The packager sends that file to
# CurseForge as the changelog of the uploaded file (.pkgmeta: manual-changelog), so players see only
# what changed in that version, on the website and in the CurseForge app.
#
#   bash scripts/release-notes.sh 1.0.1        # the "## 1.0.1" section
#   bash scripts/release-notes.sh 1.1.0-beta1  # "## 1.1.0-beta1" if it exists, otherwise "## 1.1.0"
#   bash scripts/release-notes.sh              # the newest section (dry runs)
#
# Fails when the section is missing or has no "- " entry, so a release never goes out without a summary.
set -euo pipefail
cd "$(dirname "$0")/.."

version="${1:-}"

# Prints the section whose heading is "## <version>" (anything may follow the version, such as the date),
# or the first section when no version is given. Carriage returns are dropped, for Windows checkouts.
extract() {
	awk -v v="$1" '
		{ sub(/\r$/, "") }
		/^## / {
			if (found) exit
			split($0, words, " ")
			if (v == "" || words[2] == v) found = 1
		}
		found { print }
	' CHANGELOG.md
}

notes=""
if [[ -n "$version" ]]; then
	notes="$(extract "$version")"
	if [[ -z "$notes" ]]; then
		notes="$(extract "${version%%-*}")"
	fi
else
	notes="$(extract "")"
fi

if [[ -z "$notes" ]] || ! grep -q '^- ' <<< "$notes"; then
	echo "::error::CHANGELOG.md has no section with entries for ${version:-the newest version}. Add a '## <version> (<date>)' section listing what is new, fixed or changed." >&2
	exit 1
fi

printf '%s\n' "$notes" > RELEASE_NOTES.md
echo "Changelog sent to CurseForge for ${version:-the newest version}:"
cat RELEASE_NOTES.md
