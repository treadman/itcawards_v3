<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
		<title>Exception Error</title>
		<STYLE TYPE="text/css">
			p, td, body {font : 12px arial; color:000000; font-weight:normal;font-family:Arial, Verdana, Helvetica, sans-serif}
			a {color:#cb0400;text-decoration:underline}
			a:hover {color:#cb0400;text-decoration:none}
			.alert {color:#cb0400;font-weight:bold}
			.actionlink {background-color:#888888;color:#ffffff;font-weight:bold;padding:2px;text-decoration:none; border:1px solid #000000}
			.actionlink:hover {background-color:#cb0400;color:#ffffff;font-weight:bold;padding:2px;text-decoration:none; border:1px solid #000000}
			.Error_Message {color::#FFFF00; font-weight:bold;}
			.Error_Details {padding:4px; background-color:#F0F8FF;}
		</STYLE>
	</head>

	<body>
<cfinclude template="includes/environment.cfm">
		<cfinvoke component="#Application.ComponentPath#.error_handling" method="init"	returnvariable="iError">
		
		<cfset iError.SetErrorDetails(Error.Diagnostics)>
		
		<cfif Application.DevApp>
			<cfset iError.FormatErrorDetails("screen")>
		<cfelse>
			<cfset iError.HandleError()>
			<cfset iError.DisplayFriendlyError()>
		</cfif>
	</body>
</html>