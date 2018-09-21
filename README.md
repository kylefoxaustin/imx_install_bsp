# imx_install_yocto_poky

This container's single purpsoe is to install Yocto 'Poky' SDK.

It is flexible in that if you map a volume to /root/poky on your host machine, the full Poky SDK
will be copied to that volume on the host.

There are two modes of operation:
1) interactive
2) non-interactive

# Interactive mode
This mode launches a simple terminal based script that presents you a menu of options.
Choosing option 1) Install Poky will download and sync the Poky SDK to the container's /root/poky folder.

# How to run in interactive mode
In this example i have included a host volume in the command string.  You can omit the volume if you do not want it

docker run -i -v /mypath/mydir:/root/poky <imx_install_yocto_poky>

The continer will execute and the menu system will appear in your terminal.
select option 1, hit enter and the process will begin.
Once Poky is downloaded, you have the option to run the oe-setup script (no options, default values)
After this you can return to the main menu or exit the script.
Once you exit the menu, the container stops.

# how to run in non-interactive mode
Non-interactive mode instructs the container to download the poky sdk to /root/poky inside the container.
By default it also runs oe-setup.sh after download.

You instruct the container to run non-interactively by include the term "no_option" in the run command (without quotes).
You also remove the "-i" option in the docker run command.

docker run -v /mypath/mydir:/root/poky <imx_install_yocto_poky> no_option

# how to build
simple clone the project to your local host and run the following:

$ make build <- builds the container
$ make run <- runs a test container with default options
$ make build run <- builds the container and runs it in a test mode
