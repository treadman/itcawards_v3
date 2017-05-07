<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<cfparam name="DisplayMode" default="Welcome">

<cfinclude template="includes/header.cfm">

<cfoutput>#Replace(additional_content_message,chr(10),"<br>","ALL")#</cfoutput>

<cfinclude template="includes/footer.cfm">
