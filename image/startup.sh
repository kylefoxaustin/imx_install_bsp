#!/bin/bash

##### imx-install-bsp script #####

# This is the ENTRYPOINT script which is run in the docker container imx_install_bsp
# the purpose of the script is to provide an interactive or non-interactive method of
# pulling down any i.MX yocto source base to the container and any host volume mapped to the container
#
# When run without an argument, the script will pull the default i.MX BSP
# namely: repo init -u  https://source.codeaurora.org/external/imx/imx-manifest -b imx-linux-rock -m imx-4.9.88-2.0.0_ga.xml
#
# The directory is hard coded to $HOME/nxp/imx-yocto-bsp which the BSP itself is pulled into
#
# When startup.sh is run interactively, it will enable user to input which BSP they want to pull by asking for the manifest location, the name and the version to pull down
# to run it interactively the script expects this:  startup.sh interactive
#
# This script will also enable the user to specify a USER name and PASSWORD.
# These parameters are passed to the startup.sh by the docker run command itself, not via this script's argument processing capabilities
# that is why you see USER and PASSWORD processed below without any apparent checking for those arguments to be passed into the shell itself.
# that is all handled by docker...
#
# Maintainer:  kyle fox (github.com/kylefoxaustin)



### debug messaging on or off function
### this function must always be at the top of the script as it
### may be used in the script immediately following its definition
### within the body of this script, if a debug message is to be run
### it will have the form of "debug && <command to run>
### if DEBUGON=0 then the <command to run> will be executed
### if DEBUGON=1 then the <command to run> will be ignored

debug () {
      return $DEBUGON
      }

debug && echo "Beginning of startup.sh script"



###############################
#       process arguments    #
#############################

INTERACTIVE=1
if [ "$1" != "interactive" ]; then
    debug && echo "non-interactive mode"
    INTERACTIVE=1 # user does NOT want interactive mode
else
    INTERACTIVE=0 # user WANTS interactive mode
fi


###############################
#       globals              #
#############################

# set DEBUGON initial value to OFF =1

DEBUGON=1

BINDIRECTORY="/usr/local/bin"
REPOFILE="/usr/local/bin/repo"
TERM=xterm	 
POKYDIR="${HOME}/nxp/poky"



######################################
# set the user up and permissions  ##
# either root or user supplied    ##
# via docker run -e USER         ##
##################################


debug && echo "This is the HOME directory before setting HOME to root $HOME"
debug && echo "this is the path of current directory:"
debug && pwd
debug && echo "this is who the user is $USER"
debug && sleep 2

debug && echo "setting USER to root"

USER=${USER:-root}
debug && echo "this is who the user is $USER"

debug && echo "setting HOME to root"
HOME=/root
if [ "$USER" != "root" ]; then
    debug && echo "starting user not equal to root"
    debug && echo "* enable custom user: $USER"
    useradd --create-home --shell /bin/bash --user-group --groups adm,sudo $USER

    if [ -z "$PASSWORD" ]; then
        debug && echo "Setting default password to \"password\""
        PASSWORD=password

    fi
    HOME=/home/$USER
    echo "$USER:$PASSWORD" | chpasswd

fi
debug && sleep 2


# check if 1st time run or not
# if already run, then we don't need to change permissions and don't want to
# this keeps chown from changing owernship of potentially thousands of files
# which can take a long time

if [ ! -f /usr/local/chownstatus/chownhasrun.txt ]; then
    debug && echo "This is 1st time container has run, need to chown $USER:$USER $HOME" 
    chown -R --verbose $USER:$USER $HOME
    chown -R --verbose $USER:$USER $BINDIRECTORY
    mkdir -p /usr/local/chownstatus/
    touch /usr/local/chownstatus/chownhasrun.txt 
fi


 
################################
#  Final Steps               ##
##############################


debug && echo "HOME ENV was $HOME"
debug && echo "setting HOME ENV to actual path"
debug && echo "HOME ENV is now $HOME"
debug && sleep 10

#now add line to bashrc and profile for HOME directory's actual position
#at this point, ubuntu has HOME=/home.  But if you start container as root (default) and
#don't place a new user name in the docker run command, then HOME needs to be /root
#we do the install menu prior to this so that if we are already root, we don't change
#the bashrc and profiles to 'root'

