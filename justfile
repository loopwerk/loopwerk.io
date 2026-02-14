run:
	#!/usr/bin/env bash
	set -m
	pnpm css-watch &
	CSS_PID=$!
	trap "kill $CSS_PID 2>/dev/null" EXIT
	saga dev --ignore input.css

# Remove generated responsive hero image variants
clean:
	rm -f content/articles/heroes/*-315w.webp content/articles/heroes/*-630w.webp content/articles/heroes/*-740w.webp content/articles/heroes/*-1480w.webp

# Generate responsive hero image variants (315w, 630w, 740w, 1480w)
resize:
	#!/usr/bin/env bash
	cd content/articles/heroes
	for img in *.webp; do
		# Skip already-generated variants
		[[ "$img" =~ -[0-9]+w\.webp$ ]] && continue

		base="${img%.webp}"
		for size in 315 630 740 1480; do
			variant="${base}-${size}w.webp"
			if [[ ! -f "$variant" ]]; then
				echo "Generating: $variant"
				magick "$img" -resize "${size}x" -strip -quality 85 -define webp:method=6 "$variant"
			fi
		done
	done

format:
  swiftformat --swift-version 5 .
