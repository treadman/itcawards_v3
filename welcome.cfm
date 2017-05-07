<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<cfparam name="DisplayMode" default="Welcome">

<cfinclude template="includes/header.cfm">

<script language="javascript">
function openCertificate() {
	 winAttributes = 'width=600, top=1, resizable=yes, scrollbars=yes, status=yes, titlebar=yes'
	 winPath = '<cfoutput>#application.WebPath#award_certificate/#users_username#_certificate_#program_ID#.pdf</cfoutput>'
	 window.open(winPath,'Certificate',winAttributes);
}
</script>
<cfif display_message NEQ ""><cfoutput>#display_message#</cfoutput><br><br><br></cfif>
<cfif welcome_bg NEQ ""><div align="center"><img src="<cfoutput>#welcome_bg#</cfoutput>"></div></cfif>
<cfif DisplayMode EQ "Welcome">
	<span class="welcome"><cfoutput>#Replace(welcome_message,chr(10),"<br>","ALL")#</cfoutput></span>
</cfif>

<cfif has_divisions AND show_divisions>
	<br><br>
	<div align="center">
	<cfoutput query="GetDivisions">
		<span class="active_button welcome_button" onmouseover="mOver(this,'selected_button welcome_button');" onmouseout="mOut(this,'active_button welcome_button');" onclick="window.location='welcome.cfm?div=#GetDivisions.ID#'">#GetDivisions.welcome_button#</span>
	</cfoutput>
	</div>
</cfif>

<cfinclude template="includes/footer.cfm">
