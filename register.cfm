<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<!--- Put the following in admin --->
<cfset register_thankyou_text = "
	Thank you for registering.<br><br>
">

<cfquery name="GetRegister" datasource="#application.DS#">
	SELECT ID, register_name, date_start, date_end, award_points
	FROM #application.database#.program_register
	WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
	AND date_start <= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#">
	AND date_end >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#">
</cfquery>

<cfset points=0>
<cfif GetRegister.recordcount GT 0>
	<cfset points = GetRegister.award_points>
</cfif>

<cfif NOT has_register>
	<cflocation addtoken="no" url="main.cfm">
</cfif>

<cfparam name="pgfn" default="input">

<cfparam name="email" default="">
<cfparam name="password" default="">
<cfparam name="confirmpassword" default="">
<cfparam name="first_name" default="">
<cfparam name="last_name" default="">
<cfparam name="phone" default="">
<cfparam name="ship_address1" default="">
<cfparam name="ship_address2" default="">
<cfparam name="ship_city" default="">
<cfparam name="ship_state" default="">
<cfparam name="ship_zip" default="">

<cfset ErrorMessage = "">

<cfif pgfn IS 'verify'>
	<cfif email IS "" OR NOT FLGen_IsValidEmail(email)>
		<cfset ErrorMessage = ErrorMessage & 'Please enter a valid email address<br />'>
	<cfelseif register_email_domain NEQ "" AND NOT ListFind(register_email_domain,ListLast(email,"@"))>
		<cfif ListLen(register_email_domain) EQ 1>
			<cfset ErrorMessage = ErrorMessage & 'You may only register with a "#register_email_domain#" email address.<br />'>
		<cfelse>
			<cfset ErrorMessage = ErrorMessage & 'You may only register with one of these email address domains: "#register_email_domain#".<br />'>
		</cfif>
	</cfif>
	<cfif password IS "">
		<cfset ErrorMessage = ErrorMessage & 'Please enter a password<br />'>
	<cfelse>
		<!--- <cfif LEN(password) LT 8>
			<cfset ErrorMessage = ErrorMessage & 'Your password must be at least 8 characters in length<br />'>
		<cfelse> --->
			<cfif confirmpassword IS "">
				<cfset ErrorMessage = ErrorMessage & 'Please confirm your password<br />'>
			<cfelseif password NEQ confirmpassword>
				<cfset ErrorMessage = ErrorMessage & 'Your passwords do not match<br />'>
			</cfif>
		<!--- </cfif> --->
	</cfif>
	<cfif first_name IS ""><cfset ErrorMessage = ErrorMessage & 'Please enter your first name<br />'></cfif>
	<cfif last_name IS ""><cfset ErrorMessage = ErrorMessage & 'Please enter your last name<br />'></cfif>
	<cfif register_get_shipping>
		<cfif ship_address1 IS ""><cfset ErrorMessage = ErrorMessage & 'Please enter your address<br />'></cfif>
		<cfif ship_city IS ""><cfset ErrorMessage = ErrorMessage & 'Please enter your city<br />'></cfif>
		<cfif ship_state IS ""><cfset ErrorMessage = ErrorMessage & 'Please enter your state<br />'></cfif>
		<cfif ship_zip IS ""><cfset ErrorMessage = ErrorMessage & 'Please enter your zip code<br />'></cfif>
	</cfif>
	<cfif phone IS ""><cfset ErrorMessage = ErrorMessage & 'Please enter your phone number<br />'></cfif>
	<cfif ErrorMessage GT "">
		<cfset pgfn = 'input'>
	</cfif>
</cfif>
	
<cfinclude template="includes/header.cfm">

<cfparam name="CONFIRM" default=0>

