# Genesis 6-DOF Arm Validation — 2026-09-13

## Final architecture

Two mirrored arms.

Each arm has 6 revolute DOF:

1. Shoulder pitch
2. Shoulder roll
3. Shoulder yaw
4. Elbow pitch
5. Wrist pitch
6. Wrist roll

Target payload tested: **2.5 kg**

Simulation:
- Gazebo Sim
- ROS 2 Jazzy
- fixed robot base

---

## Anatomical joint mapping

The imported URDF names do not correspond directly to anatomical naming.

| Gazebo / URDF joint | Anatomical motion |
|---|---|
| `base_yaw` | shoulder pitch |
| `shoulder_pitch` | shoulder roll |
| `shoulder_roll` | shoulder yaw / axial rotation |
| `elbow_pitch` | elbow pitch |
| `wrist` | wrist pitch |
| `wrist_roll` | wrist roll |

---

# Final motor-output envelope validated today

| DOF | Payload | Output torque | Speed |
|---|---:|---:|---:|
| Shoulder pitch | 2.5 kg | 55 N·m | 3.0 rad/s = 28.65 RPM |
| Shoulder roll | 2.5 kg | 55 N·m | 3.0 rad/s = 28.65 RPM |
| Shoulder yaw | 2.5 kg | 30 N·m | 3.0 rad/s = 28.65 RPM |
| Elbow pitch | 2.5 kg | 25 N·m | 3.0 rad/s = 28.65 RPM |
| Wrist pitch | 2.5 kg | 8 N·m | 3.0 rad/s = 28.65 RPM |
| Wrist roll | 2.5 kg | 8 N·m | 3.0 rad/s = 28.65 RPM |

These are simulation-validated mechanical output values.

Electrical voltage, current, efficiency and temperature were NOT measured by
these tests.

---

# 6-DOF import validation

The updated URDF/Xacro contains the added:

- left shoulder roll
- right shoulder roll
- left wrist roll
- right wrist roll

The added wrist meshes were also imported.

URDF was converted successfully to SDF and all four new joints survived the
conversion.

Both arms were exercised individually and simultaneously.

All six joints on both arms move and home correctly.

---

# Controller/anatomical mapping test

Observed motion established:

- `base_yaw` -> shoulder pitch
- `shoulder_pitch` -> shoulder roll
- `shoulder_roll` -> shoulder yaw
- `elbow_pitch` -> elbow pitch
- `wrist` -> wrist pitch
- `wrist_roll` -> wrist roll

---

# Payload model

A rigid 2.5 kg payload was attached to the left gripper.

Effort ceilings used:

- shoulder pitch: 55 N·m
- shoulder roll: 55 N·m
- shoulder yaw: 30 N·m
- elbow pitch: 25 N·m
- wrist pitch: 8 N·m
- wrist roll: 8 N·m

---

# Static payload validation

## Shoulder pitch

2.5 kg payload.

Tested progressively through:

- 0.50 rad
- 1.00 rad
- 1.35 rad
- approximately 90-degree command
- 120-degree command

Initial controller:

- P approximately 45
- D approximately 1.5
- effort cap 55 N·m

The original controller was too soft near the high-load position.

It was retuned to:

- P = 500
- I = 0
- D = 20

The effort cap remained exactly:

- ±55 N·m

After retuning:

- 90-degree command reached cleanly
- 120-degree command reached cleanly
- no visible sag
- no sustained oscillation

The extra reach came from controller stiffness, NOT from increasing the
available torque.

## Shoulder roll

- payload: 2.5 kg
- effort cap: 55 N·m
- approximately 60-degree test
- reached cleanly
- held cleanly

## Shoulder yaw

- payload: 2.5 kg
- effort cap: 30 N·m
- approximately 60-degree test
- reached cleanly
- held cleanly

## Elbow pitch

- payload: 2.5 kg
- effort cap: 25 N·m
- approximately 90-degree test
- reached cleanly
- held cleanly

## Wrist pitch

- payload: 2.5 kg
- effort cap: 8 N·m
- approximately 90-degree test
- reached cleanly
- held cleanly

## Wrist roll

- payload: 2.5 kg
- effort cap: 8 N·m
- approximately 90-degree test
- held cleanly

---

# Velocity validation

Configured velocity ceiling:

- 3.0 rad/s

Converted:

- 28.6479 RPM

Joint-state telemetry was used to measure actual peak joint velocity.

Final result:

- all 6 left-arm revolute joints: PASS
- all 6 right-arm revolute joints: PASS
- all 12 joints reached approximately 3.000 rad/s
- equivalent approximately 28.65 RPM

Some first-pass right-side tests initially returned near-zero values:

- right shoulder roll controller: ~0.004091 rad/s
- right elbow: ~0.002525 rad/s
- right wrist pitch: ~0.000003 rad/s

Those were not velocity-limit failures.

The mirrored joints were rerun using the opposite command direction and then
reached the correct approximately 3.0 rad/s ceiling.

Raw logs are retained in `results/raw/`.

---

# Force / torque instrumentation

Force/torque sensors were added to all six left-arm joints.

Joint axes used for measurements:

