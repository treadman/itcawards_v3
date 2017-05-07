<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000037-1000000076", true)>

<!--- ************************************ --->
<!--- param all variables used on this page --->
<!--- ************************************ --->
<cfparam name="FromDate" default="">
<cfparam name="ToDate" default="">
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">
<cfparam name="division_ID" default="0">

<!--- Verify that a program was selected --->
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
<cfset leftnavon = "newbillingreport">
<cfset request.main_width = 1100>
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">
		Billing Report
	</span>
	<br/>
	<br/>
	<span class="alert">
		<cfoutput>#application.AdminSelectProgram#</cfoutput>
	</span>
<cfelse>
	<span class="pagetitle">
		Billing Report for 
		<cfoutput>#request.program_name#</cfoutput>
	</span>
	<br/>
	<br/>
	<!--- find program's min max order dates --->
	<cfif IsDefined('form.submit')>
		<cfif FromDate EQ "" OR ToDate EQ "">
			<cfquery name="MinMaxOrderDates" datasource="#application.DS#">
				SELECT MIN(created_datetime) AS first_order, MAX(created_datetime) AS last_order
				FROM #application.database#.order_info
				WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" 
			              value="#request.selected_program_ID#" maxlength="10">
				AND is_valid = 1
			</cfquery>
			<cfif FromDate EQ "" AND MinMaxOrderDates.first_order NEQ "">
				<cfset FromDate = FLGen_DateTimeToDisplay(MinMaxOrderDates.first_order)>
			<cfelseif FromDate EQ "">
				<cfset FromDate = FLGen_DateTimeToDisplay()>
			</cfif>
			<cfif ToDate EQ "" AND MinMaxOrderDates.last_order NEQ "">
				<cfset ToDate = FLGen_DateTimeToDisplay(MinMaxOrderDates.last_order)>
			<cfelseif ToDate EQ "">
				<cfset ToDate = FLGen_DateTimeToDisplay()>
			</cfif>
		</cfif>
		<cfset FromDate = FLGen_DateTimeToDisplay(FromDate)>
		<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
		<cfset ToDate = FLGen_DateTimeToDisplay(ToDate)>
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
	</cfif>

	<cfoutput>
	
		<!--- TODO:  Get KCG working for divisions --->
		<cfset has_unassigned = false>
		<cfif request.has_divisions>
			<cfset unassigned_points = hasUserUnassignedPoints()>
			<cfif unassigned_points.recordcount GT 0>
				<cfset has_unassigned = true>
				<p class="alert">
					There are users with points that have not been assigned to a division.
				</p>
				<p><a href="program_details.cfm">Go to Program Details</a> to assign points.</p>
			</cfif>
			<cfif not has_unassigned>
				<cfset has_unassigned = hasOrdersUnassignedPoints()>
				<cfif has_unassigned>
					<p class="alert">
						There are orders that have not been assigned division points.
					</p>
					<p>
						<a href="program_division.cfm?pgfn=unassigned_orders" onclick="this.style.display = 'none'; document.getElementById('please_wait').style.display = 'block'">
							Assign Points
						</a>
					</p>
					<p id="please_wait" style="display:none;">
						Please wait...
					</p>
					
					<br>
				</cfif>
			</cfif>
		</cfif>

		<cfif NOT has_unassigned>
			<!--- search box (START) --->
			<table cellpadding="5" cellspacing="0" border="0" width="350">
				<tr class="contenthead">
					<td colspan="3">
						<span class="headertext">
							Generate Billing Report
						</span>
						&nbsp;&nbsp;&nbsp;&nbsp;
						<span class="sub">
							(dates are optional)
						</span>
					</td>
				</tr>
				<form action="#CurrentPage#" method="post">
					<cfif request.has_divisions>
						<tr class="content">
							<td colspan="2" class="content" align="right">
								Division:
							</td>
							<td class="content">
								<select name="division_ID">
									<option value="0">
										-- All Divisions -- 
									</option>
									<cfloop query="request.GetDivisions">
										<option value="#request.GetDivisions.ID#" <cfif request.GetDivisions.ID EQ division_ID>selected</cfif>>#request.GetDivisions.program_name#</option>
									</cfloop>
								</select>
							</td>
						</tr>
					<cfelse>
						<input type="hidden" name="division_id" value="0">
					</cfif>
					<tr>
						<td class="content">
						</td>
						<td class="content" align="right">
							From Date: 
						</td>
						<td class="content" align="left">
							<input type="text" name="FromDate" value="#FromDate#" size="12">
						</td>
					</tr>
					<tr>
						<td class="content">
						</td>
						<td class="content" align="right">
							To Date:
						</td>
						<td class="content" align="left">
							<input type="text" name="ToDate" value="#ToDate#" size="12">
						</td>
					</tr>
					<tr class="content">
						<td colspan="3" align="center">
							<input type="submit" name="submit" value="Generate Report">
						</td>
					</tr>
				</form>
			</table>
			<br/>
			<br/>
			<!--- search box (END) --->
		</cfif>
	
	</cfoutput>
