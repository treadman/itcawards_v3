<cfsilent>

<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<!--- form fields --->
<cfparam name="username" default="">
<cfparam name="password" default="">

<!--- variables --->
<cfparam name="HashedProgramID" default="">
<cfparam name="alert_msg" default="">
<cfparam name="login_msg" default="">

<cfparam name="program_ID" default="">
<cfparam name="program" default="">
<cfparam name="user_ID" default="">
<cfparam name="is_done" default="false">
<cfparam name="defer_allowed" default="0">
<cfparam name="cc_max" default="0">
<cfparam name="CheckProgUserLogin_RecordCount" default="0">

<cfparam name="this_http_host" default="#CGI.HTTP_HOST#">
			
<cfparam name="url.p" default="">
<cfparam name="form.email" default="">
<cfset emailFrom="errors@itcsafety.com">
<cfset emailSubject = "Database Errors Logging into Awards 3">
<cfset showPWRecoverLink = false>
<cfset showPWRecoverForm = false>

<cfif this_HTTP_HOST EQ 'mcn.itcawards.com'>
	<cfquery name="CheckMCN" datasource="#application.DS#">
		SELECT pl.program_ID, p.company_name
		FROM #application.database#.program_login pl
		JOIN #application.database#.program p ON pl.program_ID = p.ID AND p.parent_ID = 0
		WHERE 	pl.password = <cfqueryparam cfsqltype="cf_sql_varchar" value="mcn" maxlength="128"> 
			AND pl.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="mcn" maxlength="32">
			AND p.is_active = 1 
			AND p.expiration_date >= CURDATE()
	</cfquery>
	<cfset program_ID = CheckMCN.program_ID>

	<cfset HashedProgramID = FLGen_CreateHash(program_ID)>
	<cfcookie name="itc_pid" value="#program_ID#-#HashedProgramID#">
	<cflocation url="main.cfm">
</cfif>

<cfif url.p NEQ "">
	<!--- is the url.p valid ? --->
	<cfquery name="CheckUsername" datasource="#application.DS#">
		SELECT p.ID, p.has_password_recovery, p.orders_from, pl.username
		FROM #application.database#.program_login pl
		JOIN #application.database#.program p ON pl.program_ID = p.ID AND p.parent_ID = 0
		WHERE 	pl.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#url.p#" maxlength="32">
				AND p.is_active = 1 
				AND p.expiration_date >= CURDATE()
	</cfquery>
	<cfif CheckUsername.RecordCount GT 0 AND CheckUsername.has_password_recovery>
		<cfset showPWRecoverForm = true>
	<cfelse>
		<cfset url.p = "">
	</cfif>
</cfif>

<cfif url.p NEQ "" AND form.email NEQ "">
	<cfquery name="CheckProgramUser" datasource="#application.DS#">
		SELECT fname, lname, username
		FROM #application.database#.program_user
		WHERE email = <cfqueryparam value="#form.email#" cfsqltype="CF_SQL_VARCHAR" maxlength="128">
		AND program_ID = <cfqueryparam value="#CheckUserName.ID#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfif CheckProgramUser.RecordCount EQ 0>
		<cfset alert_msg = 'The email address, <strong>#form.email#</strong>,<br /> was not found in the <strong>#url.p#</strong> program.'>
	<cfelseif CheckProgramUser.RecordCount GT 1>
		<cfmail to="#Application.ErrorEmailTo#" from="#emailFrom#" subject="#emailSubject#" type="html">
#form.email# is duplicated in #Application.database#.program_user.<br>
WHERE program_ID EQ #CheckUserName.ID#<br>
This is in index.cfm (login)
		</cfmail>
		<cfset alert_msg = 'There was a problem with that email address.  For assistance, #Application.OrdersAdminMessage#'>
	<cfelse>
		<cfset emailFrom = CheckUsername.orders_from>
		<cfset emailSubject = CheckUserName.username & " password">
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
Below is your password and log-in instructions to enter the Awards Site:<br><br><br>
<ul>
	<li> Go to #Application.PlainURL#</li>
	<li> Enter Company Name: <strong># CheckUserName.username#</strong></li>
	<li> Enter Password: <strong>#CheckProgramUser.username#</strong></li>
