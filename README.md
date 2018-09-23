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

docker run -i -v /mypath/mydir:/root/poky <imx_install_bsp> --interactive
You can shorten the --interactive to just -i and it will run interactively

The continer will execute and the menu system will appear in your terminal.
select option 1, hit enter and the process will begin.

Once you exit the menu, the container stops.

# Non-interactive mode
This mode will run straight through installing the default i.MX BSP (default is rocko)

There are two primary methods:
1) utilize the default BSP naming stated within the startup.sh script (BSP name = rocko)
2) input your desired BSP via the command line arguments of the docker run command

# how to run in non-interactive mode
Non-interactive mode instructs the container to download the yocto repository to /root/nxp inside the container.

to run non-interactive mode, use the docker run command listed above in interactive mode but omit the argument "interactive"
so:

docker run -i -v /mypath/mydir:/root/poky <imx_install_bsp>

if you want the container to process a specific BSP, then the format for your command is the following:

docker run -i -v /mypath/mydir:/root/nxp <imx_install_bsp> --source ARG1 ARG2 ARG3

where:

  ARG1 = URL for the codeaurora site where the BSP resides (e.g.: https://source.codeaurora.org/external/imx/imx-manifest)
  
  ARG2 = Name of the i.MX BSP you desire (e.g. imx-linux-rocko)
  
  ARG3 = version of the i.MX BSP (e.g. imx-4.9.88-2.0.0_ga.xml) \
  

As an example:
docker run -i -v /mypath/mydir:/root/nxp imx_install_bsp --source https://source.codeaurora.org/external/imx/imx-manifest imx-linux-rocko imx-4.9.88-2.0.0_ga.xml

if you don't specify all three values, the container will use its defaults (which is the rocko bsp version)
however, you cannot skip a value.. e.g. if you only want to include an i.MX BSP version # on the command line, you 
must include the URL and BSP name.  however, if you include the Code Aurora URL and the i.MX BSP name but leave off the BSP version, then the container will default the version to the internal default it was programmed with. 

# Simple examples of use

assume the name of the docker image is imx_install_bsp and this is what you will docker run

Basic interactive examples:
- docker run -i imx_install_bsp --interactive
      --> runs the container interactively with the terminal based menu.  You can choose your BSP to download within the menu
      --> the BSP will be placed within the container at /root/nxp.

- docker run -i imx_install_bsp --interactive --source https://source.codeaurora.org/external/imx/imx-manifest imx-linux-rock imx-4.9.88-2.0.0_ga.xml
      --> this will run the interactive version and the default BSP sources will be what you placed in the command line (e.g. imx-linux-rocko)
      --> the BSP will be placed within the container at /root/nxp
      
- docker run -i -v /mypath/mydir:/root/nxp imx_install_bsp --interactive
      --> same as 1st example however the output of the container will appear in the host directory /mypath/mydir as well as in the container /root/nxp/

- docker run -i -v /mypath/mydir:/root/nxp imx_install_bsp --interactive --source https://source.codeaurora.org/external/imx/imx-manifest imx-linux-rock imx-4.9.88-2.0.0_ga.xml
     --> same as 2nd example except the BSP will be placed within the container at /root/nxp as well as the host directory /mypath/mydir

Basic non-interactive examples:
- non interactive examples are exactly the same as the interactive examples except you will remove the --interactive flag.
- by doing this the container will run to completion and then exit.   The BSP will be loaded into the container at /root/nxp and if you mapped a host directory,
  in /mypath/mydir as well
  
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