<cfif pgfn IS 'verify'>
	<cflock name="program_userLock" timeout="60">
		<cfquery name="CheckUserName" datasource="#application.DS#">
			SELECT ID 
			FROM #application.database#.program_user
			WHERE username = <cfqueryparam value="#password#" cfsqltype="CF_SQL_VARCHAR">
			AND program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
		</cfquery>
		<cfquery name="CheckEmail" datasource="#application.DS#">
			SELECT ID 
			FROM #application.database#.program_user
			WHERE email = <cfqueryparam value="#email#" cfsqltype="CF_SQL_VARCHAR">
			AND program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
		</cfquery>
		<cfquery name="CheckProgram" datasource="#application.DS#">
			SELECT ID 
			FROM #application.database#.program_login
			WHERE password = <cfqueryparam value="#password#" cfsqltype="CF_SQL_VARCHAR">
			AND program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
		</cfquery>
		<cfif CheckUserName.RecordCount IS 0 AND CheckEmail.RecordCount IS 0 AND CheckProgram.RecordCount IS 0>
			<cfquery name="AddProgramUser" datasource="#application.DS#" result="stResult">
				INSERT INTO #application.database#.program_user (
					created_user_ID, created_datetime, program_ID, username, fname, lname, ship_address1, ship_address2, ship_city, ship_state, ship_zip, phone, email, is_active)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">,
					'#FLGen_DateTimeToMySQL()#',
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#password#" maxlength="16">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#first_name#" maxlength="30">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#" maxlength="30">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ship_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(ship_address1)))#">, 
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ship_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(ship_address2)))#">, 
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ship_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(ship_city)))#">, 
					<cfqueryparam cfsqltype="cf_sql_char" value="#ship_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(ship_state)))#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ship_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(ship_zip)))#">, 
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#phone#" maxlength="35">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#email#" maxlength="128">,
					1)
			</cfquery>
			<cfset programUserID = stResult.GENERATED_KEY>
			<cfif points GT 0>
				<cfset points_division_id = 0>
				<cfif has_divisions>
					<cfquery name="getDefaultDiv" datasource="#application.DS#">
						SELECT default_division
						FROM #application.database#.program
						WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
					</cfquery>
					<cfset points_division_id = getDefaultDiv.default_division>
				</cfif>
				<cfset Notes = "#Points# points for registering." & CHR(13) & CHR(10)>
				<cfquery name="AwardPoints" datasource="#application.DS#">
					INSERT INTO #application.database#.awards_points (
						created_user_ID, created_datetime, user_ID, points, notes, division_ID)
					VALUES (
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#',
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#programUserID#" maxlength="10">,
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#Points#">,
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#Notes#">,
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#points_division_id#" maxlength="10">
					)
				</cfquery>
			</cfif>
			<!--- Check if they are a cost center user --->
			<cfquery name="GetUsers" datasource="#application.DS#">
				SELECT
					cc_code,
					cc_desc,
					mgr_lastname,
					mgr_firstname,
					mgr_email,
					mc_lastname,
					mc_firstname,
					mc_email
				FROM #application.database#.cost_center_user
				WHERE email = <cfqueryparam value="#email#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>
			<cfif GetUsers.recordcount EQ 1>
				<cfset this_cc_number = trim(GetUsers.cc_code)>
				<cfif programUserID GT 0 AND this_cc_number NEQ "">
					<cfset this_cc_ID = 0>
					<!---Look up cost center--->
					<cfquery name="GetCostCenter" datasource="#application.DS#">
						SELECT ID
						FROM #application.database#.cost_centers
						WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
						AND number = '#this_cc_number#'
					</cfquery>
					<cfif GetCostCenter.recordcount EQ 1>
						<cfset this_cc_ID = GetCostCenter.ID>
					<cfelse>
						<cfset this_cc_ID = 0>
					</cfif>
					<!--- Check if user is in cost center --->
					<cftry>
					<cfquery name="AddUserToCC" datasource="#application.DS#">
						INSERT INTO #application.database#.xref_cost_center_users
							(cost_center_ID, program_user_ID)
						VALUES
							(#this_CC_ID#, #programUserID#)
					</cfquery>
					<cfcatch></cfcatch></cftry>
					<!--- Mark user as uses_cost_center = 2 --->
					<cfquery name="UpdateUser" datasource="#application.DS#">
						UPDATE #application.database#.program_user
						SET uses_cost_center = 2
						WHERE ID = #programUserID#
					</cfquery>
				</cfif>
			</cfif>
			<cfif register_template_id GT 0>
				<cfset email_error = "">
				<cfquery name="FindTemplateText" datasource="#application.DS#">
					SELECT email_text
					FROM #application.database#.email_template
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#register_template_id#">
				</cfquery>
				<cfset email_text = FindTemplateText.email_text>
				<cfset email_text = Replace(email_text,"DATE-TODAY",DateFormat(Now(),'m/d/yyyy'),"all")>
				<cfset email_text = Replace(email_text,"USER-FIRST-NAME",first_name,"all")>
				<cfset email_text = Replace(email_text,"PASSWORD",password,"all")>
				<cfset email_text = Replace(email_text,"USER-REMAINING-POINTS",points,"all")>
				<cftry>
				<!--- Send Email Alert --->
				<cfset email_subject = "Thank you for registering!">
				<cfif register_email_subject neq "">
					<cfset email_subject = register_email_subject>
				</cfif>
				<cfmail failto="#Application.ErrorEmailTo#" to="#email#" from="#Application.DefaultEmailFrom#" subject="#email_subject#" type="html">
#email_text#
				</cfmail>
				<cfcatch><cfset email_error = "<br><br><b>email not sent</b> -- [email: #email#]"></cfcatch>
			</cftry>
			<cfif email_error NEQ "">
		<cfmail to="#Application.ErrorEmailTo#" from="#Application.DefaultEmailFrom#" subject="Error in Register Email" type="html">
#email_error#
		</cfmail>
			</cfif>

	
			</cfif>
			<cfparam name="cc_max" default="0">
			<cfset GetProgramUserInfo(programUserID,email)>
			<cfif has_welcomepage>
				<cflocation addtoken="no" url="welcome.cfm">
			<cfelse>
				<cflocation addtoken="no" url="main.cfm">
			</cfif>
			<cfset pgfn = "thankyou">
		<cfelse>
			<cfif CheckUserName.RecordCount GT 0 OR CheckProgram.RecordCount GT 0>
				<cfset ErrorMessage = ErrorMessage & 'That is not a valid password. Please enter a different password.<br />'>
			</cfif>
			<cfif CheckEmail.RecordCount GT 0>
				<cfset ErrorMessage = ErrorMessage & 'That email address has already been registered.  You may only register once.<br />'>
			</cfif>
			<cfset password = "">
			<cfset confirmpassword = "">
			<cfset pgfn='input'>
		</cfif>
	</cflock>
</cfif>							
<cfoutput>
<cfif pgfn EQ 'input'>
	<cfcookie name="itc_user" expires="now" value="">
	<cfcookie name="itc_email" expires="now" value="">
	<cfif trim(register_form_text) NEQ "">
		#register_form_text#
	</cfif>
	<form action="#application.SecureWebPath#/register.cfm" method="post" NAME="form_entry" ><!--- onSubmit="return validateForm();" --->
		<input type="hidden" name="pgfn" value="verify">
		<table border="0" cellpadding="3" cellspacing="0">
			<tr><td align="left" colspan="2"><font color="##FF0000"><br>#ErrorMessage#</font><br></td></tr>
			<tr><td align="right" class="main_login">Email Address </td><td><input type="text" name="email" size="30" maxlength="128" value="#email#"></td></tr>
			<tr><td align="right" class="main_login">Password </td><td><input type="password" name="password" size="16" maxlength="16" value="#password#"></td></tr>
			<tr><td align="right" class="main_login">Confirm Password </td><td><input type="password" name="confirmpassword" size="16" maxlength="16" value="#confirmpassword#"></td></tr>
			<tr><td align="right" class="main_login">First Name </td><td><input type="text" name="first_name" size="30" maxlength="30" value="#first_name#"></td></tr>
			<tr><td align="right" class="main_login">Last Name </td><td><input type="text" name="last_name" size="30" maxlength="30" value="#last_name#"></td></tr>
			<cfif register_get_shipping>
	<tr>
	<td align="right" class="main_login">Address</td>
	<td valign="top"><input type="text" name="ship_address1" value="#ship_address1#" maxlength="64" size="40"></td>
	</tr>
	<tr>
	<td align="right" class="main_login"></td>
	<td><input type="text" name="ship_address2" value="#ship_address2#" maxlength="64" size="40"></td>
	</tr>
	<tr>
	<td align="right" class="main_login">City</td>
	<td>
		<input type="text" name="ship_city" value="#ship_city#" maxlength="30" size="20">
		&nbsp;&nbsp;&nbsp;State&nbsp;
		<input type="text" name="ship_state" value="#ship_state#" maxlength="2" size="4">
		<!--- <cfoutput>#FLForm_SelectState("ship_state",ship_state,false,"",true,"",false)#</cfoutput> --->
		&nbsp;&nbsp;&nbsp;Zip Code&nbsp;
		<input type="text" name="ship_zip" value="#ship_zip#" maxlength="10" size="6">
	</td>
	</tr>
			</cfif>
			<tr><td align="right" class="main_login">Phone Number </td><td><input type="text" name="phone" size="14" maxlength="35" value="#phone#"></td></tr>
			<tr><td align="right" class="main_login">&nbsp;</td><td>&nbsp;</td></tr>
			<tr><td colspan="2" align="center">
		<table cellpadding="8" cellspacing="1" border="0">
			
		<tr>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="form_entry.submit();">  Register  </td>
		</tr>
		
		</table>
	</form>
<cfelseif pgfn EQ "thankyou">
	#register_thankyou_text#
</cfif>							
</cfoutput>

<cfinclude template="includes/footer.cfm">
