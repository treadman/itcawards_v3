<!--- function library --->
<cfinclude template="includes/function_library_local.cfm">
<cfinclude template="includes/function_library_public.cfm">

<cfif IsDefined('cookie.itc_user') AND cookie.itc_user IS NOT "">
	<cfset AuthenticateProgramUserCookie()>
</cfif>

<cfset GetProgramInfo(request.division_id)>

<cfset logThemOut = true>

<cfif linked_program_id GT 0>
	<cfquery name="GetUser" datasource="#application.DS#">
		SELECT u.ID, u.username
		FROM #application.database#.program_user u
		LEFT JOIN #application.database#.program p ON u.program_ID = p.ID AND p.parent_ID = 0
		WHERE u.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_id#" maxlength="10">
		AND p.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_id#" maxlength="10">
		AND p.is_active = 1
		AND u.is_active = 1 
	</cfquery>
	<cfif GetUser.recordcount EQ 1>
		<cfset new_user_id = 0>
		<cfquery name="GetLinked" datasource="#application.DS#">
			SELECT ID
			FROM #application.database#.program_user
			WHERE linked_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetUser.ID#" maxlength="10">
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#linked_program_id#" maxlength="10">
		</cfquery>
		<cfif GetLinked.recordcount EQ 1>
			Found it!
			<cfset new_user_id = GetLinked.ID>
		<cfelseif GetLinked.recordcount EQ 0>
			<cfquery name="CreateUser" datasource="#application.DS#" result="result">
				INSERT INTO #application.database#.program_user
					(program_ID, username, nickname, fname, lname, ship_company, ship_fname, ship_lname, ship_address1, ship_address2, ship_city, ship_state, ship_zip, ship_country, phone, email, bill_company, bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state, bill_zip, cc_max, is_active, is_done, defer_allowed, expiration_date, entered_by_program_admin, supervisor_email, level_of_award, badge_id, department, linked_user_ID)
				SELECT #linked_program_id#, username, nickname, fname, lname, ship_company, ship_fname, ship_lname, ship_address1, ship_address2, ship_city, ship_state, ship_zip, ship_country, phone, email, bill_company, bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state, bill_zip, cc_max, is_active, is_done, defer_allowed, expiration_date, entered_by_program_admin, supervisor_email, level_of_award, badge_id, department, #GetUser.ID#
				FROM #application.database#.program_user
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_id#" maxlength="10">
			</cfquery>
			<cfset new_user_id = result.generated_key>
		</cfif>
		<cfif new_user_id GT 0>
			<cfset logThemOut = false>
			<cfset GetProgramUserInfo(new_user_id)>
			<cfset HashedProgramID = FLGen_CreateHash(linked_program_id)>
			<cfcookie name="itc_pid" value="#linked_program_id#-#HashedProgramID#">
			<cflocation addtoken="no" url="welcome.cfm">
		</cfif>
	</cfif>
</cfif>

<cfif logThemOut>
	<cflocation addtoken="no" url="logout.cfm">
</cfif>


<cfinclude template="includes/header.cfm">

<cfoutput>
You linked from #program_id# to #linked_program_id#!
<br><br>
#secondary_auth_field#
</cfoutput>



<cfinclude template="includes/footer.cfm">
