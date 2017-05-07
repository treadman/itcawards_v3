<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">
<cfcookie name="filter" expires="now">
<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<cfparam name="pgfn" default="input">
<cfparam name="email" default="">
<cfparam name="password" default="">

<cfset ErrorMessage = "">
<cfset login_msg = "">

<cfparam name="url.p" default="">
<cfparam name="form.email" default="">

<cfset showPWRecoverLink = false>
<cfset showPWRecoverForm = false>

<cfif has_password_recovery>
	<cfset showPWRecoverLink = true>
	<cfif url.p EQ "r">
		<cfset showPWRecoverForm = true>
	</cfif>
</cfif>

<cfif pgfn IS 'verify'>
	<cfif email IS "" OR NOT FLGen_IsValidEmail(form.email)>
		<cfset ErrorMessage = ErrorMessage & 'Please enter a valid email address<br />'>
		<cfset pgfn = 'input'>
	<cfelse>
		<cfquery name="CheckProgUserLogin" datasource="#application.DS#">
			SELECT DISTINCT up.ID AS user_ID, IF(up.is_done=1,"true","false") AS is_done, up.defer_allowed, up.cc_max, pl.program_ID, p.company_name, p.email_login, up.email
			FROM #application.database#.program_user up
			JOIN #application.database#.program p ON up.program_ID = p.ID
				JOIN #application.database#.program_login pl ON pl.program_ID = p.ID
			WHERE up.email = <cfqueryparam value="#form.email#" cfsqltype="CF_SQL_VARCHAR">
			AND up.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.password#" maxlength="128">
			AND up.program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
				AND p.is_active = 1
				AND up.is_active = 1
				AND p.expiration_date >= CURDATE()
				AND (up.expiration_date >= CURDATE() OR up.expiration_date IS NULL)
		</cfquery>
		<cfset program_ID = CheckProgUserLogin.program_ID>
		<cfset company_name = HTMLEditFormat(CheckProgUserLogin.company_name)>
		<cfset user_ID = CheckProgUserLogin.user_ID>
		<cfset is_done = HTMLEditFormat(CheckProgUserLogin.is_done)>
		<cfset defer_allowed = HTMLEditFormat(CheckProgUserLogin.defer_allowed)>
		<cfset cc_max = HTMLEditFormat(CheckProgUserLogin.cc_max)>
		<cfset CheckProgUserLogin_RecordCount = CheckProgUserLogin.RecordCount>
		<cfset email_login = CheckProgUserLogin.email_login>
		<cfif CheckProgUserLogin.RecordCount EQ 1>
			<cfset GetProgramUserInfo(user_ID,form.email)>
			<cfif has_welcomepage>
				<cflocation addtoken="no" url="welcome.cfm">
			<cfelse>
				<cflocation addtoken="no" url="main.cfm">
			</cfif>
		<cfelse>
			<cfset ErrorMessage = ErrorMessage & 'That information is not valid<br />'>
			<cfset pgfn = 'input'>
		</cfif>
	</cfif>
</cfif>							

<cfif pgfn EQ "get_password" AND form.email NEQ "">
	<cfif NOT FLGen_IsValidEmail(form.email)>
		<cfset ErrorMessage = 'Please enter a valid email address.'>
	<cfelse>
	<cfquery name="CheckProgramUser" datasource="#application.DS#">
		SELECT fname, lname, username
		FROM #application.database#.program_user
		WHERE email = <cfqueryparam value="#form.email#" cfsqltype="CF_SQL_VARCHAR" maxlength="128">
		AND program_ID = <cfqueryparam value="#program_ID#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfif CheckProgramUser.RecordCount EQ 0>
		<cfset ErrorMessage = 'The email address, <strong>#form.email#</strong>, was not found in the <strong>#url.p#</strong> program.'>
	<cfelseif CheckProgramUser.RecordCount GT 1>
		<cfmail to="#Application.ErrorEmailTo#" from="#emailFrom#" subject="#emailSubject#" type="html">
