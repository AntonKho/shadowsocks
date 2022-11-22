#!/bin/bash
# ss-libev-autogen is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# For GNU General Public License, please see <https://www.gnu.org/licenses/>.
#----------------------------------------------------------------------------

app_exit() {
  echo "*"
  echo -e "* \e[96mHave a nice day\e[97m !!"
  echo -e "*\e[0m"
  exit 0
}

main_menu() {
  clear
  echo -e "\e[97m****************************************"
  echo -e "* \e[92mHostingInside Shadowsocks Menu v0.2\e[97m  *"
  echo "****************************************"
  echo -e "* \e[93m1\e[97m. Install ss-libev                  *"
  echo -e "* \e[93m2\e[97m. Update ss-libev                   *"
  echo -e "* \e[93m3\e[97m. List Installed Users              *"
  echo -e "* \e[93mX\e[97m. Exit                              *"
  echo "****************************************"
  read -p "* Select[1-2,0]: " CHOOSE_MENU

  case $CHOOSE_MENU in
   1) install_libev ;;
   2) update_libev ;;
   3) list_users ;;
   x) app_exit;;
   *) main_menu
  esac;

}

install_libev() {
  clear
  echo -e "\e[97m*****************************"
  echo -e "* \e[92mInstall Shadowsocks-libev\e[97m *"
  echo "*****************************"
  /bin/mkdir ~/ss
  /bin/yum -y update && /bin/yum -y install epel-release
  /bin/wget -4 -O /etc/yum.repos.d/librehat-shadowsocks-epel-7.repo https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo
  /bin/yum clean all
  /bin/yum makecache
  /bin/yum -y install jq shadowsocks-libev
  /usr/bin/wget -4 -O ~/ss/prestart.sh http://scripts.hostinginside.com/ss/prestart.sh
  /usr/bin/wget -4 -O ~/ss/prestop.sh http://scripts.hostinginside.com/ss/prestop.sh
  /bin/systemctl stop shadowsocks-libev
  /bin/systemctl disable shadowsocks-libev

  /bin/cat <<EOF >/lib/systemd/system/shadowsocks@.service
#  This file is part of shadowsocks-libev.
#
#  Shadowsocks-libev is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This file is a copy from default for Debian/Ubuntu packaging. 

[Unit]
Description=Shadowsocks-libev Per User Server Service
Documentation=man:shadowsocks-libev(8)
After=network.target

[Service]
Type=simple
User=root
Group=root
LimitNOFILE=32768
ExecStartPre=/bin/bash /root/ss/prestart.sh %i
ExecStart=/usr/bin/ss-server -a ss%i -c /home/ss%i/ss.json -u
ExecStop=/bin/bash /root/ss/prestop.sh %i

[Install]
WantedBy=multi-user.target
EOF

  /bin/systemctl daemon-reload
  echo -e "\e[97m*"
  echo -ne "*\e[96m Done !! Press any key to continue . . .\e[97m"; read nothing
  main_menu
}

update_libev() {
  echo "*"
  echo "****************************"
  echo -e "* \e[92mUpdate Shadowsocks-libev\e[97m *"
  echo "****************************"
  /bin/yum -y update
  echo -e "\e[97m*"
  echo -ne "*\e[96m Done !! Press any key to continue . . .\e[97m"; read nothing
  main_menu
}

