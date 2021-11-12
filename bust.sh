#!/usr/bin/env bash

# -- Globals, constants

WORDLIST="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
EXT=".php .html /"
SEP="/"
THREADS="10"
TMPFILE="$(mktemp)"
METHOD="GET"
USERAGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
VERBOSE=""
COLORIZE=""
DOWNLOAD=""

RED=""
REDINBL=""
GREEN=""
YELLOW=""
EOC=""

OK="[+]"
NOK="[-]"
WTF="[!]"

# -- Functions

printc() {
	if [ "x${COLORIZE}x" != "xx" ]; then
		STROUT=""
		OPT="$1"
		shift
		case "$OPT" in
		WTF)
			STROUT="$WTF $@"
			STRADD="\n"
			;;
		OK)
			STROUT="$OK $@"
			STRADD="\n"
			;;
		NOK)
			STROUT="$NOK $@"
			STRADD="\n"
			;;
		NOKR)
			STROUT="$NOK $@"
			STRADD="\r"
			;;
		*)
			echo "### $@"
			;;
		esac
		PADNR=$(( $(tput cols) - $(echo -n $STROUT | wc -c) - 1))
		PADOUT="$(printf %${PADNR}s ' ')"
		STROUT="${STROUT}${PADOUT}${STRADD}"
		echo -en "${STROUT}"
	else
		shift
		echo "$@"
	fi
	return 0
}

warn() {
	printc WTF "$@" >&2
	return 0
}

die() {
	warn "$@. Aborted"
	exit 1
}

usage() {
	cat <<-EOF
	Sorry. Not implemented yet.
	EOF
	return 0
}

geturl() {
	myurl=$@
	if [ -z "$myurl" ]; then
		die "Missing url"
	fi
	FOUND="$(curl -X $METHOD -A "$USERAGENT" -c $TMPFILE -b $TMPFILE -v -m 1 "$myurl" 2>&1 | strings | grep '^< ' | head -n 1 | awk '{print $3}')"
	hasretval=2
	case $FOUND in
	200)
		printc OK "${GREEN}$myurl${EOC} --> $FOUND"
		hasretval=0
		if [ "x${DOWNLOAD}x" != "Xx" ]; then
			wget -q -U "$USERAGENT" "$myurl"
		fi
		;;
	301|302)
		LOC="$(curl -X $METHOD -A "$USERAGENT" -c $TMPFILE -b $TMPFILE -v -m 1 "$myurl" 2>&1 | strings | grep -i '^< Location' | head -n 1 | awk '{print $3}')"
		printc OK "$myurl --> $FOUND --> $LOC"
		hasretval=0
		;;
	*)
		if [ "x${VERBOSE}x" != "xx" ]; then
			printc NOKR "$myurl --> $FOUND"
		fi
		hasretval=1
		;;
	esac
	return $hasretval
}

# -- Parameter parsing

while getopts w:x:u:t:s:m:hpvcd param
do
	case $param in
	w)
		WORDLIST="${OPTARG}"
		;;
	x)
		EXT="${OPTARG}"
		;;
	u)
		URL="${OPTARG}"
		;;
	t)
		THREADS="${OPTARG}"
		;;
	s)
		SEP="${OPTARG}"
		;;
	m)
		METHOD="${OPTARG}"
		;;
        h)
                usage
                ;;
	p)
		METHOD="POST"
		;;
	v)
		VERBOSE="YES"
		;;
	c)
		COLORIZE="YES"
		RED="\e[31m"
		REDINBL="\e[31;7;5m"
		GREEN="\e[32m"
		YELLOW="\e[33m"
		EOC="\e[0m"
		OK="[${GREEN}+${EOC}]"
		NOK="[${RED}-${EOC}]"
		WTF="[!]"
		;;
	d)
		DOWNLOAD="YES"
		;;
	*)
		# -- *: Every other parameter gets an error message
		die "$param -- Not implemented. Use -h for help"
		;;
	esac
done
shift $(($OPTIND - 1))

# -- Sanity checks

if [ -z "$URL" ]; then
	die "URL is missing"
fi

if [ ! -r "$TMPFILE" ]; then
	die "Cannot read $TMPFILE"
fi

if [ ! -w "$TMPFILE" ]; then
	die "Cannot write $TMPFILE"
fi

if expr "$THREADS" + 1 >/dev/null 2>&1 -ne 0; then
	die "Threads is not a number"
fi

if [ $THREADS -le 0 ]; then
	die "Threads should be greater than 0"
fi

if [ -r "$WORDLIST" ]; then
	GETWORDS="cat $WORDLIST | grep -v '^#'"
elif [ $(echo $WORDLIST | sed 's/^\(.\).*$/\1/') = "0" ]; then
	RANGE="$(echo -n $WORDLIST | wc -c)"
	RANGE=$((RANGE - 1))
	BEGINRANGE=$(printf "%0${RANGE}d")
	ENDRANGE="$(echo -n $WORDLIST | sed 's/^.\(.*\)$/\1/')"
	expr "$ENDRANGE" + 1 >/dev/null 2>&1 || \
		die "$ENDRANGE is not numerical"
	GETWORDS="for num in {${BEGINRANGE}..${ENDRANGE}}; do echo \$num; done"
elif expr "$WORDLIST" + 1 >/dev/null 2>&1; then
	GETWORDS="seq 1 $WORDLIST"
else
	die "Can't read $WORDLIST"
fi

if tty >/dev/null 2>&1; then
	echo -e "${REDINBL}******************************************************************${EOC}"
	echo -e "${REDINBL}***${EOC}  ${RED}WARNING! BRUTEFORCE DIRECTORY BUSTING IS ABOUT TO START  ${REDINBL}***${EOC}"
	echo -e "${REDINBL}******************************************************************${EOC}"
	echo -e "${URL}${SEP}$(eval $GETWORDS | head -n 1)$(echo $EXT | awk '{print $1}')"
	echo -e "TARGET URL: $URL"
	echo -e "SEPERATOR: $SEP"
	echo -e "FILE EXTENSIONS SCANNED FOR: $EXT"
	echo -e "USING: \"$GETWORDS\""
	echo -e "METHOD: $METHOD"
	echo -e "THREADS: $THREADS"
	echo -e "COLORIZED: $COLORIZE"
	echo -e "VERBOSE: $VERBOSE"
	echo -e "DOWNLOAD IF FOUND: $DOWNLOAD"
	echo -e "...Or hit CTRL+C ${YELLOW}RIGHT NOW!${EOC}"
	read -t 3 dummy
	echo "Here we go..."
	echo
fi

# -- Main

COUNT="$THREADS"
echo $GETWORDS
eval $GETWORDS | while read line
do
	if [ ! -z "$EXT" ]; then
		for ext in $EXT
		do
			COUNT=$(($COUNT - 1))
			if [ $COUNT -le 0 ]; then
				wait
				COUNT=$THREADS
			fi
			browse="${URL}${SEP}${line}${ext}"
			geturl "$browse" &
		done
	else
		COUNT=$(($COUNT - 1))
		if [ $COUNT -le 0 ]; then
			wait
			COUNT=$THREADS
		fi
		browse="${URL}${SEP}${line}"
		geturl "$browse" &
	fi
done


