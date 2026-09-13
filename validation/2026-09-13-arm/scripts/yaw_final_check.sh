#!/usr/bin/env bash

getpos () {
  timeout 1 gz topic -e -t /robothath/joint_state 2>/dev/null | awk '
  /name: "l_shoulder_roll_joint"/ {cap=1}
  cap && /position:/ {
      print $2
      exit
  }'
}

for T in 28 30 32; do

    # absolutely clear external load
    gz topic -t /world/robocup_home/wrench/clear \
      -m gz.msgs.Entity \
      -p 'name: "l_upper_arm_link", type: LINK'

    # home
    gz topic -t /robothath/l_shoulder_roll/cmd_pos \
      -m gz.msgs.Double -p 'data: 0.0'

    sleep 2

    P0=$(getpos)

    echo
    echo "=== ${T} N.m ==="
    echo "start = ${P0} rad"

    gz topic -t /world/robocup_home/wrench/persistent \
      -m gz.msgs.EntityWrench \
      -p "entity: {name: \"l_upper_arm_link\", type: LINK},
          wrench: {
            force: {x: 0, y: 0, z: 0},
            torque: {x: 0, y: 0, z: ${T}}
          }"

    # let PID settle
    sleep 2

    P1=$(getpos)

    echo "loaded = ${P1} rad"

    python3 - <<PY
p0=float("${P0}")
p1=float("${P1}")
print(f"steady displacement = {abs(p1-p0):.6f} rad")
PY

    gz topic -t /world/robocup_home/wrench/clear \
      -m gz.msgs.Entity \
      -p 'name: "l_upper_arm_link", type: LINK'

    sleep 1
done

gz topic -t /robothath/l_shoulder_roll/cmd_pos \
  -m gz.msgs.Double -p 'data: 0.0'
