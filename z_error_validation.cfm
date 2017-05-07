<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>Validation Error</title>
<link href="includes/admin_style.css" rel="stylesheet" type="text/css">
<link href="../includes/admin_style.css" rel="stylesheet" type="text/css">
</head>

<body>
	<cfinclude template="includes/environment.cfm">

<cfoutput>
<br><br>
<span class="alert">#error.ValidationHeader#</span><br><br>
The item(s) that need attention:<br>
#error.InvalidFields#
Please go <a href="javascript:history.back()" class="actionlink">back</a> and correct the problem.
</cfoutput>
</body>
</html>