</ul>
<br>
Should you need further assistance, #Application.OrdersAdminMessage#  Thank you.
		</cfmail>
		<cfset login_msg = 'We have sent your password to <strong>#form.email#</strong><br><br>Thank you!'>
		<cfset showPWRecoverForm = false>
		<cfset url.p = "">
	</cfif>
</cfif>


<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->
 
<cfif IsDefined('username') AND Trim(username) IS NOT "" AND IsDefined('password') AND Trim(password) IS NOT "">

	<cfset username = Left(Trim(username),32)>
	<cfset password = Left(Trim(password),128)>
	
	<!--- is the username valid ? --->
	<cfquery name="CheckUsername" datasource="#application.DS#">
		SELECT p.ID, p.has_password_recovery, p.allow_secondary_auth, p.secondary_auth_field
		FROM #application.database#.program_login pl
		JOIN #application.database#.program p ON pl.program_ID = p.ID AND p.parent_ID = 0
		WHERE 	pl.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#username#" maxlength="32">
				AND p.is_active = 1 
				AND p.expiration_date >= CURDATE()
	</cfquery>
	
	<cfif CheckUsername.RecordCount EQ 0>
		<cfset alert_msg = "Please enter a valid company name.">
	<cfelse>
	
		<!--- check the program for the username/password match --->
		<cfquery name="CheckLogin" datasource="#application.DS#">
			SELECT pl.program_ID, p.company_name
			FROM #application.database#.program_login pl
			JOIN #application.database#.program p ON pl.program_ID = p.ID AND p.parent_ID = 0
			WHERE 	pl.password = <cfqueryparam cfsqltype="cf_sql_varchar" value="#password#" maxlength="128"> 
					AND pl.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#username#" maxlength="32">
					AND p.is_active = 1 
					AND p.expiration_date >= CURDATE()
		</cfquery>
		<cfset program_ID = CheckLogin.program_ID>
		<cfset company_name = HTMLEditFormat(CheckLogin.company_name)>
		
		<!--- if no match, check the user --->
		<cfif CheckLogin.RecordCount EQ 0>
			<cfquery name="CheckProgUserLogin" datasource="#application.DS#">
				SELECT DISTINCT up.ID AS user_ID, IF(up.is_done=1,"true","false") AS is_done, up.defer_allowed, up.cc_max, pl.program_ID, p.company_name
				FROM #application.database#.program_user up
				JOIN #application.database#.program p ON up.program_ID = p.ID AND p.parent_ID = 0
					JOIN #application.database#.program_login pl ON pl.program_ID = p.ID
				WHERE up.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#password#" maxlength="128">
					AND pl.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#username#" maxlength="32">
					AND p.is_active = 1
					AND up.is_active = 1
					AND p.expiration_date >= CURDATE()
					AND (up.expiration_date >= CURDATE() OR up.expiration_date IS NULL)
			</cfquery>
			<cfset CheckProgUserLogin_RecordCount = CheckProgUserLogin.RecordCount>
		</cfif>
		<cfif CheckLogin.RecordCount EQ 0 AND CheckProgUserLogin_RecordCount EQ 0 AND CheckUsername.allow_secondary_auth EQ 1>
			<!--- Check the secondary authentication --->
			<cfquery name="CheckProgUserLogin" datasource="#application.DS#">
				SELECT DISTINCT up.ID AS user_ID, IF(up.is_done=1,"true","false") AS is_done, up.defer_allowed, up.cc_max, pl.program_ID, p.company_name
				FROM #application.database#.program_user up
				JOIN #application.database#.program p ON up.program_ID = p.ID AND p.parent_ID = 0
					JOIN #application.database#.program_login pl ON pl.program_ID = p.ID
				WHERE up.#CheckUsername.secondary_auth_field# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#password#" maxlength="128">
					AND pl.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#username#" maxlength="32">
					AND p.is_active = 1
					AND up.is_active = 1
					AND p.expiration_date >= CURDATE()
					AND (up.expiration_date >= CURDATE() OR up.expiration_date IS NULL)
			</cfquery>
			<cfset CheckProgUserLogin_RecordCount = CheckProgUserLogin.RecordCount>
			<cfif CheckProgUserLogin_RecordCount GT 1>
				<cfmail to="#Application.ErrorEmailTo#" from="#emailFrom#" subject="#emailSubject#" type="html">
