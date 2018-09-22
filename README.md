# imx_install_bsp

This container's single purpsoe is to pull down any i.MX Yocto source/image repository

It is flexible in that if you map a volume to /root/nxp on your host machine, the full Yocto repository 
will be copied to that volume on the host.

There are two modes of operation:
1) interactive
2) non-interactive

# Interactive mode
This mode launches a simple terminal based script that presents you a menu of options.
Choosing option 1) Install i.MX BSP will then guide you through specifying which one.
It has a series of defaults to use if you don't know which one to pull down.  The default is rocko

# How to run in interactive mode
In this example i have included a host volume in the command string.  You can omit the volume if you do not want it

docker run -i -v /mypath/mydir:/root/poky <imx_install_bsp> interactive

The continer will execute and the menu system will appear in your terminal.
select option 1, hit enter and the process will begin.

Once you exit the menu, the container stops.

# Non-interactive mode
This mode will run straight through installing the default i.MX BSP (default is rocko)
At this time, i have not added the ability to select your desired BSP via command line.  This is
a feature i'm working on.   But rocko is the latet published by NXP.  You can always modify startup.sh
with whatever you desire to download

# how to run in non-interactive mode
Non-interactive mode instructs the container to download the yocto repository to /root/nxp inside the container.

to run non-interactive mode, use the docker run command listed above in interactive mode but omit the argument "interactive"
so:

docker run -i -v /mypath/mydir:/root/poky <imx_install_bsp>

# How to build
simple clone the project to your local host and run the following:

Makefile based.  Here are some simple build options you can use:

$ make build <- builds the container

$ make run <- runs a test container with default options

$ make build run <- builds the container and runs it in a test mode

$ make shell <-- after performing a make run, executing a make shell command will docker exec -it bash to the running container

"cleanrun" based
I created this script to do a complete build after docker rm of all containers on your host.
This made my life a bit easier with dependencies and cluttered up containers with various builds.
WARNING:  running ./cleanrun WILL automatically stop all containers, rm all containers and will not give you an option to stop!!!! 