if [ "$HOME" = "/root" ]; then
    debug && echo "HOME was /root so about to set bashrc and profile exports"
    echo 'export HOME=/root/' >> /root/.bashrc
    source /root/.bashrc
    echo 'export HOME=/root/' >> /root/.profile
    source /root/.bashrc
else
    debug && echo "HOME was NOT /root so about to set bashrc and profile exports"
    echo 'export HOME=$HOME' >> /${HOME}/.bashrc
    source /${HOME}/.bashrc
    echo 'export HOME=$HOME' >> /${HOME}/.profile
    source /${HOME}/.bashrc
fi


#############################################
# Main interactive install menu           ##
# 1) setup i.MX BSP                       ##
# 2) Exit                                 ##
############################################


# ===================
# Script funtionality
# ===================
# FUNCTION: dosomething_1
# note:  for each menu item, you will create a new dosomething_x function
#        e.g. menu item 2 requires a dosomething_2 function here




################################
#  functions for menu script  ##
##############################


repocheck () {
    # function returns
    # "1" in passed-in variable REPOFILE if the repo file is not installed
    # "2" in passed-in variable REPOFILE if the repo file IS installed
    
	      debug && echo "REPOFILE is equal to $REPOFILE " > /dev/stderr
	      debug && echo "BINDIRECTORY = $BINDIRECTORY " > /dev/stderr
	      sleep 2
	      if [ ! -f "$REPOFILE" ]; then
		  debug && echo "repo does not exist in $BINDIRECTORY" > /dev/stderr
		  debug && echo "ls the directory for repo" > /dev/stderr
		  debug && sudo ls $BINDIRECTORY > /dev/stderr      
		  debug && echo $PATH > /dev/stderr
		  debug && sleep 2
		  REPOEXISTS="1"
	      elif [ -f "$REPOFILE" ]; then
		  debug && echo "repo found!  repo is installed here: $BINDIRECTORY" > /dev/stderr
		  debug && echo "ls the directory for repo" > /dev/stderr
		  debug && sudo ls $BINDIRECTORY > /dev/stderr
		  debug && echo $PATH > /dev/stderr
		  debug && sleep 2
		  REPOEXISTS="2"
	      fi
}


curl_repo () {
if [ "$1" == "non_interactive" ]; then

    echo "curl //storage.googleapis.com/git-repo-downloads/repo..."
    sudo curl https://storage.googleapis.com/git-repo-downloads/repo > temprepo
    echo "curl complete to temprepo file...."
    echo "attempting to set temprepo file  executable"
    sudo chmod a+x temprepo
    echo "copying temprepo into $REPOFILE"
    sudo cp temprepo $REPOFILE
    echo "cleaning up temprepo file..."
    sudo rm temprepo
else
    
    # function attempts to install the googleapis.com git-repo file
    echo "curl //storage.googleapis.com/git-repo-downloads/repo..."
    sudo curl https://storage.googleapis.com/git-repo-downloads/repo > temprepo
    echo "curl complete to temprepo file...."
    echo "attempting to set temprepo file  executable"
    sudo chmod a+x temprepo
    echo "copying temprepo into $REPOFILE"
    sudo cp temprepo $REPOFILE
    echo "cleaning up temprepo file..."
    sudo rm temprepo
    echo "press ENTER to continue"
    read enterkey
fi

}