#form.email# is duplicated in #Application.database#.Program_User.<br>
WHERE program_ID ID EQ #CheckUserName.ID#<br>
This is in index.cfm (login)
		</cfmail>
		<cfset ErrorMessage = 'There was a problem with that email address.  For assistance, #Application.OrdersAdminMessage#'>
	<cfelse>
		<cfset emailFrom = orders_from>
		<cfset emailSubject = "Awards Password">
		<cfif Application.OverrideEmail NEQ "">
			<cfset this_to = Application.OverrideEmail>
		<cfelse>
			<cfset this_to = form.email>
		</cfif>
		<cfmail to="#this_to#" failto="#Application.ErrorEmailTo#" from="#emailFrom#" subject="#emailSubject#" type="html">
			<cfif Application.OverrideEmail NEQ "">
				Emails are being overridden.<br>
				Below is the email that would have been sent to #form.email#<br>
				<hr>
			</cfif>
Dear #CheckProgramUser.fname#,<br><br>

You requested your password for the Awards Site:<br><br><br>
<ul>
	<li>Password: <strong>#CheckProgramUser.username#</strong></li>
</ul>
<br>
Should you need further assistance, #Application.OrdersAdminMessage#  Thank you.
		</cfmail>
		<cfset login_msg = 'We have sent your password to <strong>#form.email#</strong><br><br>Thank you!'>
		<cfset showPWRecoverForm = false>
		<cfset url.p = "">
	</cfif>
	</cfif>
	<cfif ErrorMessage neq ''>
		<cfset showPWRecoverForm = true>
	</cfif>
	<cfset pgfn = 'input'>
</cfif>

<cfinclude template="includes/header.cfm">

<cfoutput>
<cfif pgfn EQ 'input'>
	<cfif showPWRecoverForm>
		Please enter your email address.<br>Your password will be emailed to you.
	<cfelseif trim(login_text) NEQ "">
		#login_text#
	</cfif>
	<form action="#application.SecureWebPath#/login.cfm" method="post" NAME="form_entry" ><!--- onSubmit="return validateForm();" --->
		<table border="0" cellpadding="3" cellspacing="0">
		<cfif login_msg NEQ "">
			<tr><td align="left" colspan="2"class="login_msg">#login_msg#</td></tr>
		</cfif>
			<tr><td align="left" colspan="2"><font color="##FF0000"><br>#ErrorMessage#</font></td></tr>
	<cfif showPWRecoverForm>
		<input type="hidden" name="pgfn" value="get_password">
			<tr><td align="right" class="main_login">Email Address </td><td><input type="text" name="email" size="30" maxlength="128" value="#email#"></td></tr>
	<cfelse>
		<input type="hidden" name="pgfn" value="verify">
			<tr><td align="right" class="main_login">Email Address </td><td><input type="text" name="email" size="30" maxlength="128" value="#email#"></td></tr>
			<tr><td align="right" class="main_login">Password </td><td><input type="password" name="password" size="30" maxlength="128" value=""></td></tr>
	</cfif>
			<tr><td colspan="2" align="center">
		<table cellpadding="8" cellspacing="1" border="0">

		<tr>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="form_entry.submit();">  Submit  </td>
		</tr>
		
		</table></td></tr></table>
		<cfif showPWRecoverLink>
			<br />
			<cfif showPWRecoverForm>
			<span class="login_msg"><a href="login.cfm">Return to the login screen.</a></span>
			<cfelse>
			<span class="login_msg"><a href="login.cfm?p=r">Already Registered&nbsp; &mdash; &nbsp;Forgot Your Password?</a></span>
			</cfif>
		</cfif>
	</form>
<cfelse>
	<cflocation url="logout.cfm" addtoken="no">
</cfif>							
</cfoutput>

<cfinclude template="includes/footer.cfm">
