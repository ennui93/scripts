#!/bin/sh

apply_clut ()
{
	command -v convert >/dev/null 2>&1 || fail "Couldn't locate convert command -- install ImageMagick"
	command -v composite >/dev/null 2>&1 || fail "Couldn't locate composite command -- install ImageMagick"

	[ -f "${1}" ] || fail "Couldn't find ${1}."
	[ -f "${2}" ] && fail "${2} already exists."

	[ ! -f /tmp/CLUT.png ] && convert -size 30x600 gradient: -rotate 90  -interpolate bilinear \( +size 'xc:#1f2c33' 'xc:#f7c3ab' 'xc:#ffffff' +append \) -clut /tmp/CLUT.png # || fail "Couldn't create CLUT."
	convert "${1}" -modulate 100,0 /tmp/CLUT.png -clut "${2}.converted" || fail "Couldn't perform CLUT operation."
	composite -dissolve 60 "${2}.converted" "${1}" -alpha Set "${2}.dissolved" || fail "Couldn't perform composition."
	convert "${2}.dissolved" -normalize "${2}.normalized" || fail "Couldn't perform normalization."
	composite "${1}" "${2}.normalized" -compose Dst_In -alpha Set "${2}" || fail "Couldn't copy original alpha channel."

	rm "${2}.converted" || fail "Couldn't remove ${2}.converted."
	rm "${2}.dissolved" || fail "Couldn't remove ${2}.dissolved."
	rm "${2}.normalized" || fail "Couldn't remove ${2}.normalized."
}