</cfif>

<!--- **************** --->
<!--- if survey report --->
<!--- **************** --->
<cfif IsDefined('form.submit')>
	<cfset displayed_anything = false>
	<!--- find the users for this program --->
	<cfquery name="FindAllUsers" datasource="#application.DS#">
		SELECT DISTINCT u.fname, u.lname, u.ID, u.nickname, u.email, u.username
		FROM #application.database#.program_user u
		JOIN #application.database#.order_info o ON o.created_user_ID = u.ID
		WHERE u.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" 
	              value="#request.selected_program_ID#" maxlength="10">
		AND o.order_number > 0
		AND o.is_valid = 1
		AND o.created_datetime >= <cfqueryparam value="#formatFromDate#">
		AND o.created_datetime <= <cfqueryparam value="#formatToDate#">
		ORDER BY u.lname ASC 
	</cfquery>
	<!--- <cfdump var="#FindAllUsers#"><cfabort> --->
	<cfoutput>
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
			<!--- header row --->
			<tr class="content2">
				<td colspan="100%">
					<span class="headertext">
						Program: 
						<span class="selecteditem">
							#request.program_name#
						</span>
					</span>
				</td>
			</tr>
			<tr class="content2">
				<td colspan="100%">
					<span class="headertext">
						Dates:&nbsp;&nbsp;&nbsp;
						<span class="selecteditem">
							#FromDate#
							<span class="reg">
								&nbsp;&nbsp;&nbsp;to&nbsp;&nbsp;&nbsp;
							</span>
							#ToDate#
						</span>
					</span>
				</td>
			</tr>
			<tr class="contenthead">
				<td class="headertext" rowspan="2">
					Username
				</td>
				<td class="headertext" rowspan="2">
					Name
				</td>
				<td class="headertext" rowspan="2">
					Email Address
				</td>
				<td class="headertext" align="center" colspan="3">
					Total Points
				</td>
				<td class="headertext" rowspan="2">
					Last Order
				</td>
			</tr>
			<tr class="contenthead">
				<td class="headertext" align="center">
					Awarded
				</td>
				<td class="headertext" align="center">
					Used
				</td>
				<td class="headertext" align="center">
					Remaining
				</td>
			</tr>
			<cfset GT_Award = 0>
			<cfset GT_Used = 0>
			<cfloop query="FindAllUsers">
				<cfset username = FindAllUsers.username>
				<cfset fname = FindAllUsers.fname>
				<cfset lname = FindAllUsers.lname>
				<cfset ID = FindAllUsers.ID>
				<cfset nickname = FindAllUsers.nickname>
				<cfset email = FindAllUsers.email>
				<cfif request.has_divisions>
					<cfset rem_div = StructNew()>
					<cfset last_div = 0>
					<cfquery name="getOrders" datasource="#application.DS#">
						SELECT o.ID, o.created_user_ID, o.created_datetime, o.order_number, o.credit_card_charge,
						x.award_points AS points_used, x.division_id, p.program_name
						FROM #application.database#.xref_order_division x
						LEFT JOIN #application.database#.order_info o on x.order_ID = o.ID
						LEFT JOIN #application.database#.program p ON p.ID = x.division_ID
						WHERE o.created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#">
						AND o.is_valid = 1
						AND o.created_datetime >= <cfqueryparam value="#formatFromDate#">
						AND o.created_datetime <= <cfqueryparam value="#formatToDate#">
						<cfif division_ID GT 0>
							AND x.division_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#division_ID#">
						</cfif>
						ORDER BY x.division_ID, o.created_datetime DESC
					</cfquery>
				<cfelse>
					<cfquery name="getOrders" datasource="#application.DS#">
						SELECT o.ID, o.created_user_ID, o.created_datetime, o.order_number, o.points_used,
						o.credit_card_charge
						FROM #application.database#.order_info o
						WHERE o.created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#">
						AND o.is_valid = 1
						AND o.created_datetime >= <cfqueryparam value="#formatFromDate#">
						AND o.created_datetime <= <cfqueryparam value="#formatToDate#">
						ORDER BY o.created_datetime DESC
					</cfquery>
				</cfif>
				#ProgramUserInfoConstrained(ID, formatFromDate, formatToDate)#
				<cfquery name="PosPoints" datasource="#application.DS#">
					SELECT IFNULL(SUM(a.points),0) AS pos_pt
					<cfif request.has_divisions>
						, a.division_id, p.program_name 
					</cfif>
					FROM #application.database#.awards_points a
					<cfif request.has_divisions>
						LEFT JOIN 
						#application.database#
						.program p ON p.ID = a.division_ID
					</cfif>
					WHERE a.user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#">
					AND is_defered = 0
					AND a.created_datetime <= <cfqueryparam value="#formatToDate#">
					<cfif request.has_divisions>
						<cfif division_ID GT 0>
							AND a.division_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#division_ID#">
						</cfif>
						GROUP BY a.division_id
						ORDER BY a.division_id
					</cfif>
				</cfquery>
			
				<cfif getOrders.recordcount GT 0 AND BRp_pospoints NEQ 0>
					<tr class="content">
						<td>
							#username#
						</td>
						<td>
							#lname#
							, 
							#fname#
							<cfif nickname NEQ "">
								(
								#nickname#
								)
							</cfif>
						</td>
						<td>
							#email#
						</td>
						<td align="right" valign="bottom">
							<!--- Awarded --->
							<cfset awarded = 0>
							<cfloop query="PosPoints">
								<cfset awarded = awarded + PosPoints.pos_pt>
								<cfif request.has_divisions>
									<cfif NOT StructKeyExists(rem_div, PosPoints.division_ID)>
										<cfset rem_div[PosPoints.division_ID] = StructNew()>
										<cfset rem_div[PosPoints.division_ID].name = PosPoints.program_name>
										<cfset rem_div[PosPoints.division_ID].points = 0>
									</cfif>
									<cfset last_div = PosPoints.division_ID>
									<cfset rem_div[PosPoints.division_ID].points = rem_div[PosPoints.division_ID].points + PosPoints.pos_pt>
									#PosPoints.program_name#
									<span <cfif PosPoints.recordcount EQ PosPoints.currentrow>style="text-decoration: underline;"</cfif>>
									 #PosPoints.pos_pt#
								</span>
									<br>
								</cfif>
							</cfloop>
							#awarded#
							&nbsp;
						</td>
						<td align="right" valign="bottom">
							<!--- Used --->
							<cfset usedPoints = 0>
							<cfloop query="getOrders">
								<cfset usedPoints = usedPoints + getOrders.points_used>
								<cfif request.has_divisions>
									<cfif NOT StructKeyExists(rem_div, getOrders.division_ID)>
										<cfset rem_div[getOrders.division_ID] = StructNew()>
										<cfset rem_div[getOrders.division_ID].name = getOrders.program_name>
										<cfset rem_div[getOrders.division_ID].points = 0>
									</cfif>
									<cfset rem_div[getOrders.division_ID].points = rem_div[getOrders.division_ID].points - getOrders.points_used>
									#getOrders.program_name#
									<span <cfif getOrders.recordcount EQ getOrders.currentrow>style="text-decoration: underline;"</cfif>>
									 #getOrders.points_used#
								</span>
									<br>
								</cfif>
							</cfloop>
							#usedPoints#
							&nbsp;
						</td>
						<td align="right" valign="bottom">
							<cfif request.has_divisions>
								<cfset div_count = 0>
								<cfloop collection="#rem_div#" item="this_div">
									<cfset div_count = div_count+1>
									#rem_div[this_div].name#
									<span <cfif div_count EQ structcount(rem_div)>style="text-decoration: underline;"</cfif>>
									 #rem_div[this_div].points#
								</span>
									<br>
								</cfloop>
							</cfif>
							#awarded - usedPoints#
							&nbsp;
						</td>
						<td>
							#BRp_last_order#
							<cfset displayed_anything = true>
						</td>
					</tr>
					<cfset GT_Award = GT_Award + awarded>
					<cfset GT_Used = GT_Used + usedPoints>
				</cfif>
			
				<cfif getOrders.recordcount GT 0>
					<cfset old_ID = "FIRST_TIME">
					<cfset order_output = "">
					<cfloop query="getOrders">
						<cfif isNumeric(getOrders.points_used) and getOrders.points_used GT 0>
							<cfif old_ID NEQ getOrders.ID>
								<cfset order_output = order_output & '<tr><td colspan="7">Order #getOrders.order_number# - #dateFormat(getOrders.created_datetime,"mm/dd/yyyy")#'>
							</cfif>
							<cfset order_output = order_output & ' - #getOrders.points_used# points'>
							<cfif request.has_divisions>
								<cfset order_output = order_output & ' from #getOrders.program_name#'>
							</cfif>
							<cfif old_ID NEQ getOrders.ID AND isNumeric(getOrders.credit_card_charge) AND getOrders.credit_card_charge 
							      GT 0>
								<cfset order_output = order_output & ' - #DollarFormat(getOrders.credit_card_charge)# charged'>
							</cfif>
							<cfif getOrders.recordcount EQ getOrders.currentrow OR getOrders.ID NEQ getOrders.ID[getOrders.currentrow 
							      + 1]>
								<cfquery name="getItems" datasource="#application.DS#">
									SELECT quantity, snap_meta_name, snap_productvalue, snap_options
									FROM #application.database#.inventory
									WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#getOrders.ID#">
								</cfquery>
								<cfif getItems.recordcount GT 0>
									<cfloop query="getItems">
										<cfset order_output = order_output & '<br>&nbsp;&nbsp;&nbsp;#getItems.quantity# #getItems.snap_meta_name# #getItems.snap_options# (#DollarFormat(getItems.snap_productvalue)# value)'>
									</cfloop>
									<cfset order_output = order_output & '<br>'>
								<cfelse>
									<cfset order_output = order_output & 'NO LINE ITEMS FOUND!'>
								</cfif>
								<cfset order_output = order_output & '
								</td>
							</tr>'>
							</cfif>
							<cfset old_ID = getOrders.ID>
						<cfelse>
							<cfset order_output = order_output & '<tr><td colspan="7">No orders found!</td></tr>'>
						</cfif>
					</cfloop>
					#order_output#
				</cfif>
			</cfloop>
			<cfif displayed_anything>
				<tr class="contenthead">
					<td class="headertext" colspan="3">
						&nbsp;
					</td>
					<td class="headertext" align="center">
						Awarded
					</td>
					<td class="headertext" align="center">
						Used
					</td>
					<td class="headertext" align="center">
						Remaining
					</td>
					<td class="headertext" colspan="1">
						&nbsp;
					</td>
				</tr>
				<tr class="content">
					<td>
					</td>
					<td>
					</td>
					<td align="right">
						Grand Total: 
					</td>
					
					`
					<td align="right">
						#GT_Award#
					</td>
					<td align="right">
						#GT_Used#
					</td>
					<td align="right">
						#GT_Award - GT_Used#
					</td>
					<td>
					</td>
				</tr>
			</cfif>
		</table>
	</cfoutput>
	<cfif NOT displayed_anything>
		<br>
		<p class="alert">
			There is no information to display.
		</p>
	</cfif>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->