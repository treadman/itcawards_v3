<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000089,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">

<!--- param a/e form fields --->
<cfparam name="additional_content_button" default="">
<cfparam name="additional_content_message" default="">

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<cfif has_program>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit') AND form.Submit IS NOT "" AND IsDefined('form.additional_content_message_unapproved') AND form.additional_content_message_unapproved IS NOT "">

	<cfquery name="UpdateQuery" datasource="#application.DS#">
		UPDATE #application.database#.program
		SET	additional_content_button_unapproved = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#additional_content_button_unapproved#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(additional_content_button_unapproved)))#">,
			additional_content_message_unapproved = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#additional_content_message_unapproved#" null="#YesNoFormat(NOT Len(Trim(additional_content_message_unapproved)))#">,
			additional_content_program_admin_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#">
			#FLGen_UpdateModConcatSQL("from program_admin_additional_content.cfm")#
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfif Application.OverrideEmail NEQ "">
		<cfset this_to = Application.OverrideEmail>
	<cfelse>
		<cfset this_to = Application.AdminEmailTo>
	</cfif>
	<cfmail to="##" from="#Application.DefaultEmailFrom#" subject="#request.program_name# Content Approval Needed">
		<cfif application.OverrideEmail NEQ "">
			Emails are being overridden.<br>
			Below is the email that would have been sent to #Application.AdminEmailTo#<br>
			<hr>
		</cfif>
	Please review the additional content entered by #FLGen_GetAdminName(FLGen_adminID)# for the award program #request.program_name#.
	
	1) Login to the admin website
	2) Click on Program
	3) Click on Details for #request.program_name#
	4) Scroll to the bottom of the Welcome Page section and click "more information ..."
	5) Review unapproved additional content and take appropriate action.
	
	Note:  This is an automatically generated email.
	</cfmail>
	
	<cfset alert_msg = "Your entries have been saved and will be sent to ITC for approval.">

</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->
</cfif>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programadmin_additionalcontent">
<cfinclude template="includes/header.cfm">

<cfset tinymce_fields = "additional_content_message_unapproved">
<cfset tinymce_image_list = "/admin/image_lists/#request.selected_program_ID#_1_image_list.js">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">

<span class="pagetitle">Edit Additional Content</span>
<br /><br />

<cfif NOT has_program>
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<span class="pageinstructions">The information submitted by this form must be approved by ITC before it will be available on the live website.</span>
<br /><br />

<cfquery name="ToBeEdited" datasource="#application.DS#">
	SELECT additional_content_button, additional_content_message, additional_content_button_unapproved, additional_content_message_unapproved
	FROM #application.database#.program
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
</cfquery>
<cfset additional_content_button = ToBeEdited.additional_content_button>
<cfset additional_content_message = ToBeEdited.additional_content_message>
<cfset additional_content_button_unapproved = ToBeEdited.additional_content_button_unapproved>
<cfset additional_content_message_unapproved = ToBeEdited.additional_content_message_unapproved>

<cfoutput>

<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="content">
	<td colspan="4"><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span></td>
	</tr>

	<tr class="contenthead">
	<td colspan="2" class="headertext">Additional Content</td>
	</tr>
	
	<cfif additional_content_button_unapproved NEQ "" AND additional_content_message_unapproved NEQ "">
																	
	<tr class="contenthead">
	<td colspan="2" class="content"><span class="alert">The text in the form is awaiting approval.</span></td>
	</tr>
	
	</cfif>
																	
	<tr class="content">
	<td align="right" valign="top">Additional Content Button Text: </td>
	<td valign="top"><input type="text" name="additional_content_button_unapproved" value="#additional_content_button_unapproved#" maxlength="30" size="40">
	<input type="hidden" name="additional_content_button_unapproved_required" value="Please enter button text."></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Additional Content Message:</td>
	<td valign="top"><textarea name="additional_content_message_unapproved" cols="50" rows="15">#additional_content_message_unapproved#</textarea>
	<input type="hidden" name="additional_content_message_unapproved_required" value="Please enter message text."></td>
	</tr>
												
	<tr class="content">
	<td colspan="2" align="center">
			
	<input type="submit" name="submit" value="   Save and Request Approval   " >

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

</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->