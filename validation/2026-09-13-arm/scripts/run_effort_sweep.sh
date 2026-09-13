#!/usr/bin/env bash

RESULT=/tmp/effort_results.csv
echo "joint,axis,target_Nm,measured_peak_Nm" > "$RESULT"

run_test () {
    joint="$1"
    axis="$2"
    limit="$3"
    target="$4"

    topic="/robothath/ft/${joint}"
    log="/tmp/ft_${joint}.log"

    echo
    echo "=== ${joint} | axis ${axis} | expected ${limit} N.m ==="

    # Home all six joints before each test
    for j in base_yaw shoulder_pitch shoulder_roll elbow_pitch wrist wrist_roll; do
        gz topic -t /robothath/l_${j}/cmd_pos \
          -m gz.msgs.Double -p 'data: 0.0' >/dev/null 2>&1
    done

    sleep 1

    rm -f "$log"

    timeout 3 gz topic -e -t "$topic" \
      > "$log" 2>/dev/null &

    sleep 0.25

    gz topic -t /robothath/l_${joint}/cmd_pos \
      -m gz.msgs.Double -p "data: ${target}"

    sleep 3.2

    awk -v joint="$joint" \
        -v axis="$axis" \
        -v limit="$limit" \
        -v result="$RESULT" '
    /torque {/ {intorque=1; next}

    intorque && axis=="x" && /^[[:space:]]*x:/ {
        v=$2+0
        if(v<0)v=-v
        if(v>max)max=v
    }

    intorque && axis=="y" && /^[[:space:]]*y:/ {
        v=$2+0
        if(v<0)v=-v
        if(v>max)max=v
    }

    intorque && axis=="z" && /^[[:space:]]*z:/ {
        v=$2+0
        if(v<0)v=-v
        if(v>max)max=v
    }

    intorque && /^}/ {intorque=0}

    END {
        printf "%-18s peak = %.6f N.m   target = %.2f N.m\n",
               joint,max,limit
        printf "%s,%s,%.2f,%.6f\n",
               joint,axis,limit,max >> result
    }' "$log"

    gz topic -t /robothath/l_${joint}/cmd_pos \
      -m gz.msgs.Double -p 'data: 0.0' >/dev/null 2>&1

    sleep 0.6
}

run_test base_yaw        y 55  -1.50
run_test shoulder_pitch  z 55   1.00
run_test shoulder_roll   x 30   1.00
run_test elbow_pitch     y 25   1.20
run_test wrist           y  8   1.20
run_test wrist_roll      z  8   1.20

echo
echo "==============================="
echo "FINAL EFFORT RESULTS"
echo "==============================="
column -s, -t "$RESULT"
