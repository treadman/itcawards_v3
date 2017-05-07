<cfif FileExists(application.AbsPath & "award_certificate/" & users_username & "_certificate_" & program_ID & ".pdf")>
	<script>
	function openCertificate() {
		winAttributes = 'width=600, top=1, resizable=yes, scrollbars=yes, status=yes, titlebar=yes'
		winPath = '<cfoutput>#application.WebPath#award_certificate/#users_username#_certificate_#program_ID#.pdf</cfoutput>'
		window.open(winPath,'Certificate',winAttributes);
	}
	</script>
	<tr><td>&nbsp;</td></tr>
	<tr>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="openCertificate()">View Certificate</td>
	</tr>
</cfif>

<cfif additional_content_button NEQ "">
	<tr><td>&nbsp;</td></tr>
	<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='additional_content.cfm'"><cfoutput>#additional_content_button#</cfoutput></td></tr>
</cfif>

<cfif help_button NEQ "">
	<tr><td>&nbsp;</td></tr>
	<tr>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="openHelp()"><cfoutput>#help_button#</cfoutput></td>
	</tr>
</cfif>

<cfif isBoolean(can_defer) AND can_defer>
	<tr><td>&nbsp;</td></tr>
	<tr>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='<cfoutput>main_login.cfm?defer=yes&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#</cfoutput>'">Deferral Options</td>
	</tr>
</cfif>
