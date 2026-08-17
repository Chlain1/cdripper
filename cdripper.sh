#!/bin/bash
# Automated CD ripping - insert CDs one at a time
if ! [ -x "$(command -v cdparanoia)" ]; then
    echo "cdparanoia must be installed first!"
    exit 1
fi

sanitize_filename() {
    printf '%s' "$1" \
    | sed -E 's/[<>:"|?*]//g; s/[\\/]/_/g; s/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:cntrl:]]//g'
}

fetch_metadata() {
    DISC_TITLE="Unknown Album"
    declare -Ag TRACK_NAMES
    TRACK_NAMES=()   # reset, otherwise old entries from the previous CD can survive

    for i in $(seq 1 99); do
        TRACK_NAMES[$i]="Track $(printf '%02d' "$i")"
    done

    # Make sure the dotnet tool dir is actually on PATH (tilde is NOT expanded in quotes!)
    export PATH="$PATH:$HOME/.dotnet/tools"

    if command -v dotnet >/dev/null 2>&1; then
        local discid
        discid="$(dotnet mbdiscid 2>/dev/null | grep -oP '(?<=MusicBrainz Disc ID : ).*' || true)"

        if [[ -n "$discid" && "$discid" != "0" ]]; then
            local musicbrainz_json
            musicbrainz_json="$(curl -fsSL --max-time 20 "https://musicbrainz.org/ws/2/discid/${discid}?fmt=json" 2>/dev/null || true)"

            if [[ -n "$musicbrainz_json" ]]; then
                local release_id
                release_id="$(printf '%s' "$musicbrainz_json" | jq -r '.releases[0].id // empty' 2>/dev/null || true)"

                if [[ -n "$release_id" ]]; then
                    local release_json
                    release_json="$(curl -fsSL --max-time 20 "https://musicbrainz.org/ws/2/release/${release_id}?inc=recordings+artists+artist-credits&fmt=json" 2>/dev/null || true)"

                    if [[ -n "$release_json" ]]; then
                        local album_title
                        album_title="$(printf '%s' "$release_json" | jq -r '.title // (.["release-group"].title // empty)' 2>/dev/null || true)"
                        if [[ -n "$album_title" ]]; then
                            DISC_TITLE="$album_title"
                        fi

                        while IFS=$'\t' read -r track_num track_title; do
                            [[ -z "$track_num" || -z "$track_title" ]] && continue
                            if [[ "$track_num" =~ ^[0-9]+$ ]]; then
                                TRACK_NAMES[$track_num]="$track_title"
                            fi
                        done < <(printf '%s' "$release_json" | jq -r '.media[]?.tracks[]? | select(.recording.title != null) | ((.position // .number // empty) | tostring) + "\t" + (.recording.title // "")' 2>/dev/null || true)
                    fi
                fi
            fi
        fi
    else
        echo "dotnet (mbdiscid tool) not found, skipping MusicBrainz lookup"
    fi

    if [[ "$DISC_TITLE" == "Unknown Album" ]]; then
        local cd_info
        cd_info="$(cd-info 2>/dev/null || true)"
        if [[ -n "$cd_info" ]]; then
            local derived_title
            derived_title="$(printf '%s\n' "$cd_info" | grep -E '^[[:space:]]*(Album|Disc|Title)[[:space:]]*:' | head -n 1 | sed -E 's/^[[:space:]]*(Album|Disc|Title)[[:space:]]*:[[:space:]]*//; s/[[:space:]]+$//' )"
            if [[ -n "$derived_title" ]]; then
                DISC_TITLE="$derived_title"
            fi
        fi
    fi
}

rename_tracks() {
    shopt -s nullglob
    local file num title new_name

    for file in track*.wav; do
        num="${file#track}"
        num="${num%%.*}"
        num="${num%.cdda}"

        if [[ ! "$num" =~ ^[0-9]+$ ]]; then
            continue
        fi

        title="${TRACK_NAMES[$((10#$num))]:-Track $(printf '%02d' "$((10#$num))") }"
        new_name="$(sanitize_filename "$(printf '%02d - %s.wav' "$((10#$num))" "$title")")"
        mv -- "$file" "$new_name"
    done
}

while true; do
    echo "Please insert the next CD and press Enter, or enter 'q' to quit:"
    read -r input
    [[ $input == q ]] && break

    fetch_metadata

    ALBUM_DIR="$(sanitize_filename "$DISC_TITLE")"
    mkdir -p "$ALBUM_DIR"
    cd "$ALBUM_DIR" || continue

    echo "Ripping: $DISC_TITLE"
    cdparanoia -B
    rip_status=$?

    if [ "$rip_status" -eq 0 ]; then
        rename_tracks
        echo "Saved in $ALBUM_DIR"
    else
        echo "Rip failed for $DISC_TITLE"
    fi

    eject
    cd ..

    sleep 2
done