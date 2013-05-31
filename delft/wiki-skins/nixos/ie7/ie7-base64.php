<?php
$data = split(";", $_SERVER["REDIRECT_QUERY_STRING"]);
$type = $data[0];
$data = split(",", $data[1]);
header("Content-type: ".$type);
echo base64_decode($data[1]);
?>