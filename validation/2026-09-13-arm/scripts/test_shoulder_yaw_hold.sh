#!/usr/bin/env bash

JOINT=shoulder_roll
LINK=l_upper_arm_link

# Home
gz topic -t /robothath/l_${JOINT}/cmd_pos \
  -m gz.msgs.Double -p 'data: 0.0'

sleep 1

for T in 10 20 25 28 30 32 35; do
    echo
    echo "=== external torque ${T} N.m ==="

    # Clear any previous wrench
    gz topic -t /world/robocup_home/wrench/clear \
      -m gz.msgs.Entity \
      -p 'name: "l_upper_arm_link", type: LINK'

    sleep 0.4

    # Re-home
    gz topic -t /robothath/l_${JOINT}/cmd_pos \
      -m gz.msgs.Double -p 'data: 0.0'

    sleep 0.8

    # Capture state
    timeout 2 gz topic -e -t /robothath/joint_state \
      > /tmp/yaw_hold_${T}.log 2>/dev/null &

    sleep 0.2

    # Apply known external world-Z torque
    gz topic -t /world/robocup_home/wrench/persistent \
      -m gz.msgs.EntityWrench \
      -p "entity: {name: \"${LINK}\", type: LINK},
          wrench: {
            force: {x: 0, y: 0, z: 0},
            torque: {x: 0, y: 0, z: ${T}}
          }"

    sleep 1.5

    # Clear wrench
    gz topic -t /world/robocup_home/wrench/clear \
      -m gz.msgs.Entity \
      -p 'name: "l_upper_arm_link", type: LINK'

    # Find maximum absolute joint displacement
    awk '
    /name: "l_shoulder_roll_joint"/ {cap=1}
    cap && /position:/ {
        p=$2+0
        a=(p<0?-p:p)
        if(a>max)max=a
        cap=0
    }
    END {
        printf "max joint displacement = %.6f rad\n", max
    }' /tmp/yaw_hold_${T}.log

    sleep 0.5
done
