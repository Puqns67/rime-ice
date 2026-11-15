#!/usr/bin/fish

function get_dict_version
    set dict_name $argv[1]
    if test ! -e "$dict_name.dict.yaml"
        printf undefined
        return
    end
    string match --regex --quiet '^version: (?P<dict_version>[\d\."]+)$' (grep "version: " "$dict_name.dict.yaml")
    printf $dict_version
end

function set_dict_version
    set dict_name $argv[1]
    set dict_version $argv[2]
    sed --regexp-extended --in-place "s/version: [0-9\.\"]+/version: $dict_version/" "$dict_name.dict.yaml"
end

function sort_dict
    set dict_file "$argv[1].dict.yaml"
    set header_end (grep --line-number --max-count=1 '^\.\.\.$' "$dict_file" | string split --fields 1 :)
    if test -z "$header_end"
        echo "warning: no header end found in \"$dict_file\", skip sorting." >&2
        return 1
    end
    set body_start (math $header_end + 1)
    set tmp_file (mktemp)
    head --lines=$header_end "$dict_file" >$tmp_file
    if not tail --lines=+$body_start "$dict_file" | env LC_ALL=C sort --field-separator=(printf '\t') --key=2,2 >>$tmp_file
        rm --force $tmp_file
        echo "error: failed to sort \"$dict_file\"." >&2
        return 1
    end
    mv --force $tmp_file $dict_file
end

set -x GH_PROMPT_DISABLED true
set -x GH_SPINNER_DISABLED true

# moegirl
set -x GH_REPO outloudvi/mw2fcitx
set moegirl_current (get_dict_version moegirl)

echo "fetcing latest version for moegirl dict..."
set moegirl_latest (gh release list --json tagName --jq '.[0].tagName')

if test $moegirl_current = $moegirl_latest
    echo "skip update for moegirl dict."
else
    echo "update moegirl dict from \"$moegirl_current\" to \"$moegirl_latest\""
    echo "downloading latest version of moegirl dict..."
    gh release download $moegirl_latest --clobber --pattern "moegirl.dict.yaml"
    echo "download done."
    set_dict_version moegirl $moegirl_latest
    sort_dict moegirl
end

# zhwiktionary
set -x GH_REPO felixonmars/fcitx5-pinyin-zhwiki
set zhwiktionary_current (get_dict_version zhwiktionary)

echo "fetcing latest version for zhwiktionary dict..."
set _t (gh release view --json assets --jq '.assets.[].name' | grep 'zhwiktionary.*yaml' | sed --regexp-extended 's/.+([0-9]{8}).+/\1/' | sort --reverse)
set zhwiktionary_latest $_t[1]

if test $zhwiktionary_current = $zhwiktionary_latest
    echo "skip update for zhwiktionary dict."
else
    echo "update zhwiktionary dict from \"$zhwiktionary_current\" to \"$zhwiktionary_latest\""
    echo "downloading latest version of zhwiktionary dict..."
    gh release download --clobber --pattern "zhwiktionary-$zhwiktionary_latest.dict.yaml" --output "zhwiktionary.dict.yaml"
    echo "download done."
    set_dict_version zhwiktionary $zhwiktionary_latest
    sort_dict zhwiktionary
end
