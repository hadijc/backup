#!/bin/bash

clear
if [ "$*" == '--nohttps' ];  then
	FILEREPO=http://files.softaculous.com
else
	FILEREPO=https://files.softaculous.com
fi


#----------------------------------
# Detecting the Architecture
#----------------------------------
if ([ `uname -i` == x86_64 ] || [ `uname -m` == x86_64 ]); then
	ARCH=64
else
	ARCH=32
fi

echo "-----------------------------------------------"
echo " Welcome to Softaculous Apps Installer"
echo "-----------------------------------------------"
echo " "

#----------------------------
# Download the PHP Installer
#----------------------------

if [ -d /usr/local/cpanel ] ; then

	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/usr/local/cpanel/3rdparty/bin/php install.inc $@

elif [ -d /usr/local/directadmin ] ; then
	
	mkdir /usr/local/directadmin/plugins >> /dev/null 2>&1
	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/usr/local/bin/php -d open_basedir="" -d safe_mode=0 -d disable_functions="" install.inc $@
	
elif [ -d /usr/local/psa ] ; then
	
	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/usr/bin/php -d open_basedir="" -d safe_mode=0 -d disable_functions="" install.inc $@
	
elif [ -d /hsphere ] ; then
	
	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/hsphere/shared/php5/bin/php-cli -d open_basedir="" -d safe_mode=0 install.inc $@

elif [ -d /home/interworx ] ; then

	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/home/interworx/bin/php install.inc $@

elif [ -d /usr/local/mgr5 ]; then

	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/usr/bin/php -d open_basedir="" -d safe_mode=0 install.inc $@
	
elif [ -d /usr/local/ispmgr ] ; then

	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/usr/bin/php -d open_basedir="" -d safe_mode=0 install.inc $@

elif [ -d /usr/local/ispconfig ] ; then

	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/usr/bin/php -d open_basedir="" -d safe_mode=0 install.inc $@

elif [ -d /usr/local/cwp ] ; then

	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/usr/local/cwp/php/bin/php -d open_basedir="" -d safe_mode=0 install.inc $@
	
elif [ -d /usr/local/vesta ] ; then

	wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
	/usr/bin/php -d open_basedir="" -d safe_mode=0 install.inc $@
	
fi

phpret=$?
# Was there an error
if [ $phpret != "0" ]; then
 	exit $phpret;
fi

for opt in "$@" 
	do
	case $opt in
	"--remote")
		LOG=/var/log/softaculous_remote.log
		
		# Stop all the services of EMPS if they were there.
		/usr/local/emps/bin/mysqlctl stop >> $LOG 2>&1
		/usr/local/emps/bin/nginxctl stop >> $LOG 2>&1
		/usr/local/emps/bin/fpmctl stop >> $LOG 2>&1

		# Remove the EMPS package
		rm -rf /usr/local/emps/ >> $LOG 2>&1

		# The necessary folders
		mkdir /usr/local/emps >> $LOG 2>&1
		mkdir /usr/local/softaculous >> $LOG 2>&1

		echo "Installing EMPS..." >> $LOG 2>&1
		wget -N -O /usr/local/softaculous/EMPS.tar.gz "$FILEREPO/emps.php?arch=$ARCH" >> $LOG 2>&1

		# Extract EMPS
		tar -xvzf /usr/local/softaculous/EMPS.tar.gz -C /usr/local/emps >> $LOG 2>&1
		rm -rf /usr/local/softaculous/EMPS.tar.gz >> $LOG 2>&1

		wget -O install.inc $FILEREPO/install.inc >> /dev/null 2>&1
		/usr/local/emps/bin/php -d open_basedir="" -d zend_extension=/usr/local/emps/lib/php/ioncube_loader_lin_5.3.so install.inc $*
		;;
	"--enterprise")
		NOEMPS=0
		if [ -n "$2" ] && [ $2 == '--noemps' ] ; then
			NOEMPS=1
		fi
		
		LOG=/var/log/softaculous_enterprise.log
		
		# Stop all the services of EMPS if they were there.
		/usr/local/emps/bin/mysqlctl stop >> $LOG 2>&1
		/usr/local/emps/bin/nginxctl stop >> $LOG 2>&1
		/usr/local/emps/bin/fpmctl stop >> $LOG 2>&1

		# Remove the EMPS package
		rm -rf /usr/local/emps/ >> $LOG 2>&1
		
		# Softaculous Directory
		mkdir /usr/local/softaculous >> $LOG 2>&1

		# Install EMPS
		if [ $NOEMPS != '1' ] ; then
			# EMPS Directory
			mkdir /usr/local/emps >> $LOG 2>&1
			
			echo "Installing EMPS..."
			wget -N -O /usr/local/softaculous/EMPS.tar.gz "$FILEREPO/emps.php?arch=$ARCH" >> $LOG 2>&1
		
			# Extract EMPS
			tar -xvzf /usr/local/softaculous/EMPS.tar.gz -C /usr/local/emps >> $LOG 2>&1
			rm -rf /usr/local/softaculous/EMPS.tar.gz >> $LOG 2>&1
			
			PHPBIN=/usr/local/emps/bin/php
			OPT_IONCUBE="-d zend_extension=/usr/local/emps/lib/php/ioncube_loader_lin_5.3.so"
		else
			PHPBIN=php
			OPT_IONCUBE=""
			PHP_VER=`$PHPBIN -n -r "echo PHP_VERSION;"`
			if [ $? != 0 ]; then
				echo "PHP Version : Not Found"
				exit 1;
			else
				echo "PHP Version : $PHP_VER"
			fi
			php -m | grep ionCube > /dev/null 2>&1
			if [ $? != 0 ]; then
				echo "ionCube Loader : Not Found"
				exit 1;
			else
				echo "ionCube Loader : OK"
			fi
		fi
		
		wget -O install.inc $FILEREPO/install.inc >> $LOG 2>&1
		$PHPBIN -d open_basedir="" $OPT_IONCUBE install.inc $*
		if [ $? != 0 ] ; then
			echo "Setup was not successful"
		fi
		;;
	esac
done

