<cfparam name="set" default="0">
<cfif isDefined("form.submitSort")>
	<cfif form.sortValue NEQ "">
		<!--- Set the cookie --->
		<cfcookie name="sort" value="#form.sortValue#">
	<cfelse>
		<!--- Delete the cookie --->
		<cfcookie name="sort" expires="now">
	</cfif>
</cfif>

<!--- Locate to main --->
<cflocation url="main.cfm?c=#c#&g=#g#&set=#set#&div=#request.division_ID#" addtoken="no">
