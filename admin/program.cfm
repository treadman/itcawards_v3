<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">
<cfparam name="delete" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="program">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="OnPage" default="">

<!--- param a/e form fields --->
<cfparam  name="pgfn" default="list">

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfset has_program = false>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- massage form data --->
	<cfif orders_from EQ "">
		<cfset orders_from = Application.DefaultEmailFrom>
	</cfif>
	<!--- update --->
	<cfif form.ID IS NOT "" AND pgfn EQ "edit">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.program
			SET	#FLGen_UpdateModConcatSQL()#
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelse>
		<cflock name="programLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.program
						(created_user_ID, created_datetime, can_defer, defer_msg, logo, cross_color, main_bg, main_congrats, main_instructions, return_button, text_active, bg_active, text_selected, bg_selected, cart_exceeded_msg, cc_exceeded_msg, orders_to, orders_from, conf_email_text, program_email_subject, display_col, display_row, menu_text, credit_desc, accepts_cc, login_prompt, display_welcomeyourname, display_youhavexcredits, credit_multiplier, points_multiplier)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 		
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#can_defer#" maxlength="1">, 
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#defer_msg#"  null="#YesNoFormat(NOT Len(Trim(logo)))#">,  
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#logo#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(logo)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cross_color#" maxlength="6" null="#YesNoFormat(NOT Len(Trim(cross_color)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#main_bg#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(main_bg)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#main_congrats#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(main_congrats)))#">, 
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#main_instructions#" null="#YesNoFormat(NOT Len(Trim(main_instructions)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#return_button#" maxlength="30">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text_active#" maxlength="6">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bg_active#" maxlength="6">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#text_selected#" maxlength="6">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#bg_selected#" maxlength="6">, 
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#cart_exceeded_msg#">, 
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#cc_exceeded_msg#" null="#YesNoFormat(NOT Len(Trim(cc_exceeded_msg)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#orders_to#" maxlength="128">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#orders_from#" maxlength="64">,
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#conf_email_text#" null="#YesNoFormat(NOT Len(Trim(conf_email_text)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#program_email_subject#" maxlength="50">, 
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#display_col#" maxlength="2">, 
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#display_row#" maxlength="2">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#menu_text#" maxlength="40">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#credit_desc#" maxlength="40">, 
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#accepts_cc#" maxlength="1">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#login_prompt#" maxlength="120">, 
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#display_welcomeyourname#" maxlength="1">,
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#display_youhavexcredits#" maxlength="1">,
						<cfqueryparam cfsqltype="cf_sql_float" value="#credit_multiplier#" scale="2">,
						<cfqueryparam cfsqltype="cf_sql_float" value="#points_multiplier#" scale="2">
					)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.program
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfset pgfn = "edit">
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000051)>
	<cfquery name="DeleteGroup" datasource="#application.DS#">
		DELETE FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<SCRIPT LANGUAGE="JavaScript"><!-- 
function openURL() { 
	// grab index number of the selected option
	selInd = document.pageform.pageselect.selectedIndex; 
	// get value of the selected option
	goURL = document.pageform.pageselect.options[selInd].value;
	// redirect browser to the grabbed value (hopefully a URL)
	top.location.href = goURL; 
}
//--></SCRIPT>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfif pgfn EQ "list">

	<cflocation url="program_list.cfm" addtoken="no">

<cfelseif pgfn EQ "add"><!---  OR pgfn EQ "edit" OR pgfn EQ "copy" --->
	<span class="alert">This isn't used!</span>
	<!--- I don't believe there is any "edit" or "copy" here.  Copy makes a copy then cflocates to program_details.cfm where all edits take place. --->
<cfelse>
	<span class="alert">pgfn = <cfoutput>#pgfn#</cfoutput> not used here!</span>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->