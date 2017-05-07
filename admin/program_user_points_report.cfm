<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000036,true)>

<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>-
</cfif>

<cfset request.main_width = 1100>
<cfset leftnavon = "program_user_points_report">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Points Report</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>
	<span class="pagetitle">Points Report for <cfoutput>#request.program_name#</cfoutput></span>
	<br /><br />

	<cfparam name="FromDate" default="">
	<cfparam name="ToDate" default="">
	<cfparam name="formatFromDate" default="">
	<cfparam name="formatToDate" default="">
	<cfparam name="ShowZero" default="0">
	<cfparam name="SortBy" default="Last Name">
	<cfparam name="SortOrder" default="ASC">

	<cfif FromDate NEQ "">
		<cfset FromDate = FLGen_DateTimeToDisplay(FromDate)>
		<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
	</cfif>	
	<cfif ToDate NEQ "">
		<cfset ToDate = FLGen_DateTimeToDisplay(ToDate)>
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
	</cfif>
	
	<cfoutput>
	<table cellpadding="5" cellspacing="1" border="0">
	<form action="#CurrentPage#" method="post">
		<tr>
			<td class="content" align="right">From Date: </td>
			<td class="content" align="left"><input type="text" name="FromDate" value="#FromDate#" size="12"></td>
		</tr>
		<tr>
			<td class="content" align="right">To Date:</td>
			<td class="content" align="left"><input type="text" name="ToDate" value="#ToDate#" size="12"></td>
		</tr>
		<tr>
			<td class="content" align="right">Sort By:</td>
			<td class="content" align="left">
				<select name="SortBy">
					<cfloop list="Username,Last Name,First Name,Email,Awarded,Used,Remaining" index="thisOption">
						<option value="#thisOption#" <cfif SortBy eq "#thisOption#">selected</cfif>>#thisOption#</option>
					</cfloop>
				</select>
			</td>
		</tr>
		<tr>
			<td class="content" align="right">Sort Direction:</td>
			<td class="content" align="left">
				<input type="radio" name="SortOrder" value="asc" <cfif SortOrder eq "asc">checked</cfif>> Asc
				&nbsp;&nbsp;&nbsp;
				<input type="radio" name="SortOrder" value="desc" <cfif SortOrder eq "desc">checked</cfif>> Desc
			</td>
		</tr>
		<tr>
			<td class="content" align="right">Show users where awarded<br>and used points are zero?</td>
			<td class="content" align="left">
				<input type="radio" name="ShowZero" value="1" <cfif ShowZero eq 1>checked</cfif>> Yes
				&nbsp;&nbsp;&nbsp;
				<input type="radio" name="ShowZero" value="0" <cfif ShowZero eq 0>checked</cfif>> No
			</td>
		</tr>
		<tr class="content">
			<td colspan="3" align="center"><input type="submit" name="submit" value="Generate Report"></td>
		</tr>
	</form>
	</table>
	<br /><br />
	</cfoutput>
	
