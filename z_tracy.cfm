<cfabort showerror="Look before you leap!!!!">
<cfquery name="GetUsers" datasource="#application.DS#">
	SELECT
		w3.ID, w3.username as w3_username, w3.badge_id,
		w3.fname as w3_fname, w3.lname as w3_lname, w3.email as w3_email,

		w2.username as w2_username,
		w2.fname as w2_fname, w2.lname as w2_lname, w2.email as w2_email

	FROM #application.database#.program_user w3
	LEFT JOIN ITCAwards.program_user w2 ON w2.username = w3.username OR w2.username = w3.badge_id
	where w3.program_id = 1000000100
	and w2.program_id = 1000000035
</cfquery>
<cfoutput>
<!---The following merges have different supervisors:--->
<table>
<cfloop query="GetUsers">
	<cfif trim(w3_email) EQ '' AND trim(w2_email) NEQ ''> 
	<tr>
		<td>W2</td><td>#GetUsers.w2_username#</td><td>#GetUsers.w2_fname# #GetUsers.w2_lname#</td><td>#GetUsers.w2_email#</td>
	</tr>
	<tr>
		<td>#GetUsers.ID#</td><td>#GetUsers.w3_username#</td><td>#GetUsers.w3_fname# #GetUsers.w3_lname#</td><td>#GetUsers.w3_email#</td>
	</tr>
	<tr>
		<td>&nbsp;</td>
	</tr>
	<!---<cfquery name="UpdateUsers" datasource="#application.DS#">
		UPDATE ITCAwards_v3.program_user
		SET email = '#GetUsers.w2_email#'
		WHERE ID = #GetUsers.ID#
	</cfquery>--->
	</cfif>
</cfloop>
</table>
</cfoutput>


<!---

	<cfif FileExists("/inetpub/wwwroot/content/htdocs/itcawards_v3/award_certificate/" & username & "_certificate_1000000100" & ".pdf")>
		<cfset w3_user = true>
	</cfif>
	<cfif FileExists("/inetpub/wwwroot/content/htdocs/itcawards_v2/award_certificate/" & username & "_certificate_1000000035" & ".pdf")>
		<cfset w2_user = true>
	</cfif>
	<cfif FileExists("/inetpub/wwwroot/content/htdocs/itcawards_v2/award_certificate/" & badge_id & "_certificate_1000000035" & ".pdf")>
		<cfset w2_exists_badge = true>
	</cfif>
	<cfif FileExists("/inetpub/wwwroot/content/htdocs/itcawards_v3/award_certificate/" & badge_id & "_certificate_1000000100" & ".pdf")>
		<cfset w2_badge = true>
	</cfif>
	<cfif w3_badge>
		<cfabort>
		----#username# / #badge_id#----<br>
		w3 by badge!<br />
	</cfif>
	<cfif w3_user>
		<cfif w2_user OR w2_badge>
			<cfabort>
			----#username# / #badge_id#----<br>
			w2 username: #username#<br />
			w2 badge id: #badge_id#<br />
			In both<br />
		</cfif>
	</cfif>
	<cfif w2_user AND w2_badge>
		----#username# / #badge_id#----<br>
		Has both<br />
	</cfif>
	<cfif w2_user>
		#username#<br>
		<cfset FileCopy(
			"/inetpub/wwwroot/content/htdocs/itcawards_v2/award_certificate/" & username & "_certificate_1000000035" & ".pdf",
			"/inetpub/wwwroot/content/htdocs/itcawards_v3/award_certificate/" & username & "_certificate_1000000100" & ".pdf"
		)>
	</cfif>
	<cfif w2_badge>
		/ #badge_id#<br>
		<cfabort>
		<!---<cfset FileCopy(
			"/inetpub/wwwroot/content/htdocs/itcawards_v2/award_certificate/" & badge_id & "_certificate_1000000035" & ".pdf",
			"/inetpub/wwwroot/content/htdocs/itcawards_v3/award_certificate/" & username & "_certificate_1000000100" & ".pdf"
		)>--->
	</cfif>
</cfloop>
</cfoutput>


