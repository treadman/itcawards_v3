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
<cfparam name="logo" default="">
<cfparam name="cross_color" default="">
<cfparam name="text_active" default="FFFFFF">
<cfparam name="bg_active" default="FF6600">
<cfparam name="bg_warning" default="FFFF00">
<cfparam name="text_selected" default="FFFFFF">
<cfparam name="bg_selected" default="888888">
<cfparam name="login_prompt" default="Certificate Number">
<cfparam  name="display_welcomeyourname" default="0">
<cfparam  name="display_youhavexcredits" default="0">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfquery name="UpdateQuery" datasource="#application.DS#">
		UPDATE #application.database#.program
		SET logo = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#logo#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(logo)))#">,
			cross_color = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cross_color#" maxlength="6" null="#YesNoFormat(NOT Len(Trim(cross_color)))#">,
			text_active = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text_active#" maxlength="6">,
			bg_active = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bg_active#" maxlength="6">,
			text_selected = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text_selected#" maxlength="6">,
			bg_selected = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bg_selected#" maxlength="6">,
			login_prompt = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#login_prompt#" maxlength="120">,
			display_welcomeyourname = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#display_welcomeyourname#" maxlength="1">,
			display_youhavexcredits = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#display_youhavexcredits#" maxlength="1">,
			bg_warning = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bg_warning#" maxlength="6">
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
<cfinclude template="includes/header.cfm">

<script language="javascript">
function enterThisImage(image)
{
	document.getElementById('logo').value = image
}
</script>

<cfoutput>
<span class="pagetitle">
	Edit
	<cfif edit_division>
		<span class="highlight">General Display Settings for #request.division_name#</span> a division of
	<cfelse>
		General Display Settings for
	</cfif>
	#request.program_name#
</span>
<br /><br />
<span class="pageinstructions">Return to the <a href="program_details.cfm"><cfif edit_division>Division<cfelse>Award Program</cfif> Details</a><cfif edit_division> or the <a href="program_details.cfm?division_select=">Parent Program Details</a></cfif> or the <a href="program_list.cfm?division_select=">Award Program List</a> without making changes.</span>
<br /><br />
</cfoutput>

<cfquery name="ToBeEdited" datasource="#application.DS#">
	SELECT login_prompt, display_welcomeyourname, display_youhavexcredits, text_active, bg_active, text_selected, bg_selected, logo, cross_color, bg_warning 
	FROM #application.database#.program
	WHERE ID =
	<cfif edit_division> 
		<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
	<cfelse>
		<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfif>
</cfquery>
<cfset logo = htmleditformat(ToBeEdited.logo)>
<cfset cross_color = htmleditformat(ToBeEdited.cross_color)>
<cfset text_active = htmleditformat(ToBeEdited.text_active)>
<cfset bg_active = htmleditformat(ToBeEdited.bg_active)>
<cfset bg_warning = htmleditformat(ToBeEdited.bg_warning)>
<cfset text_selected = htmleditformat(ToBeEdited.text_selected)>
<cfset bg_selected = htmleditformat(ToBeEdited.bg_selected)>
<cfset login_prompt = htmleditformat(ToBeEdited.login_prompt)>
<cfset display_welcomeyourname = htmleditformat(ToBeEdited.display_welcomeyourname)>
<cfset display_youhavexcredits = htmleditformat(ToBeEdited.display_youhavexcredits)>

<cfoutput>

<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext <cfif edit_division>highlight</cfif>">General Display Settings</td>
	</tr>
					
	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Program Logo name (250 X 250): </td>
	<td valign="top"><input type="text" name="logo" id="logo" value="#logo#" maxlength="32" size="40">
 <cfif logo  NEQ "">
	<table width="100%">
	
	<tr>
	<td align="right" valign="top">Current:</td>
	<td>&nbsp;&nbsp;&nbsp;<a href="../pics/program/#logo#" target="_blank">view</a>&nbsp;&nbsp;&nbsp;<a href="##" onClick="enterThisImage('#logo#')">choose</a>&nbsp;&nbsp;&nbsp;#logo#</td>
	</tr>
</cfif>

<!--- do a search for this program's program images --->
<cfquery name="SelectImageNames" datasource="#application.DS#">
	SELECT i.imagename, i.admin_title
	FROM #application.database#.image_content i
	JOIN #application.database#.xref_image_program x ON i.ID = x.image_ID
	WHERE x.program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
</cfquery>

<!--- if has some, display a list of them here with "use this logo" js link next to it --->

