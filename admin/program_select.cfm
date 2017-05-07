<!--- Sets the cookie for the selected program.  Expire the cookie for admin --->
<!--- To force a selection from a link, add "&program_select=#program_ID#" to your link --->

<cfif isDefined("url.returnto") AND ListLast(url.returnto,".") EQ "cfm" AND (isDefined("url.program_select") OR isDefined("url.division_select"))>
	<cfif isDefined("url.program_select")>
		<cfif isNumeric(url.program_select) AND url.program_select GT 0>
			<!--- Set the cookie to the passed in program ID --->
			<cfset HashedProgramID = FLGen_CreateHash(url.program_select)>
			<cfcookie name="program_id" value="#url.program_select#-#HashedProgramID#">
		<cfelse>
			<!--- Expire the cookie making it the admin selection --->
			<cfcookie name="program_id" expires="now">
		</cfif>
	</cfif>
	<cfif isDefined("url.division_select")>
		<cfif isNumeric(url.division_select) AND url.division_select GT 0>
			<!--- Set the cookie to the passed in division ID --->
			<cfset HashedDivisionID = FLGen_CreateHash(url.division_select)>
			<cfcookie name="division_id" value="#url.division_select#-#HashedDivisionID#">
		<cfelse>
			<cfcookie name="division_id" expires="now">
		</cfif>
	</cfif>
	<!--- Parse the query string so you don't keep passing around the returnto and program ID --->
	<cfset qString = "">
	<cfset locateTo = url.returnto>
	<cfloop list="#CGI.QUERY_STRING#" index="thisQuery" delimiters="&">
		<!---<cfif ListFirst(thisQuery,"=") NEQ "program_select" AND ListFirst(thisQuery,"=") NEQ "returnto">--->
		<cfif NOT ListFind("program_select,division_select,returnto",ListFirst(thisQuery,"="))>
			<cfset qString = ListAppend(qString,thisQuery,"&")>
		</cfif>
	</cfloop>
	<cfif qString NEQ "">
		<cfset locateTo = locateTo & "?" & qString>
	</cfif>
	<!--- Send them back to whence they came --->
	<cflocation url="#locateTo#" addtoken="no">
<cfelse>
	<!--- This is from a form post, which is only in header.cfm (I think) --->
	<cfif form.Program NEQ "">
		<cfset HashedProgramID = FLGen_CreateHash(form.Program)>
		<cfcookie name="program_id" value="#form.Program#-#HashedProgramID#">
	<cfelse>
		<cfcookie name="program_id" expires="now">
	</cfif>
	<cflocation url="#form.ReturnTo#" addtoken="no">
</cfif>
