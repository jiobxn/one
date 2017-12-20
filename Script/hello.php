<?php
echo $_SERVER['REMOTE_ADDR'];
$myIp = getHostByName(getHostName());
echo "PHP $myIp --> \r";
session_start();
$bb = session_id();
echo "$bb\n";
phpinfo();
?>
