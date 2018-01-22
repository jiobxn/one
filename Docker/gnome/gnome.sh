#!/bin/bash

: ${VNC_PASS:=$(pwmake 64)}
: ${VNC_VIEWONLY:=n}


init_vnc() {
	cat >/vnc.sh <<-END
	#!/bin/bash

	#gnome status
	for i in {120..0}; do
	    if [ "\$(netstat -tupnl |awk '\$NF~"/X$"{print }' |wc -l)" -eq 2 ]; then
	        break
	    fi
	    echo 'GNOME Desktop init process in progress...'
	    sleep 3
	done

	if [ "\$i" = 0 ]; then
	    echo >&2 'GNOME Desktop init process failed.'
	    exit 1
	fi

	#init vnc
	if [ ! -d /root/.vnc ]; then
	    expect -c "
	        set timeout 60
	        spawn vncserver
	        expect {
	            \"Password:\" {send \"$VNC_PASS\r\"; exp_continue}
	            \"Verify:\" {send \"$VNC_PASS\r\"; exp_continue}
	            \"*(y/n)*\" {send \"$VNC_VIEWONLY\r\"; exp_continue}
	            \"*~]# *\" {send \"exit \r\"; exp_continue}
	        }
	    "
	fi

	    sleep 2
	    pkill Xvnc
	    \rm /tmp/.X11-unix/*
	    \rm /root/.vnc/*.log || echo
	    \rm /root/.vnc/*.pid || echo
	    vncserver
	END

	chmod +x /vnc.sh
}


if [ "$1" = '/usr/sbin/init' ]; then
	nohup startx &

	if [ ! -f /vnc.sh ]; then
	    init_vnc
	fi

	atd
	echo '/bin/bash /vnc.sh' |at now + 1 minutes

	echo -e "\nVNC Server Port: 5901\nVNC Server Password: $VNC_PASS\n"
	exec "$@"
else
	echo -e " 
	Example:
				docker run -d --restart always --privileged \\
				[-v /sys/fs/cgroup:/sys/fs/cgroup:ro] \\
				-v /docker/gnome:/gnome
				-p 5901:5901 \\
				-e VNC_PASS=[pwmake 64] \\
				-e VNC_VIEWONLY=n \\
				--name gnome gnome
	"
fi
