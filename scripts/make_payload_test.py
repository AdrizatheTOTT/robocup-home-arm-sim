#!/usr/bin/env python3

import argparse
import xml.etree.ElementTree as ET
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--side", choices=["l", "r"], required=True)
parser.add_argument("--mass", type=float, required=True)
parser.add_argument(
    "--mode",
    choices=["continuous", "peak"],
    default="continuous",
)
parser.add_argument(
    "--input",
    default="simulation/robothath_both_arms.sdf",
)
parser.add_argument(
    "--output",
    default="/tmp/robothath_payload.sdf",
)
args = parser.parse_args()

if args.mass <= 0:
    raise SystemExit("Payload mass must be > 0")

tree = ET.parse(args.input)
root = tree.getroot()
model = root.find("model")

if model is None:
    raise SystemExit("No <model> found")

# Current actuator specification.
if args.mode == "continuous":
    limits = {
        "base_yaw": 30.0,
        "shoulder_pitch": 55.0,
        "elbow_pitch": 25.0,
        "wrist": 8.0,
    }
else:
    limits = {
        "base_yaw": 40.0,
        "shoulder_pitch": 70.0,
        "elbow_pitch": 25.0,
        "wrist": 8.0,
    }

# Make the SDF physics limits match the controller limits.
for side in ("l", "r"):
    for suffix, effort in limits.items():
        joint_name = f"{side}_{suffix}_joint"
        joint = model.find(f"./joint[@name='{joint_name}']")

        if joint is None:
            continue

        e = joint.find("axis/limit/effort")
        if e is not None:
            e.text = str(effort)

# Make PID output limits match the intended actuator effort.
for plugin in model.findall("plugin"):
    joint_name = plugin.findtext("joint_name")

    if not joint_name:
        continue

    for side in ("l", "r"):
        for suffix, effort in limits.items():
            if joint_name == f"{side}_{suffix}_joint":
                max_e = plugin.find("cmd_max")
                min_e = plugin.find("cmd_min")

                if max_e is not None:
                    max_e.text = str(effort)

                if min_e is not None:
                    min_e.text = str(-effort)

# Add joint-state output for quantitative testing.
jsp = ET.SubElement(
    model,
    "plugin",
    {
        "filename": "gz-sim-joint-state-publisher-system",
        "name": "gz::sim::systems::JointStatePublisher",
    },
)

ET.SubElement(jsp, "topic").text = "/robothath/joint_state"
ET.SubElement(jsp, "update_rate").text = "100"

# Rigid test payload.
side = args.side
mass = args.mass
size = 0.08

# Cube inertia.
I = mass * size * size / 6.0

link = ET.SubElement(
    model,
    "link",
    {"name": f"{side}_payload_test"},
)

pose = ET.SubElement(
    link,
    "pose",
    {"relative_to": f"{side}_wrist_link"},
)

# Payload COM approximately beyond the gripper.
pose.text = "0 0 -0.50 0 0 0"

inertial = ET.SubElement(link, "inertial")
ET.SubElement(inertial, "mass").text = str(mass)

inertia = ET.SubElement(inertial, "inertia")
ET.SubElement(inertia, "ixx").text = str(I)
ET.SubElement(inertia, "iyy").text = str(I)
ET.SubElement(inertia, "izz").text = str(I)
ET.SubElement(inertia, "ixy").text = "0"
ET.SubElement(inertia, "ixz").text = "0"
ET.SubElement(inertia, "iyz").text = "0"

collision = ET.SubElement(link, "collision", {"name": "collision"})
geometry = ET.SubElement(collision, "geometry")
box = ET.SubElement(geometry, "box")
ET.SubElement(box, "size").text = f"{size} {size} {size}"

visual = ET.SubElement(link, "visual", {"name": "visual"})
geometry = ET.SubElement(visual, "geometry")
box = ET.SubElement(geometry, "box")
ET.SubElement(box, "size").text = f"{size} {size} {size}"

joint = ET.SubElement(
    model,
    "joint",
    {
        "name": f"{side}_payload_fixed_joint",
        "type": "fixed",
    },
)

ET.SubElement(joint, "parent").text = f"{side}_wrist_link"
ET.SubElement(joint, "child").text = f"{side}_payload_test"

tree.write(
    args.output,
    encoding="utf-8",
    xml_declaration=True,
)

print(f"Created {args.output}")
print(f"Payload: {mass:.3f} kg")
print(f"Side: {side}")
print(f"Mode: {args.mode}")
print(f"Limits: {limits}")
