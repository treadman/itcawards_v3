<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000016-1000000083",true)>

<cfparam name="action" default="">
<cfparam name="report" default="">

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<cfif has_program>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit1') OR IsDefined('form.Submit2')>
	<cfset action_clause = " ">
	<cfset action_clause2 = " ">
	<cfif action NEQ "">
		<cfset action_clause = ' AND action = "#action#" '>
		<cfset action_clause2 = ' AND s.action = "#action#" '>
	</cfif>
	<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
	<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
</cfif>

<!--- Survey Report --->
<cfif IsDefined('form.Submit1')>
	<cfset report = "survey">
	<cfquery name="Report1" datasource="#application.DS#">
		SELECT COUNT(ID) AS total_response
		FROM #application.database#.survey 
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#' 
			#action_clause#
	</cfquery>
	<cfset total_response = Report1.total_response>
	<cfquery name="Report2" datasource="#application.DS#">
		SELECT COUNT(ID) AS nav1 
		FROM #application.database#.survey 
		WHERE navigation = 1 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#'  
			#action_clause#
	</cfquery>
	<cfset nav1 = Report2.nav1>
	<cfquery name="Report3" datasource="#application.DS#">
		SELECT COUNT(ID) AS nav2
		FROM #application.database#.survey 
		WHERE navigation = 2 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#'  
			#action_clause#
	</cfquery>
	<cfset nav2 = Report3.nav2>
	<cfquery name="Report4" datasource="#application.DS#">
		SELECT COUNT(ID) AS nav3 
		FROM #application.database#.survey 
		WHERE navigation = 3 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#' 
			#action_clause#
	</cfquery>
	<cfset nav3 = Report4.nav3>
	<cfquery name="Report5" datasource="#application.DS#">
		SELECT COUNT(ID) AS nav4 
		FROM #application.database#.survey 
		WHERE navigation = 4 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#' 
			#action_clause# 
	</cfquery>
	<cfset nav4 = Report5.nav4>
	<cfquery name="Report6" datasource="#application.DS#">
		SELECT COUNT(ID) AS nav5 
		FROM #application.database#.survey 
		WHERE navigation = 5 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#'  
			#action_clause#
	</cfquery>
	<cfset nav5 = Report6.nav5>
	<cfquery name="Report7" datasource="#application.DS#">
		SELECT COUNT(ID) AS sel1 
		FROM #application.database#.survey 
		WHERE selection = 1 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#'  
			#action_clause#
	</cfquery>
	<cfset sel1 = Report7.sel1>
	<cfquery name="Report8" datasource="#application.DS#">
		SELECT COUNT(ID) AS sel2 
		FROM #application.database#.survey 
		WHERE selection = 2 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#'  
			#action_clause#
	</cfquery>
	<cfset sel2 = Report8.sel2>
	<cfquery name="Report9" datasource="#application.DS#">
		SELECT COUNT(ID) AS sel3 
		FROM #application.database#.survey 
		WHERE selection = 3 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#'  
			#action_clause#
	</cfquery>
	<cfset sel3 = Report9.sel3>
	<cfquery name="Report10" datasource="#application.DS#">
		SELECT COUNT(ID) AS sel4 
		FROM #application.database#.survey 
		WHERE selection = 4 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#'  
			#action_clause#
	</cfquery>
	<cfset sel4 = Report10.sel4>
	<cfquery name="Report11" datasource="#application.DS#">
		SELECT COUNT(ID) AS sel5 
		FROM #application.database#.survey 
		WHERE selection = 5 
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND created_datetime >= '#formatFromDate#' AND created_datetime <= '#formatToDate#'  
			#action_clause#
	</cfquery>
	<cfset sel5 = Report11.sel5>
<!--- Comment Report --->
<cfelseif IsDefined('form.Submit2')>
	<cfset report = "comment">
	<cfquery name="GetComments" datasource="#application.DS#">
		SELECT up.fname, up.lname, s.note 
		FROM #application.database#.survey s
		JOIN #application.database#.program_user up ON s.created_user_ID = up.ID
		WHERE s.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND s.created_datetime >= '#formatFromDate#' 
			AND s.created_datetime <= '#formatToDate#'
			AND Trim(s.note) <> '' 
			#action_clause2#
	</cfquery>	
</cfif>