repo_install() {
    if [ "$1" == "non_interactive" ]; then

	local REPOEXISTS=""
	local CHECKREPO=""
	debug && echo "inside repo_install non interactive"
	debug && echo "Checking for existance of file /usr/local/bin/repo"
	repocheck $REPOEXISTS
	debug && echo " $REPOEXISTS is the value of repo_check function"
	CHECKREPO=$REPOEXISTS
		  
	if [[ "$CHECKREPO" -eq "1" ]]; then
	    echo "repo file not found!"
	    echo "proceeding with repo installation into $REPOFILE"
	    curl_repo non_interactive
	elif [[ "$CHECKREPO" -eq "2" ]]; then
	    echo "repo file found!"
	    echo "file is located in $BINDIRECTORY"
	    echo "exiting repo install function, nothing to install..."
     	fi
	
    else

	echo "Install repo tool?  Enter Y or N" 
	debug && echo "i am inside repo_install interactive"
	local CONTINUE=0
	local REPOEXISTS=""
	local CHECKREPO=""
	read CONTINUE
	case $CONTINUE in 
	    y|Y ) debug && echo "yes"
		  debug && echo "inside repo_install interactive, Checking for existance of file /usr/local/bin/repo"
		  repocheck $REPOEXISTS
		  debug && echo " $REPOEXISTS is the value of repo_check function"
		  CHECKREPO=$REPOEXISTS
		  
		  if [[ "$CHECKREPO" -eq "1" ]]; then
		      echo "repo file not found!"
		      echo "proceeding with repo installation into $REPOFILE"
		      curl_repo
		  elif [[ "$CHECKREPO" -eq "2" ]]; then
		      echo "repo file found!"
		      echo "file is located in $BINDIRECTORY"
		      echo "exiting repo install..."
     		  fi
		  ;;
	    n|N ) echo "no";;
	    * ) echo "invalid option";;
	esac
    fi
    
}


imx_BSP_install() {


if [ "$1" == "non_interactive" ]; then
	repo_install non_interactive
	IMXBSPNAME=0
	CODEAUR=0
	IMXBSPVERSION=0
	IMXPARENTDIR="${HOME}/nxp"
	DIR="${HOME}/nxp/yocto-imx-bsp"
	YESNOEXIT=0
	echo "SOURCE REPOSITORY:  Using default https://source.codeaurora.org/external/imx/imx-manifest"  
	CODEAUR="https://source.codeaurora.org/external/imx/imx-manifest"
	echo "BSP NAME:  using default imx-linux-rocko" 
	IMXBSPNAME="imx-linux-rocko"
	echo "BSP VERSION:  using default imx-4.9.88-2.0.0_ga.xml"  
	IMXBSPVERSION="imx-4.9.88-2.0.0_ga.xml"
	
	echo "this is the init and sync that will be attempted"
	echo "repo init -u $CODEAUR -b $IMXBSPNAME -m $IMXBSPVERSION"
	debug && sleep 5
	echo "beginning repo sync"
	echo "install directory will be ./yocto-imx-bsp"
	echo "mkdir $DIR/imx-4.9.88-2.0.0_ga"
        debug && echo "i am in directory"
	debug && pwd
	mkdir -p $DIR/imx-4.9.88-2.0.0_ga
	debug && sleep 3
	echo "attempting to chown $USER to own $IMXPARENTDIR and $DIR"
	sudo chown $USER:$USER $IMXPARENTDIR
	sudo chown $USER:$USER $DIR
	echo "cd $DIR/imx-4.9.88-2.0.0_ga"
	cd $DIR/imx-4.9.88-2.0.0_ga
	debug && echo "i am now in directory"
	debug && pwd
	echo "initializing repo"
	repo init -u $CODEAUR -b $IMXBSPNAME -m $IMXBSPVERSION
	echo "initialization complete"
	echo ""
	echo "syncing repo"
	echo ""
	/usr/local/bin/repo sync
	echo ""
	echo "repo sync complete"
	cat README-IMXBSP | head
	echo -e "\n\n\n"
	echo "cat README-IMXBSP to see the complete the options on how to build"
else
    
    echo "Install i.MX 8 bsp?  Enter Y or N" 
    local CONTINUE=0
    read CONTINUE
    case $CONTINUE in 
	y|Y )
	    repo_install
	    
	    debug && echo "yes"
	    STOPLOOP=0
	    while [ $STOPLOOP -eq 0 ]
	    do
		IMXBSPNAME=0
		CODEAUR=0
		IMXBSPVERSION=0
		IMXPARENTDIR="${HOME}/nxp"
		DIR="${HOME}/nxp/yocto-imx-bsp"
		YESNOEXIT=0
		debug && echo "these are the directory values:  $IMXPARENTDIR $DIR "
		echo "I need the source code repository URL"
		echo "Just hit ENTER if you want to use default https://source.codeaurora.org/external/imx/imx-manifest"  
		echo "please enter the URL:"
		read CODEAUR
		if [ -z "$CODEAUR" ]; then
		    CODEAUR="https://source.codeaurora.org/external/imx/imx-manifest"
		fi

		echo "I need the name of the bsp" 
		echo "Just hit ENTER if you want to use default imx-linux-rocko"  
		echo "please enter the name:"
		read IMXBSPNAME
		if [ -z "$IMXBSPNAME" ]; then
		    IMXBSPNAME="imx-linux-rocko"
		fi

		echo "I need the version of the bsp" 
		echo "Just hit ENTER if you want to use default imx-4.9.88-2.0.0_ga.xml"  
		echo "please enter the version:"
		read IMXBSPVERSION
		if [ -z "$IMXBSPVERSION" ]; then
		    IMXBSPVERSION="imx-4.9.88-2.0.0_ga.xml"
		fi

		echo "this is the init and sync I will attempt:"
		echo "repo init -u $CODEAUR -b $IMXBSPNAME -m $IMXBSPVERSION"
		echo "is this correct?  enter Y (to sync), N (to redo), E (to exit)"

		read YESNOEXIT
		
		case $YESNOEXIT in 
		    y|Y ) echo "beginning repo sync"
			  echo "install directory will be ./yocto-imx-bsp"
			  
			  echo "mkdir $DIR/imx-4.9.88-2.0.0_ga"
			  mkdir -p $DIR/imx-4.9.88-2.0.0_ga
			  echo "attempting to chown $USER to own $DIR"
			  sudo chown $USER:$USER $IMXPARENTDIR
			  sudo chown $USER:$USER $DIR
			  
			  echo "cd /nxp/$DIR/imx-4.9.88-2.0.0_ga"
			  cd $DIR/imx-4.9.88-2.0.0_ga

			  echo "initializing repo"
			  repo init -u $CODEAUR -b $IMXBSPNAME -m $IMXBSPVERSION
			  echo "initialization complete"
			  echo ""
			  echo "syncing repo"
			  echo ""
			  /usr/local/bin/repo sync
			  echo ""
			  echo "repo sync complete"
			  
			  cat README-IMXBSP | head
			  
			  echo -e "\n\n\n"

			  echo "cat README-IMXBSP to see the complete the options on how to build"
			  STOPLOOP=1
			  break;;
		    n|N ) STOPLOOP=0
			  continue;;
		    e|E ) STOPLOOP=1
			  break;;
		    * ) echo "invalid option"
			STOPLOOP=0
			;;
		esac

	    done
	    ;;
	n|N ) debug && echo "no"
	      ;;
	* ) echo "invalid option"
	    ;;
    esac