The #CheckUsername.secondary_auth_field# secondary authentication for #password# is duplicated in #Application.database#.program_user.<br>
WHERE program_ID EQ #CheckUserName.ID#<br>
This is in index.cfm (login)
				</cfmail>
			</cfif>
		</cfif>
		<cfif CheckProgUserLogin_RecordCount EQ 1>
			<cfset program_ID = CheckProgUserLogin.program_ID>
			<cfset company_name = HTMLEditFormat(CheckProgUserLogin.company_name)>
			<cfset user_ID = CheckProgUserLogin.user_ID>
			<cfset is_done = HTMLEditFormat(CheckProgUserLogin.is_done)>
			<cfset defer_allowed = HTMLEditFormat(CheckProgUserLogin.defer_allowed)>
			<cfset cc_max = HTMLEditFormat(CheckProgUserLogin.cc_max)>
		</cfif>
		<cfif CheckLogin.RecordCount EQ 0 AND CheckProgUserLogin_RecordCount EQ 0>
			<cfif this_http_host EQ "www3.itcawards.com">
				<cfset alert_msg = "Please enter a valid password.">
			<cfelse>
				<cfset alert_msg = "Please enter a valid employee ID number.">
			</cfif>
			<cfif CheckUsername.has_password_recovery>
				<cfset showPWRecoverLink = true>
			</cfif>
		<cfelseif is_done>
			<cfset alert_msg = "You have already selected your gift.">
		<cfelseif CheckProgUserLogin_RecordCount GT 1>
		<cfmail to="#Application.ErrorEmailTo#" from="#emailFrom#" subject="Duplicate User" type="html">
<cfdump var="#CheckProgUserLogin#">
This is in index.cfm (login)
		</cfmail>
			<cfset alert_msg = "There is more that one user in the system with that login.<br><br>For assistance, #Application.OrdersAdminMessage#">
		<cfelse>
		
			<!--- SET USER INFO --->
			<!--- if it was an upfront authorization login, set all the user stuff --->
			<cfif CheckProgUserLogin_RecordCount EQ 1>
				<!--- get user info and write program user cookie --->
				<cfset GetProgramUserInfo(user_ID)>
			</cfif>
			
			<!--- SET PROGRAM INFO --->
			<!--- hash program ID and save cookie --->
			<cfset HashedProgramID = FLGen_CreateHash(program_ID)>
			<cfcookie name="itc_pid" value="#program_ID#-#HashedProgramID#">

			<cfquery name="GetProgram" datasource="#application.DS#">
				SELECT has_welcomepage, has_register, email_login
				FROM #application.database#.program
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
			</cfquery>
			<cfif GetProgram.has_register AND GetProgram.email_login>
				<!--- Must register AND requires email login.  Send them to the chooser page. --->
				<cflocation addtoken="no" url="chooser.cfm">
			<cfelseif GetProgram.has_register>
				<!--- Only register is needed.  If not logged in send them to register --->
				<cfif CheckProgUserLogin_RecordCount NEQ 1>
					<cflocation addtoken="no" url="register.cfm">
				</cfif>
			<cfelseif GetProgram.email_login>
				<!--- Only login is required --->
				<cflocation addtoken="no" url="login.cfm">
			</cfif>
			<cfif GetProgram.has_welcomepage>
				<cflocation addtoken="no" url="welcome.cfm">
			<cfelse>
				<cflocation addtoken="no" url="main.cfm">
			</cfif>
			
		</cfif>

	</cfif>



