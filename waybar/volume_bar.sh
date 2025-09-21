#!/usr/bin/env bash

# Retry until default sink is available
for i in {1..5}; do
  DEFAULT_SINK=$(pactl get-default-sink)
  if [ -n "$DEFAULT_SINK" ]; then
    break
  fi
  sleep 0.5
done

# Fallback if still not found
if [ -z "$DEFAULT_SINK" ]; then
  echo '{"text":"No audio","tooltip":"No audio device found"}'
  exit 0
fi

# Get current volume
VOLUME=$(pactl get-sink-volume "$DEFAULT_SINK" | grep -oP '\d+%' | head -1 | tr -d '%')

# Get mute status
MUTED=$(pactl get-sink-mute "$DEFAULT_SINK" | grep -q yes && echo true || echo false)

# Get cleaned output description
DESCRIPTION=$(pactl list sinks | grep -A10 "Name: $DEFAULT_SINK" | grep "Description:" | cut -d ' ' -f2-)
OUTPUT=$(echo "$DESCRIPTION" | sed -E 's/_/ /g; s/SteelSeries /SteelSeries /; s/GameDAC.*/GameDAC Pro/; s/ +$//')

# Build ASCII bar
TOTAL_BLOCKS=10
FILLED_BLOCKS=$((VOLUME * TOTAL_BLOCKS / 100))
EMPTY_BLOCKS=$((TOTAL_BLOCKS - FILLED_BLOCKS))

BAR=""
for ((i=0; i<FILLED_BLOCKS; i++)); do
  BAR+="█"
done
for ((i=0; i<EMPTY_BLOCKS; i++)); do
  BAR+="░"
done

if [ "$MUTED" = "true" ]; then
  echo "{\"text\":\"$OUTPUT Muted\",\"tooltip\":\"Output: $OUTPUT (Muted)\"}"
else
  echo "{\"text\":\"$OUTPUT $BAR $VOLUME%\",\"tooltip\":\"Output: $OUTPUT, Volume: $VOLUME%\"}"
fi
