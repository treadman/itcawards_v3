<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<cfparam name="iprod" default="">
<cfparam name="prod" default="">
<cfparam name="c" default="">
<cfparam name="url.p" default="">
<cfparam name="g" default="">
<cfparam name="OnPage" default="1">
<cfparam name="defer" default="">

<cfparam name="founduser" default="yes">
<cfparam name="has_points" default="yes">
<cfparam name="is_done" default="false">
<cfparam name="cantdefer" default="false">
<cfparam name="partialcredit" default="false">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<!--- kick out if trying to defer and program doesn't allow it --->
<cfif NOT isBoolean(can_defer) OR (NOT can_defer and defer EQ "yes")>
	<cflocation addtoken="no" url="logout.cfm">
</cfif>

<!--- form was submitted --->
<cfif IsDefined('form.username') AND form.username IS NOT "">
	<!--- check for username/program --->
	<cfquery name="FindProgramUser" datasource="#application.DS#">
		SELECT ID AS user_ID, IF(is_done=1,"true","false") AS is_done, defer_allowed, cc_max, email
		FROM #application.database#.program_user
		WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#username#" maxlength="128">
		<cfif email_login>
			AND email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.email#">
		</cfif>
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
			AND is_active = 1
			AND (expiration_date >= CURDATE() OR expiration_date IS NULL)
	</cfquery>
	<cfif FindProgramUser.RecordCount EQ 1>
		<cfset user_ID = FindProgramUser.user_ID>
		<cfset is_done = FindProgramUser.is_done>
		<cfset defer_allowed = FindProgramUser.defer_allowed>
		<cfset cc_max = FindProgramUser.cc_max>
		<cfset email = FindProgramUser.email>
	</cfif>
	<!--- calculate award points as long as one user was found in this program with the submitted username --->
	<cfif FindProgramUser.RecordCount EQ 1 AND NOT is_done>
		<!--- get user info and write program user cookie --->
		<cfset GetProgramUserInfo(user_ID,email)>
		<!--- user was found and is ORDERING --->
		<cfif IsDefined('form.defer') AND form.defer IS NOT "yes">
			<cfif user_totalpoints GT 0 OR is_one_item GT 0>
				<cfif defer EQ "yes">
					<cflocation addtoken="no" url="defer.cfm">
				<cfelse>
					<cflocation addtoken="no" url="cart.cfm?iprod=#iprod#&prod=#prod#&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#">
				</cfif>
			<cfelse>
				<cfset has_points = "no">
			</cfif>
		<!--- user was found and is DEFERRING --->
		<cfelseif IsDefined('form.defer') AND form.defer IS "yes">
			<cfif defer_allowed EQ 0>
				<cfset cantdefer = "true">
			<cfelseif user_totalpoints EQ defer_allowed>
				<cfset user_total = user_totalpoints>
				<cfset WriteSurveyCookie()>
				<!--- the defer_allowed equals the total points available --->
				<cflocation  addtoken="no" url="defer.cfm">
			<cfelse>
				<cfset partialcredit = "true">
			</cfif>
		</cfif>
	<cfelse>
		<!--- username not found --->
		<cfset founduser = "no">
	</cfif>
</cfif>

<cfinclude template="includes/header.cfm">

<cfoutput>
<cfif defer EQ "yes">
	<div align="left">
		<span class="main_login"><cfoutput>#Replace(defer_msg,chr(13) & chr(10),"<br>","ALL")#</cfoutput></span>
	</div>
</cfif>
<br><br><br><br><br>
<span class="main_login">To Continue With The <cfif defer EQ "yes">Deferral<cfelse>Ordering</cfif> Process<br>
	Please Enter Your<br>
	<cfif email_login>
		<b>Email address<b> and 
	</cfif>
	<b>#login_prompt#</b><br>
	Without Dashes or Spaces<br><br>
</span>

<form method="post" action="#CurrentPage#?p=#url.p#">
	<input type="hidden" name="username_required" value="Please enter a #login_prompt#.">
	<input type="hidden" name="iprod" value="#iprod#">
	<input type="hidden" name="prod" value="#prod#">
	<input type="hidden" name="c" value="#c#">
	<input type="hidden" name="g" value="#g#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	<input type="hidden" name="defer" value="#defer#">
	<table cellpadding="2" cellspacing="3" border="0">
	<cfif email_login>
		<tr>
			<td align="right" class="main_login">Email: </td>
			<td><input type="text" name="email" maxlength="128" size="44"><br /></td>
		</tr>
	</cfif>
	<tr>
		<td align="right" class="main_login">#login_prompt#:</td>
		<td><input type="text" name="username" maxlength="128" size="32"></td>
	</tr>
	</table>
	<br><br>
	<input type="submit" name="submit" value="Submit">
</form>
<br><br>

<!--- ************** --->
<!--- ERROR MESSAGES --->
<!--- ************** --->

<cfif is_done>
	<!--- already ordered one item in one item store --->
	<span class="alert">You have already selected your gift.</span>
<cfelseif has_points EQ "no">
	<!--- used all their points --->
	<span class="alert">You have no #credit_desc# remaining.</span>
<cfelseif founduser EQ "no" and defer NEQ "yes">
	<!--- invalid login for ORDER--->
	<span class="main_login">
		<b>Invalid Entry</b>
		<br><br>
		You may have entered your #login_prompt#<br>
		incorrectly or may not be eligible for this award.
		<br><br>
		Please Try Again
		<br><br>
		If you continue to experience difficulty<br>
		please contact Sarah Woodland,<br>
		ITC Awards Administrator, toll free at 1.888.266.6108.
	</span>
<cfelseif founduser EQ "no" and defer EQ "yes">
	<!--- invalid login for DEFER--->
	<span class="main_login">
		<b>Invalid Entry</b>
		<br><br>
		You may have entered your<br>
		#login_prompt# incorrectly.
		<br><br>
		Please Try Again
		<br><br>
		If you continue to experience difficulty<br>
		please contact Sarah Woodland,<br>
		ITC Awards Administrator, toll free at 1.888.266.6108.
	</span>
<cfelseif cantdefer>
	<!--- Not allowed to defer --->
	<span class="main_login">
		You are not eligible to defer.  Please use your #credit_desc#.
	</span>
	<br><br>
	<a href="main.cfm?c=#c#&p=#url.p#&g=#g#&Onpage=#Onpage#">Return to Award Selection</a>
<cfelseif partialcredit>
	<!--- Can't defer because total points doesn't match the defer amount --->
	<span class="main_login">
		You have a partial #credit_desc# balance and cannot defer.
	</span>
	<br><br>
	<a href="main.cfm?c=#c#&p=#url.p#&g=#g#&Onpage=#Onpage#">Return to Award Selection</a>
</cfif>
</cfoutput>

<cfinclude template="includes/footer.cfm">
