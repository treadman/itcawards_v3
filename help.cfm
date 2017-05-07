<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<cfset GetProgramInfo(request.division_id)>

<cfset has_wrapper = false>
<cfinclude template="includes/header.cfm">

<!---<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>

<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Awards Help</title>
</head>
<body>
	<cfinclude template="includes/environment.cfm">
--->
<cfoutput>#help_message#</cfoutput>

<cfinclude template="includes/footer.cfm">
<!---
</body>
</html>
--->