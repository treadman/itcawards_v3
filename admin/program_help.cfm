<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="program_list.cfm" addtoken="no">
</cfif>
<cfset edit_division = false>
<cfif isNumeric(request.selected_division_ID) AND request.selected_division_ID GT 0>
	<cfset edit_division = true>
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<!--- param a/e form fields --->
<cfparam name="help_button" default="">
<cfparam name="help_message" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfquery name="UpdateQuery" datasource="#application.DS#">
		UPDATE #application.database#.program
		SET	help_button = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#help_button#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(help_button)))#">,
			help_message = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#help_message#" null="#YesNoFormat(NOT Len(Trim(help_message)))#">
			#FLGen_UpdateModConcatSQL("from program_help.cfm")#
			WHERE ID =
			<cfif edit_division> 
				<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
			<cfelse>
				<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
			</cfif>
	</cfquery>
	<cflocation addtoken="no" url="program_details.cfm">

</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfset tinymce_fields = "help_message">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">

<cfquery name="ToBeEdited" datasource="#application.DS#">
	SELECT help_button, help_message 
	FROM #application.database#.program
	WHERE ID =
	<cfif edit_division> 
		<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
	<cfelse>
		<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfif>
</cfquery>
<cfset help_button = htmleditformat(ToBeEdited.help_button)>
<cfset help_message = htmleditformat(ToBeEdited.help_message)>

<cfoutput>
<span class="pagetitle">
	Edit
	<cfif edit_division>
		<span class="highlight">Help Page for #request.division_name#</span> a division of
	<cfelse>
		Help Page for
	</cfif>
	#request.program_name#
</span>
<br /><br />
<span class="pageinstructions">Return to the <a href="program_details.cfm"><cfif edit_division>Division<cfelse>Award Program</cfif> Details</a><cfif edit_division> or the <a href="program_details.cfm?division_select=">Parent Program Details</a></cfif> or the <a href="program_list.cfm?division_select=">Award Program List</a> without making changes.</span>
<br /><br />

<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext <cfif edit_division>highlight</cfif>">Help Page</td>
	</tr>
					
	<tr class="content">
	<td align="right" valign="top">Help Button Text: </td>
	<td valign="top"><input type="text" name="help_button" value="#help_button#" maxlength="30" size="40"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Help Content:</td>
	<td valign="top"><textarea name="help_message" cols="50" rows="15">#help_message#</textarea></td>
	</tr>
												
	<tr class="content">
	<td colspan="2" align="center">
		
	<input type="submit" name="submit" value="   Save Changes   " >

	</td>
	</tr>
		
	</table>

</form>

</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->