<!--- function library --->
<cfinclude template="/cfscripts/dfm_common/function_library_form.cfm">
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)><!--- TODO: This function could help validate the cookie matches, maybe --->

<cfparam name="where_string" default="">
<cfparam name="ID" default="">
<cfparam name="datasaved" default="no">
<cfparam name="addr1" default="0">
<cfparam name="dept" default="0">

<!--- param search criteria xS=ColumnSort xT=SearchString --->
<cfparam name="xS" default="program">
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">
<cfparam name="only_unfulfilled" default="false">

<!--- param a/e form fields --->
<cfparam name="status" default="">	
<cfparam name="x_date" default="">

<cfset leftnavon = "labels">
<cfinclude template="includes/header.cfm">

<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<span class="alert">Please select a program.</span>
<cfelse>
		<!--- CASE WHEN oi.snap_ship_address1 IS NULL OR oi.snap_ship_address1 = ''
					THEN u.ship_address1
					ELSE oi.snap_ship_address1
					END,'' --->

	
	<cfquery name="SelectLoc" datasource="#application.DS#">
			SELECT DISTINCT
					CASE WHEN u.ship_address1 IS NULL OR u.ship_address1 = ''
						THEN oi.snap_ship_address1
						ELSE u.ship_address1
						END AS final_address1
			FROM #application.database#.order_info oi
			INNER JOIN #application.database#.program_user u ON u.ID = oi.created_user_ID 
			WHERE oi.is_valid = 1 
			<cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>
				AND oi.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			</cfif>
			ORDER BY final_address1
		</cfquery>
	<cfquery name="SelectDept" datasource="#application.DS#">
			SELECT DISTINCT	u.department
			FROM #application.database#.order_info oi
			INNER JOIN #application.database#.program_user u ON u.ID = oi.created_user_ID 
			WHERE oi.is_valid = 1 
			<cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>
				AND oi.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			</cfif>
			ORDER BY department
		</cfquery>
				
<cfoutput>	
<span class="pagetitle">Print Labels for <cfif request.selected_program_ID eq 0>All Programs<cfelse>#request.program_name#</cfif></span>
<br />
<br />
<!--- search box --->
<table cellpadding="5" cellspacing="0" border="0" width="100%">
<tr>
<td class="contentsearch" colspan="2" align="center"><span class="sub">All fields are optional.  Leave unnecessary fields blank.</span></td>
</tr>
<tr>
<td class="content" colspan="2" align="center">
	<form action="labels_pdf.cfm" method="post">
		<table cellpadding="5" cellspacing="0" border="0" width="100%">
			<tr>
			<td align="center">
			<span class="sub">show:</span>
			<br>
			<select name="only_unfulfilled" size="2"><option value="false"#FLForm_Selected("false",only_unfulfilled," selected")#>All Orders</option><option value="true"#FLForm_Selected("true",only_unfulfilled," selected")#>Only Unfulfilled Orders</option></select>
			</td>
			<td>	<span class="sub">order ## or user's name</span><br><input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20"><br><br>
				
				<span class="sub">From Date:</span> <input type="text" name="this_from_date" value="#this_from_date#" size="20" style="margin-bottom:5px"><br>
				<span class="sub">To Date:</span> <input type="text" name="this_to_date" value="#this_to_date#" size="20">
				<br><br>
			</td>
			</tr>
			<tr class="content2"><td>Locations</td></tr>
			<tr>
			<td align="left" valign="top">


<input type="radio" name="addr1" value="0" <cfif addr1 eq "0">checked</cfif>> All locations<br>
<input type="radio" name="addr1" value="99" <cfif addr1 eq "99">checked</cfif>> Blank locations<br>
<cfset cnt = 2>
<cfloop query="SelectLoc">
	<cfif cnt gt 8>
		</td><td align="left" valign="top">
		<cfset cnt = 0>
	</cfif>
	<cfif trim(SelectLoc.final_address1) neq "">
		<input type="radio" name="addr1" value="#SelectLoc.final_address1#" <cfif addr1 eq "#SelectLoc.final_address1#">checked</cfif>> #SelectLoc.final_address1#<br>
		<cfset cnt = cnt + 1>
	</cfif>
</cfloop>
<br><br>
</td>
		</td>
			</tr>
			<tr class="content2"><td>Departments</td></tr>
			<tr>
			<td align="left" valign="top">

<input type="radio" name="dept" value="0" <cfif dept eq "0">checked</cfif>> All departments<br>
<input type="radio" name="dept" value="99" <cfif dept eq "99">checked</cfif>> Blank departments<br>
<cfset cnt = 2>
<cfloop query="SelectDept">
	<cfif cnt gt 28>
		</td><td align="left" valign="top">
		<cfset cnt = 0>
	</cfif>
	<cfif trim(SelectDept.department) neq "">
		<input type="radio" name="dept" value="#SelectDept.department#" <cfif addr1 eq "#SelectDept.department#">checked</cfif>> #SelectDept.department#<br>
		<cfset cnt = cnt + 1>
	</cfif>
</cfloop>

			</td>
			</tr>
			<tr>
			<td colspan="2" align="center">
				<input type="submit" name="search" value="  Generate PDF  ">
			</td>
				
			</tr>
		</table>
	</form>
	<br>
</td>
</tr>
</table>
<br />
</cfoutput>
</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->