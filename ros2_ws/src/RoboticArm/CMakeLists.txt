cmake_minimum_required(VERSION 3.8)
project(robothath_description)

find_package(ament_cmake REQUIRED)

install(DIRECTORY urdf meshes launch
        DESTINATION share/${PROJECT_NAME})


install(
  DIRECTORY config
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