<cfset UploadType="points">

<cffile action="read" variable="thisData" file="#application.FilePath#/itg.csv">
<cfset thisData = Replace(thisData,"#CHR(13)##CHR(10)#","|","ALL")>

<cfset firstLine = true>
<cfset dupes = "">
<cfset already = "">
<cfset found = "">
<cfset notfound = "">
<cfset count = 1>

<cfset division = 1000000111>

<cfloop list="#thisData#" index="thisLine" delimiters="|">
	<cfif NOT firstLine>

		<cfswitch expression="#UploadType#">
		<cfcase value="points">
			<cfif ListLen(thisLine) NEQ 4>
				<cfabort showerror="#thisLine# is not 4 columns">
			</cfif>
			<cfset empID = Replace(ListGetAt(thisLine,1),'^','','ALL')>
			<cfset firstname = Replace(ListGetAt(thisLine,2),'^','','ALL')>
			<cfset lastname = Replace(ListGetAt(thisLine,3),'^','','ALL')>
			<cfset points = Replace(ListGetAt(thisLine,4),'^','','ALL')>
			<cfset numID = empID * 1>
			<cfoutput>#count#) #numID# / #empID# - #firstname# #lastname#<br></cfoutput>
			<cfset count = count + 1>
			<cfquery name="GetUser" datasource="#application.DS#">
				SELECT ID, username, fname, lname, CAST(username AS decimal(6,0)) AS empID
				FROM #application.database#.program_user
				WHERE fname = '#firstname#' AND (lname = '#lastname#' OR lname = '#lastname# JR')
				AND CAST(username AS decimal(6,0)) = #numID#
			</cfquery>
		
			<cfif GetUser.recordcount EQ 0>
				<cfset notfound = ListAppend(notfound,"#numID#|#firstname#|#lastname#")>
			<cfelseif GetUser.recordcount GT 1>
				<cfset already = ListAppend(already,"#numID#|#firstname#|#lastname#")>
			<cfelse>				
				<cfif NOT ListFind(found,"#numID#|#firstname#|#lastname#")>
					<cfset found = ListAppend(found,"#numID#|#firstname#|#lastname#")>
					<cfquery name="InsertPoints" datasource="#application.DS#" result="result">
						INSERT INTO #application.database#.awards_points
							(created_user_ID, created_datetime, user_ID, points,division_ID)
						VALUES (
							<cfqueryparam cfsqltype="cf_sql_integer" value="1212121212" maxlength="10">,
							'#FLGen_DateTimeToMySQL()#', 
							<cfqueryparam cfsqltype="cf_sql_integer" value="#GetUser.ID#" maxlength="10">, 
							<cfqueryparam cfsqltype="cf_sql_integer" value="#points#" maxlength="10">,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#division#" maxlength="10">
							)
					</cfquery>
					<cfset pointsID = result.GENERATED_KEY>
				<cfelse>
					<cfset dupes = ListAppend(dupes,"#firstname#|#lastname#")>
				</cfif>
			</cfif>
		</cfcase>

		<!---<cfcase value="users">
			<cfif ListLen(thisLine) NEQ 9>
				<cfabort showerror="#thisLine# is not 9 columns">
			</cfif>
			<cfset empID = Replace(ListGetAt(thisLine,1),'^','','ALL')>
			<cfset lastname = Replace(ListGetAt(thisLine,2),'^','','ALL')>
			<cfset firstname = Replace(ListGetAt(thisLine,3),'^','','ALL')>
			<cfset middlename = Replace(ListGetAt(thisLine,4),'^','','ALL')>
			<cfset address1 = Replace(ListGetAt(thisLine,5),'^','','ALL')>
			<cfset address2 = Replace(ListGetAt(thisLine,6),'^','','ALL')>
			<cfset city = Replace(ListGetAt(thisLine,7),'^','','ALL')>
			<cfset state = Replace(ListGetAt(thisLine,8),'^','','ALL')>
			<cfset zip = Replace(ListGetAt(thisLine,9),'^','','ALL')>
			<cfif NOT ListFind(found,empID)>
				<cfset found = ListAppend(found,empID)>
				<cfoutput>#count#) #empID#<br></cfoutput>
				<cfset count = count + 1>
				<cfquery name="InsertUser" datasource="#application.DS#" result="result">
					INSERT INTO #application.database#.program_user
						(created_user_ID, created_datetime, program_ID, username, fname, lname)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="1212121212" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="cf_sql_integer" value="1000000100" maxlength="10">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#empID#" maxlength="128">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#firstname#" maxlength="30">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lastname#" maxlength="30"> 
						)
				</cfquery>
				<cfset userID = result.GENERATED_KEY>
				<cfquery name="InsertAddress" datasource="#application.DS#">
					INSERT INTO #application.database#.program_user_address
						(program_user_ID, address1, address2, city, state, zip)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#userID#" maxlength="10">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#address1#" maxlength="64">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(address2)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#city#" maxlength="30">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#zip#"> 
					)
				</cfquery>
			<cfelse>
				<cfset dupes = ListAppend(dupes,empID)>
			</cfif>
		</cfcase>--->
		</cfswitch>
	</cfif>
	<cfset firstLine = false>
