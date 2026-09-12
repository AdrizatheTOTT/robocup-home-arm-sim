#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/jazzy/setup.bash
source "$HOME/robocup_arm_sim/ros2_ws/install/setup.bash"

export GZ_SIM_RESOURCE_PATH="$(ros2 pkg prefix robothath_description)/share:${GZ_SIM_RESOURCE_PATH:-}"

SDF="$HOME/robocup_arm_sim/simulation/robothath_both_arms.sdf"

ros2 run ros_gz_sim create \
  -world robocup_home \
  -name robothath_live \
  -file "$SDF" \
  -x -0.55 \
  -y 0.0 \
  -z 1.0 \
  -P -1.5708

gz service -s /world/robocup_home/control \
  --reqtype gz.msgs.WorldControl \
  --reptype gz.msgs.Boolean \
  --timeout 3000 \
  --req 'pause: false'
