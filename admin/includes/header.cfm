<cfparam name="alert_msg" default="">
<cfparam name="alert_error" default="">
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>ITC Award Programs Administration</title>

<link href="../includes/admin_style.css" rel="stylesheet" type="text/css">
<cfif alert_msg NEQ "">
	<script src="../includes/alert.js"></script>
</cfif>

</head>

<body leftmargin="0" topmargin="0" marginheight="0" marginwidth="0" <cfif alert_msg NEQ "" OR alert_error NEQ "">onLoad='<cfif alert_msg NEQ "">DisplayAlert("AlertBox",350,200); doTimer();</cfif><cfif alert_error NEQ "">alert("<cfoutput>#alert_error#</cfoutput>");</cfif>'</cfif>>

<cfinclude template="../../includes/environment.cfm"> 

<cfoutput>
<div class="pageheader">
	<div class="pageheadleft">
		A W A R D&nbsp;&nbsp;&nbsp;P R O G R A M S&nbsp;&nbsp;&nbsp;A D M I N I S T R A T I O N
	</div>
	<div class="pageheadright">
		<cfif FLGen_AuthenticateAdmin()>
			<cfif isDefined("cookie.admin_name") AND cookie.admin_name EQ "Tracy">
				<span class="loginname">Hello #cookie.admin_name#!</span> &nbsp;&nbsp;&nbsp;
			</cfif>
			<a href="logout.cfm" class="logout">Logout</a>
		</cfif>
	</div>
	<!--- --------------------------------------- --->
	<!--- ------ Program Selector --------------- --->
	<!--- --------------------------------------- --->
	<cfif isDefined("request.is_admin") AND request.is_admin>
		<cfquery name="GetProgramNames" datasource="#application.DS#">
			SELECT ID, company_name, program_name, is_active
			FROM #application.database#.program
			WHERE parent_ID = 0
			ORDER BY is_active desc, company_name, program_name
		</cfquery>
		<div class="pageheader2">
			<cfoutput>
			<form action="program_select.cfm" method="post" name="ProgramSelect">
				<input type="hidden" name="ReturnTo" value="#CurrentPage#" />
				<select name="Program" onChange="ProgramSelect.submit();">
					<option value="">#application.AdminName# Admin (All programs)</option>
					<cfset actives = true>
					<cfloop query="GetProgramNames">
						<cfif actives and NOT GetProgramNames.is_active>
							<cfset actives = false>
							<option disabled="true" value="" style="text-align:right; font-weight:bold;">Inactive programs:</option>
						</cfif>
						<option value="#GetProgramNames.ID#"<cfif GetProgramNames.ID EQ request.selected_program_ID> selected</cfif>>#GetProgramNames.company_name# [#GetProgramNames.program_name#]</option>
					</cfloop>
				</select>
			</form>
			</cfoutput>
		</div>
	</cfif>
</div>
</cfoutput>

<cfif isDefined("leftnavon")>
	<cfparam name="request.main_width" default="1100">
	<table cellpadding="5" cellspacing="0" width="<cfoutput>#request.main_width#</cfoutput>" border="0">
		<tr>
			<td valign="top" width="185" class="leftnav"><cfinclude template="leftnav.cfm"></td>
			<td valign="top" width="10">&nbsp;</td>
			<td valign="top" width="<cfoutput>#request.main_width - 195#</cfoutput>"><br />
</cfif>
<cfif alert_msg NEQ "">
	<div id="AlertBox" class="alertBoxClass">
		<cfoutput>#alert_msg#</cfoutput>
		<form style="text-align:right">
			<input type="button" value="OK" style="width:75px;" onclick="document.getElementById('AlertBox').style.display='none'">
		</form>
	</div>
</cfif>

<!-- ------------- --->
<!-- End of header --->
<!-- ------------- --->
