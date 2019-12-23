#!/bin/sh

mask_background ()
{
	command -v convert >/dev/null 2>&1 || fail "Couldn't locate convert command -- install ImageMagick"
	command -v composite >/dev/null 2>&1 || fail "Couldn't locate composite command -- install ImageMagick"

	[ -f "${1}" ] || fail "Couldn't find ${1}."
	[ -f "${2}" ] && fail "${2} already exists."
	printf "${3}" | grep -Eq '^\-?[[:digit:]]*$' || fail "Third argument must be an integer."
	printf "${4}" | grep -Eq '^\-?[[:digit:]]*$' || fail "Fourth argument must be an integer."
	printf "${5}" | grep -Eq '^\-?[[:digit:]]*\.?[[:digit:]]+$' || fail "Fifth argument must be a float."

	color=$(convert "${1}" -format "%[pixel:p{${3},${4}}]" info:-)
	convert "${1}" \
		-alpha off -bordercolor "${color}" -border 1 \
		\( +clone -fuzz "${5}%" -fill none -floodfill "+${3}+${4}" "${color}" \
			-alpha extract -geometry 200% -blur 0x0.5 -morphology erode square:1 -geometry 50% \) \
		-compose CopyOpacity -composite -shave 1 \
		"PNG32:${2}.transparent"
	composite "${1}" "${2}.transparent" -compose Dst_In -alpha Set "${2}" || fail "Couldn't copy original alpha channel."

	rm "${2}.transparent" || fail "Couldn't remove ${2}.transparent."
}