<!--- set search parameters if not submitted --->
<cfif NOT IsDefined('form.Submit2') AND  NOT IsDefined('form.Submit1')>
	<!--- find the first and last survey for this program and set as from and to dates --->
	<cfquery name="GetDates" datasource="#application.DS#">
		SELECT MIN(created_datetime) as FromDate, MAX(created_datetime) as ToDate
		FROM #application.database#.survey
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfif GetDates.FromDate NEQ "" AND GetDates.ToDate NEQ "">
		<cfset FromDate =  FLGen_DateTimeToDisplay(GetDates.FromDate)>
		<cfset ToDate = FLGen_DateTimeToDisplay(GetDates.ToDate)>
	</cfif>
</cfif>

<!--- find the actions for this program to create the dropdown --->
	<!--- only create the dropdown if more than one action --->
<cfquery name="GetSurveyAction" datasource="#application.DS#">
	SELECT DISTINCT action AS selectaction
	FROM #application.database#.survey
	WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
</cfquery>

</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "report_survey">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Survey Report</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>
<cfoutput>
<span class="pagetitle">Survey Report for #request.program_name#</span>
<br /><br />
<cfif GetSurveyAction.RecordCount NEQ 0>
<span class="pageinstructions">The dates of this award program's first and last survey are automatically entered </span><br />
<span class="pageinstructions">into the From and To Dates when the page loads. You may change these dates.</span>
<br /><br />
</cfif>
<cfif GetSurveyAction.RecordCount EQ 0>
	<span class="pageinstructions"><span class="alert">This Award Program has no surveys.</span></span>
</cfif>
<br /><br />
</cfoutput>

<cfif GetSurveyAction.RecordCount NEQ 0>

	<!--- search box (START) --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td><span class="headertext">Generate Survey Report</span></td>
	</tr>
		
	<tr>
	<td class="content" align="center">
		<cfoutput>
		<form action="#CurrentPage#" method="post">
			From Date: <input type="text" name="FromDate" value="#FromDate#" size="12">
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			To Date: <input type="text" name="ToDate" value="#ToDate#" size="12">
			<cfif GetSurveyAction.RecordCount EQ 1>
				<input type="hidden" name="action" value="">
			<cfelse>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
				Action:  
				<select name="action">
					<option value=""<cfif action EQ ""> selected</cfif>>All Actions</option>
					<cfloop query="GetSurveyAction">
						<option value="#selectaction#"<cfif selectaction EQ action> selected</cfif>>#selectaction#</option>
					</cfloop>
				</select>
					
			</cfif>
					
			<br><br>

			<input type="submit" name="submit1" value="Generate Report">
			<input type="submit" name="submit2" value="Display Comments">
		</form>
		</cfoutput>
	</td>
	</tr>
	
	</table>
	<!--- search box (END) --->
	
	<br />
	<br />
	
	<!--- **************** --->
	<!--- if survey report --->
	<!--- **************** --->
	
	<cfif report EQ "survey">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">

<!--- header row --->
<cfoutput>
	<tr class="content2">
	<td  colspan="3"><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span></td>
	</tr>

	<tr class="contenthead">
	<td class="headertext" colspan="3">How would you rate the NAVIGATION of this website?</td>
	</tr>

	<tr class="content2">
	<td align="right">Rating</td>
	<td align="right">Total</td>
	<td align="right">Percent</td>
	</tr>

	<tr class="content">
	<td align="right"><span class="sub">[best]</span> <b>5</b></td>
	<td align="right">#nav5#</td>
	<td align="right" >#NumberFormat((nav5 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right"><b>4</b></td>
	<td align="right">#nav4#</td>
	<td align="right">#NumberFormat((nav4 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right"><b>3</b></td>
	<td align="right">#nav3#</td>
	<td align="right">#NumberFormat((nav3 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right"><b>2</b></td>
	<td align="right">#nav2#</td>
	<td align="right">#NumberFormat((nav2 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right"><span class="sub">[worst]</span> <b>1</b></td>
	<td align="right">#nav1#</td>
	<td align="right">#NumberFormat((nav1 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right">&nbsp;</td>
	<td align="right"><b>#total_response#</b></td>
	<td colspan="2"><b>Total Responses</b></td>
	</tr>
	
