#!/bin/bash

# -------------------------------------------------------------------------- #
# Copyright 2010, K.Q. Infotech Pvt. Ltd.                                    #
#                                                                            #
# Licensed under Open-source License ; you may not use this file except in   #
# compliance  with the License. You may obtain a copy of the License as part #
# of the software distribution.                                              #
# Unless agreed to in writing, software distributed under the                #
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES             #
# OR CONDITIONS OF ANY KIND, either express or implied. See the              #
# License for the specific language governing permissions and                #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

HOME_DIR=`pwd`
KERNEL_VERSION=`uname -r`
CONFIG_PARAM=''
 
# COLORS
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtrst='\e[0m'    # Text Reset


function capture_spin {
	trap "stop_spin" SIGINT SIGTERM
}

function stdin_stdout_to_log {
	exec 6>&1
	exec &> $LOG
}

function start_spin {


	(while true
	do
        echo -en '/\010' ; sleep .1
		echo -en '-\010' ; sleep .1
		echo -en '\\\010' ; sleep .1
		echo -en '|\010' ; sleep .1 
	done) &
	SPIN_PID=$!
}

function stop_spin {
	kill $SPIN_PID
	kill $SPIN_PID
	kill $SPIN_PID
	echo ' ' 
}

function exits {
   stop_spin
   exit $1
}

# CONFIGURATION
function Message {
	echo -e "################################################"
	echo  -e $*
	echo -e "################################################"
}

function select_deployment {
	msg "Select deployment type (press '0' to exit):"
	msg "1) ZFS on Ubuntu 10.04"
	msg "2) ZFS on Ubuntu 10.10"
	msg "3) ZFS on Fedora 13"
	msg "4) ZFS on Fedora 14"
	msg "5) ZFS on Redhat 6"
	msg "6) ZFS on Gentoo"
	read DEPLOYMENT
	
	case $DEPLOYMENT in
		1)  
            # start ops
			;;
		2) 
            # start ops
			;;
		3) 
            # start ops
			;;
		4) 
            # start ops
			;;
 		5) 
            # start ops
			;;
 		6) 
            # start ops
			;;
 
 
		*)
			exits 1
			;;
	esac
	
	msg ""	
}

function ask_configuration {
	msg "You have selected an XXX deployment. Do you want automatic configuration"
	echo -n "(y/n) " >&6
	read OPT
	case $OPT in 
		y*|Y*)
			OPT='yes'
			;;
		*)	OPT='no'
			;;
	esac
	msg ""
	if [ "$OPT" = 'yes' ]; then
		msg "input YYY"
		read IP
	fi
	msg ""
}

function install_Ubuntu_pkg {
   # check for package availability
   if dpkg -s $1 ; then
     echo  -e "${txtgrn}package available: " $1 "${txtrst}"
   else 
        echo -e "${txtgrn}going to install $1 tool...${txtrst}"
        if apt-get install $1
         then
          echo -e "${txtgrn}$1 installed successfully${txtrst}"
         else
          Message "${txtred}failure. Try $1 manual installation${txtrst}"
          exits 1
         fi 
    fi
}
 
function install_Fedora_pkg {
   # check for package availability
   if yum list installed $1 ; then
     echo -e  "${txtgrn}package available: " $1 "${txtrst}"
   else 
        echo -e "${txtgrn}going to install $1...${txtrst}"
        if yum install $1
         then
          echo -e "${txtgrn}$1 installed successfully${txtrst}"
         else
          Message "${txtred}failure. Try $1 manual installation${txtrst}"
          exits 1
         fi 
    fi 
}
function install_Ubuntu_dependencies {
     DEP_LIST="gawk zlib1g-dev uuid-dev"
     for pkg in $DEP_LIST
     do
          install_Ubuntu_pkg $pkg
     done
}

function install_Fedora_dependencies {
     DEP_LIST="gcc kernel-devel-`uname -r` zlib-devel libuuid-devel"
     for pkg in $DEP_LIST
     do
          install_Fedora_pkg $pkg
     done
}


 
function resolve_dependencies {
       for OS in `cat /etc/issue` ; do echo -e "${txtgrn}Operating system: " $OS `uname -r` ${txtrst} ; break ; done
       case $OS in
        'Fedora')
             install_Fedora_dependencies 
         ;;
        'Ubuntu')
             install_Ubuntu_dependencies 
         ;;
       *)
        Message "failure. unexpected distro found. Resolve dependencies manually."
         ;;
     esac 
 
}

