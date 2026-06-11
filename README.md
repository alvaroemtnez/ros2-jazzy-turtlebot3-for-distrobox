# ROS2 Jazzy & CoppeliaSim Turtlebot3 Container for Distrobox

This repository contains the configuration to build and run a fully integrated robotics development and simulation environment. Built on top of **Ubuntu 24.04**, this container packages **ROS2 Jazzy**, **Gazebo Harmonic**, and **CoppeliaSim Edu v4.10.0**.

It is specifically optimized for containerized deployment via **Distrobox** on immutable/traditional Linux distributions (like Fedora Silverblue, Ubuntu, or Arch) and **Windows via WSL2**. It provides out-of-the-box hardware graphics acceleration, shared network spaces for ROS2 DDS discovery, and seamless GUI display forwarding.

---

## Host Prerequisites

Before jumping into the Quick Start guide, you must ensure your host operating system has both a container engine (Podman or Docker) and Distrobox installed.

### Linux Hosts

Install Podman and Distrobox using your distribution's native package manager:

* **Ubuntu / Debian / Linux Mint:**
```bash
sudo apt update && sudo apt install -y podman distrobox

```


* **Fedora Workstation:**
```bash
sudo dnf install -y podman distrobox

```


* **Fedora Atomic (Silverblue, Kinoite, etc.):**
```bash
rpm-ostree install podman distrobox
reboot

```


* **Arch Linux:**
```bash
sudo pacman -S podman distrobox

```



### Windows Hosts (WSL2)

Windows users must set up a WSL2 environment capable of running containers and GUI applications (WSLg):

1. **Install WSL2:** Open PowerShell as Administrator and run:
```powershell
wsl --install -d Ubuntu

```


*Note: Windows 11 (or modern Windows 10) is highly recommended for automatic, high-performance GUI support.*
2. **Open your WSL2 Terminal:** After rebooting, launch **Ubuntu** from your Windows Start Menu to finish the initialization (it will prompt you to create a Linux username and password).
3. **Install Container Engine & Distrobox:** Run the following commands inside your new Ubuntu terminal:
```bash
sudo apt update && sudo apt install -y podman distrobox

```



---

## Quick Start Guide (Pull & Run)

Once your host prerequisites are met, follow these steps to initialize and enter the robotics environment.

### 1. Create the Distrobox Container

Pull the container image from the registry and initialize it. This command isolates your environment configuration to a clean local directory while sharing necessary display and device hooks.

```bash
distrobox create --image registre.etsinf.upv.es/ros2-jazzy-turtlebot3-for-distrobox:latest --name ros2-tb3

```

### 2. Enter the Environment

Jump directly into your new Ubuntu 24.04 workspace. All ROS2 environments, simulator paths, and core tools are sourced automatically upon entry.

```bash
distrobox enter ros2-tb3

```

### 3. Launching Applications

Once inside the container, you can run graphical applications seamlessly. If you are on Windows, these apps will pop up as individual, hardware-accelerated Windows desktop applications:

* **Open RViz2:** `rviz2`
* **Open CoppeliaSim:** `coppeliaSim.sh`
* **Open Gazebo:** `gz sim`

---

## Network Switching (Discovery Server vs. Multicast)

This container includes a built-in helper network toggle utility mapped to a single, simple terminal alias.

If you are developing across multiple machines (or bridging your WSL2 environment to an external physical robot), you can bypass standard multicast discovery to reduce network overhead:

* **Switch to Discovery Server mode:**
```bash
discovery_server [SERVER_IP]

```


* **Revert back to standard multicast:**
```bash
discovery_server disable

```


* **View the network help menu:**
```bash
discovery_server

```



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

**Using Podman (Recommended):**

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