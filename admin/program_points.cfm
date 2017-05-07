<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="program_list.cfm" addtoken="no">
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000014-1000000020",true)>

<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<cfparam name="where_string" default="">
<cfparam name="puser_ID" default="">
<cfparam name="duplicateusername" default="false">

<!--- main program page paging/sort/search variables --->
<cfparam name="xS" default="">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="OnPage" default="">
<cfparam name="xtrawhrere" default="">
<cfparam name="delete" default="">

<!--- param search criteria xxS=ColumnSort xxT=SearchString xxL=Letter --->
<cfparam name="xxS" default="username">
<cfparam name="xxT" default="">
<cfparam name="xxL" default="">
<cfparam name="xOnPage" default="1">

<!--- param a/e form fields --->


<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfif request.has_divisions AND (NOT isNumeric(division_ID) OR division_ID EQ 0)>
		<cfset alert_msg = "Please select a division.">
	<cfelse>
		<cfif addsub EQ "sub">
			<cfset point_amount = - point_amount>
		</cfif>
		<!--- if user, add points for this user --->
		<cfif puser_ID NEQ "">
			<cfquery name="InsertPoints" datasource="#application.DS#">
				INSERT INTO #application.database#.awards_points
					(created_user_ID, created_datetime, user_ID, points, notes, division_ID)
				VALUES
					(
						'#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#',
						<cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#point_amount#" maxlength="8">,
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#note#" null="#YesNoFormat(NOT Len(Trim(note)))#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#division_ID#" maxlength="10">
					)
			</cfquery>
			<!--- add points in subprogram_points, too --->
			<cfif IsDefined('form.subprogram_ID') and form.subprogram_ID NEQ "">
				<cfquery name="InsertPoints" datasource="#application.DS#">
					INSERT INTO #application.database#.subprogram_points
					(created_user_ID, created_datetime, subprogram_ID, user_ID, subpoints)
					VALUES
					('#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#',
						<cfqueryparam cfsqltype="cf_sql_integer" value="#subprogram_ID#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#point_amount#">)
				</cfquery>
			</cfif>
		<!--- if NO user, add points for all users in this program --->
		<cfelse>
			<cfquery name="FindAllProgramUsers" datasource="#application.DS#">
				SELECT ID AS THISpuser_ID
				FROM #application.database#.program_user
				WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
				AND is_active = 1
			</cfquery>
			<cfloop query="FindAllProgramUsers">
				<cfquery name="InsertEachPoints" datasource="#application.DS#">
					INSERT INTO #application.database#.awards_points
						(created_user_ID, created_datetime, user_ID, points, notes, division_ID)
					VALUES
						(
							'#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#',
							<cfqueryparam cfsqltype="cf_sql_integer" value="#THISpuser_ID#" maxlength="10">,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#point_amount#" maxlength="8">,
							<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#note#" null="#YesNoFormat(NOT Len(Trim(note)))#">,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#division_ID#" maxlength="10">
						)
				</cfquery>
				<!--- add points in subprogram_points, too --->
				<cfif IsDefined('form.subprogram_ID') and form.subprogram_ID NEQ "">
					<cfquery name="InsertPoints" datasource="#application.DS#">
						INSERT INTO #application.database#.subprogram_points
						(created_user_ID, created_datetime, subprogram_ID, user_ID, subpoints)
						VALUES
						('#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#',
							<cfqueryparam cfsqltype="cf_sql_integer" value="#subprogram_ID#">,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#THISpuser_ID#">,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#point_amount#">)
					</cfquery>
				</cfif>
			</cfloop>
		</cfif>
		<cfset alert_msg = Application.DefaultSaveMessage>
	</cfif>
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000047)>
	<cfquery name="DeleteLineItem" datasource="#application.DS#">
		DELETE FROM #application.database#.awards_points
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "program_user">
<cfinclude template="includes/header.cfm">

<cfquery name="SelectProgramInfo" datasource="#application.DS#">
	SELECT credit_multiplier, points_multiplier
	FROM #application.database#.program
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
</cfquery>
<cfset credit_multiplier = SelectProgramInfo.credit_multiplier>
<cfset points_multiplier = SelectProgramInfo.points_multiplier>