function startups {
       for OS in `cat /etc/issue` ; do echo -e "${txtgrn}Operating system: " $OS `uname -r` ${txtrst} ; break ; done
       case $OS in
        'Fedora')
             if cp $HOME_DIR/lzfs/etc/init.d/zfsload /etc/init.d/zfsload ; then
                echo -e "${txtgrn}${txtrst}"
             else
                echo -e "${txtred}can not copy init file ${txtrst}"  
             fi
             if chkconfig --add zfsload ; then 
                echo -e "${txtgrn}init script applied successfully${txtrst}"
             else
                echo -e "${txtred}init script initialization error ${txtrst}"  
             fi
         ;;
        'Ubuntu')
             if cp $HOME_DIR/lzfs/scripts/zfsload-ubuntu /etc/init.d/zfsload ; then
                echo -e "${txtgrn}${txtrst}"
             else
                echo -e "${txtred}can not copy init file ${txtrst}"  
             fi
             if update-rc.d zfsload defaults ; then 
                echo -e "${txtgrn}init script applied successfully${txtrst}"
             else
                echo -e "${txtred}init script initialization error ${txtrst}"  
             fi
         ;;
       *)
        Message "failure. unexpected distro found. Resolve dependencies manually."
         ;;
     esac 
 
}

function make_configure {
  if cd $HOME_DIR/$1 ; then
      echo -e "${txtgrn}configure $1  ${txtrst}"  
      if ./configure $CONFIG_PARAM ; then 
          echo -e "${txtgrn}lzfs configured successfully : ${txtrst}"
      else
          Message "${txtred}lzfs Configure error ${txtrst}"  
          exits 1
      fi
      if make ; then 
          echo -e "${txtgrn}lzfs make successful : ${txtrst}"
      else
          Message "${txtred}lzfs Make error ${txtrst}"  
          exits 1
      fi
  else
      Message "${txtred}can not cd to $HOME_DIR/zfs ${txtrst}"  
  fi 
}

function load_zfs_modules_stack {
  if cd $HOME_DIR/$1 ; then
      echo -e "${txtgrn}loading zfs module stack  ${txtrst}"  
      if ./zfs.sh -v ; then 
          echo -e "${txtgrn}zfs module stack loaded successfully : ${txtrst}"
      else
          echo -e "${txtred}error while loading zfs module stack ${txtrst}"  
      fi
  else
      Message "${txtred}can not cd to $HOME_DIR/zfs ${txtrst}"  
  fi 
}

function insert_lzfs {
  if insmod $HOME_DIR/$1 ; then 
      echo -e "${txtgrn}insmod lzfs successful${txtrst}"
  else
      echo -e "${txtred}insmod lzfs failure${txtrst}"  
  fi
}

function make_install {
# make install 
  if cd $HOME_DIR/$1 ; then
      echo -e "${txtgrn}starting $1 make install ${txtrst}"  
      if make install ; then 
          echo -e "${txtgrn}$1 make install successful : ${txtrst}"
      else
          Message "${txtred}$1 make install error ${txtrst}"  
          exits 1
      fi
  else
      Message "${txtred}can not cd to $HOME_DIR/zfs ${txtrst}"  
  fi 
}

function main { 
    if (test $UID -ne 0) then
        Message "${txtred}Error : Superuser previllages required${txtrst}"
        exit 1
    fi
    capture_spin
    start_spin
 
    echo -e "${txtgrn}starting zfs installation : ${txtrst}"
    echo -e "${txtgrn}HOME_DIR : $HOME_DIR ${txtrst}"
    echo -e "${txtgrn}KERNEK_VERSION : $KERNEL_VERSION ${txtrst}"

    resolve_dependencies 

    CONFIG_PARAM="--with-linux=/lib/modules/$KERNEL_VERSION/build" 
    make_configure spl
 
    CONFIG_PARAM=$CONFIG_PARAM" --with-spl=$HOME_DIR/spl/"
    make_configure zfs
 
    CONFIG_PARAM=$CONFIG_PARAM" --with-zfs=$HOME_DIR/zfs/"
    make_configure lzfs
 
    load_zfs_modules_stack "zfs/scripts/"
    insert_lzfs "lzfs/module/lzfs.ko"
    make_install spl
    make_install zfs
    make_install lzfs

    startups 
    stop_spin
    Message "${txtgrn}zfs installation done ${txtrst}"
    sleep 2
}

main
