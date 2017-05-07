<cfparam name="set" default="0">
<cfif isDefined("form.searchText") AND form.searchText NEQ "">
	<!--- Set the cookie --->
	<cfcookie name="prodval" value="#form.searchText#">
<!--- <cfelseif isDefined("url.clear")>
	<!--- Delete the cookie --->
	<cfcookie name="search" expires="now"> --->
<cfelse>
	<cfdump var="#form#"><cfabort>
</cfif>

<!--- Locate to main --->
<cflocation url="main.cfm?set=#set#&div=#request.division_ID#" addtoken="no">
