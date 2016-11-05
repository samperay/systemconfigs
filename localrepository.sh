#!/bin/bash
#
# Description:
# If there are no requirement for you to pull packages from Internet to installing the packages,
# you can use this script to build your local repository at your desired localtion.

# Summary:
# You are required to mount the installation CD/DVD/ISO image in your drive.
# this script is designed so that it would check image is mounted and would then mount to the '/media' mount point.
# It would copy all the contents from the media to your desired folder where you wanted to build your repository
# YUM pointed also added to the repository mentioned which comes pre-defined in the script.
# creates and builds your repository.
# checks are you able to query your repository
# Finally, unmounts the your media which is mounted
# you can remove your CD/DVD/ISo from the drive.

# this script is designed and tested on CentOS7


# Author: sunlnx
# email : sunlnx@gmail.com
#
##################################################################################################################

LOCALREPO=localrepo
REPONAME=centos7
LOGFILE=/tmp/centosrepo_output.log

# Check your DVD is available in the drive
function check_drive {
blkid /dev/sr0 >/dev/null
if [ $? -eq 0 ]
        then
                return 0
        else
                return 1
fi
}

# mount your DVD to some temp mount point
function mount_drive {

#fucntion call to check_drive
check_drive

#getting the return status from the fucntion called.
DRIVESTAT=$?

#mount DVD/ISO to some mount point on successful

        if [ $DRIVESTAT -eq 0 ]
        then
                echo "checking for /media as mount point"
                if [ -d "/media" ]
                  then
                                echo "media exists && attempting to mounting image...."
                                mount /dev/sr0 /media 2>/dev/null
                                [ $? -eq 0 ] && echo "image mount successful!";echo || echo "image unable to mount";echo
                  else
                   echo "/media doesn't exist, creating and mounting image";echo
                   mkdir /media
                   mount /dev/sr0 /media >/dev/null;echo
                fi

        else
                echo "Please insert the DVD/ISO image... exiting .."
                exit
        fi

}

#function call for mounting the media to mount point
mount_drive

#if you had installed minimal installation on the server, then you need to install the 'deps' package before
#creating the repository
echo --------------------------------
echo " Logs written @ $LOGFILE"
echo --------------------------------

echo;
echo "Installing the dependencies before creating reposiotry" 2>&1 | tee $LOGFILE
echo;
rpm -ivh /media/Packages/libxml2-python-2.9.1-5.el7.x86_64.rpm >>$LOGFILE 2>&1
rpm -ivh /media/Packages/deltarpm-3.6-3.el7.x86_64.rpm  >>$LOGFILE 2>&1
rpm -ivh /media/Packages/python-deltarpm-3.6-3.el7.x86_64.rpm  >>$LOGFILE 2>&1
rpm -ivh /media/Packages/createrepo-0.9.9-23.el7.noarch.rpm  >>$LOGFILE 2>&1
echo;

#dump your packages from DVD to the folder which has capacity of 4.2GB in your hard disk space
echo "Enter your path to create your repository"
read DIR
echo

#on your mentioned path, creating directory localrepo in which all packages do exists
echo "creating folder '$LOCALREPO' in $DIR"
mkdir $DIR/$LOCALREPO
echo


#check capacity on the disk to store packages
read -n1 -p "$DIR has 4.2G of free space in the Disk or LV ?[y/n]:" ch
#echo "$DIR has 4.2G of free space in the Disk or LV ?:[y/n] "
#read ch
echo
case $ch in
        y|Y) echo "copying packages to $DIR/$LOCALREPO"
               cp -arvf /media/* $DIR/$LOCALREPO  >>$LOGFILE 2>&1
                [ $? -eq 0 ] && echo "copy completed" ;echo;
        ;;

        n|N) echo "script aborted"
             exit
        ;;

        *)echo "Invalid option, re-run script"
        exit
        ;;

esac

cat >/etc/yum.repos.d/$REPONAME.repo <<EOF
[centos7]
name=CentOS 7 Local Repository
baseurl=file://$DIR/$LOCALREPO
gpgcheck=0
enabled=1
EOF

#building the repository
echo;echo "building repo"
createrepo -vg $DIR/$LOCALREPO/repodata/*.xml $DIR/$LOCALREPO/ >>$LOGFILE 2>&1
echo;echo "repo build completed"

#cleaing the repository
echo "refreshing repository..";echo
yum clean all >>$LOGFILE 2>&1
echo "clean completed.." ;echo

#Listing repositories
echo "Listing repositories";echo
yum list all
yum grouplist

#unmount the mounted media
echo "umounting the /media";echo
umount /media
        [ $? -eq 0 ] && echo "filesystem unmounted successfully !!" || echo "media unsuccessful"
echo;echo "it's safe to remove your installation image from the drive !"
echo;
echo "LOCAL YUM REPOSITORY CREATED & SUCCESSFUL !!! :) "
