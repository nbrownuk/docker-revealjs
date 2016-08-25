#!/bin/bash

set -e

file="index.html"

usage () {
cat <<EOF

Usage: entrypoint.sh [OPTIONS]

Options:

--autoSlide=0                     Number of milliseconds before proceeding to
                                  next slide
--autoSlideStoppable=true         Stop auto-sliding after user input
--autoSlideMethod=next|right      If set to the non-default setting 'right',
                                  auto-sliding navigates top level slides only
--backgroundTransition='default'  Transition style for full page slide
                                  backgrounds*
--center=true                     Vertical centering of slides
--controls=true                   Display controls in the bottom right corner
--embedded=false                  Flags if the presentation is running in
                                  embedded mode, i.e. contained within a
                                  limited portion of the screen
--fragments=true                  Turns fragments on and off globally
-h|--help                         Prints this usage text
--hideAddressBar=true             Hides the address bar on mobile devices
--history=false                   Push each slide change to the browser history
--keyboard=true                   Enable keyboard shortcuts for navigation
--loop=false                      Loop the presentation
--mouseWheel=false                Enable slide navigation via mouse wheel
--overview=true                   Enable the slide overview mode
--parallaxBackgroundHorizontal=0  On slide change, amount of pixels to move
                                  parallax background (horizontal)
--parallaxBackgroundImage=''      Parallax background image location
--parallaxBackgroundSize=''       Parallax background size in CSS syntax (only
                                  pixel support, e.g. "2100px 900px)
--parallaxBackgroundVertical=0    On slide change, amount of pixels to move
                                  parallax background (vertical)
--previewLinks=false              Open links in an iframe preview overlay
--progress=true                   Displays a progress bar at bottom of screen
--question=true                   Show help overlay when questionmark pressed
--rtl=false                       Change presentation direction right to left
--showNotes=false                 Sets speaker's notes visible to visible
--shuffle=false                   Randomises the slide order
--slideNumber=false|''            Displays number of current slide; turn off
                                  with false, default with true, 'c', 'c/t',
                                  'h/v', 'h.v' (current, total, vertical,
                                  horizontal)
--theme=''                        Specify an alternative theme from one of
                                  those built-in**
--touch=true                      Enables touch navigation on devices that
                                  support it
--transition='default'            Slide transition style*
--transitionSpeed='default'       Transition speed (default|slow|fast)
--viewDistance=3                  Number of slides away from the current that
                                  are pre-loaded

          *  Transition styles: default|none|fade|slide|convex|concave|zoom
          ** Themes: black|white|league|beige|sky|night|serif|simple|solarized|blood|moon

EOF
}


valid_arg () {
    case "$1" in
	--autoSlideMethod)
            case "$2" in
		next|right)
		    return
		    ;;
		*)
		    echo "$1: bad argument, please specify next or right"
		    ;;
            esac
	    ;;
        --autoSlide|--viewDistance|--parallaxBackgroundHorizontal|--parallaxBackgroundVertical)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                return
            else
                echo "$1: bad argument, please specify an integer"
            fi
            ;;
        --parallaxBackgroundImage)
            if wget -S --spider "$2" 2>&1 | grep -q "HTTP/1.1 200 OK"; then
                return
            else
                echo "$1: bad argument, please specify a valid URL to file"
            fi
            ;;
        --parallaxBackgroundSize)
            if echo "$2" | grep -qE "^[[:digit:]]*px [[:digit:]]*px"; then
                return
            else
                echo "$1: bad argument, please specify size in px (e.g. 2100px 900px)"
            fi
            ;;
        --slideNumber)
            case "$2" in
                true|false|c|h/v|c/t|h.v)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify true, false, c, c/t, h/v or h.v"
                    ;;
            esac
            ;;
        --theme)
            case "$2" in
                black|white|league|beige|sky|night|serif|simple|solarized|blood|moon)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify one of black, white, league, beige, sky, night, serif, simple, solarized, blood, moon"
                    ;;
            esac
            ;;
        --transition|--backgroundTransition)
            case "$2" in
                default|none|fade|slide|convex|concave|zoom)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify one of default, none, fade, slide, convex, concave or zoom"
                    ;;
            esac
            ;;
        --transitionSpeed)
            case "$2" in
                default|slow|fast)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify one of default, slow or fast"
                    ;;
            esac
            ;;
        *)
            case "$2" in
                true|false)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify true or false"
                    ;;
            esac
            ;;
    esac
    exit 1
}