<!--- Get User Info IF PASSED --->
<!--- run query --->
<cfif puser_ID NEQ "">

	<cfquery name="SelectUserInfo" datasource="#application.DS#">
		SELECT IFNULL(fname,"-") AS fname, IFNULL(lname,"-") AS lname
		FROM #application.database#.program_user
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">
	</cfquery>
	<cfset fname = HTMLEditFormat(SelectUserInfo.fname)>
	<cfset lname = HTMLEditFormat(SelectUserInfo.lname)>
	
	<!--- CALCULATE USER'S POINTS --->
		<!--- look in the points database for the starting point amount --->
		<cfquery name="PosPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM(points),0) AS pos_pt
			FROM #application.database#.awards_points
			WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10"> 
		</cfquery>
		
		<!--- look in the order database for orders/points_used --->
		<cfquery name="NegPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM((points_used * credit_multiplier)/points_multiplier),0) AS neg_pt
			FROM #application.database#.order_info
			WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10"> 
		</cfquery>

		<cfset user_total = PosPoints.pos_pt - NegPoints.neg_pt>
			
<cfelse>
	<cfset fname = "">
	<cfset lname = "">
	<cfset user_total = "">
</cfif>

<cfoutput>
<span class="pagetitle">Award Points for #request.program_name#</span>
<br /><br />
<span class="pageinstructions">Return to <a href="program_user.cfm?xL=#xL#&xT=#xT#&OnPage=#OnPage#&xOnPage=#xOnPage#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#">Program User List</a>  or  <a href="program.cfm?&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Award Program List</a> without making changes.</span>
<br /><br />

<form method="post" action="#CurrentPage#">


	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<cfif points_multiplier NEQ 1>
	<tr class="content2">
	<td  colspan="3"><span class="alert">NOTE:</span> Points will be multiplied by #points_multiplier# when displayed to the user.<br><br> For example, if a user has 10 points on this page, they will be told they have #NumberFormat(points_multiplier * 10,Application.NumFormat)# points when they are shopping.</td>
	</tr>	
	</cfif>

	<cfif credit_multiplier NEQ 1>
	<tr class="content2">
	<td  colspan="3"><span class="alert">NOTE:</span> Products will be multiplied by #credit_multiplier# when displayed to the user.<br><br> For example, if a product costs 10 points, they will see the product costs #NumberFormat(credit_multiplier * 10,Application.NumFormat)# points when they are shopping.</td>
	</tr>	
	</cfif>

	<cfif puser_ID NEQ "">
		<tr class="content2">
		<td  colspan="3"><span class="headertext">User: <span class="selecteditem">#fname# #lname#</span></span></td>
		</tr>
	</cfif>

	<!--- search for subprograms --->
	<cfquery name="SelectSubprograms" datasource="#application.DS#">
		SELECT ID as subprogram_ID, subprogram_name, is_active
		FROM #application.database#.subprogram
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		ORDER BY sortorder
	</cfquery>

	<cfquery name="SelectActiveSubprograms" dbtype="query">
		SELECT subprogram_ID, subprogram_name
		FROM SelectSubprograms
		WHERE is_active = 1
	</cfquery>

	<tr class="contenthead">
	<td class="headertext">Award Points</td>
	</tr>
	
	<cfif puser_ID EQ "">
	<tr class="content" valign="top">
	<td><span class="alert">You are adding points to all users in this Award Program.</span></td>
	</tr>
	</cfif>
	
	<cfif request.has_divisions>
		<tr class="content" valign="top">
		<td valign="top" style="padding-left:35px;">
			<input type="hidden" name="division_ID_required" value="Please select a division.">
			<select name="division_ID">
				<option value=""> -- Select a Division --</option>
				<cfloop query="request.GetDivisions">
					<option value="#request.GetDivisions.ID#">#request.GetDivisions.program_name#</option>
				</cfloop>
			</select>
		</td>
		</tr>
	<cfelse>
		<input type="hidden" name="division_id" value="0">
	</cfif>
	
	<tr class="content" valign="top">
	<td style="padding-left:35px;">
		<input type="hidden" name="addsub_required" value="Please choose to either add or subtract the Award Points.">
		<input type="hidden" name="point_amount_required" value="Please enter a number of points to add or subtract.">
		<table>
			<tr><td>
				
		<select name="addsub" size="2">
			<option value="add" selected>add (+)</option>
			<option value="sub">sub (-)</option>
		</select>
				
			</td><td>
				
		<input type="text" name="point_amount" maxlength="8" size="5" style="margin-left:20px;"> Award Points
				
			</td></tr>
		</table>
	</td>
	</tr>
	
	<cfif SelectSubprograms.RecordCount NEQ 0>
	<tr class="content" valign="top">
	<td valign="top" style="padding-left:35px;">
	Associate these points with this subprogram <span class="sub">(for billing report purposes only)</span><br>
	<select name="subprogram_ID" size="#SelectActiveSubprograms.RecordCount#">
		<cfset counter = 1>
		<cfloop query="SelectActiveSubprograms">
			<option value="#subprogram_ID#" <cfif counter EQ 1> selected</cfif>>#subprogram_name#</option>
			<cfset counter = IncrementValue(counter)>
		</cfloop>
	</select>
	<input type="hidden" name="subprogram_ID_required" value="Please choose a subprogram.">
	</td>
	</tr>
	</cfif>
	
	<tr class="content" valign="top">
	<td style="padding-left:35px;">optional note:<br><textarea name="note" cols="70" rows="2"></textarea></td>
	</tr>
	
		
	<tr class="content">
	<td align="center">

	<!--- This page's variables --->	
	<input type="hidden" name="xxS" value="#xxS#">
	<input type="hidden" name="xxL" value="#xxL#">
	<input type="hidden" name="xxT" value="#xxT#">
	<input type="hidden" name="xOnPage" value="#xOnPage#">
	
	<!--- the main program page's variables --->	
	<input type="hidden" name="xS" value="#xS#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">

	<input type="hidden" name="puser_ID" value="#puser_ID#">
			
	<input type="submit" name="submit" value="   Save Changes   " >
	
	</td>
	</tr>
		
	</table>
