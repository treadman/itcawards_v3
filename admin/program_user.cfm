<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000014-1000000020",true)>

<cfparam name="delete" default="">
<cfparam name="company_name" default="">
<cfparam name="where_string" default="">
<cfparam name="puser_ID" default="">
<cfparam name="duplicateusername" default="false">
<cfparam name="pgfn" default="list">
<cfparam name="entered_by_program_admin" default="">
<cfparam name="find_users_categories" default="0">
<cfparam name="has_categories" default="false">
<cfparam name="email_from" default="#Application.DefaultEmailFrom#">
<cfparam name="email_subject" default="Award Notification">

<!--- param search criteria xxS=ColumnSort xxT=SearchString xxL=Letter --->
<cfparam name="xxS" default="username">
<cfparam name="xxT" default="">
<cfparam name="xxL" default="">
<cfparam name="xxA" default="">
<cfparam name="xOnPage" default="1">

<!--- param a/e form fields --->
<cfparam name="username" default="">
<cfparam name="badge_id" default="">
<cfparam name="fname" default="">
<cfparam name="lname" default="">
<cfparam name="nickname" default="">
<cfparam name="email" default="">
<cfparam name="phone" default="">
<cfparam name="is_active" default="">
<cfparam name="uses_cost_center" default="0">
<cfparam name="is_done" default="">
<cfparam name="expiration_date" default="">
<cfparam name="cc_max" default="">
<cfparam name="defer_allowed" default="">
<cfparam name="ship_address1" default="">
<cfparam name="ship_address2" default="">
<cfparam name="ship_city" default="">
<cfparam name="ship_state" default="">
<cfparam name="ship_zip" default="">
<cfparam name="bill_fname" default="">
<cfparam name="bill_lname" default="">
<cfparam name="bill_address1" default="">
<cfparam name="bill_address2" default="">
<cfparam name="bill_city" default="">
<cfparam name="bill_state" default="">
<cfparam name="bill_zip" default="">
<cfparam name="supervisor_email" default="">
<cfparam name="department" default="">
<cfparam name="level_of_award" default="">
<cfparam name="cost_center_list" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif has_program>
<cfif IsDefined('form.Submit') AND IsDefined('form.username') AND form.username IS NOT "">
	<!--- check to see if this username is already in use for this program --->
	<cfquery name="AnyDuplicateUsernames" datasource="#application.DS#">
		SELECT ID
		FROM #application.database#.program_user
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.username#">
		AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		<cfif form.puser_ID IS NOT "">
			AND ID <> <cfqueryparam cfsqltype="cf_sql_integer" value="#form.puser_ID#">
		</cfif>
	</cfquery>
	<cfif AnyDuplicateUsernames.RecordCount EQ 0>
		<cfif cc_max EQ ''><cfset cc_max = 0></cfif>
		<cfif defer_allowed EQ ''><cfset defer_allowed = 0></cfif>
		<!--- upload certificate --->
		<cfif IsDefined('form.certificate_upload') AND TRIM(form.certificate_upload) IS NOT "">
			<cfset results = FLGen_UploadThis("certificate_upload","award_certificate/",username & "_certificate_" & request.selected_program_ID)>
		</cfif>
		<!--- update --->
		<cfif form.puser_ID IS NOT "">
			<cfquery name="UpdateQuery" datasource="#application.DS#">
				UPDATE #application.database#.program_user
				SET username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.username#" maxlength="128">,
					badge_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.badge_id#" maxlength="128">,
					fname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.fname)))#">,
					lname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.lname)))#">,
					nickname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.nickname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.nickname)))#">,
					email = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(form.email)))#">,
					phone = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.phone#" maxlength="35" null="#YesNoFormat(NOT Len(Trim(form.phone)))#">,
					ship_address1 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.ship_address1)))#">,
					ship_address2 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.ship_address2)))#">,
					ship_city = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.ship_city)))#">,
					ship_state = <cfqueryparam cfsqltype="cf_sql_char" value="#form.ship_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.ship_state)))#">,
					ship_zip = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.ship_zip)))#">,
					bill_fname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_fname)))#">,
					bill_lname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_lname)))#">,
					bill_address1 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.bill_address1)))#">,
					bill_address2 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.bill_address2)))#">,
					bill_city = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_city)))#">,
					bill_state = <cfqueryparam cfsqltype="cf_sql_char" value="#form.bill_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.bill_state)))#">,
					bill_zip = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.bill_zip)))#">,
					is_active = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_active#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.is_active)))#">,
					uses_cost_center = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.uses_cost_center#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.uses_cost_center)))#">,
					is_done = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_done#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.is_done)))#">,
					expiration_date = <cfqueryparam cfsqltype="cf_sql_date" value="#form.expiration_date#" null="#YesNoFormat(NOT Len(Trim(form.expiration_date)))#">,
					cc_max = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cc_max#">,
					defer_allowed = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#defer_allowed#">
					<cfif IsDefined('form.entered_by_program_admin') AND form.entered_by_program_admin NEQ "">, entered_by_program_admin = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#entered_by_program_admin#"></cfif>,
					department = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.department#" null="#YesNoFormat(NOT Len(Trim(form.department)))#">,
					supervisor_email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.supervisor_email#" null="#YesNoFormat(NOT Len(Trim(form.supervisor_email)))#">,
					level_of_award = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.level_of_award#" null="#YesNoFormat(NOT Len(Trim(form.level_of_award)))#">
					#FLGen_UpdateModConcatSQL()#
					WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.puser_ID#">
			</cfquery>
		<!--- add --->
		<cfelse>
			<cflock name="program_userLock" timeout="10">
				<cftransaction>
					<cfquery name="InsertQuery" datasource="#application.DS#">
						INSERT INTO #application.database#.program_user
							(created_user_ID, created_datetime, username, badge_id, fname, lname, nickname, email, phone, is_active, uses_cost_center, is_done, expiration_date, cc_max, defer_allowed, ship_address1, ship_address2, ship_city, ship_state,  ship_zip, bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state,  bill_zip, program_ID, department, supervisor_email, level_of_award)
						VALUES (
							<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#', 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.username#" maxlength="128">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.badge_id#" maxlength="128">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.fname)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.lname)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.nickname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.nickname)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(form.email)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.phone#" maxlength="35" null="#YesNoFormat(NOT Len(Trim(form.phone)))#">, 
							<cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_active#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.is_active)))#">, 
							<cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.uses_cost_center#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.uses_cost_center)))#">, 
							<cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_done#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.is_done)))#">, 
							<cfqueryparam cfsqltype="cf_sql_date" value="#form.expiration_date#" null="#YesNoFormat(NOT Len(Trim(form.expiration_date)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cc_max#">,
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#defer_allowed#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.ship_address1)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.ship_address2)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.ship_city)))#">, 
							<cfqueryparam cfsqltype="cf_sql_char" value="#form.ship_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.ship_state)))#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.ship_zip)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_fname)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_lname)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.bill_address1)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.bill_address2)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_city)))#">, 
							<cfqueryparam cfsqltype="cf_sql_char" value="#form.bill_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.bill_state)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.bill_zip)))#">, 
							<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.department#" null="#YesNoFormat(NOT Len(Trim(form.department)))#">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.supervisor_email#" null="#YesNoFormat(NOT Len(Trim(form.supervisor_email)))#">,
							<cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.level_of_award#" null="#YesNoFormat(NOT Len(Trim(form.level_of_award)))#">
						)
					</cfquery>
					<cfquery name="getID" datasource="#application.DS#">
						SELECT Max(ID) As MaxID FROM #application.database#.program_user
					</cfquery>
					<cfset puser_ID = getID.MaxID>
				</cftransaction>
			</cflock>
			<cfif trim(form.submit) EQ "Save and go to Add Points page">
				<cflocation addtoken="no" url="program_points.cfm?puser_ID=#puser_ID#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">
			</cfif>
		</cfif>
		<!--- save the category information --->
		<cfif has_categories>
			<cfif pgfn EQ 'edit'>
				<cfquery name="DeleteCatXref" datasource="#application.DS#">
					DELETE FROM #application.database#.xref_user_category
					WHERE user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#puser_ID#">
				</cfquery>
			</cfif>
			<!--- insert all the xref category data for this user --->
			<cfif IsDefined('form.FieldNames') AND Trim(#form.FieldNames#) IS NOT "">
				<cfloop list="#form.FieldNames#" index="FormField">
					<cfif FormField CONTAINS 'category_'>
						<cfset current_category_ID = ReplaceNoCase(FormField,'category_','')>
						<cfset current_category_data = Form[FormField]>
						<cfquery name="InsertUserCat" datasource="#application.DS#">
							INSERT INTO #application.database#.xref_user_category
							(created_user_ID, created_datetime, user_ID, category_ID, category_data)
							VALUES
							(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#',
								<cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#current_category_ID#">,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#current_category_data#" maxlength="40">
								)
						</cfquery>
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
		<!--- Update cost centers --->
		<cfquery name="DeleteCurrentSettings" datasource="#application.DS#">
			DELETE FROM #application.database#.xref_cost_center_users
			WHERE program_user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#puser_ID#" maxlength="10">
		</cfquery>
		<cfif cost_center_list NEQ "">
			<cfloop list="#cost_center_list#" index="this_cc">
				<cfquery name="AddSetting" datasource="#application.DS#">
					INSERT INTO #application.database#.xref_cost_center_users
						(cost_center_ID, program_user_ID)
					VALUES (
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#this_cc#" maxlength="10">,
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#puser_ID#" maxlength="10">
					)
				</cfquery>
			</cfloop>
		</cfif>
		<cfset alert_msg = Application.DefaultSaveMessage>
		<cfset pgfn = "list">
	<cfelse>
		<cfset duplicateusername = true>
		<cfset pgfn = form.pgfn>
	</cfif>
<cfelseif IsDefined('form.Submit') AND pgfn EQ 'ccmax'>
	<cfquery name="SetCCMax" datasource="#application.DS#">
		UPDATE #application.database#.program_user
		SET cc_max = <cfqueryparam cfsqltype="cf_sql_integer" value="#cc_max#" maxlength="6">
			#FLGen_UpdateModConcatSQL()#
			WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
	</cfquery>
	<cfset pgfn = "list">
<cfelseif IsDefined('form.Submit') AND pgfn EQ 'allowdefer'>
	<cfquery name="SetCCMax" datasource="#application.DS#">
		UPDATE #application.database#.program_user
		SET defer_allowed = <cfqueryparam cfsqltype="cf_sql_integer" value="#defer_allowed#" maxlength="6">
			#FLGen_UpdateModConcatSQL()#
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
	</cfquery>
	<cfset pgfn = "list">
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000052)>
	<cfquery name="DeleteUserPoints" datasource="#application.DS#">
		DELETE 
		FROM #application.database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#">
	</cfquery>
	<cfquery name="DeleteUserp" datasource="#application.DS#">
		DELETE 
		FROM #application.database#.program_user
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#">
	</cfquery>