<cfif SelectImageNames.RecordCount GTE 1>
<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td align="right" valign="top">Available:</td>
	<td>
		<cfloop query="SelectImageNames">
		&nbsp;&nbsp;&nbsp;<a href="/pics/uploaded_images/#imagename#" target="_blank">view</a>&nbsp;&nbsp;&nbsp;<a href="##" onClick="enterThisImage('#imagename#');return false;">choose</a>&nbsp;&nbsp;&nbsp;#imagename# - #admin_title#<br>
		</cfloop>
	</td>
	</tr>
	
</cfif>

 <cfif logo  NEQ "">
	</table>
</cfif>


</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Cross color: </td>
	<td valign="top"><input type="text" name="cross_color" value="#cross_color#" maxlength="6" size="40">&nbsp;<cfif cross_color NEQ "">&nbsp;<img src="../pics/shim.gif" style="background-color:###cross_color#" width="15" height="10">&nbsp;&nbsp;</cfif><span class="sub">(Leave blank for no cross.)</span></td>
	</tr>

	<tr class="content2">
	<td align="center" valign="top">&nbsp;</td>
	<td valign="bottom"> 
		<table cellpadding="4" cellspacing="0" border="0">
		<tr>
		<td width="250"><img src="../pics/contrls-desc.gif" width="7" height="6"> Used for active buttons and headers.</td>
		<td align="center" width="8">&nbsp;</td>
		<td align="center" width="130" style="background-color:###bg_active#;color:###text_active#;font-weight:bold">Active&nbsp;Colors</td>
		</tr>
		</table>
	</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">ACTIVE Background Color*: </td>
	<td valign="top"><input type="text" name="bg_active" value="#bg_active#" maxlength="6" size="40">
	<input type="hidden" name="bg_active_required" value="Please enter an active background color."> <span class="sub">Do not make this white.</span></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">ACTIVE Text Color*: </td>
	<td valign="top"><input type="text" name="text_active" value="#text_active#" maxlength="6" size="40">
	<input type="hidden" name="text_active_required" value="Please enter an active text color."></td>
	</tr>
				
	<tr class="content2">
	<td align="center" valign="top">&nbsp;</td>
	<td valign="bottom">
		<table cellpadding="4" cellspacing="0" border="0">
		<tr>
		<td width="250"><img src="../pics/contrls-desc.gif" width="7" height="6"> Used for selected buttons and rollovers.</td>
		<td align="center" width="8">&nbsp;</td>
		<td align="center" width="130" style="background-color:###bg_selected#;color:###text_selected#;font-weight:bold">Selected&nbsp;Colors</td>
		</tr>
		</table>

	</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">SELECTED Background Color*: </td>
	<td valign="top"><input type="text" name="bg_selected" value="#bg_selected#" maxlength="6" size="40">
	<input type="hidden" name="bg_selected_required" value="Please enter a selected background color."> <span class="sub">Do not make this white.</span></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">SELECTED Text Color*: </td>
	<td valign="top"><input type="text" name="text_selected" value="#text_selected#" maxlength="6" size="40">
	<input type="hidden" name="text_selected_required" value="Please enter a selected text color."></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">WARNING Text Color*: </td>
	<td valign="top"><input type="text" name="bg_warning" value="#bg_warning#" maxlength="6" size="40">
	<input type="hidden" name="bg_warning_required" value="Please enter a warning text color."> <span class="sub">Do not make this white.</span></td>
	</tr>

	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="bottom"><img src="../pics/contrls-desc.gif" width="7" height="6"> Indicate whether you want to display the "Welcome Your Name" and/or "You have XX credits" messages to display on the welcome page and main page.</span> The word &quot;credits&quot; will be replaced with the credit description you entered above. </td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Login Prompt*: </td>
	<td valign="top"><input type="text" name="login_prompt" value="#login_prompt#" maxlength="120" size="40">
	<input type="hidden" name="login_prompt_required" value="Please enter a login prompt."></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Display "Welcome Your Name"</td>
	<td valign="top">
		<select name="display_welcomeyourname">
			<option value="0"<cfif #display_welcomeyourname# EQ 0> selected</cfif>>No
			<option value="1"<cfif #display_welcomeyourname# EQ 1> selected</cfif>>Yes
		</select>
	</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Display "You have XX credits."</td>
	<td valign="top">
		<select name="display_youhavexcredits">
			<option value="0"<cfif #display_youhavexcredits# EQ 0> selected</cfif>>No
			<option value="1"<cfif #display_youhavexcredits# EQ 1> selected</cfif>>Yes
		</select>
	</td>
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