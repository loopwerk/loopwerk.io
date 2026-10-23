run:
  saga dev

# Generate photo thumbnails (shortest side 660px) for the album pages, skipping ones that already exist
thumbnails:
	#!/usr/bin/env bash
	shopt -s nullglob
	for img in content/photos/*/*.{webp,jpg,jpeg,png}; do
		name=$(basename "$img")
		album=$(basename "$(dirname "$img")")
		thumb="content/static/thumbnails/$album/${name%.*}.webp"
		if [[ ! -f "$thumb" ]]; then
			echo "Generating: $thumb"
			mkdir -p "content/static/thumbnails/$album"
			magick "$img" -resize "660x660^" -strip -quality 85 -define webp:method=6 "$thumb"
		fi
	done

# Delete game posters whose id is no longer listed in games.csv
clean-posters:
	#!/usr/bin/env fish
	set -l ids (tail -n +2 Sources/Loopwerk/csv/games.csv | cut -d ';' -f 1 | tr -d '\r')
	set -l removed 0

	for poster in (find content/static/posters/games -name '*.jpg')
		if not contains -- (basename $poster .jpg) $ids
			echo "Removing $poster"
			rm $poster
			set removed (math $removed + 1)
		end
	end

	echo "Removed $removed poster(s), $(count $ids) games in games.csv"

# Delete photo thumbnails whose source photo no longer exists
clean-thumbnails:
	#!/usr/bin/env fish
	set -l photos content/photos/*/*.{webp,jpg,jpeg,png}
	set photos (string replace -r '^content/photos/(.+)\.[^.]+$' '$1' $photos)
	set -l removed 0

	# Thumbnails outside an album folder are from before they were split per album, and never match
	for thumb in content/static/thumbnails/*.webp content/static/thumbnails/*/*.webp
		if not contains -- (string replace -r '^content/static/thumbnails/(.+)\.webp$' '$1' $thumb) $photos
			echo "Removing $thumb"
			rm $thumb
			set removed (math $removed + 1)
		end
	end

	echo "Removed $removed thumbnail(s), $(count $photos) photos"

format:
  swiftformat --swift-version 6 .