fi
}

echo "ABOVE INSTALL MENU SCRIPT STRUCTURE"

# ================
# Install Menu Script structure
# ================


# FUNCTION: display menu options
# this is the main menu engine to show what you can do
show_menus() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo " Main Menu"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "  1. Install i.MX BSP"
    echo "  2. Exit"
    echo ""
}

# Use menu...
# Main menu handler loop


echo "ABOUT TO START THE MENU INSTALL"
debug && sleep 2

if [ "$INTERACTIVE" == "1" ]; then
    debug && echo "starting non-interactive mode"
    imx_BSP_install non_interactive
    echo ""
    echo ""
    echo "Installation complete"
else
    debug && echo "starting interactive mode"
    KEEPLOOPING=0
    while [ $KEEPLOOPING -eq 0 ]
    do
	show_menus
	echo "Enter choice [ 1 - 2 ] "
	menuchoice=0
	read menuchoice
	case $menuchoice in
	    1) imx_BSP_install
	       ;;
	    2) echo "exiting"
	       KEEPLOOPING=1
	       continue;;
	    *) echo -e "${RED}Error...${STD}" && sleep 2
	       ;;
	esac
	echo "Return to the Main Menu? (y/n)"
	yesno=0
	read yesno
	case $yesno in 
	    y|Y ) continue;;
	    n|N ) break;;
	esac
    done
fi
