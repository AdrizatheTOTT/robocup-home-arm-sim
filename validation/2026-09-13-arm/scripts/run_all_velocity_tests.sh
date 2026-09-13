#!/usr/bin/env bash

TOPIC=/robothath/joint_state
OUT=/tmp/arm_velocity_results.csv

echo "joint,left_rad_s,right_rad_s,left_rpm,right_rpm" > "$OUT"

run_test () {
    joint="$1"
    target="$2"
    logfile="/tmp/vel_${joint}.log"

    echo
    echo "=== $joint : target ${target} rad ==="

    # Home this joint on both arms
    gz topic -t /robothath/l_${joint}/cmd_pos \
      -m gz.msgs.Double -p 'data: 0.0'
    gz topic -t /robothath/r_${joint}/cmd_pos \
      -m gz.msgs.Double -p 'data: 0.0'

    sleep 1

    rm -f "$logfile"

    # Capture state in background
    timeout 4 gz topic -e -t "$TOPIC" \
      > "$logfile" 2>/dev/null &

    sleep 0.3

    # Step both arms together
    gz topic -t /robothath/l_${joint}/cmd_pos \
      -m gz.msgs.Double -p "data: ${target}"

    gz topic -t /robothath/r_${joint}/cmd_pos \
      -m gz.msgs.Double -p "data: ${target}"

    sleep 4.2

    awk -v j="$joint" -v out="$OUT" '
    $0 ~ "name: \"l_" j "_joint\"" {side="L"; next}
    $0 ~ "name: \"r_" j "_joint\"" {side="R"; next}

    side=="L" && /velocity:/ {
        v=$2+0
        if(v<0) v=-v
        if(v>L) L=v
        side=""
    }

    side=="R" && /velocity:/ {
        v=$2+0
        if(v<0) v=-v
        if(v>R) R=v
        side=""
    }

    END {
        pi=3.141592653589793
        Lrpm=L*60/(2*pi)
        Rrpm=R*60/(2*pi)

        printf "LEFT : %.6f rad/s = %.2f RPM\n", L, Lrpm
        printf "RIGHT: %.6f rad/s = %.2f RPM\n", R, Rrpm

        printf "%s,%.6f,%.6f,%.2f,%.2f\n",
               j,L,R,Lrpm,Rrpm >> out
    }' "$logfile"

    # Return home
    gz topic -t /robothath/l_${joint}/cmd_pos \
      -m gz.msgs.Double -p 'data: 0.0'
    gz topic -t /robothath/r_${joint}/cmd_pos \
      -m gz.msgs.Double -p 'data: 0.0'

    sleep 1
}

run_test base_yaw        1.50
run_test shoulder_pitch  1.00
run_test shoulder_roll   1.00
run_test elbow_pitch     1.00
run_test wrist           1.00
run_test wrist_roll      1.00

echo
echo "=============================="
echo "FINAL RESULTS"
echo "=============================="
column -s, -t "$OUT"