set_config () {
    set -- "${1#--}" "${@:2}"
    if [ "$1" = 'theme' ]; then
        sed -ri "s/(^[[:blank:]]*<link rel=\"stylesheet\" href=\"css\/$1\/)[[:alnum:]]+(\.css\")/\1$2\2/" "$file"
    else
        set -- "${1/question/help}" "${@:2}"
	[ "$1" = 'autoSlideMethod' ] && set -- "$1" "Reveal.navigate${2^}"
        case $(grep -E "^[[:blank:]]*$1:[[:blank:]]+'{0,1}[^']+'{0,1}.*" "$file" | wc -l) in
            0)
                insert_config_param $1 $2
                ;;
            1)
                amend_config_param $1 $2
                ;;
            *)
                delete_config_param $1 $2
                insert_config_param $1 $2
                ;;
        esac
    fi
}


delete_config_param () {
    sed -ri "/^[[:blank:]]*$1:[[:blank:]]+'{0,1}[^']+'{0,1}.*/d" "$file"
}


amend_config_param () {
    if [ "$1" = 'slideNumber' ]; then
        case "$2" in
            c|h/v|c/t|h.v)
                if grep -qE "^[[:blank:]]*$1:[[:blank:]]+[[:alpha:]]+.*," "$file"; then
                    set -- "$1" "${2/$2/\'$2\'}"
                fi
                ;;
            *)
                if grep -qE "^[[:blank:]]*$1:[[:blank:]]+'[^']+',.*" "$file"; then
                    sed -ri "s/(^[[:blank:]]*$1:[[:blank:]]*)'([^']+)'(,).*/\1\2\3/" "$file"
                fi
                ;;
        esac
    fi
    sed -ri "s|(^[[:blank:]]*$1:[[:blank:]]*'{0,1})[^']+('{0,1},).*|\1$2\2|" "$file"
}


insert_config_param () {
    WSPACE=$(sed -rn 's/^([[:blank:]]*)Reveal.initialize\(\{/\1/p' "$file")
    case "$1" in
        transition|transitionSpeed|backgroundTransition|parallaxBackgroundImage|parallaxBackgroundSize)
            sed -ri "/^[[:blank:]]*Reveal.initialize\(\{/ a\\$WSPACE\t$1: '$2'," "$file"
            ;;
        slideNumber)
            case "$2" in
                true|false)
                    sed -ri "/^[[:blank:]]*Reveal.initialize\(\{/ a\\$WSPACE\t$1: $2," "$file"
                    ;;
                *)
                    sed -ri "/^[[:blank:]]*Reveal.initialize\(\{/ a\\$WSPACE\t$1: '$2'," "$file"
                    ;;
            esac
            ;;
        *)
            sed -ri "/^[[:blank:]]*Reveal.initialize\(\{/ a\\$WSPACE\t$1: $2," "$file"
            ;;
    esac
}


OPTIONS=$(getopt -n "$0" \
            -o "h" \
            -l "autoSlide:, \
	        autoSlideMethod:, \
                autoSlideStoppable:, \
                backgroundTransition:, \
                center:, \
                controls:, \
                embedded:, \
                fragments:, \
                help, \
                hideAddressBar:, \
                history:, \
                keyboard:, \
                loop:, \
                mouseWheel:, \
                overview:, \
                parallaxBackgroundHorizontal:, \
                parallaxBackgroundImage:, \
                parallaxBackgroundSize:, \
                parallaxBackgroundVertical:, \
                previewLinks:, \
                progress:, \
                question:, \
                rtl:, \
                showNotes:, \
		shuffle:, \
                slideNumber:, \
                theme:, \
                touch:, \
                transition:, \
                transitionSpeed:, \
                viewDistance:" \
            -- \
            "$@")

eval set -- "$OPTIONS"

while true; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            valid_arg "$1" "$2"
            set_config "$1" "$2"
            shift 2
            ;;
    esac
done


if [ $# -eq 0 ]; then
    set -- "grunt" "serve"
fi

exec "$@"
