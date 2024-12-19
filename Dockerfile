FROM osrf/ros:humble-desktop

ENV DEBIAN_FRONTEND=noninteractive

# Install tools needed
RUN apt-get update && apt-get install -y curl gnupg lsb-release && rm -rf /var/lib/apt/lists/*

# Add the Gazebo (Ignition Fortress) repository and key (only if not already present)
RUN curl -sSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/gazebo-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gazebo-archive-keyring.gpg] \
    http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

# Update and install Ignition Fortress and ROS-IGN packages
RUN apt-get update && apt-get install -y \
    ignition-fortress \
    ros-humble-ros-ign \
    ros-humble-ros-ign-gazebo \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
RUN apt-get update && apt-get install -y mesa-utils x11-apps && rm -rf /var/lib/apt/lists/*

# Source ROS on shell startup
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc

CMD ["/bin/bash"]
