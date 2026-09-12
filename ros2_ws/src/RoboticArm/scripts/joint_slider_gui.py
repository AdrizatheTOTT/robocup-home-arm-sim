#!/usr/bin/env python3
"""Slider panel that publishes /joint_states, so you can pose the robot in RViz.

A stand-in for joint_state_publisher_gui, which is not installed here. It reads the
movable joints straight out of the URDF, so it stays correct if you edit the model.

    python3 joint_slider_gui.py <path-to-urdf>
"""
import sys
import threading
import tkinter as tk
import xml.etree.ElementTree as ET

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState

MOVABLE = ("revolute", "continuous", "prismatic")


def read_joints(urdf_path):
    """Return [(name, lower, upper, is_angular)] for every independently driven joint."""
    root = ET.parse(urdf_path).getroot()
    joints = []
    for j in root.findall("joint"):
        jtype = j.get("type")
        if jtype not in MOVABLE:
            continue
        # A mimic joint is driven by another joint; robot_state_publisher computes it.
        if j.find("mimic") is not None:
            continue
        limit = j.find("limit")
        if jtype == "continuous" or limit is None:
            lower, upper = -3.14159, 3.14159
        else:
            lower = float(limit.get("lower", -3.14159))
            upper = float(limit.get("upper", 3.14159))
        joints.append((j.get("name"), lower, upper, jtype != "prismatic"))
    return joints


class SliderPublisher(Node):
    def __init__(self, joints):
        super().__init__("joint_slider_gui")
        self.pub = self.create_publisher(JointState, "joint_states", 10)
        self.names = [n for n, _, _, _ in joints]
        self.values = {n: 0.0 for n in self.names}
        self.create_timer(1.0 / 30.0, self.tick)

    def tick(self):
        msg = JointState()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.name = self.names
        msg.position = [float(self.values[n]) for n in self.names]
        self.pub.publish(msg)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    urdf = sys.argv[1]
    joints = read_joints(urdf)
    if not joints:
        print(f"no movable joints found in {urdf}")
        return 1

    rclpy.init()
    node = SliderPublisher(joints)
    threading.Thread(target=rclpy.spin, args=(node,), daemon=True).start()

    win = tk.Tk()
    win.title("robothath — joint sliders")
    win.configure(padx=10, pady=10)

    scales = []

    def on_change(name):
        def handler(raw):
            node.values[name] = float(raw)
        return handler

    for row, (name, lower, upper, angular) in enumerate(joints):
        unit = "rad" if angular else "m"
        tk.Label(win, text=f"{name}  [{unit}]", anchor="w", font=("TkDefaultFont", 9)).grid(
            row=row * 2, column=0, sticky="w", pady=(6, 0)
        )
        s = tk.Scale(
            win,
            from_=lower,
            to=upper,
            resolution=(upper - lower) / 400.0,
            orient=tk.HORIZONTAL,
            length=420,
            command=on_change(name),
        )
        s.set(0.0)
        s.grid(row=row * 2 + 1, column=0, sticky="we")
        scales.append(s)

    def reset():
        for s in scales:
            s.set(0.0)

    tk.Button(win, text="Reset all to zero", command=reset).grid(
        row=len(joints) * 2, column=0, pady=(12, 0), sticky="we"
    )

    def shutdown():
        node.destroy_node()
        rclpy.shutdown()
        win.destroy()

    win.protocol("WM_DELETE_WINDOW", shutdown)
    win.mainloop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
