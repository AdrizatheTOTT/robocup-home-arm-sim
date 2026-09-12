# Arm simulation bring-up status

Date: 2026-09-13

## Environment

Gazebo world:

    worlds/robocup_home.sdf

Controlled robot:

    simulation/robothath_both_arms.sdf

Known-good spawn transform:

    x = -0.55 m
    y = 0.00 m
    z = 1.00 m
    pitch = -1.5708 rad

The robot base is fixed to the world for manipulation development.

## Verified joints

Both sides were tested independently.

| Joint | Left | Right |
|---|---|---|
| Shoulder yaw | PASS | PASS |
| Shoulder pitch | PASS | PASS |
| Elbow pitch | PASS | PASS |
| Wrist | PASS | PASS |

The zero pose is symmetric.

Equal positive commands produced symmetric motion during the final test.
Recheck the sign convention before autonomous task development.

## Current effort limits

| Joint | Peak effort |
|---|---:|
| Shoulder pitch | 70 Nm |
| Shoulder yaw | 40 Nm |
| Elbow pitch | 25 Nm |
| Wrist | 8 Nm |

These are actuator peak limits used for simulation bring-up.

## Gripper

The left gripper has explicit control for both prismatic finger joints.

Finger travel:

    0.000 m = closed
    0.025 m = open

The Gazebo physics engine does not provide the requested native mimic
constraint, so the two fingers are commanded explicitly.

## Known model limitations

The supplied robot description currently has four revolute arm joints per
side:

    shoulder yaw
    shoulder pitch
    elbow pitch
    wrist

The intended shoulder-roll joint is absent from the supplied URDF.

The supplied package is also missing:

    l_wrist_link.stl
    r_wrist_link.stl

The wrist kinematic links still exist, but their visual and collision meshes
must be corrected when the final CAD/URDF is available.

## Next tasks

1. Recheck mirrored motion signs.
2. Determine table reach poses.
3. Test left and right grippers.
4. Execute reach, pre-grasp, grasp, lift, transfer, and release.
5. Add planning only after deterministic joint-space task execution works.