</cfloop>
<br><br>
Already in System:<br>
<cfoutput>#already#<br></cfoutput>
<!---<cfloop list="#thisData#" index="thisLine" delimiters="|">
	<cfset numID = -1>
	<cftry><cfset numID = Replace(ListGetAt(thisLine,1),'^','','ALL') * 1><cfcatch></cfcatch></cftry>
	<cfswitch expression="#UploadType#">
	<cfcase value="points">
		<cfset empID = numID&"|"&ListGetAt(thisLine,2)&"|"&ListGetAt(thisLine,3)>
		<cfif ListFind(already,empID)>
			<cfoutput>#Replace(thisLine,'^','','ALL')#</cfoutput><br>
		</cfif>
	</cfcase>
	<cfcase value="users">
		<cfset empID = ListGetAt(thisLine,1)>
		<cfif ListFind(already,empID)>
			<cfoutput>#Replace(thisLine,'^','','ALL')#</cfoutput><br>
		</cfif>
	</cfcase>
	</cfswitch>
</cfloop>--->
<br><br>
Dupes:<br>
<cfoutput>#dupes#<br></cfoutput>
<!---<cfloop list="#thisData#" index="thisLine" delimiters="|">
	<cfswitch expression="#UploadType#">
	<cfcase value="points">
		<cfset empID = numID&"|"&ListGetAt(thisLine,2)&"|"&ListGetAt(thisLine,3)>
		<cfif ListFind(dupes,empID)>
			<cfoutput>#Replace(thisLine,'^','','ALL')#</cfoutput><br>
		</cfif>
	</cfcase>
	<cfcase value="users">
		<cfset empID = ListGetAt(thisLine,1)>
		<cfif ListFind(dupes,empID)>
			<cfoutput>#Replace(thisLine,'^','','ALL')#</cfoutput><br>
		</cfif>
	</cfcase>
	</cfswitch>
</cfloop>--->
<br><br>
Not Found:<br>
<cfloop list="#thisData#" index="thisLine" delimiters="|">
	<cfset numID = -1>
	<cftry><cfset numID = Replace(ListGetAt(thisLine,1),'^','','ALL') * 1><cfcatch></cfcatch></cftry>
	<cfswitch expression="#UploadType#">
	<cfcase value="points">
		<cfset empID = numID&"|"&ListGetAt(thisLine,2)&"|"&ListGetAt(thisLine,3)>
		<cfif ListFind(notfound,empID)>
			<cfoutput>#Replace(thisLine,'^','','ALL')#</cfoutput><br>
		</cfif>
	</cfcase>
	<cfcase value="users">
		<cfset empID = ListGetAt(thisLine,1)>
		<cfif ListFind(notfound,empID)>
			<cfoutput>#Replace(thisLine,'^','','ALL')#</cfoutput><br>
		</cfif>
	</cfcase>
	</cfswitch>
</cfloop>
--->
<br><br>
Done!