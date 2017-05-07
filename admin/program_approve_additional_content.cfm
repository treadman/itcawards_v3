<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="program_list.cfm" addtoken="no">
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="where_string" default="">

<!--- param a/e form fields --->
<cfparam name="additional_content_button" default="">
<cfparam name="additional_content_message" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfif form.submit EQ 'Edit'>
		<cflocation addtoken="no" url="program_welcome.cfm?unapproved=yes">
	<cfelseif form.submit EQ 'Approve'>
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.program
			SET	
				additional_content_button = additional_content_button_unapproved,
				additional_content_message = additional_content_message_unapproved							
				#FLGen_UpdateModConcatSQL("from program_approve_additional_content.cfm")#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfquery>
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.program
			SET	additional_content_button_unapproved = <cfqueryparam null="yes">,
				additional_content_message_unapproved = <cfqueryparam null="yes">,
				additional_content_program_admin_ID = <cfqueryparam null="yes">
				#FLGen_UpdateModConcatSQL("from program_approve_additional_content.cfm")#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfquery>
		<cflocation addtoken="no" url="program_details.cfm">
	<cfelseif form.submit EQ 'Delete'>
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.program
			SET	additional_content_button_unapproved = <cfqueryparam null="yes">,
				additional_content_message_unapproved = <cfqueryparam null="yes">,
				additional_content_program_admin_ID = <cfqueryparam null="yes">
				#FLGen_UpdateModConcatSQL("from program_approve_additional_content.cfm")#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#">
		</cfquery>
		<cflocation addtoken="no" url="program_details.cfm">
	</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfquery name="ToBeEdited" datasource="#application.DS#">
	SELECT additional_content_button, additional_content_message, additional_content_button_unapproved, additional_content_message_unapproved
	FROM #Application.database#.program
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
</cfquery>
<cfset additional_content_button = ToBeEdited.additional_content_button>
<cfset additional_content_message = ToBeEdited.additional_content_message>
<cfset additional_content_button_unapproved = ToBeEdited.additional_content_button_unapproved>
<cfset additional_content_message_unapproved = ToBeEdited.additional_content_message_unapproved>

<cfoutput>
<span class="pagetitle">Approve Additional Content for #request.program_name#</span>
<br /><br />

<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="content"><span class="alert">This text is awaiting approval.</span></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Additional Content Button Text: </td>
	<td valign="top">#additional_content_button_unapproved#</td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Additional Content Message:</td>
	<td valign="top">#additional_content_message_unapproved#</td>
	</tr>
												
	<tr class="content">
	<td colspan="2" align="center">
			
	<input type="submit" name="submit" value="Approve"> <input type="submit" name="submit" value="Edit"> <input type="submit" name="submit" value="Delete"> 

	</td>
	</tr>
		
	</table>

</form>
<cfif additional_content_button NEQ "" AND additional_content_message NEQ "">
	<br><br>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext">Current Additional Content Available on Live Website</td>
	</tr>
																																			
	<tr class="content">
	<td align="right" valign="top">Additional Content Button Text: </td>
	<td valign="top">#additional_content_button#</td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Additional Content Message:</td>
	<td valign="top">#additional_content_message#</td>
	</tr>
														
	</table>
</cfif>
</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->