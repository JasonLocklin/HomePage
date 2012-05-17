<?php
$password="oaueg3u056ut3qeg7uv-0b394uy8tsdgi3o894";
if ($_GET['pas'] == $password) {
	$out = fopen("server.htm", "w");
	$address = getenv('REMOTE_ADDR');
	$page = "<html><head><title>Redirecting to home server</title>
	<meta http-equiv=\"Refresh\" content=\"0; url=http://$address\">
	<script type=\"text/javascript\">
	<!--/nwindow.location = \"http://$address\"
	//-->
	</script></head>
	Our home server is currently at: <a href=\"http://$address\">http://$address</a>";

	fwrite($out, $page);
	fclose($out);
	print "success";
}
?>
