<?php
#session_start();
#if($_SESSION["logged"] != "yes")
#{
 $agent = $_SERVER['HTTP_USER_AGENT'];
 $uri = $_SERVER['REQUEST_URI'];
 $ip = $_SERVER['REMOTE_ADDR'];
 $ref = $_SERVER['HTTP_REFERER'];
 $visitTime = date("r"); //Example: Thu, 21 Dec 2000 16:01:07 +0200

if($ip != "129.97.23.18")
 {
 $logLine = "$visitTime - IP: $ip || User Agent: $agent || Page: $uri || Referrer: $ref\n";
 $fp = fopen("visitorLog.txt", "a");
 fputs($fp, "$logLine");
 fclose($fp);
 #$_SESSION["logged"] = "no";
 #print($logLine);
 }
?>  
