<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000036,true)>

<cfparam name="FromDate" default="">
<cfparam name="ToDate" default="">
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">

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

<cfset leftnavon = "registration_report">
<cfinclude template="includes/header.cfm">

<span class="pagetitle">User Registration Report<cfif has_program> for <cfoutput>#request.program_name#</cfoutput></cfif></span>
<br /><br />
<cfif NOT has_program>
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
	<br /><br />
<cfelse>

<span class="pageinstructions">Leave the dates blank to see users/products for all time.</span>
<br /><br />

<!--- search box (START) --->
<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="3"><span class="headertext">Generate User/Product Report</span></td>
	</tr>
	
	<cfoutput>
	<form action="#CurrentPage#" method="post">
	<tr>
	<td class="content" align="right">From Date: </td>
	<td class="content" align="left"><input type="text" name="FromDate" value="#FromDate#" size="12"></td>
	</tr>

	<tr>
	<td class="content" align="right">To Date:</td>
	<td class="content" align="left"><input type="text" name="ToDate" value="#ToDate#" size="12"></td>
	</tr>

	<tr class="content">
	<td colspan="3" align="center"><input type="submit" name="submit" value="Generate Report"></td>
	</tr>
	</form>
	</cfoutput>
	
</table>
<br /><br />
<!--- search box (END) --->
	
<!--- **************** --->
<!--- if survey report --->
<!--- **************** --->
	
<cfif IsDefined('form.submit')>

	<cfif FromDate NEQ "">
		<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
	</cfif>	
	<cfif ToDate NEQ "">
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
	</cfif>	

	<cfquery name="ReportUsers" datasource="#application.DS#">
		SELECT created_datetime, fname, lname, ship_address1, ship_address2, ship_city, ship_state, ship_zip, phone, email
		FROM #application.database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		<cfif formatFromDate NEQ "">
			AND created_datetime >= '#formatFromDate#' 
		</cfif>	
		<cfif formatToDate NEQ "">
			AND created_datetime <= '#formatToDate#' 
		</cfif>	
		ORDER BY created_datetime, lname, fname
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<!--- header row --->
	<tr class="content2">
	<td colspan="3"><span class="headertext">Program: <span class="selecteditem"><cfoutput>#request.program_name#</span></span></cfoutput></td>
	</tr>
	
	<tr class="contenthead">
	<td class="headertext">Registered</td>
	<td class="headertext">User</td>
	<td class="headertext">Email<br>Phone</td>
	<td class="headertext">Address</td>
	</tr>
	
	<cfif ReportUsers.RecordCount EQ 0>
	<tr class="content2">
	<td colspan="3" align="center" class="alert"><br>There are no results to display.<br><br></td>
	</tr>
	</cfif>
	<cfset count = 1>
	<cfoutput query="ReportUsers">
		<cfset count = count + 1>
		<tr class="#Iif(((count MOD 2) is 0),de('content2'),de('content'))#">
		<td valign="top">#FLGen_DateTimeToDisplay(created_datetime)#</td>
		<td valign="top">#lname#, #fname#</td>
		<td valign="top">#email#<br>#phone#</td>
		<td valign="top">
			#ship_address1#<br>
			<cfif trim(ship_address2) NEQ "">
				#ship_address2#<br>
			</cfif>
		 	<cfif trim(ship_city) NEQ "">#ship_city#, </cfif>#ship_state# #ship_zip#
		 </td>
		</tr>
	
	</cfoutput>
	
	</table>

</cfif>



</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->