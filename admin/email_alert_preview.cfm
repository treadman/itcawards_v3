<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000072-1000000075",true)>

<cfparam name="where_string" default="">
<cfparam name="delete" default="">

<cfinclude template="includes/header_lite.cfm">

<cfif isDefined("ID") AND isNumeric(ID)>
	<!--- find template --->
	<cfquery name="ALERTFindTemplateText" datasource="#application.DS#">
		SELECT email_text
		FROM #application.database#.email_template
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#url.ID#">
	</cfquery>
	<cfset email_text = ALERTFindTemplateText.email_text>
</cfif>
<cfif NOT isDefined("ID") OR NOT isNumeric(ID) OR ALERTFindTemplateText.RecordCount EQ 0>
	<br><div class="alert" style="padding-left:30px">This email alert template can not be displayed. <br><br>Please contact an administrative user for assistance.</div>
<cfelse>
	<cfif IsDefined('url.prog') AND url.prog NEQ "">
		<!--- find program info --->
		<cfquery name="ALERTGetProgramInfo" datasource="#application.DS#">
			SELECT company_name, Date_Format(expiration_date,'%c/%d/%Y') AS expiration_date
			FROM #application.database#.program
			<cfif has_program>
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
			<cfelse>
				WHERE parent_id = 0
			</cfif>
		</cfquery>
		<!--- swap out the fill in the blank --->
		<cfset email_text = Replace(email_text,"PROGRAM-NAME-HERE","#ALERTGetProgramInfo.company_name#","all")>
		<cfset email_text = Replace(email_text,"PROGRAM-EXPIRATION-DATE","#ALERTGetProgramInfo.expiration_date#","all")>
	</cfif>
	<br><span class="alert" style="letter-spacing:3PX;padding-left:30px">EMAIL ALERT PREVIEW</span><br><br>
	<hr size="1" width="100%">
	<cfoutput>#email_text#</cfoutput>
</cfif>

<cfinclude template="includes/footer.cfm">
