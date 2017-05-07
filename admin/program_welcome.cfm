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

<cfparam name="where_string" default="">
<cfparam name="delete" default="">
<cfparam name="unapproved" default="">

<!--- param a/e form fields --->
<cfparam name="has_welcomepage" default="">
<cfparam name="welcome_bg" default="">
<cfparam name="welcome_instructions" default="Gifts are categorized by Safety Awards Credits. 

Your Safety Awards Credits can be used can be applied to any category of gifts. 

If your selection exceeds your Safety Awards Credits you may use your credit card to complete the transaction.">
<cfparam name="welcome_message" default="">
<cfparam name="welcome_congrats" default="">
<cfparam name="welcome_button" default="View Selections">
<cfparam name="welcome_admin_button" default="">
<cfparam name="admin_logo" default="">
<cfparam name="email_form_button" default="">
<cfparam name="email_form_button" default="">
<cfparam name="additional_content_button" default="">
<cfparam name="additional_content_message" default="">
<cfparam name="welcome_certificate" default="">
<cfparam name="welcome_certificate_style" default="">
<cfparam name="show_landing_text" default="">
<cfparam name="landing_text" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>

	<cfquery name="UpdateQuery" datasource="#application.DS#">
		UPDATE #application.database#.program
		SET	has_welcomepage = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#has_welcomepage#">,
			welcome_bg = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#welcome_bg#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(welcome_bg)))#">, 
			welcome_instructions = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#welcome_instructions#" null="#YesNoFormat(NOT Len(Trim(welcome_instructions)))#">,
			welcome_message = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#welcome_message#" null="#YesNoFormat(NOT Len(Trim(welcome_message)))#">,
			welcome_congrats = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#welcome_congrats#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(welcome_congrats)))#">, 
			welcome_button = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#welcome_button#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(welcome_button)))#">,
			welcome_admin_button = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#welcome_admin_button#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(welcome_admin_button)))#">,
			admin_logo = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#admin_logo#" maxlength="40" null="#YesNoFormat(NOT Len(Trim(admin_logo)))#">,
			email_form_button = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#email_form_button#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(email_form_button)))#">,
			email_form_message = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#email_form_message#" null="#YesNoFormat(NOT Len(Trim(email_form_message)))#">,
			email_form_recipient = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="255" value="#email_form_recipient#" null="#YesNoFormat(NOT Len(Trim(email_form_recipient)))#">,
			additional_content_button = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#additional_content_button#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(additional_content_button)))#">,
			additional_content_message = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#additional_content_message#" null="#YesNoFormat(NOT Len(Trim(additional_content_message)))#">,
			show_landing_text = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#show_landing_text#">,
			landing_text = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#landing_text#" null="#YesNoFormat(NOT Len(Trim(landing_text)))#">
			<!--- welcome_certificate = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="64" value="#welcome_certificate#" null="#YesNoFormat(NOT Len(Trim(welcome_certificate)))#">
			welcome_certificate_style = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#additional_content_message#" null="#YesNoFormat(NOT Len(Trim(additional_content_message)))#"> --->
			
			<cfif form.unapproved NEQ "">
				,
				additional_content_button_unapproved = <cfqueryparam null="yes">,
				additional_content_message_unapproved = <cfqueryparam null="yes">,
				additional_content_program_admin_ID = <cfqueryparam null="yes">
			</cfif>
			
			#FLGen_UpdateModConcatSQL("from program_welcome.cfm")#
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
<cfset request.main_width = 900>
<cfinclude template="includes/header.cfm">

<script language="javascript">
function enterThisImage(image,field)
{
document.getElementById(field).value = image
}
</script>

<cfset tinymce_fields = "welcome_instructions,landing_text,email_form_message">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">

<cfset tinymce_skip_include = true>
<cfset tinymce_fields = "additional_content_message">
<cfset tinymce_image_list = "/admin/image_lists/#request.selected_program_ID#_1_image_list.js">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">

<cfset tinymce_fields = "welcome_message">
<cfset tinymce_image_list = "/admin/image_lists/#request.selected_program_ID#_3_image_list.js">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">


