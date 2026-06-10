# ROS2 Jazzy & CoppeliaSim Turtlebot3 Container for Distrobox

This repository contains the configuration to build and run a fully integrated robotics development and simulation environment. Built on top of **Ubuntu 24.04**, this container packages **ROS2 Jazzy**, **Gazebo Harmonic**, and **CoppeliaSim Edu v4.10.0**.

It is specifically optimized for cloud or local containerized deployment via **Distrobox** on immutable or traditional Linux distributions (like Fedora Silverblue, Ubuntu, or Arch). It provides out-of-the-box hardware graphics acceleration, shared network spaces for ROS2 DDS discovery, and seamless X11/Wayland display forwarding.

---

## Quick Start Guide (Pull & Run)

If you just want to pull the pre-built image and start developing immediately using **Distrobox**, follow these steps.

### 1. Create the Distrobox Container

Pull the container image from the registry and initialize it. This command isolates your environment configuration to a clean local directory while sharing necessary display and device hooks.

```bash
distrobox create \
  --image registre.etsinf.upv.es/ros2-jazzy-turtlebot3-for-distrobox:latest \
  --name ros2-tb3 \
  --home ~/.ros2-tb3_home

```

### 2. Enter the Environment

Jump directly into your new Ubuntu 24.04 workspace. All ROS2 environments, simulator paths, and core tools are sourced automatically upon entry.

```bash
distrobox enter ros2-tb3

```

### 3. Launching Applications

Once inside the container, you can run graphical applications as if they were natively installed on your host system:

* **Open RViz2:** `rviz2`
* **Open CoppeliaSim:** `coppeliaSim.sh`
* **Open Gazebo:** `gz sim`

---

## How to Build from Source

If you want to modify the packages, add custom dependencies, or host the image on your own container registry, you can build it locally using either **Podman** or **Docker**.

### 1. Clone the Repository

```bash
git clone https://git.upv.es/etsinf/ros2-jazzy-turtlebot3-for-distrobox.git
cd ros2-jazzy-turtlebot3-for-distrobox

```

### 2. Build the Image

Ensure your system has internet access, as the build process pulls down heavy graphics binaries, ROS2 core desktops, and compiler suites.

**Using Podman (Recommended for Fedora/Silverblue):**

```bash
podman build -t ros2-jazzy-turtlebot3-for-distrobox:latest -f Containerfile .

```

**Using Docker:**

```bash
docker build -t ros2-jazzy-turtlebot3-for-distrobox:latest -f Containerfile .

```

---

## Included Packages

* **Base Layer:** Ubuntu 24.04 LTS (Noble Numbat)
* **Robotics Stack:** `ros-jazzy-desktop`, `ros-jazzy-navigation2`, `ros-jazzy-cartographer`, `ros-jazzy-slam-toolbox`, and TurtleBot3 support binaries.
* **Simulators:** Gazebo Harmonic & CoppeliaSim Edu V4.10.0.