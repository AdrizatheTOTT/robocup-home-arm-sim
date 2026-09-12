"""Bring up robothath in RViz.

    ros2 launch robothath_description display.launch.py

Starts robot_state_publisher, joint_state_publisher_gui, and RViz preloaded with a
RobotModel display. Set use_xacro:=true to build the description from the
.urdf.xacro instead of the plain .urdf.
"""
import os
import sys

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, OpaqueFunction
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def _setup(context, *args, **kwargs):
    pkg = get_package_share_directory('robothath_description')
    use_xacro = LaunchConfiguration('use_xacro').perform(context).lower() in ('1', 'true', 'yes')

    urdf_path = os.path.join(pkg, 'urdf', 'robothath.urdf')
    if use_xacro:
        import xacro
        robot_description = xacro.process_file(
            os.path.join(pkg, 'urdf', 'robothath.urdf.xacro')).toxml()
    else:
        with open(urdf_path, 'r') as f:
            robot_description = f.read()

    return [
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            output='screen',
            parameters=[{'robot_description': robot_description}],
        ),
        Node(
            package='rviz2',
            executable='rviz2',
            output='screen',
            arguments=['-d', os.path.join(pkg, 'launch', 'robothath.rviz')],
        ),
        Node(
            package='joint_state_publisher_gui',
            executable='joint_state_publisher_gui',
            name='joint_state_publisher_gui',
            output='screen',
        ),
    ]


def generate_launch_description():
    return LaunchDescription([
        DeclareLaunchArgument(
            'use_xacro', default_value='false',
            description='Build robot_description from the .urdf.xacro instead of the .urdf'),
        OpaqueFunction(function=_setup),
    ])