<cfoutput>
<span class="pagetitle">
	Edit
	<cfif edit_division>
		<span class="highlight">Program Welcome Page for #request.division_name#</span> a division of
	<cfelse>
		Program Welcome Page for
	</cfif>
	#request.program_name#
</span>
<br /><br />
<span class="pageinstructions">Return to the <a href="program_details.cfm"><cfif edit_division>Division<cfelse>Award Program</cfif> Details</a><cfif edit_division> or the <a href="program_details.cfm?division_select=">Parent Program Details</a></cfif> or the <a href="program_list.cfm?division_select=">Award Program List</a> without making changes.</span>
<br /><br />
</cfoutput>

<cfquery name="ToBeEdited" datasource="#application.DS#">
	SELECT has_welcomepage, welcome_bg, welcome_instructions, welcome_message, welcome_congrats, welcome_button,
		welcome_admin_button, admin_logo, email_form_button, email_form_message, email_form_recipient, additional_content_button,
		additional_content_message, additional_content_button_unapproved, additional_content_message_unapproved,
		show_landing_text, landing_text
	FROM #application.database#.program
	WHERE ID =
	<cfif edit_division> 
		<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
	<cfelse>
		<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfif>
</cfquery>
<cfset has_welcomepage = htmleditformat(ToBeEdited.has_welcomepage)>
<cfset welcome_bg = htmleditformat(ToBeEdited.welcome_bg)>
<cfset welcome_instructions = htmleditformat(ToBeEdited.welcome_instructions)>
<cfset welcome_message = htmleditformat(ToBeEdited.welcome_message)>
<cfset welcome_congrats = htmleditformat(ToBeEdited.welcome_congrats)>
<cfset welcome_button = htmleditformat(ToBeEdited.welcome_button)>
<cfset welcome_admin_button = htmleditformat(ToBeEdited.welcome_admin_button)>
<cfset admin_logo = htmleditformat(ToBeEdited.admin_logo)>
<cfset email_form_button = htmleditformat(ToBeEdited.email_form_button)>
<cfset email_form_message = htmleditformat(ToBeEdited.email_form_message)>
<cfset email_form_recipient = htmleditformat(ToBeEdited.email_form_recipient)>
<cfset show_landing_text = ToBeEdited.show_landing_text>
<cfset landing_text = htmleditformat(ToBeEdited.landing_text)>

<cfif unapproved EQ "">
	<cfset additional_content_button = htmleditformat(ToBeEdited.additional_content_button)>
	<cfset additional_content_message = ToBeEdited.additional_content_message>
<cfelse>
	<cfset additional_content_button = htmleditformat(ToBeEdited.additional_content_button_unapproved)>
	<cfset additional_content_message = ToBeEdited.additional_content_message_unapproved>
</cfif>



<cfoutput>

<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext <cfif edit_division>highlight</cfif>">Welcome Page</td>
	</tr>
					
	<tr class="content">
	<td align="right" valign="top">Has a welcome page?*: </td>
	<td valign="top">
		<select name="has_welcomepage">
			<option value="0"<cfif #has_welcomepage# EQ 0> selected</cfif>>No
			<option value="1"<cfif #has_welcomepage# EQ 1> selected</cfif>>Yes
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Welcome Page Background Image: </td>
	<td valign="top"><input type="text" name="welcome_bg" value="#welcome_bg#" maxlength="64" size="40"> <span class="sub">(Leave blank if no background image.)</span></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Welcome&nbsp;Page&nbsp;Congratulations&nbsp;Image: </td>
	<td valign="top"><input type="text" name="welcome_congrats" ID="welcome_congrats" value="#welcome_congrats#" maxlength="64" size="40"><br>
	<a href="/pics/ITC_Thank-you.gif">view</a> <a href="##" onClick="enterThisImage('ITC_Thank-you.gif','welcome_congrats');return false;">choose</a> thank you<br>
	<a href="/pics/Welcome-congrats.gif">view</a> <a href="##" onClick="enterThisImage('Welcome-congrats.gif','welcome_congrats');return false;">choose</a> congratulations<br>
	<a href="/pics/congrats2.gif">view</a> <a href="##" onClick="enterThisImage('congrats2.gif','welcome_congrats');return false;">choose</a> congratulations 2</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Welcome Page Instructions*: </td>
	<td valign="top"><textarea name="welcome_instructions" cols="50" rows="15">#welcome_instructions#</textarea>
	<!---<input type="hidden" name="welcome_instructions_required" value="Please enter instructions.">---></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Welcome Page Main Message*: </td>
	<td valign="top"><textarea name="welcome_message" cols="50" rows="15">#welcome_message#</textarea><input type="hidden" name="welcome_message_required" value="Please enter a welcome message."></td>
	</tr>
				
