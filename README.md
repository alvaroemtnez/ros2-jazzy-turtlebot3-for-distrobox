# ROS2 Jazzy & CoppeliaSim Turtlebot3 Container for Distrobox

This repository contains the configuration to build and run a fully integrated robotics development and simulation environment. Built on top of **Ubuntu 24.04**, this container packages **ROS2 Jazzy**, **Gazebo Harmonic**, and **CoppeliaSim Edu v4.10.0**.

It is specifically optimized for containerized deployment via **Distrobox** on immutable/traditional Linux distributions (like Fedora Silverblue, Ubuntu, or Arch), **Windows via WSL2** and **macOS (Apple Silicon) via a Linux VM**. It provides out-of-the-box hardware graphics acceleration, shared network spaces for ROS2 DDS discovery, and seamless GUI display forwarding.

The image is built for both **amd64 (x86_64)** and **arm64 (aarch64)** architectures.

> [!WARNING]
> **CoppeliaSim is NOT available on ARM64.** Coppelia Robotics does not publish CoppeliaSim builds for Linux ARM64, so the ARM64 image (used on Apple Silicon Macs, ARM Linux machines, Raspberry Pi, etc.) does **not** include CoppeliaSim nor the simROS2 interface. Everything else (ROS2, Gazebo, RViz2, Nav2, TurtleBot3 packages...) is identical. If you need CoppeliaSim, use an amd64 (x86_64) machine.

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
It will prompt you to create a username and password for the Ubuntu VM.

2. **(Only if connecting to other ROS2 instances) Enable Mirrored Network Mode and Disable Firewall:** Open WSL Settings from the Windows Start Menu and in the "Network" tab, change the network mode to "Mirrored". This is required to make networking with other ROS2 instances work (i.e.: connect to a Turtlebot 3), as ROS2 must know the host's IP address. Also, **disable the Windows Defender firewall** or whitelist WSL, as the firewall cuts all connections ROS2 uses.

3. **Open your WSL2 Terminal:** Launch WSL from your Windows Start Menu.

4. **Install Container Engine & Distrobox:** Run the following commands inside your new Ubuntu terminal:
```bash
sudo apt update && sudo apt install -y podman distrobox

```

### macOS Hosts (Apple Silicon)

Distrobox needs a Linux kernel, so on macOS you must run it inside a Linux virtual machine. The VM runs natively on Apple Silicon (no emulation), so it will use the **ARM64 image** (remember: no CoppeliaSim, see the warning above).