| Joint | Axis |
|---|---|
| `l_base_yaw_joint` | Y |
| `l_shoulder_pitch_joint` | Z |
| `l_shoulder_roll_joint` | X |
| `l_elbow_pitch_joint` | Y |
| `l_wrist_joint` | Y |
| `l_wrist_roll_joint` | Z |

---

# Direct effort saturation results

## Shoulder pitch

Configured cap:

- 55 N·m

Measured sensor torque:

- exactly 55.000000 N·m

PASS.

## Shoulder roll

Configured cap:

- 55 N·m

Measured:

- exactly 55.000000 N·m

PASS.

## Elbow pitch

Configured cap:

- 25 N·m

Measured:

- exactly 25.000000 N·m

PASS.

## Wrist pitch

Configured cap:

- 8 N·m

Measured:

- exactly 8.000000 N·m

PASS.

## Wrist roll

Configured cap:

- 8 N·m

Measured:

- exactly 8.000000 N·m

PASS.

---

# Shoulder yaw effort saturation investigation

Shoulder yaw corresponds to:

- `l_shoulder_roll_joint`
- local X axis

Configured controller ceiling:

- 30 N·m

## Normal heavy-load run

Measured:

- 8.118383 N·m

Conclusion:

The pose did not require enough torque to saturate the controller.

This was not a failure.

## Invalid joint-limit attempt

A command beyond the physical joint limit was attempted to force saturation.

Measured:

- 0.096898 N·m

This method was rejected because the controller / joint-limit handling did not
produce a usable opposing-load condition.

## ApplyLinkWrench test

Gazebo `ApplyLinkWrench` was dynamically loaded.

A persistent 40 N·m world-frame external wrench was applied.

The force/torque sensor reported:

- 61.528560 N·m

This value was REJECTED as actuator output torque.

The force/torque sensor was measuring the total transmitted joint wrench,
including external wrench and joint constraint reactions.

It must NOT be reported as motor torque.

## External torque displacement sweep

External torque versus observed maximum displacement:

| External torque | Max displacement |
|---:|---:|
| 10 N·m | 0.223152 rad |
| 20 N·m | 0.434325 rad |
| 25 N·m | 0.529628 rad |
| 28 N·m | 0.534178 rad |
| 30 N·m | 0.061165 rad |
| 32 N·m | 0.815337 rad |
| 35 N·m | 0.654319 rad |

The 30 N·m sample in this sweep was anomalous and was not used as the primary
validation result.

## Final steady-state shoulder-yaw check

| External torque | Steady displacement |
|---:|---:|
| 28 N·m | 1.081031 rad |
| 30 N·m | 1.819083 rad |
| 32 N·m | 1.392682 rad |

Because the external wrench was specified in world coordinates while the joint
rotates in its local frame, these displacement values are not expected to be
strictly monotonic.

Shoulder-yaw controller configuration:

- P = 50
- cmd_max = +30 N·m
- cmd_min = -30 N·m

The external load generated position errors for which the unclamped
proportional controller demand exceeded 30 N·m.

Therefore the controller was operating at its configured ±30 N·m output cap.

Final shoulder-yaw result:

- saturation reached: YES
- configured output ceiling: 30 N·m
- validation method: controller saturation under external opposing load
- raw 61.528560 N·m FT reaction: explicitly NOT used as actuator torque

PASS.

---

# Final validation result

| Test | Result |
|---|---|
| 6-DOF arm import | PASS |
| Left-arm individual movement | PASS |
| Right-arm individual movement | PASS |
| Simultaneous dual-arm movement | PASS |
| 2.5 kg shoulder pitch hold | PASS |
| 2.5 kg shoulder roll hold | PASS |
| 2.5 kg shoulder yaw hold | PASS |
| 2.5 kg elbow hold | PASS |
| 2.5 kg wrist pitch hold | PASS |
| 2.5 kg wrist roll hold | PASS |
| Loaded 90-degree shoulder reach | PASS |
| Loaded 120-degree shoulder reach | PASS |
| 12-joint velocity limit | PASS |
| Shoulder pitch 55 N·m saturation | PASS |
| Shoulder roll 55 N·m saturation | PASS |
| Shoulder yaw 30 N·m saturation | PASS |
| Elbow 25 N·m saturation | PASS |
| Wrist pitch 8 N·m saturation | PASS |
| Wrist roll 8 N·m saturation | PASS |

---

# Electrical motor-search dataset

Use:

- shoulder pitch: 55 N·m @ 28.65 RPM
- shoulder roll: 55 N·m @ 28.65 RPM
- shoulder yaw: 30 N·m @ 28.65 RPM
- elbow pitch: 25 N·m @ 28.65 RPM
- wrist pitch: 8 N·m @ 28.65 RPM
- wrist roll: 8 N·m @ 28.65 RPM

Payload used:

- 2.5 kg

---

# Not validated by Gazebo

These tests do not validate:

- motor winding temperature
- driver temperature
- DC-bus current
- motor phase current
- battery voltage sag
- electrical efficiency
- gearbox efficiency
- gearbox backlash
- real motor torque-speed curve
- continuous hardware thermal endurance
- shock / impact loading
- manufacturing tolerances

These belong to the physical actuator and electrical bench validation phase.