</form>
</cfoutput>

<cfif puser_ID NEQ "">
	<cfquery name="GetPointHistory" datasource="#application.DS#">
		SELECT p.created_datetime, p.created_user_ID, p.points AS thispoints, IFNULL(p.notes,'(no note)') AS thisnote,
				000 AS order_number, IF(p.is_defered = 1, 'true', 'false') AS thisdef, p.ID AS point_ID , p.division_ID,
				d.program_name AS division_name, s.subdivision_name
		FROM #application.database#.awards_points p
		LEFT JOIN #application.database#.program d ON d.ID = p.division_ID
		LEFT JOIN #application.database#.subdivisions s ON s.ID = p.subdivision_ID
		WHERE p.user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">
		
		UNION
		
		SELECT created_datetime, created_user_ID, ((points_used * credit_multiplier)/points_multiplier) AS thispoints, '' AS thisnote,
				order_number AS order_number, 'false' AS thisdef, 444 AS point_ID, 0 AS division_ID,
				'' AS division_name, '' AS subdivision_name
		FROM #application.database#.order_info
		WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10"> 
			AND is_valid = 1
		ORDER BY created_datetime
	</cfquery>
	<cfoutput>
	<br>
	
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<tr class="selectedbgcolor">
	<td colspan="8" class="headertext">Actual Award Points</td>
	</tr>
	
	<tr class="contenthead">
	<td class="headertext" align="center">Date</td>
	<td class="headertext" align="right">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Points</td>
	<cfif request.has_divisions>
		<td class="headertext">Division&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
	</cfif>
	<cfif FLGen_HasAdminAccess(1000000047)>
	<td class="headertext" align="center"><span class="tooltip" title="Click the X to remove that line item.">?</span></td>
	</cfif>
	<td class="headertext" width="100%">Order Number/Inventory Note</td>
	</tr>
	
	<cfloop query="GetPointHistory">
	<tr class="content">
	<td>#FLGen_DateTimeToDisplay(created_datetime)#</td>
	<td align="right"><cfif thisdef><span class="sub">[defered]</span></cfif><cfif order_number NEQ 000>-</cfif> #thispoints#</td>
	<cfif request.has_divisions>
		<td class="headertext">#division_name# <cfif subdivision_name NEQ ""><span class="sub">(#subdivision_name#)</span></cfif></td>
	</cfif>
	<cfif FLGen_HasAdminAccess(1000000047)>
	<td class="headertext" align="center"><cfif point_ID NEQ '444'><a href="#CurrentPage#?delete=#point_ID#&puser_ID=#puser_ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#&xOnPage=#xOnPage#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#" onclick="return confirm('Are you sure you want to delete this line item?  There is NO UNDO.')">X</a><cfelse>&nbsp;</cfif></td>
	</cfif>
	<td><cfif order_number NEQ 000>Order Number: #order_number#<cfelse>#thisnote# <span class="sub">Entered by #FLGen_GetAdminName(created_user_ID)#</span></cfif></td>
	</tr>
	</cfloop>
	<cfset ProgramUserInfo(puser_ID)>
	<tr class="content">
	<td align="right" class="headertext" colspan="2">#user_totalpoints#</td>
	<cfif request.has_divisions>
	<td class="headertext">&nbsp;</td>
	</cfif>
	<cfif FLGen_HasAdminAccess(1000000047)>
	<td class="headertext">&nbsp;</td>
	</cfif>
	<td class="headertext">TOTAL POINTS</td>
	</tr>
	
	<tr class="content">
	<td align="right" colspan="2"><span class="sub">#user_deferedpoints#</span></td>
	<cfif request.has_divisions>
	<td class="headertext">&nbsp;</td>
	</cfif>
	<cfif FLGen_HasAdminAccess(1000000047)>
	<td class="headertext">&nbsp;</td>
	</cfif>
	<td><span class="sub">Deferred Points</span></td>
	</tr>
	
	<!--- subprogram point summary --->
	<cfif SelectSubprograms.RecordCount NEQ 0>
	
	<tr>
	<td colspan="4">&nbsp;</td>
	</tr>
	
	<tr>
	<td colspan="4"><span class="alert">The amounts below are ONLY used to determine billing and email blasts.  They are NOT used during the ordering process.</span><br><br>
	The negative adjustments to the subprogram points are done on the Subprogram Reports, not on this page.
	</td>
	</tr>

		<cfloop query="SelectSubprograms">

			<cfquery name="FindSubprogramPoints" datasource="#application.DS#">
				SELECT IFNULL(SUM(subpoints),0) AS subpoints
				FROM #application.database#.subprogram_points
				WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#"> 
					AND subprogram_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#subprogram_ID#">
			</cfquery>
			
			<cfquery name="GetSubpointHistory" datasource="#application.DS#">
				SELECT ID AS subpoint_ID, created_datetime, created_user_ID, subpoints 
				FROM #application.database#.subprogram_points
				WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
					AND subprogram_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#subprogram_ID#">
				ORDER BY created_datetime
			</cfquery>
			
			<cfif GetSubpointHistory.RecordCount GT 0>
			
	<tr>
	<td colspan="4">&nbsp;</td>
	</tr>
	
	<tr bgcolor="##D6EFF7">
	<td colspan="4" class="headertext">#subprogram_name# Points</td>
	</tr>
	
	<tr class="contenthead">
	<td class="headertext">Date&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
	<td class="headertext">Points&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
	<td class="headertext" align="center"><span class="tooltip" title="Click the X to remove that line item.">?</span></td>
	<td class="headertext" width="100%">Order Number/Inventory Note</td>
	</tr>
			
				<cfloop query="GetSubpointHistory">
				
	<tr class="content">
	<td>#FLGen_DateTimeToDisplay(created_datetime)#</td>
	<td align="right">#subpoints#</td>
	<td class="headertext" align="center"><cfif subpoints LTE 0><a href="#CurrentPage#?delete=#subpoint_ID#&user_ID=#puser_ID#" onclick="return confirm('Are you sure you want to delete this line item?  There is NO UNDO.')">X</a><cfelse>&nbsp;</cfif></td>
	<td><span class="sub">Entered by #FLGen_GetAdminName(created_user_ID)#</span></td>
	</tr>
		
				</cfloop>
			
	<tr class="content">
	<td align="right" class="headertext" colspan="2">#FindSubprogramPoints.subpoints#</td>
	<td class="headertext">&nbsp;</td>
	<td class="headertext">TOTAL SUBPOINTS</td>
	</tr>

			</cfif>
		
		</cfloop>

	</cfif>
	
	</table>

	</cfoutput>
	
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->