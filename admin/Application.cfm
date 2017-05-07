<cfinclude template="../Application.cfm">
<cfsilent>

<cfif NOT isDefined("url.returnto")>
	<cfif isDefined("url.program_select") OR isDefined("url.division_select")>
		<!--- <cfoutput>program_select.cfm?returnto=#GetFileFromPath(GetBaseTemplatePath())#&#CGI.QUERY_STRING#</cfoutput><cfabort> --->
		<cflocation url="program_select.cfm?returnto=#GetFileFromPath(GetBaseTemplatePath())#&#CGI.QUERY_STRING#" addtoken="no">
	</cfif>
</cfif>

<cfset request.selected_program_ID = 0>
<cfset request.selected_division_ID = 0>
<cfset request.is_admin = false>

<cfif isDefined("cookie.itc_program") AND len(cookie.itc_program) GTE 10>
	<!--- Be sure that the cookies weren't hacked --->
	<cfif ListLast(cookie.itc_program,"-") NEQ Hash(Insert(application.salt,Left(cookie.itc_program,10),1))>
		<cfabort showerror="The itc_program cookie may have been hacked: #cookie.itc_program#">
	</cfif>
	<cfif isDefined("cookie.program_ID") AND len(cookie.program_ID) GTE 10>
		<cfif ListLast(cookie.program_ID,"-") NEQ Hash(Insert(application.salt,Left(cookie.program_ID,10),1))>
			<cfabort showerror="The program_ID cookie may have been hacked: #cookie.program_ID#">
		</cfif>
	</cfif>
	<cfif isDefined("cookie.division_ID") AND len(cookie.division_ID) GTE 10>
		<cfif ListLast(cookie.division_ID,"-") NEQ Hash(Insert(application.salt,Left(cookie.division_ID,10),1))>
			<cfabort showerror="The division_ID cookie may have been hacked: #cookie.division_ID#">
		</cfif>
	</cfif>
	<cfif Left(cookie.itc_program,10) EQ '1000000001'>
		<cfset request.is_admin = true>
		<cfif isDefined("cookie.program_ID")>
			<cfset request.selected_program_ID = Left(cookie.program_ID,10)>
		</cfif>
	<cfelse>
		<cfset request.selected_program_ID = Left(cookie.itc_program,10)>
	</cfif>
	<cfif isDefined("cookie.division_ID")>
		<cfset request.selected_division_ID = Left(cookie.division_ID,10)>
	</cfif>
</cfif>

<cfif request.selected_program_ID GT 0>
	<cfquery name="request.program" datasource="#application.DS#">
		SELECT company_name, program_name, admin_logo, is_one_item, can_defer, SUBSTRING(modified_concat,1,15) AS merged_from,
			accepts_cc, has_register, register_email_domain, email_login, is_active, secondary_auth_field
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
	</cfquery>
	<cfset request.program_name = request.program.company_name & " [" & request.program.program_name & "]">
	<cfset request.has_divisions = false>
	<cfquery name="request.GetDivisions" datasource="#application.DS#">
		SELECT ID, company_name, program_name, welcome_button
		FROM #application.database#.program
		WHERE parent_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfif request.GetDivisions.recordcount GT 0>
		<cfset request.has_divisions = true>
		<cfif isDefined("request.selected_division_ID")>
			<cfloop query="request.GetDivisions">
				<cfif ID EQ request.selected_division_ID>
					<cfset request.division_name = company_name>
				</cfif>
			</cfloop>
		</cfif>
			
	</cfif>
</cfif>
</cfsilent>