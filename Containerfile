FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install foundational system utilities & repositories
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    gnupg \
    lsb-release \
    software-properties-common \
    ca-certificates \
    && add-apt-repository universe \
    && apt-get update \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Add ROS2 Jazzy and OSRF Gazebo package repositories
RUN export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}') \
    && curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb" \
    && dpkg -i /tmp/ros2-apt-source.deb \
    && rm /tmp/ros2-apt-source.deb \
    && curl -s https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

# 3. Install ROS2, Gazebo, Python dependencies, and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    gz-harmonic \
    ros-dev-tools \
    ros-jazzy-desktop \
    ros-jazzy-cartographer \
    ros-jazzy-cartographer-ros \
    ros-jazzy-navigation2 \
    ros-jazzy-nav2-bringup \
    ros-jazzy-slam-toolbox \
    ros-jazzy-teleop-twist-joy \
    libpcl-dev \
    ros-jazzy-turtlebot3 \
    ros-jazzy-turtlebot3-simulations \
    ros-jazzy-turtlebot3-gazebo \
    ros-jazzy-pcl-conversions \
    ros-jazzy-pcl-msgs \
    ros-jazzy-pcl-ros \
    ros-jazzy-laser-geometry \
    ros-jazzy-rqt-graph \
    ros-jazzy-example-interfaces \
    ros-jazzy-pendulum-msgs \
    xsltproc \
    python-is-python3 \
    python3-pip \
    python3-venv \
    python3-xmlschema \
    python3-colcon-common-extensions \
    python3-cbor2 \
    python3-zmq \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Download and install CoppeliaSim Edu (clearing tarball in the same layer)
RUN mkdir -p /opt/coppeliaSim \
    && wget -qO /tmp/coppeliaSim.tar.xz https://downloads.coppeliarobotics.com/V4_10_0_rev0/CoppeliaSim_Edu_V4_10_0_rev0_Ubuntu24_04.tar.xz \
    && tar -xvf /tmp/coppeliaSim.tar.xz --no-same-owner --one-top-level=/opt/coppeliaSim --strip-components=1 \
    && rm /tmp/coppeliaSim.tar.xz

# 5. Clone and build the simROS2 interface
RUN bash -c "source /opt/ros/jazzy/setup.bash \
    && cd /opt \
    && git clone https://github.com/CoppeliaRobotics/simROS2.git sim_ros2_interface \
    && cd sim_ros2_interface \
    && git checkout coppeliasim-v4.10.0-rev0 \
    && echo 'geometry_msgs/msg/TwistStamped' >> meta/interfaces.txt \
    && colcon build --symlink-install"

# 6. Configure environment variables inside global bashrc for Distrobox integration
RUN cat << 'EOF' >> /etc/bash.bashrc

# ROS2 & Turtlebot Configuration
source /opt/ros/jazzy/setup.bash
export TURTLEBOT3_MODEL=burger
export LDS_MODEL=LDS-02

echo "ROS_DISTRO=$ROS_DISTRO"

export ROS_DOMAIN_ID=0
echo "ROS_DOMAIN_ID=$ROS_DOMAIN_ID"

if [ -f "/opt/sim_ros2_interface/install/setup.bash" ]; then
    source /opt/sim_ros2_interface/install/setup.bash
fi

# CoppeliaSim Paths
export COPPELIASIM_ROOT_DIR=/opt/coppeliaSim
export PATH=$PATH:/opt/coppeliaSim
EOF

WORKDIR /workspace
CMD ["/bin/bash"]