</cfif>

<cfif pgfn IS 'send_the_email'>
	<cfquery name="FLITCAwards_SelectRecipients" datasource="#application.DS#">
		SELECT ID AS this_user_ID, fname, lname, email, Date_Format(expiration_date,'%c/%d/%Y') AS expiration_date, 
			Format((((SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) - (SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1)) * (SELECT points_multiplier FROM #application.database#.program WHERE program.ID = program_user.program_ID)),0) AS remaining_points,
			department, supervisor_email, level_of_award, username,badge_id <!---,
			CONCAT(IFNULL(fname,'(no first name)'),' ',IFNULL(lname,'(no last name)'),', <strong>',email,IF(TRIM(supervisor_email) <> '',' has a supervisor',''),'</strong> ',
				Format((((SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) - (SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1))* (SELECT points_multiplier FROM #application.database#.program WHERE program.ID = program_user.program_ID)),0),' points'
			 ) AS ListText--->
		FROM #application.database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND ID = <cfqueryparam value="#form.puser_ID#" cfsqltype="CF_SQL_INTEGER">
		AND email <> ''
		AND email IS NOT NULL
		AND is_active = 1
		ORDER BY lname, fname ASC 
	</cfquery>
	<!--- find template --->
	<cfquery name="ALERTFindTemplateText" datasource="#application.DS#">
		SELECT email_text
		FROM #application.database#.email_template
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#email_template_ID#">
	</cfquery>
	<cfset email_text = ALERTFindTemplateText.email_text>
	<!--- find program info --->
	<cfquery name="ALERTGetProgramInfo" datasource="#application.DS#">
		SELECT company_name, Date_Format(expiration_date,'%c/%d/%Y') AS expiration_date, points_multiplier 
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
	</cfquery>
	<cfif Find("FILL-IN-THE-BLANK",email_text) GT 0>
		<cfset email_text = Replace(email_text,"FILL-IN-THE-BLANK",#fillin#)>
	</cfif>
	<cfset email_text = Replace(email_text,"PROGRAM-NAME-HERE","#ALERTGetProgramInfo.company_name#","all")>
	<cfset email_text = Replace(email_text,"PROGRAM-EXPIRATION-DATE","#ALERTGetProgramInfo.expiration_date#","all")>
	<cfset email_text = Replace(email_text,"DATE-TODAY",DateFormat(Now(),'m/d/yyyy'),"all")>
	<cfset email_text = Replace(email_text,"USER-FIRST-NAME",FLITCAwards_SelectRecipients.fname,"all")>
	<cfset email_text = Replace(email_text,"USER-LAST-NAME",FLITCAwards_SelectRecipients.lname,"all")>
	<cfset email_text = Replace(email_text,"USER-EXPIRATION-DATE",FLITCAwards_SelectRecipients.expiration_date,"all")>
	<cfset email_text = Replace(email_text,"USER-REMAINING-POINTS",FLITCAwards_SelectRecipients.remaining_points,"all")>
	<cfset email_text = Replace(email_text,"LEVEL-OF-AWARD",FLITCAwards_SelectRecipients.level_of_award,"all")>
	<cfset email_text = Replace(email_text,"USER-NAME",FLITCAwards_SelectRecipients.username,"all")>
	<!--- Send Email Alert --->
	<cfif Application.OverrideEmail NEQ "">
		<cfset this_to = Application.OverrideEmail>
	<cfelse>
		<cfset this_to = FLITCAwards_SelectRecipients.email>
	</cfif>
	<cfmail to="#this_to#" from="#email_from#" subject="#email_subject#" type="html">
		<cfif Application.OverrideEmail NEQ "">
			Emails are being overridden.<br>
			Below is the email that would have been sent to #FLITCAwards_SelectRecipients.email#<br>
			<hr>
		</cfif>
#email_text#
	</cfmail>
	<cfset pgfn="list">
</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "program_user">
<cfinclude template="includes/header.cfm">

<script src="../includes/showhide.js"></script>
<script>
function showhideCC(el) {
	var cc = el.value;
	if (el.value > 0) {
		showThis('cost_centers');
	} else {
		hideThis('cost_centers');
	}
}
</script>

<cfparam  name="pgfn" default="list">

<cfif NOT has_program>
	<span class="pagetitle">Program Users</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

<cfif LEN(xxT) GT 0>
	<cfset xxL = "">
</cfif>

<!--- run query --->
<cfif xxS EQ "username" OR xxS EQ "lname" OR xxS EQ "email" OR xxS EQ "is_active">
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID AS puser_ID, username, fname, lname, email, If(is_active = 1,"active","inactive") AS is_active, cc_max, defer_allowed, IF(is_done=1,"ordered","not ordered") AS is_done
		FROM #application.database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		<cfif LEN(xxT) GT 0>
			AND (ID LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%"> 
				OR username LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%"> 
				OR fname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%"> 
				OR lname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%"> 
				OR email LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%">)
		<cfelseif LEN(xxL) GT 0>
			AND #xxS# LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xxL#%">
		</cfif>
		<cfif xxA NEQ 'all'>
			AND is_active = '1'
		</cfif>
		ORDER BY #xxS# ASC
	</cfquery>
</cfif>

<cfif isDefined("SelectList")>
	<!--- set the start/end/max display row numbers --->
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((xOnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
</cfif>

<cfoutput>
<span class="pagetitle">Program Users for #request.program_name#</span>
<br /><br />
<span class="pageinstructions">Return to the <a href="program_list.cfm">Award Program List</a> without making changes.</span>
<br /><br />
<span class="pageinstructions">
	<cfif xxA EQ 'all'>
		<strong>All Program Users Are Displayed</strong>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="program_user.cfm?xOnPage=#xOnPage#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#">Display Active Program Users Only</a>
	<cfelse>
		<strong>Only Active Program Users Are Displayed</strong>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="program_user.cfm?xxA=all&xOnPage=#xOnPage#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#">Display All Program Users</a>
	</cfif>
	<br /><br />
</span>
</cfoutput>
<!--- search box --->
<table cellpadding="5" cellspacing="0" border="0" width="100%">
	<tr class="contenthead">
	<td><span class="headertext">Search Criteria</span></td>
	<td align="right"><a href="<cfoutput>#CurrentPage#?xxS=#xxS#</cfoutput>" class="headertext">view all</a></td>
	</tr>
	<tr>
	<td class="content" colspan="2" align="center">
		<cfoutput>
		<form action="#CurrentPage#" method="post">
			<input type="hidden" name="xxL" value="#xxL#">
			<input type="hidden" name="xxS" value="#xxS#">
			<input type="hidden" name="xxA" value="#xxA#">
			<input type="text" name="xxT" value="#xxT#" size="50">
			<input type="submit" name="submit" value="  Search   ">
		</form>
		</cfoutput>
		<br />
		<cfoutput><cfif LEN(xxL) IS 0><span class="ltrON">ALL</span><cfelse><a href="#CurrentPage#?xxL=&xxS=#xxS#&xxA=#xxA#" class="ltr">ALL</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span><cfloop index = "LoopCount" from = "0" to = "9"><cfoutput><cfif xxL IS LoopCount><span class="ltrON">#LoopCount#</span><cfelse><a href="#CurrentPage#?xxL=#LoopCount#&xxA=#xxA#&xxS=#xxS#" class="ltr">#LoopCount#</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span></cfloop><cfloop index = "LoopCount" from = "1" to = "26"><cfoutput><cfif xxL IS CHR(LoopCount + 64)><span class="ltrON">#CHR(LoopCount + 64)#</span><cfelse><a href="#CurrentPage#?xxL=#CHR(LoopCount + 64)#&xxS=#xxS#&xxA=#xxA#" class="ltr">#CHR(LoopCount + 64)#</a></cfif></cfoutput><cfif LoopCount NEQ 26><span class="ltrPIPE">&nbsp;&nbsp;</span></cfif></cfloop>
	</td>
	</tr>
</table>
<cfif NOT isDefined("SelectList")>
	<br /><br />
	<span class="pageinstructions">No criteria selected.  Click "View All" to display all users in this program.</span>
<cfelse>
<br />
<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	<td>
		<cfif xOnPage GT 1>
			<a href="<cfoutput>#CurrentPage#?xOnPage=1&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?xOnPage=#Max(DecrementValue(xOnPage),1)#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
		</cfif>
	</td>
	<td align="center" class="sub"><cfoutput>[ page displayed: #xOnPage# of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records displayed: #StartRow_SelectList# - #EndRow_SelectList# ]&nbsp;&nbsp;&nbsp;[ total records: #SelectList.RecordCount# ]</cfoutput></td>
	<td align="right">
		<cfif xOnPage LT TotalPages_SelectList>
			<a href="<cfoutput>#CurrentPage#?xOnPage=#Min(IncrementValue(xOnPage),TotalPages_SelectList)#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?xOnPage=#TotalPages_SelectList#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#</cfoutput>" class="pagingcontrols">&raquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
		</cfif>
	</td>
	</tr>
</table>

<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<!--- header row --->
	<cfoutput>
	<tr class="contenthead">
	<td align="center" rowspan="2"><a href="#CurrentPage#?pgfn=add&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">Add</a></td>
	<td rowspan="2" colspan="3">
		<cfif xxS IS "username">
			<span class="headertext">Username</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xxS=username&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#" class="headertext">Username</a>
		</cfif>
		&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif xxS IS "lname">
			<span class="headertext">Name</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xxS=lname&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#" class="headertext">Name</a>
		</cfif>
		&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif xxS IS "email">
			<span class="headertext">Email</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xxS=email&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#" class="headertext">Email</a>
		</cfif>
	</td>
	<cfif request.program.is_one_item EQ 0>
	<td colspan="2" align="center"><span class="headertext">Points</span></td>
	</cfif>
	<cfif request.program.can_defer>
	<td colspan="2" align="center"><span class="headertext">Deferred</span></td>
	</cfif>
	<cfif request.program.accepts_cc EQ 1>
	<td rowspan="2" align="center"><span class="headertext">Max CC</span><br />
	<a href="#CurrentPage#?pgfn=ccmax&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#">set for all users</a></td>
	</cfif>
	<cfif request.program.is_one_item GT 0>
	<td align="center"><span class="headertext">Ordered?</span></td>
	</cfif>
	</tr>
	<tr class="contenthead">
	<cfif request.program.is_one_item EQ 0>
	<td colspan="2" align="center"><a href="program_points.cfm?xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#">+/-&nbsp;for&nbsp;all&nbsp;users</a></td>
	</cfif>
	<cfif request.program.can_defer>
	<td>current</td>
	<td><a href="#CurrentPage#?pgfn=allowdefer&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#">allowed</a></td>
	</cfif>
	<cfif request.program.is_one_item GT 0>
	<td align="center"><span class="sub">(#request.program.is_one_item#-item store)</span></td>
	</cfif>
	</tr>
	</cfoutput>
	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="100%" align="center"><span class="alert"><br />No records found.  Click "view all" to see all records.<br /><br /></span></td>
		</tr>
	<cfelse>
		<!--- display found records --->
		<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
			<cfset show_delete = false>
			<cfif FLGen_HasAdminAccess(1000000052)>
				<cfquery name="HasChildren" datasource="#application.DS#">
					SELECT sum(a.total) as gtotal
					FROM (

					(
					SELECT COUNT(ID) as total, 'order_info' as type
					FROM #application.database#.order_info
					WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10"> 
					AND is_valid = 1

					) UNION (
					
					SELECT COUNT(ID) as total, 'inventory' as type
					FROM #application.database#.inventory
					WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">
					AND is_valid = 1

					) UNION (
					
					SELECT COUNT(ID) as total, 'awards_points' as type
					FROM #application.database#.awards_points
					WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">

					<!---## TODO: Remove the following to allow surveys to be orphaned (or delete them).  Admin has no "delete survey" tool. --->
					) UNION (
					
					SELECT COUNT(ID) as total, 'survey' as type
					FROM #application.database#.survey
					WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">

					)
						) a
				</cfquery>
				<cfif HasChildren.gtotal EQ 0>
					<cfset show_delete = true>
				</cfif>
			</cfif>
			<tr class="#Iif(is_active EQ "active",de(Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))), de('inactivebg'))#">
				<td width="9%;">
					<a href="#CurrentPage#?pgfn=edit&puser_id=#puser_ID#&xxA=#xxA#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">Edit</a>
					<cfif FLGen_HasAdminAccess(1000000052) and show_delete>&nbsp;<a href="#CurrentPage#?delete=#puser_ID#&xxA=#xxA#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#" onclick="return confirm('Are you sure you want to delete this program user?  There is NO UNDO.')">Delete</a>
					</cfif>
				</td>
				<td valign="top" colspan="3">#HTMLEditFormat(username)#<br />#HTMLEditFormat(fname)#&nbsp;#HTMLEditFormat(lname)#<br />#HTMLEditFormat(email)# <cfif email GT ''>(<a href="#CurrentPage#?pgfn=email&puser_id=#puser_ID#&xxA=#xxA#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">Send Notification</a>)</cfif></td>
				<cfif request.program.is_one_item EQ 0>
					<!--- CALCULATE USER'S POINTS --->
					<cfset ProgramUserInfo(SelectList.puser_ID)>
					<td valign="middle" align="right">#user_totalpoints#</td>
					<td align="center"><a href="program_points.cfm?puser_ID=#SelectList.puser_ID#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#">+/-</a></td>
				</cfif>
				<cfif request.program.can_defer>
				<td valign="top" align="right"><span class="sub">[#user_deferedpoints#]</span></td>
				<td valign="top" align="right"><span class="sub">[#defer_allowed#]</span></td>
				</cfif>
				<cfif request.program.accepts_cc EQ 1>
				<td valign="top" align="right"><span class="sub">$#cc_max#</span></td>
				</cfif>
				<cfif request.program.is_one_item GT 0>
				<td valign="top" align="right"><span class="sub">#is_done#</span>
				<br>
				<cfif is_done EQ 'not ordered'>
					<a href="program_user_order.cfm?puser_ID=#SelectList.puser_ID#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">Place Order</a>
				<cfelse>
					<a href="program_user_order.cfm?puser_ID=#SelectList.puser_ID#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#&reorder=1" onClick="return confirm('Are you sure?\n\nThis will delete the existing order!!');">Reorder</a>
				</cfif>
				</td>
				</cfif>
			</tr>
		</cfoutput>
	</cfif>
</table>
</cfif>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfquery name="SelectProgramInfo" datasource="#application.DS#">
		SELECT ID AS program_ID, company_name, is_one_item, accepts_cc, IF(can_defer=1,"true","false") AS can_defer 
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfset is_one_item = SelectProgramInfo.is_one_item>
	<cfset accepts_cc = SelectProgramInfo.accepts_cc>
	<cfset can_defer = SelectProgramInfo.can_defer>
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Program User for #request.program_name#</span>
	<br /><br />
	<span class="pageinstructions">Username is the only required field.</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_user.cfm?xOnPage=#xOnPage#&xxA=#xxA#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#">Program User List</a><cfif FLGen_HasAdminAccess(1000000014)>  or  <a href="program.cfm">Award Program List</a></cfif> without making changes.</span>
	<br /><br />
	<cfif duplicateusername>
		<span class="alert">No duplicate usernames are allowed in a program.  Please enter a new username.</span>
		<br /><br />
	</cfif>
	</cfoutput>
	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT username, badge_id, fname, lname, nickname, email, phone, is_active, uses_cost_center, is_done, expiration_date,
					cc_max, defer_allowed, ship_address1, ship_address2, ship_city, ship_state,  ship_zip,
					bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state,  bill_zip,
					entered_by_program_admin, department, supervisor_email, level_of_award
			FROM #application.database#.program_user
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
		</cfquery>
		<cfset username = htmleditformat(ToBeEdited.username)>	
		<cfset badge_id = htmleditformat(ToBeEdited.badge_id)>	
		<cfset fname = htmleditformat(ToBeEdited.fname)>
		<cfset lname = htmleditformat(ToBeEdited.lname)>
		<cfset nickname = htmleditformat(ToBeEdited.nickname)>
		<cfset email = htmleditformat(ToBeEdited.email)>
		<cfset phone = htmleditformat(ToBeEdited.phone)>
		<cfset is_active = htmleditformat(ToBeEdited.is_active)>
		<cfset uses_cost_center = htmleditformat(ToBeEdited.uses_cost_center)>
		<cfset is_done = htmleditformat(ToBeEdited.is_done)>
		<cfset expiration_date = htmleditformat(ToBeEdited.expiration_date)>
		<cfset cc_max = htmleditformat(ToBeEdited.cc_max)>
		<cfset defer_allowed = htmleditformat(ToBeEdited.defer_allowed)>
		<cfset ship_address1 = htmleditformat(ToBeEdited.ship_address1)>
		<cfset ship_address2 = htmleditformat(ToBeEdited.ship_address2)>
		<cfset ship_city = htmleditformat(ToBeEdited.ship_city)>
		<cfset ship_state = htmleditformat(ToBeEdited.ship_state)>
		<cfset ship_zip = htmleditformat(ToBeEdited.ship_zip)>
		<cfset bill_fname = htmleditformat(ToBeEdited.bill_fname)>
		<cfset bill_lname = htmleditformat(ToBeEdited.bill_lname)>
		<cfset bill_address1 = htmleditformat(ToBeEdited.bill_address1)>
		<cfset bill_address2 = htmleditformat(ToBeEdited.bill_address2)>
		<cfset bill_city = htmleditformat(ToBeEdited.bill_city)>
		<cfset bill_state = htmleditformat(ToBeEdited.bill_state)>
		<cfset bill_zip = htmleditformat(ToBeEdited.bill_zip)>
		<cfset entered_by_program_admin = htmleditformat(ToBeEdited.entered_by_program_admin)>
		<cfset department = htmleditformat(ToBeEdited.department)>
		<cfset supervisor_email = htmleditformat(ToBeEdited.supervisor_email)>
		<cfset level_of_award = htmleditformat(ToBeEdited.level_of_award)>
		<!--- do a search for categories assigned to this user --->
		<cfquery name="FindUsersCategories" datasource="#application.DS#">
			SELECT category_ID, category_data 
			FROM #application.database#.xref_user_category
			WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">
		</cfquery>
		<cfset find_users_categories = FindUsersCategories.RecordCount>
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#" enctype="multipart/form-data">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Program User</td>
	</tr>
	<cfif entered_by_program_admin EQ 1 AND pgfn EQ "edit">
		<tr class="content">
		<td align="right" valign="top">Keep on<br />Users To Verify Report: </td>
		<td valign="top">
			<select name="entered_by_program_admin">
				<option value="1"<cfif entered_by_program_admin EQ 1> selected</cfif>>yes</option>
				<option value="0"<cfif entered_by_program_admin EQ 0> selected</cfif>>no</option>
			</select>
		</td>
		</tr>
	</cfif>
	<tr class="content">
	<td align="right" valign="top">Username: </td>
	<td valign="top"><input type="text" name="username" value="#username#" maxlength="128" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Badge ID: </td>
	<td valign="top"><input type="text" name="badge_id" value="#badge_id#" maxlength="128" size="40">
	<cfif request.program.secondary_auth_field EQ "badge_id"><span class="sub">Secondary Authentication</span></cfif>
	</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">First Name: </td>
	<td valign="top"><input type="text" name="fname" value="#fname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Last Name: </td>
	<td valign="top"><input type="text" name="lname" value="#lname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Nickname: </td>
	<td valign="top"><input type="text" name="nickname" value="#nickname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Email: </td>
	<td valign="top"><input type="text" name="email" value="#email#" maxlength="128" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Phone: </td>
	<td valign="top"><input type="text" name="phone" value="#phone#" maxlength="35" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Must use award amount before: </td>
	<td valign="top"><input type="text" name="expiration_date" value="<cfif expiration_date NEQ "">#FLGen_DateTimeToDisplay(expiration_date)#</cfif>" maxlength="12" size="15"> Please use date format, ex. 10/05/2005.</td>
	</tr>
	<cfif accepts_cc EQ 1>
		<tr class="content">
		<td align="right" valign="top">Credit Card Maximum: </td>
		<td valign="top"><input type="text" name="cc_max" value="#cc_max#" maxlength="6" size="8"></td>
		</tr>
	<cfelse>
		<input type="hidden" name="cc_max" value="0">
	</cfif>
	<cfif can_defer>
		<tr class="content">
		<td align="right" valign="top">Allowed Deferal Amount: </td>
		<td valign="top"><input type="text" name="defer_allowed" value="#defer_allowed#" maxlength="8" size="10"></td>
		</tr>
	<cfelse>
		<input type="hidden" name="defer_allowed" value="0">
	</cfif>
	<tr class="content">
	<td align="right" valign="top">Active: </td>
	<td valign="top">
		<select name="is_active">
			<option value="1"<cfif is_active EQ 1> selected</cfif>>yes</option>
			<option value="0"<cfif is_active EQ 0> selected</cfif>>no</option>
		</select>
	</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Cost Center: </td>
	<td valign="top">
		<select name="uses_cost_center" onChange="showhideCC(this);">
			<option value="0"<cfif uses_cost_center EQ 0> selected</cfif>>May NOT use Cost Center</option>
			<option value="1"<cfif uses_cost_center EQ 1> selected</cfif>>May ONLY use Cost Center</option>
			<option value="2"<cfif uses_cost_center EQ 2> selected</cfif>>May use Points OR Cost Center</option>
			<option value="3"<cfif uses_cost_center EQ 3> selected</cfif>>May use any Combination of Points and Cost Center</option>
		</select>
	</td>
	</tr>
	<cfquery name="CostCenters" datasource="#application.DS#">
		SELECT ID, number
		FROM #application.database#.cost_centers
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		ORDER BY number
	</cfquery>
	<tr class="content" id="cost_centers" <cfif uses_cost_center EQ 0>style="display:none"</cfif>>
	<td align="right" valign="top">Cost Centers: </td>
	<td valign="top">

	<!--- if no records --->
	<cfif CostCenters.RecordCount eq 0>
		<span class="alert">No cost centers found.</span>
	<cfelse>
		<cfset totalnum = max(CostCenters.RecordCount,20)>
		<cfset percol = int(totalnum/4)>
		<cfset currow = 1>
		<table cellpadding="2" cellspacing="0" border="0">
			<tr>
			<!--- display found records --->
			<cfloop query="CostCenters">
				<cfif currow eq 1>
					<td valign="top" width="76px;">
				</cfif>
				<cfquery name="GetCC" datasource="#application.DS#">
					SELECT ID FROM #application.database#.xref_cost_center_users
					WHERE cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
					AND
					<cfif puser_ID IS NOT "">
						program_user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#puser_ID#" maxlength="10">
					<cfelse>
						1=0
					</cfif>
				</cfquery>
				<cfset checked = "">
				<cfif GetCC.recordcount GT 0>
					<cfset checked = "checked">
				</cfif>
				<input type="checkbox" name="cost_center_list" value="#ID#" #checked#>#number#<br>
				<cfif currow eq percol>
					<cfset currow = 1>
					</td>
				<cfelse>
					<cfset currow = currow + 1>
				</cfif>
			</cfloop>
			<cfif currow neq percol>
				</td>
			</cfif>
			</tr>
		</table>
	</cfif>



	
	</td>
	</tr>
	<cfif is_one_item GT 0>
		<tr class="content">
		<td align="right" valign="top">Has ordered #is_one_item# item<cfif is_one_item NEQ 1>s</cfif>?: </td>
		<td valign="top">
			<select name="is_done">
				<option value="0"<cfif is_done EQ 0> selected</cfif>>no</option>
				<option value="1"<cfif is_done EQ 1> selected</cfif>>yes</option>
			</select>
		</td>
		</tr>
	<cfelse>
		<input type="hidden" name="is_done" value="0">
	</cfif>
	<!--- do a search for user categories --->
	<cfquery name="FindCategories" datasource="#application.DS#">
		SELECT ID as loop_category_ID, category_name 
		FROM #application.database#.program_user_category
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		ORDER BY sortorder
	</cfquery>
	<cfif FindCategories.RecordCount GT 0>
		<cfset has_categories = true>
		<tr class="content2">
		<td align="right" valign="top">&nbsp;</td>
		<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6"> User Categories <span class="sub">(only used for creating email alert groups)</span></td>
		</tr>
		<cfloop query="FindCategories">
			<cfset category_value = "">
			<cfif find_users_categories GT 0>
				<cfquery name="IsUserAssignedThisCategory" dbtype="query">
					SELECT category_data 
					FROM FindUsersCategories
					WHERE category_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#loop_category_ID#">
				</cfquery>
				<cfset category_value = htmleditformat(IsUserAssignedThisCategory.category_data)>
			</cfif>
			<tr class="content">
			<td align="right" valign="top">#category_name#</td>
			<td valign="top"><input type="text" name="category_#loop_category_ID#" value="#category_value#" maxlength="40" size="40"></td>
			</tr>
		</cfloop>
	</cfif>
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6"> Shipping Address</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Department: </td>
	<td valign="top"><input type="text" name="department" value="#department#" maxlength="64" size="40"><br /></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Address Line 1: </td>
	<td valign="top"><input type="text" name="ship_address1" value="#ship_address1#" maxlength="64" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Address Line 2: </td>
	<td valign="top"><input type="text" name="ship_address2" value="#ship_address2#" maxlength="64" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">City State Zip: </td>
	<td valign="top">
		<input type="text" name="ship_city" value="#ship_city#" maxlength="30" size="30">
		&nbsp;&nbsp;&nbsp;&nbsp;
		<input type="text" name="ship_state" value="#ship_state#" maxlength="2" size="5">
		<!--- <cfoutput>#FLForm_SelectState("ship_state",ship_state,false,"",true,"",false)#</cfoutput> --->
		&nbsp;&nbsp;&nbsp;&nbsp;
		<input type="text" name="ship_zip" value="#ship_zip#" maxlength="10" size="10">
	</td>
	</tr>
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6"> Billing Address</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">First Name: </td>
	<td valign="top"><input type="text" name="bill_fname" value="#bill_fname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Last Name: </td>
	<td valign="top"><input type="text" name="bill_lname" value="#bill_lname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Address Line 1: </td>
	<td valign="top"><input type="text" name="bill_address1" value="#bill_address1#" maxlength="64" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Address Line 2: </td>
	<td valign="top"><input type="text" name="bill_address2" value="#bill_address2#" maxlength="64" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">City State Zip: </td>
	<td valign="top">
		<input type="text" name="bill_city" value="#bill_city#" maxlength="30" size="30">
		&nbsp;&nbsp;&nbsp;&nbsp;
		<input type="text" name="bill_state" value="#bill_state#" maxlength="2" size="5">
		<!--- <cfoutput>#FLForm_SelectState("bill_state",bill_state,false,"",true,"",false)#</cfoutput> --->
		&nbsp;&nbsp;&nbsp;&nbsp;
		<input type="text" name="bill_zip" value="#bill_zip#" maxlength="10" size="10">
	</td>
	</tr>
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6"> For Email Alerts only</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Supervisor Email: </td>
	<td valign="top"><input type="text" name="supervisor_email" value="#supervisor_email#" maxlength="128" size="40"><br /><span class="sub">If a supervisor is entered, they will receive a copy of all Email Alerts sent to this program user.</span></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Level of Award: </td>
	<td valign="top"><input type="text" name="level_of_award" value="#level_of_award#" maxlength="3" size="3"> <span class="sub">(only used as merge field in email alerts)</span>
	<input type="hidden" name="level_of_award_integer" value="Please enter a number for the Level of Award."></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">PDF Certificate: </td>
	<td valign="top"><input name="certificate_upload" type="file" size="40">
		<cfif FileExists(application.FilePath & "award_certificate/" & username & "_certificate_" & request.selected_program_ID & ".pdf")><br />
			[ <a href="/award_certificate/#username#_certificate_#request.selected_program_ID#.pdf" target="_preview">preview certificate</a> ]<br />
			<span class="sub">If you upload another certificate, it will over-write this certificate.</span>
		</cfif>
	</td>
	</tr>
	<tr class="content">
	<td colspan="2" align="center">
	<input type="hidden" name="xxS" value="#xxS#">
	<input type="hidden" name="xxA" value="#xxA#">
	<input type="hidden" name="xxL" value="#xxL#">
	<input type="hidden" name="xxT" value="#xxT#">
	<input type="hidden" name="xOnPage" value="#xOnPage#">
	<input type="hidden" name="pgfn" value="#pgfn#">
	<input type="hidden" name="has_categories" value="#has_categories#">
	<input type="hidden" name="puser_ID" value="#puser_ID#">
	<input type="hidden" name="username_required" value="Please enter a username.">
	<input type="submit" name="submit" value="   Save Changes   " ><cfif pgfn EQ "add">&nbsp;&nbsp;&nbsp;<input type="submit" name="submit" value=" Save and go to Add Points page " ></cfif>
	</td>
	</tr>
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn ADD/EDIT --->
<cfelseif pgfn EQ "email">
	<!--- START pgfn EMAIL--->
	<cfoutput>
	<span class="pagetitle">Email Notification</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_user.cfm?xOnPage=#xOnPage#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#">Program User List</a> without making changes.</span>
	<br /><br />
	</cfoutput>
	<cfquery name="FindUser" datasource="#application.DS#">
		SELECT fname, lname, nickname, email
		FROM #application.database#.program_user
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">
	</cfquery>
	<cfquery name="FindTemplates" datasource="#application.DS#">
		SELECT ea.ID, ea.email_title 
		FROM #application.database#.email_template ea
		JOIN #application.database#.xref_program_email_template xref ON ea.ID = xref.email_template_ID
		WHERE ea.is_available = 1
			AND xref.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		ORDER BY ea.email_title ASC
	</cfquery>
	<cfif FindTemplates.recordcount GT 0>
		<cfoutput>
		<form method="post" action="#CurrentPage#">
			<table cellpadding="5" cellspacing="1" border="0">
				<tr class="content2"><td  colspan="2"><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span></td></tr>
				<tr class="contenthead"><td class="headertext">Send Email Notification</td></tr>
				<tr class="content">
					<td valign="top" align="center">
						<table border="0">
							<tr><td>Template:</td><td><select name="email_template_ID"><cfloop query="FindTemplates"><option value="#ID#">#email_title#</option></cfloop></select></td></tr>
							<tr><td>To:</td><td>#FindUser.fname# #FindUser.lname# (#FindUser.email#)</td></tr>
							<tr><td>From:</td><td><input name="email_from" type="text" value="#Application.DefaultEmailFrom#" size="40" maxlength="64" readonly /></td></tr>
							<tr><td>Subject:</td><td><input name="email_subject" type="text" value="#email_subject#" size="40" maxlength="64" /></td></tr>
							<tr><td valign="top">Fill In Message:</td><td valign="top"><textarea name="fillin" cols="40" rows="8"></textarea></td></tr>
						</table>
					</td>
				</tr>
				<tr class="content">
					<td valign="top" align="center">
						<input type="hidden" name="xxS" value="#xxS#">
						<input type="hidden" name="xxA" value="#xxA#">
						<input type="hidden" name="xxL" value="#xxL#">
						<input type="hidden" name="xxT" value="#xxT#">
						<input type="hidden" name="xOnPage" value="#xOnPage#">
						<input type="hidden" name="pgfn" value="send_the_email" />
						<input type="hidden" name="puser_ID" value="#puser_ID#" />
						<input type="submit" name="submit" value="   Send Email   " >
					</td>
				</tr>
			</table>
		</form>
		</cfoutput>
	<cfelse>
		<br>
		&nbsp;&nbsp;&nbsp;&nbsp;
		<span class="alert">This program has no email templates.</span>
	</cfif>
	<!--- END pgfn EMAIL --->
<cfelseif pgfn EQ "ccmax">
	<!--- START pgfn CC MAX --->
	<cfoutput>
	<span class="pagetitle">Set Credit Card Maximum</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_user.cfm?xOnPage=#xOnPage#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#">Program User List</a> without making changes.</span>
	<br /><br />
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0">
	<tr class="content2">
	<td  colspan="2"><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span></td>
	</tr>
	<tr class="contenthead">
	<td class="headertext">Set Credit Card Maximum for all Program Users</td>
	</tr>
	<tr class="content">
	<td valign="top" align="center"><input type="text" name="cc_max" maxlength="6" size="8">
	<input type="hidden" name="xxS" value="#xxS#">
	<input type="hidden" name="xxA" value="#xxA#">
	<input type="hidden" name="xxL" value="#xxL#">
	<input type="hidden" name="xxT" value="#xxT#">
	<input type="hidden" name="xOnPage" value="#xOnPage#">
	<input type="hidden" name="pgfn" value="#pgfn#">
	<input type="submit" name="submit" value="   Save Changes   " >
	</td>
	</tr>
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn CC MAX --->
<cfelseif pgfn EQ "allowdefer">
	<!--- START pgfn DEFER ALLOWED --->
	<cfoutput>
	<span class="pagetitle">Set Allowed Deferal Amount</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_user.cfm?xOnPage=#xOnPage#&xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#">Program User List</a> without making changes.</span>
	<br /><br />
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0">
	<tr class="content2">
	<td  colspan="2"><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span></td>
	</tr>
	<tr class="contenthead">
	<td class="headertext">Set Allowed Deferal Amount for all Program Users</td>
	</tr>
	<tr class="content">
	<td valign="top" align="center"><input type="text" name="defer_allowed" maxlength="6" size="8">
	<input type="hidden" name="xxS" value="#xxS#">
	<input type="hidden" name="xxA" value="#xxA#">
	<input type="hidden" name="xxL" value="#xxL#">
	<input type="hidden" name="xxT" value="#xxT#">
	<input type="hidden" name="xOnPage" value="#xOnPage#">
	<input type="hidden" name="pgfn" value="#pgfn#">
	<input type="submit" name="submit" value="   Save Changes   " >
	</td>
	</tr>
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn DEFER ALLOWED --->
</cfif>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->
