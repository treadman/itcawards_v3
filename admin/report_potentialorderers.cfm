<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<!--- ************************************ --->
<!--- get report info                      --->
<!--- ************************************ --->

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfset has_program = false>
</cfif>
<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset page_title = "Potential Order Makers">
<cfinclude template="includes/header_lite.cfm">

<cfif NOT has_program>
	<br><br>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="alert">Error:  No program selected.</span>
	<br><br>
<cfelse>

	<!--- total user for this program --->
	<cfquery name="AllUsers" datasource="#application.DS#">
		SELECT username, IFNULL(fname,"&nbsp;") AS fname, IFNULL(lname,"&nbsp;") AS lname, IFNULL(email,"&nbsp;") AS email, ID AS user_ID
		FROM #application.database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		<cfif request.program.is_one_item GT 0>
			AND is_done = 0
		</cfif>
		ORDER BY lname, fname
	</cfquery>

	<table cellpadding="5" cellspacing="0" border="1" width="90%" align="center">
	
			<tr>
			<td colspan="4" class="printlabel">I T C&nbsp;&nbsp;&nbsp;A W A R D S&nbsp;&nbsp;&nbsp;-&nbsp;&nbsp;&nbsp;
P O T E N T I A L&nbsp;&nbsp;&nbsp;O R D E R&nbsp;&nbsp;&nbsp;M A K E R S</td>
			</tr>
			
		<cfoutput>
		
			<tr class="printlabel">
			<td valign="top" class="printlabel" colspan="4" >Program: #request.program_name#</td>
			</tr>
			
			<tr>
			<td colspan="4" class="printbold">&nbsp;</td>
			</tr>
			
			<tr>
			<cfif request.program.is_one_item eq 0><td class="printtext"><b>Points</b></td></cfif>
			<td class="printtext"><b>Userame</b></td>
			<td class="printtext"><b>Name</b></td>
			<td class="printtext"><b>Email</b></td>
			</tr>
			
		<cfset user_totalpoints = 0>
		<cfloop query="AllUsers">
		
			<cfif request.program.is_one_item eq 0>
				<cfset ProgramUserInfo(user_ID)>
			</cfif>
			
			<cfif user_totalpoints NEQ 0 OR request.program.is_one_item GT 0>
			
			<tr>
			<cfif request.program.is_one_item eq 0><td class="printtext">#user_totalpoints#</td></cfif>
			<td class="printtext">#username#</td>
			<td class="printtext">#fname# #lname#</td>
			<td class="printtext">#email#</td>
			</tr>
			
			</cfif>
			
		</cfloop>
			
		</cfoutput>

		
	</table>
</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->