<cfif IsDefined('form.Submit')>
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT u.ID, u.username, u.fname, u.lname, u.email,
			IFNULL(p.points_awarded,0) AS points_awarded,
			IFNULL(o.points_used,0) AS points_used,
			IFNULL(p.points_awarded,0) - IFNULL(o.points_used,0) AS points_remaining
		FROM #application.database#.program_user u
		LEFT JOIN (
			SELECT user_ID, IFNULL(SUM(points),0) AS points_awarded
			FROM #application.database#.awards_points
			WHERE is_defered = 0
			<cfif formatFromDate neq "">
				AND created_datetime >= <cfqueryparam value="#formatFromDate#">
			</cfif>
			<cfif formatToDate neq "">
				AND created_datetime <= <cfqueryparam value="#formatToDate#">
			</cfif>
			GROUP BY user_ID
		) AS p ON p.user_ID = u.ID
		LEFT JOIN (
			SELECT created_user_ID, IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) AS points_used
			FROM #application.database#.order_info
			WHERE is_valid = 1
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
			<cfif formatFromDate neq "">
				AND created_datetime >= <cfqueryparam value="#formatFromDate#">
			</cfif>
			<cfif formatToDate neq "">
				AND created_datetime <= <cfqueryparam value="#formatToDate#">
			</cfif>
			GROUP BY created_user_ID
		) AS o on o.created_user_ID = u.ID
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND u.is_active = '1'
		<cfif ShowZero eq 0>
			AND ( points_awarded > 0 OR points_used > 0)
		</cfif>
		ORDER BY 
		<cfswitch expression="#SortBy#">
			<cfcase value="Username">
				u.username
			</cfcase>
			<cfcase value="Last Name">
				u.lname #SortOrder#, u.fname
			</cfcase>
			<cfcase value="First Name">
				u.fname #SortOrder#, u.lname
			</cfcase>
			<cfcase value="Email">
				u.email
			</cfcase>
			<cfcase value="Awarded">
				points_awarded
			</cfcase>
			<cfcase value="Used">
				points_used
			</cfcase>
			<cfcase value="Remaining">
				points_remaining
			</cfcase>
			<cfdefaultcase>
				u.lname #SortOrder#, u.fname
			</cfdefaultcase>
		</cfswitch>
		#SortOrder#
	</cfquery>
	<cfoutput>
	<p><strong>Program:</strong>  #request.program_name#</p>
	<p><strong>Dates:</strong>
	<cfif FromDate eq "" AND ToDate eq "">
		for all dates
	<cfelseif FromDate eq "" AND ToDate neq "">
		up to #ToDate#
	<cfelseif FromDate neq "" AND ToDate eq "">
		#FromDate# and later
	<cfelse>
		#FromDate# to #ToDate#
	</cfif>
	</p>
	</cfoutput>

	<table cellpadding="5" cellspacing="0" border="0">
		<cfif SelectList.RecordCount IS 0>
			<tr class="content2">
				<td colspan="100%" align="center"><span class="alert"><br>No records found for your selections.<br><br></span></td>
			</tr>
		<cfelse>
			<!--- header row --->
			<!--- tr class="contenthead">
				<td class="headertext" colspan="3" align="center">Program User</td>
				<td class="headertext" colspan="3" align="center">Award Points</td>
			</tr --->
			<tr class="contenthead">
				<td class="headertext">Username</td>
				<td class="headertext">Name</td>
				<td class="headertext">Email</td>
				<td class="headertext">Awarded</td>
				<td class="headertext">Used</td>
				<td class="headertext">Remaining</td>
			</tr>
			<cfset TotalAwarded = 0>
			<cfset TotalUsed = 0>
			<cfset TotalRemaining = 0>
			<cfoutput>
			<cfloop query="SelectList">
				<tr class="content<cfif SelectList.currentrow MOD 2>2</cfif>">
					<td>#SelectList.username#</td>
					<td nowrap="nowrap">#SelectList.lname#, #SelectList.fname#</td>
					<td>#SelectList.email#</td>
					<td align="right">#SelectList.points_awarded#</td>
					<td align="right">#SelectList.points_used#</td>
					<td align="right">#SelectList.points_remaining#</td>
 				</tr>
				<cfset TotalAwarded = TotalAwarded + SelectList.points_awarded>
				<cfset TotalUsed = TotalUsed + SelectList.points_used>
				<cfset TotalRemaining = TotalRemaining + SelectList.points_remaining>
			</cfloop>
			<tr class="content2">
				<td colspan="3" align="right" class="headertext">Totals:</td>
				<td align="right" class="headertext">#TotalAwarded#</td>
				<td align="right" class="headertext">#TotalUsed#</td>
				<td align="right" class="headertext">#TotalRemaining#</td>
			</tr>
			</cfoutput>
		</cfif>
	</table>
</cfif>
</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->

