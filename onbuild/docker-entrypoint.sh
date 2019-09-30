#!/bin/bash

set -e

file="index.html"

usage () {
cat <<EOF

Usage: entrypoint.sh [OPTIONS]

Options:

--autoPlayMedia=null              Global override for autoplaying embedded
                                  media (null|true|false)
--autoSlide=0                     Number of milliseconds before proceeding to
                                  next slide (disabled when set to 0)
--autoSlideStoppable=true         Stop auto-sliding after user input
                                  (true|false)
--autoSlideMethod=next            If set to the non-default setting 'right',
                                  auto-sliding navigates top level slides only
                                  (next|right)
--backgroundTransition='fade'     Transition style for full page slide
                                  backgrounds*
--center=true                     Vertical centering of slides (true|false)
--controls=true                   Display controls in the bottom right corner
                                  (true|false)
--controlsTutorial=true           Help the user learn the controls by providing
                                  hints, for example bybouncing the down arrow
                                  when they first encounter a vertical slide
                                  (true|false)
--controlsLayout='bottom-right'   Determines where controls appear
                                  ('edges'|'bottom-right')
--defaultTiming=120               Sets the pacing timer in seconds (per slide)
                                  in Speaker Notes view
--display='block'                 Sets CSS display property for slide layout,
                                  (e.g. flex), default is 'block'
--embedded=false                  Flags if the presentation is running in
                                  embedded mode, i.e. contained within a
                                  limited portion of the screen (true|false)
--fragments=true                  Turns fragments on and off globally
                                  (true|false)
--fragmentInURL=false             Flags whether to include the current fragment
                                  in the URL, so that reloading brings you to
                                  the same fragment position
                                  (true|false)
-h|--help                         Prints this usage text
--hash=false                      Add the current slide number to the URL hash
                                  so that reloading the page/copying the URL
                                  will return you to the same slide
                                  (true|false)
--hashOneBasedIndex=false         Use 1 based indexing for # links to match
                                  slide number (default is zero based)
                                  (true|false)
--hideAddressBar=true             Hides the address bar on mobile devices
                                  (true|false)
--hideCursorTime=5000             Time before the cursor is hidden (in ms)
--hideInactiveCursor=true         Hide cursor if inactive
                                  (true|false)
--history=false                   Push each slide change to the browser history
                                  (true|false)
--keyboard=true                   Enable keyboard shortcuts for navigation
                                  (true|false)
--loop=false                      Loop the presentation (true|false)
--mouseWheel=false                Enable slide navigation via mouse wheel
                                  (true|false)
--navigationMode='default'        Changes the behavior of our navigation
                                  directions. See official docs for details.
                                  (default|linear|grid)
--overview=true                   Enable the slide overview mode (true|false)
--parallaxBackgroundHorizontal=0  On slide change, amount of pixels to move
                                  parallax background (horizontal)
--parallaxBackgroundImage=''      Parallax background image location URL
--parallaxBackgroundSize=''       Parallax background size in CSS syntax (only
                                  pixel support, e.g. "2100px 900px)
--parallaxBackgroundVertical=0    On slide change, amount of pixels to move
                                  parallax background (vertical)
--pdfSeparateFragments=true       Prints each fragment on a separate slide
                                  (true|false)
--preloadIframes=null             Global override for preloading lazy-loaded
                                  iframes
                                  (null|true|false)
--previewLinks=false              Open links in an iframe preview overlay
                                  (true|false)
--progress=true                   Displays a progress bar at bottom of screen
                                  (true|false)
--question=true                   Show help overlay when questionmark pressed
                                  (true|false)
--rtl=false                       Change presentation direction right to left
                                  (true|false)
--showNotes=false                 Sets speaker's notes visible to visible
                                  (true|false)
--showSlideNumber=all             Defines which views slide numbers display on
                                  (all|speaker|print)
--shuffle=false                   Randomises the slide order
                                  (true|false)
--slideNumber=false|''            Displays number of current slide; turn off
                                  with false, default with true, 'c', 'c/t',
                                  'h/v', 'h.v' (current, total, vertical,
                                  horizontal)
--syntaxStyle='zenburn'           CSS style to use for code syntax (assumes a
                                  css file located in lib/css)
--theme=''                        Specify an alternative theme from one of
                                  those built-in**
--touch=true                      Enables touch navigation on devices that
                                  support it (true|false)
--transition='slide'              Slide transition style*
--transitionSpeed='default'       Transition speed (default|slow|fast)
--viewDistance=3                  Number of slides away from the current that
                                  are pre-loaded

*  Transition styles: concave|convex|fade|none|slide|zoom
** Themes: beige|black|blood|league|moon|night|serif|simple|sky|solarized|white

EOF
}


valid_arg () {
    case "$1" in
        --autoPlayMedia|--preloadIframes)
            case "$2" in
                null|false|true)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify null, false or true"
                    ;;
            esac
            ;;
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
        --autoSlide|--defaultTiming|--hideCursorTime|--viewDistance|--parallaxBackgroundHorizontal|--parallaxBackgroundVertical)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                return
            else
                echo "$1: bad argument, please specify an integer"
            fi
            ;;
        --controlsLayout)
            case "$2" in
                edges|bottom-right)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify edges or bottom-right"
                    ;;
                esac
            ;;
        --display)
            if [[ "$2" =~ ^[a-z-]+$ ]]; then
                return
            else
                echo "$1: bad argument, please specify a valid CSS display property"
            fi
            ;;
        --navigationMode)
            case "$2" in
                default|linear|grid)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify default, linear or grid"
                    ;;
                esac
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
        --showSlideNumber)
            case "$2" in
                all|speaker|print)
                    return
                    ;;
                *)
                    echo "$1: bad argument, please specify all, speaker, or print"
                    ;;
                esac
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
        --syntaxStyle)
            if [ -f lib/css/$2.css ]; then
                return
            else
                echo "$1: bad argument, 'lib/css/$2.css' does not exist"
            fi
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
                none|fade|slide|convex|concave|zoom)
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
    case "$1" in
        theme)
            sed -ri "s/(^[[:blank:]]*<link rel=\"stylesheet\" href=\"css\/$1\/)[[:graph:]]+(\.css\")/\1$2\2/" "$file"
            ;;
        syntaxStyle)
            sed -ri "s/(^[[:blank:]]*<link rel=\"stylesheet\" href=\"lib\/css\/)[[:graph:]]+(\.css\")/\1$2\2/" "$file"
            ;;
        *)
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
            ;;
    esac
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
        controlsLayout|display|navigationMode|showSlideNumber|transition|transitionSpeed|backgroundTransition|parallaxBackgroundImage|parallaxBackgroundSize)
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
            -l "autoPlayMedia:, \
                autoSlide:, \
                autoSlideMethod:, \
                autoSlideStoppable:, \
                backgroundTransition:, \
                center:, \
                controls:, \
                controlsLayout:, \
                controlsTutorial:, \
                defaultTiming:, \
                display:, \
                embedded:, \
                fragments:, \
                fragmentInURL:, \
                hash:, \
                hashOneBasedIndex:, \
                help, \
                hideAddressBar:, \
                hideCursorTime:, \
                hideInactiveCursor:, \
                history:, \
                keyboard:, \
                loop:, \
                mouseWheel:, \
                navigationMode:, \
                overview:, \
                parallaxBackgroundHorizontal:, \
                parallaxBackgroundImage:, \
                parallaxBackgroundSize:, \
                parallaxBackgroundVertical:, \
                pdfSeparateFragments:, \
                preloadIframes:, \
                previewLinks:, \
                progress:, \
                question:, \
                rtl:, \
                showNotes:, \
                showSlideNumber:, \
                shuffle:, \
                slideNumber:, \
                syntaxStyle:, \
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