<!--- 	<tr>
	<td colspan="3" align="center">
		<cfoutput>
			<cfchart 
				format="jpg"
				showborder="yes"
				chartHeight="125"    
				chartWidth="450"  
				show3d="yes"
				pieSliceStyle="solid" >
				
				<cfchartseries type="pie" colorlist="ff6600, ff9955, ffb888, ffe0cc, ffffff">
				
					<cfchartdata item="Response 5 (best)" value="#nav5#">
					<cfchartdata item="Response 4" value="#nav4#">
					<cfchartdata item="Response 3" value="#nav3#">
					<cfchartdata item="Response 2" value="#nav2#">
					<cfchartdata item="Response 1 (worst)" value="#nav1#">
					
				</cfchartseries>
			</cfchart>
		</cfoutput>
	</td>
	</tr>
 --->
	<tr class="contenthead">
	<td class="headertext" colspan="3">How would you rate the PRODUCT SELECTION?</td>
	</tr>

	<tr class="content2">
	<td align="right">Rating</td>
	<td align="right">Total</td>
	<td align="right">Percent</td>
	</tr>

	<tr class="content">
	<td align="right"><span class="sub">[best]</span> <b>5</b></td>
	<td align="right">#sel5#</td>
	<td align="right">#NumberFormat((sel5 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right"><b>4</b></td>
	<td align="right">#sel4#</td>
	<td align="right">#NumberFormat((sel4 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right"><b>3</b></td>
	<td align="right">#sel3#</td>
	<td align="right">#NumberFormat((sel3 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right"><b>2</b></td>
	<td align="right">#sel2#</td>
	<td align="right">#NumberFormat((sel2 / total_response) * 100,9999.99)#%</td>
	</tr>

	<tr class="content">
	<td align="right"><span class="sub">[worst]</span> <b>1</b></td>
	<td align="right">#sel1#</td>
	<td align="right">#NumberFormat((sel1 / total_response) * 100,9999.99)#%</td>
	</tr>
	
	<tr class="content">
	<td align="right">&nbsp;</td>
	<td align="right"><b>#total_response#</b></td>
	<td colspan="2"><b>Total Responses</b></td>
	</tr>

<!--- 	<tr>
	<td colspan="3" align="center">
		<cfoutput>
		
			<cfchart 
				format="jpg"
				showborder="yes"
				xaxistitle="Response Number" 
				yaxistitle="Number of Users" 
				show3d="yes"
				pieSliceStyle="solid" 
				gridlines="#Max(Max(Max(Max(sel5,sel4),sel3),sel2),sel1) + 1#"
				 showxgridlines="no">
				
				<cfchartseries type="bar" seriescolor="ff6600" paintstyle="light">
				
					<cfchartdata item="5" value="#sel5#">
					<cfchartdata item="4" value="#sel4#">
					<cfchartdata item="3" value="#sel3#">
					<cfchartdata item="2" value="#sel2#">
					<cfchartdata item="1" value="#sel1#">
					
				</cfchartseries>
			</cfchart>
		</cfoutput>
	</td>

	</tr>
 --->	
	<tr>
	<td><img src="../pics/shim.gif" width="60" height="1"></td>
	<td><img src="../pics/shim.gif" width="50" height="1"></td>
	<td><img src="../pics/shim.gif" width="50" height="1"></td>
	</tr>

	
</cfoutput>

	</table>
	
	<!--- ***************** --->
	<!--- if comment report --->
	<!--- ***************** --->

	<cfelseif report EQ "comment">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">

<!--- header row --->
<cfoutput>
	<tr class="content2">
	<td><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;#GetComments.RecordCount# Comments Total</td>
	</tr>
</cfoutput>

	<tr class="contenthead">
	<td class="headertext">Please give us your suggestions for website enhancements and/or product offerings.</td>
	</tr>
	
	<cfset nocomments = "true">
		
	<cfoutput query="GetComments">
	
		<cfif Trim(HTMLEditFormat(note)) NEQ "">

	<tr class="content">
	<td><b>#fname# #lname#</b><br />#Replace(HTMLEditFormat(note),chr(10),"<br>","ALL")#</td>
	</tr>
	
		<cfset nocomments = "false">
		
		</cfif>

	</cfoutput>
	
		<cfif nocomments>

	<tr class="content">
	<td align="center"><span class="alert">No comments were submitted with the surveys.</span></td>
	</tr>
			
		</cfif>
		
	</table>

	</cfif>

</cfif>
</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->