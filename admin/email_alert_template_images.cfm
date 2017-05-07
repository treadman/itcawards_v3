<!--- find program logos and admin logos --->
<cfquery name="FindProgramLogos" datasource="#application.DS#">
	SELECT company_name, program_name, logo, admin_logo
	FROM #application.database#.program
	WHERE parent_ID = 0
	ORDER BY company_name, program_name ASC 
</cfquery>
<!--- find all images in the pics/email_alerts folder --->
<cfdirectory action="list" directory="#application.AbsPath#pics/email_alerts" name="AlertImages" sort="Name ASC">

<cfinclude template="includes/header_lite.cfm">

<!--- display everything --->
Available Images for Email Alerts
<br /><br />
<table cellpadding="4" cellspacing="3">
<cfoutput query="FindProgramLogos">
	<cfif logo NEQ "">
		<tr bgcolor="##dddddd">
		<td><img src="../pics/program/#logo#" /><br />
		<span style="color:##777777">#company_name# [#program_name#] logo</span><br />
		&lt;img src="#application.SecureWebPath#/pics/program/#logo#"&gt;
		</td>
		</tr>
	</cfif>
	<cfif admin_logo NEQ "">
		<tr bgcolor="##dddddd">
		<td><img src="../pics/program/#logo#" /><br />
		<span style="color:##777777">#company_name# [#program_name#] admin logo</span><br />
		&lt;img src="#application.SecureWebPath#/pics/program/#admin_logo#"&gt;
		</td>
		</tr>
	</cfif>
</cfoutput>
<tr bgcolor="#aaaaaa">
<td>Email Alert Images<br />
To make images available on this page, send to Lou Mene for upload.
</td>
</tr>
<cfoutput query="AlertImages">
	<tr bgcolor="##dddddd">
	<td><img src="../pics/email_alerts/#Name#" /><br />
	&lt;img src="#application.SecureWebPath#/pics/email_alerts/#Name#"&gt;</td>
	</tr>
</cfoutput>
</table>
<cfinclude template="includes/footer.cfm">
