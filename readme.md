
---

# ROS 2 Humble + Gazebo Fortress Docker Environment

This repository provides a Docker-based environment for developing and testing ROS 2 Humble applications integrated with Gazebo Fortress (Ignition Fortress). By using Docker, you get a reproducible and isolated development environment without needing to install ROS 2 or Gazebo Fortress directly on your host machine.

## Prerequisites

- **Host Operating System:** A Linux distribution compatible with Docker (e.g., Ubuntu 20.04 or 22.04).
- **Docker:** Make sure Docker Engine is installed and running:
- **X11 Forwarding (optional):** If you want to view Gazebo’s GUI, you need to forward your host’s X server to the container:
  ```bash
  xhost +local:root
  ```

## Files

- **Dockerfile:** Defines the image with ROS 2 Humble and Gazebo Fortress.
  ```bash
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


  ```
- **docker-compose.yml:** Used to build and run the container with a simple `docker compose up`.
  ```bash
    services:
    ros2_gazebo_fortress:
        build:
        context: ./
        dockerfile: Dockerfile
        image: ros2_humble_gazebo_fortress:latest
        tty: true
        stdin_open: true
        container_name: ros2_gazebo_fortress

        environment:
        - DISPLAY=${DISPLAY}
        - QT_X11_NO_MITSHM=1
        volumes:
        - /tmp/.X11-unix:/tmp/.X11-unix:rw
        network_mode: host
  ```
## Building the Image

From the directory containing the `Dockerfile` and `docker-compose.yml`:

```bash
docker compose build
```

This will:
- Start from the `osrf/ros:humble-desktop` image.
- Add the Gazebo Fortress repository and key.
- Install `ignition-fortress`, `ros-humble-ros-ign`, and `ros-humble-ros-ign-gazebo`.
- Set up the environment so ROS 2 is sourced on container startup.

## Running the Container

To run the container:

```bash
docker compose up
```

If you’ve set `tty: true` and `stdin_open: true` in `docker-compose.yml`, you’ll be presented with a bash shell inside the container. If not, you can open a new terminal and attach to the running container:

```bash
docker exec -it ros2_gazebo_fortress bash
```

You should now have an interactive shell inside the container.

## Testing the Environment

1. **Source ROS 2**:
   ```bash
   source /opt/ros/humble/setup.bash
   ```

2. **List ROS packages**:
   ```bash
   ros2 pkg list | grep ign
   ```
   You should see packages like `ros_ign_bridge`, `ros_ign_gazebo`, etc.

3. **Run Gazebo Fortress standalone**:
   ```bash
   ign gazebo
   ```
   This should open the Gazebo Fortress GUI. If not, ensure that GUI forwarding is set up (`xhost +local:root`) and that you’re passing `-e DISPLAY=$DISPLAY` and `-v /tmp/.X11-unix:/tmp/.X11-unix:rw` in your `docker-compose.yml`.

4. **Run a ROS 2 integrated simulation**:
   ```bash
   ros2 launch ros_ign_gazebo ign_gazebo.launch.py
   ```
   This launch file should start Gazebo with ROS 2 integration, allowing you to interact with the simulation via ROS 2 topics and services.

5. **List ROS 2 topics**:
   Open another terminal inside the container:
   ```bash
   ros2 topic list
   ```
   You should see topics published by Ignition Gazebo, such as `/clock`.

6. **Echo a topic**:
   ```bash
   ros2 topic echo /clock
   ```
   You’ll see simulation time messages from the Gazebo simulation.

## Further Tutorials and Resources

- **Gazebo Fortress Documentation:**
  [https://gazebosim.org/docs/fortress](https://gazebosim.org/docs/fortress)  
  Contains tutorials and instructions for working with Ignition (Gazebo) Fortress, including spawning models, adding sensors, and writing plugins.

- **ROS 2 Documentation (Humble):**
  [https://docs.ros.org/en/humble](https://docs.ros.org/en/humble)  
  Offers tutorials on creating nodes, publishers/subscribers, services, and more, as well as integrating with simulation environments.

- **ROS-Ign Integration:**
  [https://github.com/gazebosim/ros_ign](https://github.com/gazebosim/ros_ign)  
  Detailed instructions, launch files, and packages to integrate ROS 2 with Ignition Gazebo. Learn how to bridge messages between ROS 2 and Ignition, spawn robots, and control them.

## Troubleshooting

- **Container Exits Immediately:**  
  Make sure `tty: true` and `stdin_open: true` are set in `docker-compose.yml`, or provide a long-running command (like `tail -f /dev/null`) to keep it alive.

- **No GUI:**  
  Ensure X forwarding is enabled:
  ```bash
  xhost +local:root
  ```
  And that `-e DISPLAY=$DISPLAY` and `-v /tmp/.X11-unix:/tmp/.X11-unix:rw` are in `docker-compose.yml`.

- **Package Not Found Errors:**  
  Double-check that the Gazebo and ROS 2 apt repositories were not added twice. The `osrf/ros:humble-desktop` base image already includes the ROS 2 repository. Just add the Gazebo repository as shown in the Dockerfile.

