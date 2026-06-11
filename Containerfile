FROM ubuntu:24.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Define CoppeliaSim environment variables properly (Build + Runtime visibility)
ENV COPPELIASIM_ROOT_DIR=/opt/coppeliaSim
ENV PATH="/opt/coppeliaSim:${PATH}"

# 1. Install foundational system utilities, repositories, and ALL precompiled locales
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    gnupg \
    lsb-release \
    software-properties-common \
    ca-certificates \
    nano vim \
    locales \
    locales-all \
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

# 6. Embed the optimized network toggle helper script into the image
RUN cat << 'EOF' > /opt/toggle_discovery.sh
#!/bin/bash

ARG1=$1
PORT=${2:-11811}
XML_FILE="/tmp/fastdds_super_client.xml"

# Help Menu / Usage info showing the custom terminal aliases
show_help() {
    echo "ROS 2 Discovery Server Network Switcher"
    echo "======================================="
    echo "Usage to connect:    discovery-server [SERVER_IP] [OPTIONAL_PORT]"
    echo "Usage to disconnect: discovery-server disable"
}

if [ -z "$ARG1" ] || [ "$ARG1" = "-h" ] || [ "$ARG1" = "--help" ]; then
    show_help
    return 0 2>/dev/null || exit 0
fi

if [ "$ARG1" = "disable" ]; then
    echo "=> Reverting network setup to standard multicast..."
    unset ROS_DISCOVERY_SERVER
    unset FASTRTPS_DEFAULT_PROFILES_FILE
    rm -f "$XML_FILE"
    echo "=> Restarting ROS 2 daemon..."
    ros2 daemon stop && ros2 daemon start
    echo "=> Success! Standard multicast active."
else
    # If it isn't "disable", the first argument must be an IP address
    SERVER_IP=$ARG1
    echo "=> Configuring ROS 2 to use Discovery Server at $SERVER_IP:$PORT..."
    
    cat <<XML > "$XML_FILE"
<?xml version="1.0" encoding="UTF-8" ?>
<dds>
    <profiles xmlns="http://www.eprosima.com/XMLSchemas/fastRTPS_Profiles">
        <participant profile_name="super_client_profile" is_default_profile="true">
            <rtps>
                <builtin>
                    <discovery_config>
                        <discoveryProtocol>SUPER_CLIENT</discoveryProtocol>
                        <discoveryServersList>
                            <RemoteServer prefix="44.53.00.5f.45.50.52.4f.53.49.4d.41">
                                <metatrafficUnicastLocatorList>
                                    <locator>
                                        <udpv4>
                                            <address>$SERVER_IP</address>
                                            <port>$PORT</port>
                                        </udpv4>
                                    </locator>
                                </metatrafficUnicastLocatorList>
                            </RemoteServer>
                        </discoveryServersList>
                    </discovery_config>
                </builtin>
            </rtps>
        </participant>
    </profiles>
</dds>
XML

    export ROS_DISCOVERY_SERVER="$SERVER_IP:$PORT"
    export FASTRTPS_DEFAULT_PROFILES_FILE="$XML_FILE"
    echo "=> Exported ROS_DISCOVERY_SERVER=$ROS_DISCOVERY_SERVER"
    echo "=> Exported FASTRTPS_DEFAULT_PROFILES_FILE=$FASTRTPS_DEFAULT_PROFILES_FILE"
    echo "=> Restarting ROS 2 daemon..."
    ros2 daemon stop && ros2 daemon start
    echo "=> Success! Super Client mode active."
fi
EOF
RUN chmod +x /opt/toggle_discovery.sh

# 7. Configure environment variables inside global bashrc for Distrobox integration
RUN cat << 'EOF' >> /etc/bash.bashrc
# ROS2 & Turtlebot Configuration
source /opt/ros/jazzy/setup.bash
source /opt/sim_ros2_interface/install/setup.bash

# CoppeliaSim Paths
export COPPELIASIM_ROOT_DIR=/opt/coppeliaSim
export PATH=$PATH:/opt/coppeliaSim

# ENV variables
export TURTLEBOT3_MODEL=burger
export LDS_MODEL=LDS-02
export ROS_DOMAIN_ID=0

# Discovery Server Aliases
alias discovery-server='source /opt/toggle_discovery.sh'

# Show Config
echo "ROS_DISTRO=$ROS_DISTRO"
echo "ROS_DOMAIN_ID=$ROS_DOMAIN_ID"

# ---------- PROMPT_COMMAND hook (array form) ----------
_ros_env_restore() {
    # Already fixed in this shell – skip
    [ -n "${_ROS_ENV_RESTORED:-}" ] && return 0

    if ! command -v ros2 >/dev/null 2>&1; then
        source /opt/ros/jazzy/setup.bash
        source /opt/sim_ros2_interface/install/setup.bash
        export PATH=$PATH:/opt/coppeliaSim
    fi

    export _ROS_ENV_RESTORED=1
}

# Set PROMPT_COMMAND as an array so that later scripts (vte) append to it,
# instead of overwriting it.
PROMPT_COMMAND=()
PROMPT_COMMAND+=("_ros_env_restore")
EOF

# Fix locale mismatch on container generation using distrobox
RUN dpkg-divert --divert /usr/sbin/update-locale.distrib --rename /usr/sbin/update-locale \
    && printf '#!/bin/bash\nexit 0\n' > /usr/sbin/update-locale \
    && chmod +x /usr/sbin/update-locale

WORKDIR /workspace
CMD ["/bin/bash"]