#!/usr/bin/env bash
set -euo pipefail

pub()
{
  gz topic -t "$1" \
    -m gz.msgs.Double \
    -p "data: $2" >/dev/null
}

home()
{
  for side in l r
  do
    pub /robothath/${side}_base_yaw/cmd_pos 0.0 &
    pub /robothath/${side}_shoulder_pitch/cmd_pos 0.0 &
    pub /robothath/${side}_elbow_pitch/cmd_pos 0.0 &
    pub /robothath/${side}_wrist/cmd_pos 0.0 &
  done
  wait
}

test_arm()
{
  side="$1"

  echo "Testing $side arm"

  pub /robothath/${side}_base_yaw/cmd_pos 0.25
  sleep 1
  pub /robothath/${side}_base_yaw/cmd_pos 0.0
  sleep 1

  pub /robothath/${side}_shoulder_pitch/cmd_pos 0.35
  sleep 1
  pub /robothath/${side}_shoulder_pitch/cmd_pos 0.0
  sleep 1

  pub /robothath/${side}_elbow_pitch/cmd_pos 0.45
  sleep 1
  pub /robothath/${side}_elbow_pitch/cmd_pos 0.0
  sleep 1

  pub /robothath/${side}_wrist/cmd_pos 0.30
  sleep 1
  pub /robothath/${side}_wrist/cmd_pos 0.0
  sleep 1
}

home
test_arm l
test_arm r
home

echo "Individual arm test complete."
