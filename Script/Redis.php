<?php
ini_set('default_socket_timeout', -1);
$redis = new Redis();
$ret = $redis->connect("127.0.0.1",6379);
$redis->set("user","DevilSix");
echo $redis->get("user");
?>