<cfelseif IsDefined('url.itg') AND Trim(url.itg) EQ 'sample'>

	<!--- is the username valid ? --->
	<cfquery name="CheckUsername" datasource="#application.DS#">
		SELECT p.ID, p.has_password_recovery, p.allow_secondary_auth, p.secondary_auth_field
		FROM #application.database#.program_login pl
		JOIN #application.database#.program p ON pl.program_ID = p.ID AND p.parent_ID = 0
		WHERE 	pl.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="itgsample" maxlength="32">
		AND p.is_active = 1 
		AND p.expiration_date >= CURDATE()
	</cfquery>
	
	<cfif CheckUsername.RecordCount EQ 0>
		<cfset alert_msg = "Please enter a valid company name.">
	<cfelse>
	
		<!--- check the program for the username/password match --->
		<cfquery name="CheckLogin" datasource="#application.DS#">
			SELECT pl.program_ID, p.company_name
			FROM #application.database#.program_login pl
			JOIN #application.database#.program p ON pl.program_ID = p.ID AND p.parent_ID = 0
			WHERE 	pl.password = <cfqueryparam cfsqltype="cf_sql_varchar" value="itgsample" maxlength="128"> 
			AND pl.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="itgsample" maxlength="32">
			AND p.is_active = 1 
			AND p.expiration_date >= CURDATE()
		</cfquery>
		
		<!--- if no match, check the user --->
		<cfif CheckLogin.RecordCount EQ 0>
			<cfset alert_msg = "Please enter a valid company name.">
		<cfelse>
			<cfset program_ID = CheckLogin.program_ID>
			<cfset company_name = HTMLEditFormat(CheckLogin.company_name)>
		
			<cfset HashedProgramID = FLGen_CreateHash(program_ID)>
			<cfcookie name="itc_pid" value="#program_ID#-#HashedProgramID#">

			<cfquery name="GetProgram" datasource="#application.DS#">
				SELECT has_welcomepage, has_register, email_login
				FROM #application.database#.program
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
			</cfquery>

			<cfif GetProgram.has_welcomepage>
				<cflocation addtoken="no" url="welcome.cfm">
			<cfelse>
				<cflocation addtoken="no" url="main.cfm">
			</cfif>
			
		</cfif>

	</cfif>


<cfelse>
	<cfinclude template="includes/expire_cookies.cfm">
</cfif>

</cfsilent>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>ITC Awards</title>

