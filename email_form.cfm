<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>
<cfparam name="emailsent" default="">

<cfif CGI.REQUEST_METHOD EQ 'Post'>

	<cfif Application.OverrideEmail NEQ "">
		<cfset this_to = Application.OverrideEmail>
	<cfelse>
		<cfset this_to = email_form_recipient>
	</cfif>
	<cfmail to="#this_to#" from="#form.form_email#" subject="#form.program_name# Email Form Submitted">
		<cfif Application.OverrideEmail NEQ "">
			Emails are being overridden.<br>
			Below is the email that would have been sent to #email_form_recipient#<br>
			<hr>
		</cfif>
	
	**********************************************
	This was submitted using the email form on
	the welcome page of the Award Program for
	#form.program_name#
	**********************************************
	
	FROM: #form_name#
	EMAIL: #form_email#
	
	MESSAGE:
	
	#form_message#
	
	</cfmail>
	
	<cfset emailsent = "Your comments have been sent.  Thank you.">

</cfif>

<cfparam name="url.div" default="0">
<cfif NOT isNumeric(url.div)>
	<cflocation url="logout.cfm" addtoken="false" >
</cfif>

<cfset div_param = "">
<cfif url.div GT 0>
	<cfset div_param = "?div=" & url.div>
	<cfquery name="GetDivisionInfo" datasource="#application.DS#">
		SELECT parent_ID, welcome_instructions, welcome_button, welcome_bg, welcome_message, welcome_admin_button,
			additional_content_button, additional_content_message, email_form_button, email_form_message, help_button, help_message
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#url.div#" maxlength="10">
	</cfquery>
	<cfset welcome_bg = HTMLEditFormat(GetDivisionInfo.welcome_bg)>
	<cfset welcome_instructions = GetDivisionInfo.welcome_instructions>
	<cfset welcome_message = GetDivisionInfo.welcome_message>
	<cfset welcome_button = GetDivisionInfo.welcome_button>
	<cfset welcome_admin_button = GetDivisionInfo.welcome_admin_button>
	<cfset additional_content_button = GetDivisionInfo.additional_content_button>
	<cfset additional_content_message = GetDivisionInfo.additional_content_message>
	<cfset email_form_button = GetDivisionInfo.email_form_button>
	<cfset email_form_message = GetDivisionInfo.email_form_message>
	<cfset help_button = GetDivisionInfo.help_button>
	<cfset help_message = GetDivisionInfo.help_message>
	<cfif GetDivisionInfo.parent_ID NEQ LEFT(cookie.itc_pid,10)>
		<cflocation url="logout.cfm" addtoken="false" >
	</cfif>
</cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>ITC Awards</title>

<cfinclude template="includes/program_style.cfm"> 

<script>

	function mOver(item, newClass)

		{
		item.className=newClass
		}

	function mOut(item, newClass)

		{
		item.className=newClass
		}
		
	function openHelp()
		{
		
			windowHeight = (screen.height - 150)
			helpLeft = (screen.width - 615)
			
			winAttributes = 'width=600, top=1, resizable=yes, scrollbars=yes, status=yes, titlebar=yes, height=' + windowHeight + ', left =' + helpLeft
			
			window.open('help.cfm','Help',winAttributes);
		}
		
</script>

</head>

<cfoutput>

<body leftmargin="0" topmargin="0" marginheight="0" marginwidth="0">
<cfinclude template="includes/environment.cfm">

<table cellpadding="0" cellspacing="0" border="0" width="800">

<tr>
<td style="padding:5px"><cfif logo NEQ ""><img src="pics/program/#logo#" style="padding-left:21px"></cfif></td>
</tr>

</table>

<table cellpadding="0" cellspacing="0" border="0" width="800">

<tr>
<td width="200" valign="top" align="center">
	<img src="pics/shim.gif" width="200" height="1">
	<br /><br />
	<table cellpadding="8" cellspacing="1" border="0" width="150">
	
	<tr>
	<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='welcome.cfm#div_param#'">Return To<br>Welcome Page</td>
	</tr>
	
	<tr>
	<td>&nbsp;</td>
	</tr>

	<tr>
	<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='main.cfm&div=#request.division_id#'">#welcome_button#</td>
	
	<cfif help_button NEQ "">
	
	<tr>
	<td>&nbsp;</td>
	</tr>
	
	<tr>
	<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="openHelp()">#help_button#</td>
	</tr>
	
	</cfif>

	</tr>
		
	</table>
</td>

<td width="725" valign="top" style="padding:25px">


	#Replace(email_form_message,chr(10),"<br>","ALL")#
	<br><br>
	
	<cfif emailsent NEQ "">
		<table width="550" border="0" cellspacing="0" cellpadding="0">
		<tr>
		<td align="left" valign="middle" width="150"><img src="pics/ThankYou.jpg" alt="" width="182" height="182" align="left" border="0"></td>
		<td align="left" valign="middle" width="400">
			<h3><font color="##ff6600"><b>Your valuable feedback <br>
						has been received by ITC</b></font></h3>
		</td>
		</tr>
		</table>
	</cfif>

	
	<cfparam name="users_name" default="">
	<cfparam name="users_email" default="">

	<!--- check ITC_USER cookie --->
	<cfif IsDefined('cookie.itc_user') AND #cookie.itc_user# NEQ "">
		<cfquery name="GetUserNameAndEmail" datasource="#application.DS#">
			SELECT fname, lname, email
			FROM #application.database#.program_user
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(cookie.itc_user,1,"-")#">
		</cfquery>
		<cfset users_name = GetUserNameAndEmail.fname & " " & GetUserNameAndEmail.lname>
		<cfset users_email = GetUserNameAndEmail.email>
	</cfif>
	
	<!--- email form that get's sent to Lou and then passes them back to welcome --->
	<form action="email_form.cfm" method="post">
	<table width="100%">
	
	<tr>
	<td align="right">Your Name</td>
	<td>
		<cfif users_name EQ "">
			<input name="form_name" type="text" maxlength="50" size="50">
			<input name="form_name_required" type="hidden" value="Please enter a name.">
		<cfelse>
			#users_name#
			<input name="form_name" type="hidden" value="#users_name#">
		</cfif>	
	</td>
	</tr>
	
	<tr>
	<td align="right">Your Email</td>
	<td>
		<cfif users_email EQ "">
			<input name="form_email" type="text" maxlength="50" size="50">
			<input name="form_email_required" type="hidden" value="Please enter an email.">
		<cfelse>
			#users_email#
			<input name="form_email" type="hidden" value="#users_email#">
		</cfif>	
	</td>
	</tr>
	
	<tr>
	<td align="right" valign="top">Message</td>
	<td><textarea rows="6" cols="48" name="form_message"></textarea></td>
	</tr>
	
	<tr>
	<td colspan="2" align="center">
		<input type="submit" value="   Send Message   ">
		<input type="hidden" name="program_name" value="#company_name# [#program_name#]">
	</td>
	</tr>
	
	</table>
	</form>
	
</td>
</tr>

</table>

</body>

</cfoutput>

</html>