1. **Install UTM:** Download it from [mac.getutm.app](https://mac.getutm.app/) (free) or the Mac App Store.

2. **Download a Linux ARM64 ISO:** Any distro works. For example, [Ubuntu Desktop 24.04 for ARM64](https://cdimage.ubuntu.com/releases/24.04/release/) (`ubuntu-24.04.x-desktop-arm64.iso`) or [Fedora Workstation for aarch64](https://fedoraproject.org/workstation/download). Make sure you pick the **ARM64 / aarch64** version, not the x86_64 one.

3. **Create the VM:** In UTM, click **Create a New Virtual Machine** → **Virtualize** (not *Emulate*) → **Linux**, and select the downloaded ISO. Recommended resources: at least **8 GB of RAM**, **4 CPU cores** and **64 GB of disk**, since Gazebo and the ROS2 stack are heavy.

4. **(Recommended) Enable graphics acceleration:** Before the first boot, open the VM settings → **Display**, and select an emulated display card marked as **GPU Supported** (e.g. `virtio-gpu-gl-pci`). This gives OpenGL acceleration to Gazebo and RViz2.

5. **(Only if connecting to other ROS2 instances) Use Bridged networking:** In the VM settings → **Network**, change the network mode from *Shared Network* to **Bridged (Advanced)** and select your Mac's active interface (Wi-Fi or Ethernet). This gives the VM its own IP on your LAN, which is needed for ROS2 to talk to other machines (i.e.: connect to a Turtlebot 3).

6. **Install Linux and follow the Linux instructions:** Boot the VM, install the distro, and then follow the [Linux Hosts](#linux-hosts) section above and the rest of this guide from inside the VM.

> **Tip:** If Gazebo crashes or renders a black window inside the VM, try launching it with software rendering: `LIBGL_ALWAYS_SOFTWARE=1 gz sim`.

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
* **Open CoppeliaSim:** `coppeliaSim.sh` (amd64 only)
* **Open Gazebo:** `gz sim`

---

## Network Switching (Discovery Server vs. Multicast)

This container includes a built-in helper network toggle utility mapped to a single, simple terminal alias.

If you are developing across multiple machines (or bridging your WSL2 environment to an external physical robot), you can bypass standard multicast discovery to reduce network overhead:

* **Switch to Discovery Server mode:**
```bash
discovery-server [SERVER_IP]

```


* **Revert back to standard multicast:**
```bash
discovery-server disable

```


* **View the network help menu:**
```bash
discovery-server

```



---

## Upgrading the Container

There are two distinct ways to handle updates depending on whether you want to quickly refresh internal software or pull down a freshly published base image from the server.

### Method 1: Upgrading Core Packages on the Fly

If you want to pull down incremental package upgrades inside the active environment without changing the structural underlying layout, you can prompt Distrobox to run an internal package sync:

```bash
distrobox-upgrade ros2-tb3

```

*Note: This utilizes Ubuntu's `apt` manager directly behind the scenes inside your box.*

### Method 2: Updating to a Fresh Base Image Registry Build

When a completely new version of the base image is pushed to the server registry (containing updated simulator architectures or pre-configured software stacks), you should reconstruct the environment container.

> **Important Data Note:** Because Distrobox completely matches and shares your host `$HOME` directory space, **removing the box will not touch your personal files, workspace project folders, or configuration files.**

Run these commands on your host system terminal (or WSL terminal):

```bash
# 1. Force pull the newest layers from the server
podman pull registre.etsinf.upv.es/ros2-jazzy-turtlebot3-for-distrobox:latest

# 2. Halt the existing container instance
distrobox stop ros2-tb3

# 3. Wipe out the old local structural instantiation
distrobox rm ros2-tb3

# 4. Instantiate a brand new instance tracking the new image base
distrobox create --image registre.etsinf.upv.es/ros2-jazzy-turtlebot3-for-distrobox:latest --name ros2-tb3

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

This builds the image for the architecture of the machine you run it on. On an ARM64 host, the same commands will produce an ARM64 image (without CoppeliaSim) automatically.

### 3. Building the ARM64 Image from an amd64 (x86_64) Linux Host

You can cross-build the ARM64 image from a regular x86_64 machine using QEMU user-mode emulation. Expect the build to be **much slower** than a native one (the whole build runs under emulation).

**a) Install QEMU user-mode emulation and register it with the kernel (binfmt):**

* **Ubuntu / Debian:**
```bash
sudo apt install -y qemu-user-static binfmt-support

```

* **Fedora Workstation:**
```bash
sudo dnf install -y qemu-user-static

```

* **Fedora Atomic (Silverblue, Kinoite, etc.):**
```bash
rpm-ostree install qemu-user-static
reboot

```

* **Arch Linux:**
```bash
sudo pacman -S qemu-user-static qemu-user-static-binfmt

```

Check that ARM64 emulation works (it should print `aarch64`):

```bash
podman run --rm --platform linux/arm64 docker.io/library/ubuntu:24.04 uname -m

```

**b) Build the ARM64 image:**

**Using Podman (Recommended):**

```bash
podman build --platform linux/arm64 -t ros2-jazzy-turtlebot3-for-distrobox:latest-arm64 -f Containerfile .

```

**Using Docker (Buildx):**

```bash
docker buildx build --platform linux/arm64 -t ros2-jazzy-turtlebot3-for-distrobox:latest-arm64 -f Containerfile --load .

```

**c) (Optional) Build a multi-architecture image for a registry:**

To publish a single tag that works on both architectures (Distrobox/Podman will automatically pull the right one for each host), build both platforms into a manifest list and push it:

```bash
podman build --platform linux/amd64,linux/arm64 --manifest ros2-jazzy-turtlebot3-for-distrobox:latest -f Containerfile .
podman manifest push --all ros2-jazzy-turtlebot3-for-distrobox:latest docker://<YOUR_REGISTRY>/ros2-jazzy-turtlebot3-for-distrobox:latest

```

> **Note:** If you get `Error: ...: image is not a manifest list`, a regular (single-architecture) image already exists locally with that same name, e.g. from a previous `podman pull` or `podman build`. Untag it first with `podman untag <IMAGE_NAME>:latest` (this only removes the name, the image and any distrobox created from it keep working) and run the build again.

With Docker Buildx, the equivalent is:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t <YOUR_REGISTRY>/ros2-jazzy-turtlebot3-for-distrobox:latest -f Containerfile --push .

```

---

## Included Packages

* **Base Layer:** Ubuntu 24.04 LTS (Noble Numbat)
* **Robotics Stack:** `ros-jazzy-desktop`, `ros-jazzy-navigation2`, `ros-jazzy-cartographer`, `ros-jazzy-slam-toolbox`, and TurtleBot3 support binaries.
* **Simulators:** Gazebo Harmonic & CoppeliaSim Edu V4.10.0 (CoppeliaSim and simROS2 interface on amd64 only).
* **Architectures:** amd64 (x86_64) and arm64 (aarch64).

---

## Known Issues Patched in the Image

* **Missing textures in the TurtleBot3 House world:** The `cafe_table` model shipped with `ros-jazzy-turtlebot3-gazebo` references its textures (`Wood_Floor_Dark.jpg`, `Maple.jpg`) with a wrong relative path, so the tables render untextured. The image patches `cafe_table.dae` to point to `../materials/textures/`.

---

## Wayland / X11

Wayland APIs for Qt (qt6-wayland and qwayland5) are not included in this image. Most of the graphical interfaces use X11. Everything has been tested and working in Wayland-only distros, using XWayland.

---

## AI Use Disclosure

This project was made with the assistance of AI development tools (Claude Opus 5.5, Gemini 3.1 Pro and 3.5 Flash, Claude Sonnet 4.6 Max and Deepseek V4 Pro) to accelerate coding and documentation. All generated code has been manually reviewed and thoroughly tested to ensure functionality and security.