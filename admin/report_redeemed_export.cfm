<cfsetting enablecfoutputonly="yes" showdebugoutput="no">

<!--- ***************** --->
<!--- page variables    --->
<!--- ***************** --->
<cfset TC = Chr(9)> <!--- Tab Char --->
<cfset NL = Chr(13) & Chr(10)> <!--- New Line --->
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">

<cfcontent type="application/msexcel">
<cfheader name="Content-Disposition" value="filename=redeemed_report.xls">

<!---<cfset merged_id = 0>
<cfset merged_db = application.database>
<cfif left(request.program.merged_from,5) EQ 'www2:'>
	<cfset merged_id = mid(request.program.merged_from,6,10)>
	<cfset merged_db = "ITCAwards">
</cfif>--->

<cfquery name="ReportRedeemed" datasource="#application.DS#">
	SELECT Date_Format(o.created_datetime,'%Y%m%d') AS order_date, p.username, p.badge_id, p.lname,
		<cfif request.selected_division_ID GT 0>
			x.award_points AS points_used
		<cfelse>
			o.points_used
		</cfif>
	FROM #application.database#.order_info o
	<cfif request.selected_division_ID GT 0>
		INNER JOIN #application.database#.xref_order_division x ON x.order_ID = o.ID
	</cfif>
	LEFT JOIN #application.database#.program_user p ON o.created_user_ID = p.ID
	WHERE o.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
	<cfif request.selected_division_ID GT 0>
		AND x.division_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_division_ID#" maxlength="10">
	</cfif>
	AND o.is_valid = '1'
	AND o.points_used > 0 
	<cfif formatFromDate NEQ "">
		AND o.created_datetime >= '#formatFromDate#' 
	</cfif>	
	<cfif formatToDate NEQ "">
		AND o.created_datetime <= '#formatToDate#' 
	</cfif>
	ORDER BY order_date ASC 
</cfquery>

<cfquery name="GetMultiplier" datasource="#application.DS#">
	SELECT points_multiplier 
	FROM #application.database#.program
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
</cfquery>
	
<cfset multiplier = GetMultiplier.points_multiplier>

<cfoutput>PIN#TC#Points Redeemed#TC#Points Redeemed Date#TC#Last Name#NL#<cfloop query="ReportRedeemed"><!--- TODO:  This is another ITG hack:  Ugh!!!  Keep these to a minimum! ---><cfif trim(badge_id) NEQ "">#badge_id#<cfelse>#username#</cfif>#TC##points_used * multiplier##TC##order_date##TC##lname##NL#</cfloop></cfoutput>

