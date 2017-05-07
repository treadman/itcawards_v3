<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<cfinclude template="includes/header.cfm">

	<cfif trim(chooser_text) NEQ "">
		<cfoutput>#chooser_text#</cfoutput>
	</cfif>
<table cellpadding="8" cellspacing="1" border="0">
	<tr>
		<td width="100px;"></td>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='login.cfm';">  Login  </td>
		<td width="100px;"></td>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='register.cfm';">  Register  </td>
	</tr>
</table>

<cfinclude template="includes/footer.cfm">
