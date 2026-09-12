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

echo "HOME"
home
sleep 1

echo "SHOULDER PITCH"
pub /robothath/l_shoulder_pitch/cmd_pos 0.25 &
pub /robothath/r_shoulder_pitch/cmd_pos 0.25 &
wait
sleep 1

echo "ELBOW"
pub /robothath/l_elbow_pitch/cmd_pos 0.40 &
pub /robothath/r_elbow_pitch/cmd_pos 0.40 &
wait
sleep 1

echo "WRIST"
pub /robothath/l_wrist/cmd_pos 0.20 &
pub /robothath/r_wrist/cmd_pos 0.20 &
wait
sleep 1

echo "YAW"
pub /robothath/l_base_yaw/cmd_pos 0.20 &
pub /robothath/r_base_yaw/cmd_pos 0.20 &
wait
sleep 2

echo "RETURN HOME"
home

echo "Both-arm test complete."