list_users() {
  USERS=`/bin/cat /etc/passwd | grep ^ss[0-9]*: | awk -F: '{ print $1 }'`
  arr=(${USERS// / })
  echo "*"
  echo "****************************************"
  echo -e "* \e[92mList Installed Users\e[97m                 *"
  echo "****************************************"
  echo -e "* \e[93mC\e[97m. Create New User"
  TOTALUSERS=0
  for i in "${!arr[@]}"
    do
      TOTALUSERS=$((i+1))
      UNO="${arr[$i]//ss}"
      SSIPv4=`/bin/cat /home/${arr[$i]}/ss.json | jq '.server' | tr -d \"`
      STATUS=`/bin/systemctl status shadowsocks@$UNO | grep -c "Active: active (running)"`
      if (( $STATUS == 1 )); then
        STATUS="\e[92mRunning\e[97m"
      else
        STATUS="\e[91mStop\e[97m"
      fi
      echo -e "* \e[93m$TOTALUSERS\e[97m. ${arr[$i]} ($SSIPv4, $STATUS)"
    done
  echo -e "* \e[93mU\e[97m. List SS URL"
  echo -e "* \e[93m0\e[97m. Back to Main Menu"
  echo -e "* \e[93mX\e[97m. Exit"
  echo "*"
  ask_user
}

ask_user() {
  read -p "* Select User: " SELECT_USER

  if [[ $SELECT_USER =~ [c|C] ]] ; then
    create_user
  elif [[ $SELECT_USER =~ [x|X] ]] ; then
    app_exit
  elif [[ $SELECT_USER =~ [u|U] ]] ; then
    list_ss_url    
  elif [[ ! $SELECT_USER =~ ^[0-9]+$ ]] || (( $SELECT_USER > $TOTALUSERS )) ; then
    echo -e "* \e[31mInvalid !!\e[97m"
    ask_user
  elif (( $SELECT_USER == 0 )) ; then
    main_menu
  else
    SELECT_USER=$((SELECT_USER-1))
    detail_user "${arr[$SELECT_USER]}"
  fi
}

list_ss_url() {
  USERS=`/bin/cat /etc/passwd | grep ^ss[0-9]*: | awk -F: '{ print $1 }'`
  arr=(${USERS// / })
  echo "*"
  echo "****************************************"
  echo -e "* \e[92mList Installed Users + SS URL\e[97m        *"
  echo "****************************************"
  echo -e "* \e[93mC\e[97m. Create New User"
  TOTALUSERS=0
  for i in "${!arr[@]}"
    do
      TOTALUSERS=$((i+1))
      UNO="${arr[$i]//ss}"
      SSIPv4=`/bin/cat /home/${arr[$i]}/ss.json | jq '.server' | tr -d \"`
      SSPort=`/bin/cat /home/${arr[$i]}/ss.json | jq '.server_port' | tr -d \"`
      PASSWD=`/bin/cat /home/${arr[$i]}/ss.json | jq '.password' | tr -d \"`
      METHOD=`/bin/cat /home/${arr[$i]}/ss.json | jq '.method' | tr -d \"`
      URL=`echo -n "$METHOD:$PASSWD@$SSIPv4:$SSPort" | base64`
      STATUS=`/bin/systemctl status shadowsocks@$UNO | grep -c "Active: active (running)"`
      if (( $STATUS == 1 )); then
        STATUS="\e[92mRunning\e[97m"
      else
        STATUS="\e[91mStop\e[97m"
      fi
      echo -e "* \e[93m$TOTALUSERS\e[97m. ${arr[$i]} ($SSIPv4, $URL, $STATUS)"
    done
  echo -e "* \e[93mU\e[97m. List SS URL"
  echo -e "* \e[93m0\e[97m. Back to Main Menu"
  echo -e "* \e[93mX\e[97m. Exit"
  echo "*"
  ask_user
}

create_user() {
  echo "*"
  echo "****************************************"
  echo -e "* \e[92mCreate New User\e[97m                      *"
  echo "****************************************"
  echo "* Available IPv4: "
  IPADDRS=`/sbin/ip addr |grep inet |grep -v 127.0.0.1|grep -v ::1/128|grep -v inet6 | awk -F' '  '{ print $2 }' | awk -F/ '{ print $1 }'`
  arr=(${IPADDRS// / })
  for i in "${!arr[@]}"
  do
    j=$((i+1))
    echo -e "* \e[93m$j\e[97m. ${arr[$i]}\e[97m"
  done
  echo "*"
  ask_add_ipv4 $j
  ask_add_port
  ask_add_passwd

  USEREXISTS=1
  i=0

  while [ $USEREXISTS == 1 ]
  do
    i=$((i+1))
    TEMPUSER="ss$i"
    USEREXISTS=`/bin/grep -c ^$TEMPUSER: /etc/passwd`
  done

  /usr/sbin/useradd $TEMPUSER -p $NEW_PASSWD -m
  NEW_IPv4=${arr[$((NEW_IPv4-1))]}
  save_user $TEMPUSER $NEW_IPv4 $NEW_PORT $NEW_PASSWD

  echo -e "\e[97m*"
  echo -ne "*\e[96m User $TEMPUSER created. Press any key to continue . . .\e[97m"; read nothing
  detail_user $TEMPUSER
}

ask_add_ipv4() {
  CTXT="1"
  if (( $j != 1 )) ; then
    CTXT="$CTXT - $j";
  fi
  echo -ne "* New Server IP (\e[93m$CTXT\e[97m): "; read NEW_IPv4
#  if [[ ! " ${arr[@]} " =~ " ${NEW_IPv4} " ]] ; then
  if (( ${NEW_IPv4} < 1 )) || (( ${NEW_IPv4} > $j )) ; then
    echo -e "* \e[91m$NEW_IPv4 is not valid IP !!\e[97m"
    ask_add_ipv4
  fi
}

ask_add_port() {
  echo -ne "* New Port(available \e[93m80-65535\e[97m) : "; read NEW_PORT
  if [[ ! $NEW_PORT =~ ^[0-9]+$ ]] || (( $NEW_PORT < 80 || $NEW_PORT > 65535 )) ; then
    echo -e "* \e[91m$NEW_PORT is not valid Port !! It should be between 80 - 65535\e[97m"
    ask_add_port
  fi
}

ask_add_passwd() {
  echo -ne "* New Password : "; read NEW_PASSWD
  if [[ $NEW_PASSWD = '' ]] ; then
    echo -e "* \e[91mPlease fill password with at least 8 chars\e[97m"
    ask_add_passwd 
  fi
  PWD_LEN=`/usr/bin/expr length $NEW_PASSWD`
  if (( $PWD_LEN < 8 )) ; then
    echo -e "* \e[91mInvalid Password !! It should be at least 8 chars\e[97m"
    ask_add_passwd
  fi
}

detail_user() {
  SSIPv4=`/bin/cat /home/$1/ss.json | jq '.server' | tr -d \"`
  SSPort=`/bin/cat /home/$1/ss.json | jq '.server_port' | tr -d \"`
  PASSWD=`/bin/cat /home/$1/ss.json | jq '.password' | tr -d \"`
  METHOD=`/bin/cat /home/$1/ss.json | jq '.method' | tr -d \"`
  UNAMELENGTH=`/usr/bin/expr length $1`
  END=`expr 16 - $UNAMELENGTH`
  SPACE=''
  for (( c=1; c<=$END; c++ ))
    do
      SPACE="$SPACE "
  done

  UNO="${1//ss}"
  STATUS=`/bin/systemctl status shadowsocks@$UNO | grep -c "Active: active (running)"`
  if (( $STATUS == 1 )); then
    STATUST="\e[92mRunning"
    SELECTION="Stop"
  else
    STATUST="\e[91mStop"
    SELECTION="Start"
  fi

  echo "*"
  echo "****************************************"
  echo -e "*\e[92m Config /home/$1/ss.json\e[97m$SPACE*"
  echo "****************************************"
  echo -e "* Server IP   : \e[93m$SSIPv4\e[97m"
  echo -e "* Server Port : \e[93m$SSPort\e[97m"
  echo -e "* Password    : \e[93m$PASSWD\e[97m"
  echo -e "* Method      : \e[93m$METHOD\e[97m"
  echo -e "* Status      : $STATUST\e[97m"
  echo "*"
  echo -e "* \e[93mS\e[97m. $SELECTION"
  if (( $STATUS == 0 )) ; then
    echo -e "* \e[93mE\e[97m. Edit"
  else
    echo -e "* \e[90mE. Edit (Please stop this user process to edit)\e[97m."
  fi
  echo -e "* \e[93mD\e[97m. Delete"
  echo -e "* \e[93mG\e[97m. Generate SS URL"
  echo -e "* \e[93mB\e[97m. Back to User List"
  echo -e "* \e[93mX\e[97m. Exit"
  echo "*"
  read -p "* What you want to do ? " DO_USER
  if [[ $DO_USER =~ [s|S] ]] ; then
    startstop_user $UNO $STATUS
  elif [[ $DO_USER =~ [e|E] ]] && (( $STATUS == 0 )) ; then
    edit_user $1
  elif [[ $DO_USER =~ [d|D] ]] ; then
    delete_user $1
  elif [[ $DO_USER =~ [g|G] ]] ; then
    generate_url $1 $METHOD $PASSWD $SSIPv4 $SSPort
  elif [[ $DO_USER =~ [x|X] ]] ; then
    app_exit
  elif [[ $DO_USER =~ [b|B] ]] ; then
    list_users
  else
    detail_user $1
  fi
}

startstop_user() {
  if (( $2 == 1 )) ; then
    /bin/systemctl stop shadowsocks@$1
    /bin/systemctl disable shadowsocks@$1
    TXT="stopped"
  else
    /bin/systemctl enable shadowsocks@$1
    /bin/systemctl start shadowsocks@$1
    TXT="started"
  fi
  echo -e "\e[97m*"
  echo -ne "*\e[96m User ss$1 has been $TXT. Press any key to continue . . .\e[97m"; read nothing
  detail_user ss$1
}

edit_user() {
  SSIPv4=`/bin/cat /home/$1/ss.json | jq '.server' | tr -d \"`
  SSPort=`/bin/cat /home/$1/ss.json | jq '.server_port' | tr -d \"`
  PASSWD=`/bin/cat /home/$1/ss.json | jq '.password' | tr -d \"`
  UNAMELENGTH=`/usr/bin/expr length $1`
  END=`expr 18 - $UNAMELENGTH`
  SPACE=''
  for (( c=1; c<=$END; c++ ))
    do
      SPACE="$SPACE "
  done
  echo "*"
  echo "****************************************"
  echo -e "* \e[92mEdit /home/$1/ss.json\e[97m$SPACE*"
  echo "****************************************"
  echo "* Available IPv4: "
  IPADDRS=`/sbin/ip addr |grep inet |grep -v 127.0.0.1|grep -v ::1/128|grep -v inet6 | awk -F' '  '{ print $2 }' | awk -F/ '{ print $1 }'`
  arr=(${IPADDRS// / })
  for i in "${!arr[@]}"
  do
    j=$((i+1))
    echo -e "* \e[93m$j\e[97m. ${arr[$i]}\e[97m"
  done
  echo "*"
  ask_edit_ipv4 $SSIPv4
  ask_edit_port $SSPort
  ask_edit_passwd $PASSWD

  if [[ $NEW_IPv4 = '' && $NEW_PORT = '' && $NEW_PASSWD = '' ]] ; then
    echo -e "\e[97m*"
    echo -ne "*\e[96m Nothing Change !! Press any key to continue to back to user $1 . . .\e[97m"; read nothing
    detail_user $1
  fi
  if [[ $NEW_IPv4 = '' ]] ; then
    NEW_IPv4="$SSIPv4"
  fi
  if [[ $NEW_PORT = '' ]] ; then
    NEW_PORT="$SSPort"
  fi
  if [[ $NEW_PASSWD = '' ]] ; then
    NEW_PASSWD="$PASSWD"
  fi
  NEW_IPv4=${arr[$((NEW_IPv4-1))]}
  save_user $1 $NEW_IPv4 $NEW_PORT $NEW_PASSWD

  echo -e "\e[97m*"
  echo -ne "*\e[96m File $FILE changed. Press any key to continue . . .\e[97m"; read nothing
  detail_user $1
}

ask_edit_ipv4() {
  CTXT="1"
  if (( $j != 1 )) ; then
    CTXT="$CTXT - $j";
  fi
  echo -ne "* New Server IP (\e[93m$CTXT\e[97m): "; read NEW_IPv4
#  if [[ ! " ${arr[@]} " =~ " ${NEW_IPv4} " ]] ; then
  if (( ${NEW_IPv4} < 1 )) || (( ${NEW_IPv4} > $j )) ; then
    if [[ ! " ${arr[@]} " =~ " ${NEW_IPv4} " ]] ; then
      echo -e "* \e[91m$NEW_IPv4 is not valid IP !!\e[97m"
      ask_edit_ipv4 $1
    fi
  fi
}

ask_edit_port() {
  echo -ne "* New Port(\e[93m$SSPort\e[97m, available \e[93m80-65535\e[97m) : "; read NEW_PORT
  if [[ ! $NEW_PORT = '' ]] ; then
    if [[ ! $NEW_PORT =~ ^[0-9]+$ ]] || (( $NEW_PORT < 80 || $NEW_PORT > 65535 )) ; then
      echo -e "* \e[91m$NEW_PORT is not valid Port !! It should be between 80 - 65535\e[97m"
      ask_edit_port $1
    fi
  fi
}

ask_edit_passwd() {
  echo -ne "* New Password(\e[93m$1\e[97m) : "; read NEW_PASSWD
  if [[ ! $NEW_PASSWD = '' ]] ; then
    PWD_LEN=`/usr/bin/expr length $NEW_PASSWD`
    if (( $PWD_LEN < 8 )) ; then
      echo -e "* \e[91mInvalid Password !! It should be at least 8 chars\e[97m"
      ask_edit_passwd $1
    fi
  fi
}

save_user() {
  i="${1//ss}"
  FILE="/home/$1/ss.json"
  /bin/touch $FILE
  /bin/chown $1:$1 $FILE
  /bin/cat <<EOF >$FILE
{
	"server":"$2",
	"server_port":$3,
	"local_port":100$i,
	"password":"$4",
	"timeout":300,
	"method":"chacha20-ietf-poly1305",
	"nameserver":"103.98.74.88,103.98.73.88,8.8.8.8"
}
EOF
}

delete_user() {
  i="${1//ss}"
  /bin/systemctl disable shadowsocks@$i
  /bin/systemctl stop shadowsocks@$i
  userdel -r $1

  echo -e "\e[97m*"
  echo -ne "*\e[96m User $1 deleted. Press any key to continue . . .\e[97m"; read nothing
  list_users
}

generate_url() {
  URL=`echo -n "$2:$3@$4:$5" | base64`
  echo -e "\e[97m*"
  echo -ne "* \e[96mSS URL: \e[92mss://$URL\e[96m Press any key to continue . . .\e[97m"; read nothing
  detail_user $1
}

main_menu

echo -e "\e[0m "