<STYLE TYPE="text/css">
td, body, .reg, button, input, select, option, textarea {font-family:Verdana, Arial, Helvetica, san-serif; font-size:8pt; color:black}
.action {border-width:2px;border-color:#ff6600;background-color:#ff6600;color:#ffffff;font-weight:bold;padding:3px;cursor:pointer}
.alert {color:#cb0400}
.login_msg {font-weight:bold;color:#969696}
.login_msg a {font-weight:bold;color:#969696}
.welcome {font-family:Arial, Verdana;font-weight:bold;font-size:8pt;color:#969696}

.button {
   border-top: 1px solid #333333;
   background: #e32424;
   background: -webkit-gradient(linear, left top, left bottom, from(#e32424), to(#e32424));
   background: -webkit-linear-gradient(top, #e32424, #e32424);
   background: -moz-linear-gradient(top, #e32424, #e32424);
   background: -ms-linear-gradient(top, #e32424, #e32424);
   background: -o-linear-gradient(top, #e32424, #e32424);
   padding: 7.5px 15px;
   -webkit-border-radius: 8px;
   -moz-border-radius: 8px;
   border-radius: 8px;
   -webkit-box-shadow: rgba(0,0,0,1) 0 1px 0;
   -moz-box-shadow: rgba(0,0,0,1) 0 1px 0;
   box-shadow: rgba(0,0,0,1) 0 1px 0;
   text-shadow: rgba(0,0,0,.4) 0 1px 0;
   color: white;
   font-size: 16px;
   font-family: Helvetica, Arial, Sans-Serif;
   text-decoration: none;
   vertical-align: middle;
   }
.button:hover {
   border-top-color: #bbb8b5;
   background: #bbb8b5;
   color: #333333;
   }
.button:active {
   border-top-color: #e32424;
   background: #e32424;
   }
</STYLE>

</head>

<body leftmargin="0" topmargin="0" marginheight="0" marginwidth="0" background="pics/login/bkgd-fade.jpg">
<cfinclude template="includes/environment.cfm">
<div align="center">
<form name="login_form" method="post" action="<cfoutput>#application.SecureWebPath#</cfoutput>/index.cfm<cfif Len(url.p) GT 0>?p=<cfoutput>#url.p#</cfoutput></cfif>">

	<table cellpadding="5" cellspacing="0" border="0">
<cfif this_HTTP_HOST EQ 'www3.itcawards.com' OR this_HTTP_HOST EQ 'uat3.itcawards.com'>
	<tr>
	<td colspan="3" align="center"><img src="pics/login/header-awards.jpg" width="392" height="178"></td>
	</tr>
	
	<tr>
	<td colspan="3" align="center">&nbsp;</td>
	</tr>
	
	<tr>
	<td colspan="3" align="center">
		<cfif alert_msg NEQ "">
			<span class="alert"><cfoutput>#alert_msg#</cfoutput></span>
			<br /><br /><br />
		</cfif>
		<cfif login_msg NEQ "">
			<span class="login_msg"><cfoutput>#login_msg#</cfoutput></span>
			<br /><br /><br />
		</cfif>
	</td>
	</tr>
	
	<cfif showPWRecoverForm>
		<input type="hidden" name="get_password" value="1">
		<tr>
			<td width="187"><img src="pics/shim.gif" width="187" height="5"></td>
			<td width="425" height="101" align="center">
				<br>
				<span class="welcome">Please enter your email address.<br>Your password will be emailed to you.</span>
				<br>
				<br>
				<table border="0" align="center">
					<tr><td align="right" class="welcome">Email Address </td><td><input type="text" name="email" size="30" maxlength="128" value="<cfoutput>#form.email#</cfoutput>"></td></tr>
					<tr><td colspan="2" align="center"><br><br><input name="submit" type="image" value="submit" src="pics/login/submitbutton_01.gif" border="0"></td></tr>
				</table>

			</td>
			<td width="188" valign="top" align="center">&nbsp;</td>
		</tr>
		<tr>
		<td colspan="3" align="center">
			<br><br>
			<span class="login_msg"><a href="index.cfm">Return to the login screen</a></span>
		</td>
		</tr>
	<cfelse>
		<tr>
		<td align="center"><img src="pics/login/entercompanyname.jpg" width="174" height="21" border="0"></td>
		<td width="8"></td>
		<td align="center"><img src="pics/login/enterpassword.jpg" width="174" height="21" border="0"></td>
		</tr>

		<tr>
		<td align="center"><input type="text" name="username" value="<cfoutput>#username#</cfoutput>" size="27" maxlength="32"></td>
		<td width="8"></td>
		<td align="center"><input type="password" name="password" size="27" maxlength="128"></td>
		</tr>
		
		<tr>
		<td colspan="3" align="center">&nbsp;</td>
		</tr>
		
		<tr>
		<td colspan="3" align="center">
		<cfif showPWRecoverLink>
			<span class="login_msg"><a href="index.cfm?p=<cfoutput>#urlencodedformat(username)#</cfoutput>">Already Registered&nbsp; &mdash; &nbsp;Forgot Your Password?</a></span>
			<br /><br /><br />
		</cfif>
		<input type="hidden" name="password_required" value="Please enter a password">
		<input type="hidden" name="username_required" value="Please enter company name">
		
		<input src="pics/login/submitbutton_01.gif" type="image" name="submit" >
		</td>
		</tr>
	</cfif>
	<tr>
	<td colspan="3" align="center">&nbsp;</td>
	</tr>
	
	<tr>
	<td colspan="3" align="center"><a href="<cfoutput>#Application.BasicURL#</cfoutput>/index.html"><img src="pics/login/SafetySpecialtyLink-2lines_.gif" width="260" height="23" border="0">
	<br>
	<a href="<cfoutput>#Application.BasicURL#</cfoutput>/pages/contactus.html"><img src="pics/login/SafetySpecialtyLink-2lin-02.gif" width="260" height="23" border="0"></td>
	</tr>
	
	<!--- -------- --->
	<!---    ITG   --->
	<!--- -------- --->

<cfelseif this_HTTP_HOST EQ 'itg.itcawards.com'>
			<input type="hidden" name="username" value="itg">
			<input type="hidden" name="this_HTTP_HOST" value="itg.itcawards.com">
	<tr>
	<td align="center"><img src="pics/program/121_image.jpg" width="1500" height="200"></td>
	</tr>
	
	<tr>
	<td colspan="3" align="center">&nbsp;</td>
	</tr>
	
	<tr>
	<td align="center">
		&nbsp;
		<cfif alert_msg NEQ "">
			<span class="alert"><cfoutput>#alert_msg#</cfoutput></span>
		</cfif>
		&nbsp;
		<br />
	</td>
	</tr>
	
		<tr>
		<td align="center">
			<p>Please enter your employee ID number:</p>
			<input type="text" name="password" size="27" maxlength="128"></td>
		</tr>
		
		<tr>
		<td align="center">&nbsp;</td>
		</tr>
		
		<tr>
		<td align="center">
		<input type="hidden" name="password_required" value="Please enter your employee ID number">
		<input type="hidden" name="username_required" value="Please enter company name">
		<a href="#" class="button" onClick="document.forms['login_form'].submit();">  &nbsp; &nbsp; Log In &nbsp; &nbsp;  </a>
		</td>
		</tr>
	
	<!--- -------- --->
	<!---  Holman  --->
	<!--- -------- --->

<cfelseif this_HTTP_HOST EQ 'holman.itcawards.com'>
			<input type="hidden" name="username" value="holman">
			<input type="hidden" name="this_HTTP_HOST" value="holman.itcawards.com">
	<tr>
	<td align="center"><img src="pics/program/113_image.jpg" width="1000" height="113"></td>
	</tr>
	
	<tr>
	<td colspan="3" align="center">&nbsp;</td>
	</tr>
	
	<tr>
	<td align="center">
		&nbsp;
		<cfif alert_msg NEQ "">
			<span class="alert"><cfoutput>#alert_msg#</cfoutput></span>
		</cfif>
		&nbsp;
		<br />
	</td>
	</tr>
	
		<tr>
		<td align="center">
			<p>Please enter your password:</p>
			<input type="password" name="password" size="27" maxlength="128"></td>
		</tr>
		
		<tr>
		<td align="center">&nbsp;</td>
		</tr>
		
		<tr>
		<td align="center">
		<input type="hidden" name="password_required" value="Please enter your employee ID number">
		<input type="hidden" name="username_required" value="Please enter company name">
		<a href="#" class="button" onClick="document.forms['login_form'].submit();">  &nbsp; &nbsp; Log In &nbsp; &nbsp;  </a>
		</td>
		</tr>
	
	<!--- -------- --->
	<!--- Unknown  --->
	<!--- -------- --->

<cfelse>
	<tr>
	<td colspan="3" align="center"><img src="pics/login/header-awards.jpg" width="392" height="178"></td>
	</tr>
	<tr>
	<td colspan="3" align="center">&nbsp;</td>
	</tr>
	
	<tr>
	<td colspan="3" align="center">
		<span class="alert">An error has occurred.</span>
		<br />
 		<br /><br />
 		<a href="https://www3.itcawards.com">Click here to return to www3.itcawards.com</a>
 		<br /><br />
 		<br /><br />
	</td>
	</tr>
	<tr>
	<td colspan="3" align="center"><a href="<cfoutput>#Application.BasicURL#</cfoutput>/index.html"><img src="pics/login/SafetySpecialtyLink-2lines_.gif" width="260" height="23" border="0">
	<br>
	<a href="<cfoutput>#Application.BasicURL#</cfoutput>/pages/contactus.html"><img src="pics/login/SafetySpecialtyLink-2lin-02.gif" width="260" height="23" border="0"></td>
	</tr>
</cfif>
	
	</table>

</form>

</div>

</body>
</html>
