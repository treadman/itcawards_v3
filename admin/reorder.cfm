<cfspreadsheet action="read" src="upload/fortune.xlsx" query="fortune">

<cfset db = "ITCAwards_v3">
<cfset count = 1>
<cfloop query="fortune">
	<cfif fortune.col_3 NEQ "email" AND fortune.col_9 NEQ "" AND fortune.col_10 NEQ "">
		<cfoutput>#count#) #fortune.col_6#</cfoutput>
		<cfquery name="GetOrder" datasource="#application.DS#">
			SELECT i.ID, i.snap_meta_name, i.snap_options
			FROM #db#.order_info o
			LEFT JOIN #db#.inventory i on i.order_ID = o.id
			WHERE o.order_number = #fortune.col_6#
			AND o.program_ID = 1000000124
		</cfquery>
		<cfif GetOrder.snap_meta_name NEQ fortune.col_7 OR GetOrder.snap_options NEQ fortune.col_8>
			<cfdump var="#GetOrder#">
			<cfabort>
		</cfif>
		<cfoutput>Change #fortune.col_7# to #fortune.col_9#, and #fortune.col_8# to #fortune.col_10#</cfoutput>
		<br><br>
		<cfquery name="UpdateOrder" datasource="#application.DS#">
			UPDATE #db#.inventory
			SET snap_meta_name = '#fortune.col_9#',snap_options = '#fortune.col_10#'
			WHERE id = #GetOrder.id#
		</cfquery>
		<cfset count = count + 1>
	</cfif>
</cfloop>

<br><br>
--- done ---