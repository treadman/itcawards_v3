<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000065,true)>

<!--- param a/e form fields --->
<cfparam name="meta_conf_email_text" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfquery name="UpdateQuery" datasource="#application.DS#">
		UPDATE #application.database#.program_meta
		SET	meta_conf_email_text = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.meta_conf_email_text#" null="#YesNoFormat(NOT Len(Trim(meta_conf_email_text)))#">
	</cfquery>
	<cfset alert_msg = Application.DefaultSaveMessage>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "meta_program">
<cfinclude template="includes/header.cfm">

<cfquery name="SelectInfo" datasource="#application.DS#">
	SELECT meta_conf_email_text
	FROM #application.database#.program_meta
</cfquery>
<cfset meta_conf_email_text = HTMLEditFormat(SelectInfo.meta_conf_email_text)>
	
<span class="pagetitle">Program Meta Information</span>
<br /><br />

<cfoutput>

<form method="post" action="#CurrentPage#">


	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext">Program Meta Information</td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Order Confirmation Email Text: </td>
	<td valign="top"><textarea name="meta_conf_email_text" rows="10" cols="50">#meta_conf_email_text#</textarea></td>
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