<!--- do a search for this program's program images --->
<cfquery name="SelectImageNames" datasource="#application.DS#">
	SELECT i.imagename, i.admin_title
	FROM #application.database#.image_content i
	JOIN #application.database#.xref_image_program x ON i.ID = x.image_ID
	WHERE x.program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
</cfquery>

				
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6">  This is the button that takes the user to the products.</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Welcome Page Button Text*: </td>
	<td valign="top"><input type="text" name="welcome_button" value="#welcome_button#" maxlength="30" size="40"> <span class="sub">&lt;br&gt; OK</span>
	<!---<input type="hidden" name="welcome_button_required" value="Please enter welcome button text.">---></td>
	</tr>
				
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6">  This button takes the user to a branded version of the admin login using the admin logo (max 140px wide) in the field below.  If you do not want this button on the welcome page, leave the Admin Button Text field blank.</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Admin Button Text: </td>
	<td valign="top"><input type="text" name="welcome_admin_button" value="#welcome_admin_button#" maxlength="30" size="40"> <span class="sub">&lt;br&gt; OK</span></td>
	</tr>
				
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="bottom"><img src="../pics/contrls-desc.gif" width="7" height="6"> The maximum width for the admin logo is 150px wide.</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Admin Logo: </td>
	<td valign="top"><input type="text" name="admin_logo" value="#admin_logo#" maxlength="40" size="40"></td>
	</tr>
												
	<tr class="content">
	<td align="right" valign="top">Email Form Button Text: </td>
	<td valign="top"><input type="text" name="email_form_button" value="#email_form_button#" maxlength="30" size="40"> <span class="sub">&lt;br&gt; OK</span></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Email Form Message:<br><span class="sub">(displays above email form)</span></td>
	<td valign="top"><textarea name="email_form_message" cols="50" rows="15">#email_form_message#</textarea></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Email Form Recipient(s): </td>
	<td valign="top"><input type="text" name="email_form_recipient" value="#email_form_recipient#" maxlength="255" size="40"><br><span class="sub">Separate multiple emails with commas and NO SPACES.</span></td>
	</tr>
	
	<cfif unapproved NEQ "">
	
	<tr class="content">
	<td valign="top" colspan="2"><span class="alert">Below is Unapproved Additional Content.</span>  When you click "Save" the text below (with your edits) will become the current Additional Content.</td>
	</tr>

	</cfif>
												
	<tr class="content">
	<td align="right" valign="top">Additional Content Button Text: </td>
	<td valign="top"><input type="text" name="additional_content_button" value="#additional_content_button#" maxlength="30" size="40"> <span class="sub">&lt;br&gt; OK</span></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Additional Content Message:</td>
	<td valign="top"><textarea name="additional_content_message" cols="50" rows="15">#additional_content_message#</textarea></td>
	</tr>
												
	<tr class="content">
	<td align="right" valign="top">Show All Products at Login? </td>
	<td valign="top">
		<select name="show_landing_text">
			<option value="0"<cfif show_landing_text EQ 0> selected</cfif>>Yes
			<option value="1"<cfif show_landing_text EQ 1> selected</cfif>>No
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">If not showing ALL products:</td>
	<td valign="top"><textarea name="landing_text" cols="50" rows="15">#landing_text#</textarea></td>
	</tr>
												
	<tr class="content">
	<td colspan="2" align="center">
		
	<input type="hidden" name="unapproved" value="#unapproved#">
			
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