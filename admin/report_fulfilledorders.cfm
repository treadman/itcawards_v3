<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000087,true)>

<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "fulfilledordersreport">
<cfinclude template="includes/header.cfm">

<cfoutput>
<span class="pagetitle">Shipped Quantity Report for <cfif has_program>#request.program_name#<cfelse>All Programs</cfif></span>
<br /><br />
<!--- search box (START) --->
<form action="#CurrentPage#" method="post">
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	<tr class="content">
		<td colspan="2" align="center"><input type="submit" name="submit" value="Generate Report"></td>
	</tr>
	</table>
</form>
<!--- search box (END) --->
</cfoutput>
<br /><br />
	
<!--- **************** --->
<!--- if survey report --->
<!--- **************** --->
	
<cfif IsDefined('form.submit')>
	<cfquery name="ReportAllOrders" datasource="#application.DS#">
		SELECT COUNT(ID) AS total
		FROM #application.database#.order_info
		WHERE is_valid = 1
		<cfif has_program>
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10"> 
		</cfif>	
	</cfquery>
	<cfquery name="ReportFulfilledOrders" datasource="#application.DS#">
		SELECT COUNT(ID) AS total 
		FROM #application.database#.order_info
		WHERE is_all_shipped = 1
		AND is_valid = 1
		<cfif has_program>
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10"> 
		</cfif>	
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<!--- header row --->
		<tr class="content2">
			<td colspan="3"><span class="headertext">Program: <span class="selecteditem"><cfif has_program><cfoutput>#request.program_name#</cfoutput><cfelse>All Award Programs</cfif></span></span></td>
		</tr>
		<tr valign="top" class="contenthead">
			<td valign="top" class="headertext">Total Orders</td>
			<td valign="top" class="headertext">Fulfilled</td>
			<td valign="top" class="headertext">Not Fulfilled</td>
		</tr>
		<!--- detail row --->
		<cfoutput>	
		<tr class="content">
			<td valign="top">#ReportAllOrders.total#</td>
			<td valign="top">#ReportFulfilledOrders.total#</td>
			<td valign="top">#ReportAllOrders.total - ReportFulfilledOrders.total#</td>
		</tr>
		</cfoutput>
	</table>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->