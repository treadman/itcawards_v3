<!---
Branched from:  www2.itcawards.com/lorillard_update.cfm
--->

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<cfif NOT has_program>
	<span class="pagetitle">Program Users</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<cfset errors1 = "">
<cfset errors2 = "">
<cfset errors3 = "">
<cfset errors4 = "">
<cfset errors5 = "">
<cffile action="read" variable="thisData" file="#application.FilePath#/admin/upload/supervisor_updates.csv">
<cfset thisData = Replace(thisData,"#CHR(13)##CHR(10)#","|","ALL")>
<cfset firstLine = true>
<cfloop list="#thisData#" index="thisLine" delimiters="|">
	<cfif NOT firstLine>
		<cfset colNum = 1>
		<cfset EmptyLine = true>
		<cfset thisCol = "">
		<cfset thisLine = Replace(Replace(thisLine,', JR',''),'"','','ALL')>
		<cfloop from="1" to="#len(trim(thisLine))#" index="x">
			<cfset thisChar = mid(trim(thisLine),x,1)>
			<cfif thisChar EQ "," OR x EQ len(trim(thisLine))>
				<cfif x EQ len(trim(thisLine))>
					<cfif thisChar NEQ ",">
						<cfset thisCol = thisCol & thisChar>
					</cfif>
				</cfif>
				<cfif colNum EQ 2 AND thisCol NEQ "">
					<cfset TopSuper = thisCol>
					<cfset EmptyLine = false>
				</cfif>
				<cfif colNum EQ 4 AND thisCol NEQ "">
					<cfset MidSuper = thisCol>
					<cfset EmptyLine = false>
				</cfif>
				<cfif colNum EQ 6 AND thisCol NEQ "">
					<cfset Manager = thisCol>
					<cfset EmptyLine = false>
				</cfif>
				<cfset thisCol = "">
				<cfset colNum = colNum + 1>
			<cfelse>
				<cfif thisChar NEQ "," AND thisChar NEQ "`">
					<cfset thisCol = thisCol & thisChar>
				</cfif>
			</cfif>
		</cfloop>
		<cfif NOT EmptyLine>
			<cfoutput>#TopSuper#,#MidSuper#,#Manager#</cfoutput><br>
			<cftry>
			<cfset TSFirst = trim(ListGetAt(TopSuper,1," "))>
			<cfset TSLast = trim(ListGetAt(TopSuper,2," "))>
			<cfquery name="GetTopSuper" datasource="#application.ds#">
				SELECT ID, fname,lname,email
				FROM #application.database#.program_user
				WHERE LEFT(fname,#len(TSFirst)#) = '#TSFirst#'
				AND lname = '#TSLast#'
				AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
				AND is_active = 1
			</cfquery>
			<cfif GetTopSuper.recordcount EQ 1>
				<cfset thisTopSuperEmail = GetTopSuper.email>
				<cfset thisTopSuperID = GetTopSuper.ID>
			<cfelse>
				<cfset thisTopSuperEmail = "">
				<cfset thisTopSuperID = 0>
			</cfif>
			<cfset MSFirst = trim(ListGetAt(MidSuper,1," "))>
			<cfif Len(MSFirst) EQ 2 AND mid(MSFirst,2,1) EQ ".">
				<cfset MSFirst = MSFirst & " " & trim(ListGetAt(MidSuper,2," "))>
				<cfset MSLast = trim(ListGetAt(MidSuper,3," "))>
			<cfelse>
				<cfset MSLast = trim(ListGetAt(MidSuper,2," "))>
			</cfif>
			<cfquery name="GetMidSuper" datasource="#application.ds#">
				SELECT ID,fname,lname,email,supervisor_email
				FROM #application.database#.program_user
				WHERE LEFT(fname,#len(MSFirst)#) = '#MSFirst#'
				AND lname = '#MSLast#'
				AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
				AND is_active = 1
			</cfquery>
			<cfif GetMidSuper.recordcount EQ 1>
				<cfset thisMidSuperID = GetMidSuper.ID>
				<cfset thisMidSuperEmail = GetMidSuper.email>
				<cfset thisMidSuperSuperEmail = GetMidSuper.supervisor_email>
			<cfelse>
				<cfset thisMidSuperID = 0>
				<cfset thisMidSuperEmail = "">
				<cfset thisMidSuperSuperEmail = "">
			</cfif>
			<cfif ListLen(Trim(Manager)," ") GT 1>
				<cfset MgrFirst = trim(ListGetAt(trim(Manager),1," "))>
				<cfset MgrLast = trim(ListGetAt(trim(Manager),2," "))>
				<cfif ListLen(trim(Manager)," ") GT 2>
					<cfset MgrLast = MgrLast & " " & trim(ListGetAt(trim(Manager),3," "))>
				</cfif>
				<cfquery name="GetManager" datasource="#application.ds#">
					SELECT ID,fname,lname,email,supervisor_email
					FROM #application.database#.program_user
					WHERE LEFT(fname,#len(trim(MgrFirst))#) = '#trim(MgrFirst)#'
					AND lname = '#MgrLast#'
					AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
					AND is_active = 1
				</cfquery>
				<!--- <cfif trim(MgrFirst) EQ 'CRAIG'>
					<cfoutput>
					SELECT ID,fname,lname,email,supervisor_email
					FROM #application.database#.program_user
					WHERE LEFT(fname,#len(trim(MgrFirst))#) = '#trim(MgrFirst)#'
					AND lname = '#MgrLast#'
					AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
					</cfoutput><cfabort>
				</cfif> --->
				<cfif GetManager.recordcount EQ 1>
					<cfset thisManagerID = GetManager.ID>
					<cfset thisManagerSuperEmail = GetManager.supervisor_email>
				<cfelse>
					<cfset thisManagerID = 0>
					<cfset thisManagerSuperEmail = "">
				</cfif>
				<cfif thisTopSuperID EQ 0 OR thisMidSuperID EQ 0 OR thisManagerID EQ 0>
					<cfif thisTopSuperID EQ 0>
						<cfif NOT ListFindNoCase(errors1,TopSuper)>
							<cfset errors1 = ListAppend(errors1,TopSuper)>
						</cfif>
						<cfoutput>#TopSuper#</cfoutput> not found.<br>
					</cfif>
					<cfif thisMidSuperID EQ 0>
						<cfif NOT ListFindNoCase(errors2,MidSuper)>
							<cfset errors2 = ListAppend(errors2,MidSuper)>
						</cfif>
						<cfoutput>#MidSuper#</cfoutput> not found.<br>
					</cfif>
					<cfif thisManagerID EQ 0>
						<cfif NOT ListFindNoCase(errors3,Manager)>
							<cfset errors3 = ListAppend(errors3,Manager)>
						</cfif>
						<cfoutput>#Manager#</cfoutput> not found.<br>
					</cfif>
				<cfelse>
					<cfif thisMidSuperSuperEmail NEQ thisTopSuperEmail>
						Change midSuper <cfoutput>(#thisMidSuperID#) #MidSuper#</cfoutput>'s supervisor email to <cfoutput>#thisTopSuperEmail#</cfoutput><br />
						<cfquery name="UpdateMidSuper" datasource="#application.ds#">
							UPDATE #application.database#.program_user
							SET supervisor_email = '#trim(thisTopSuperEmail)#'
							WHERE ID = #thisMidSuperID#
							AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
						</cfquery>
					</cfif>
					<cfif thisManagerSuperEmail NEQ thisMidSuperEmail>
						Change manager <cfoutput>(#thisManagerID#) #Manager#</cfoutput>'s supervisor email to <cfoutput>#thisMidSuperEmail#</cfoutput><br />
						<cfquery name="UpdateManager" datasource="#application.ds#">
							UPDATE #application.database#.program_user
							SET supervisor_email = '#trim(thisMidSuperEmail)#'
							WHERE ID = #thisManagerID#
							AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
						</cfquery>
					</cfif>
				</cfif>
			<cfelse>
				<cfif NOT ListFindNoCase(errors4,Manager)>
					<cfset errors4 = ListAppend(errors4,Manager)>
				</cfif>
				<cfoutput>#Manager#</cfoutput> no good<br>
			</cfif>
			<cfcatch>
				<cfset errors5 = ListAppend(errors5,TopSuper&","&MidSuper&","&Manager&" has an error.<br>")>
				Error
			</cfcatch>
			</cftry>
			<hr>
		</cfif>
	</cfif>
	<cfset firstLine = false>
</cfloop>
<br>
<cfif errors1 NEQ "">
	Area Directors not found:<br>
	<cfoutput>#Replace(errors1,",","<br>","ALL")#</cfoutput>
	<br><br>
</cfif>
<cfif errors2 NEQ "">
	Regional Sales Managers not found:<br>
	<cfoutput>#Replace(errors2,",","<br>","ALL")#</cfoutput>
	<br><br>
</cfif>
<cfif errors3 NEQ "">
	Division Managers not found:<br>
	<cfoutput>#Replace(errors3,",","<br>","ALL")#</cfoutput>
	<br><br>
</cfif>
<cfif errors4 NEQ "">
	Division Managers no good:<br>
	<cfoutput>#Replace(errors4,",","<br>","ALL")#</cfoutput>
	<br><br>
</cfif>
<cfif errors5 NEQ "">
	Try/catch errors found:<br>
	<cfoutput>#errors5#</cfoutput>
	<br><br>
</cfif>

</cfif>
