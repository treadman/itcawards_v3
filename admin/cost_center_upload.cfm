<cfsetting requesttimeout="300" >

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>


<cfparam name="pgfn" default="upload">
<cfparam name="uses_cost_center" default="2">

<cfset errors_found = false>
<cfset alert_msg = "">
<cfset DeleteResults = "">
<cfset DisplayResults = "">
<cfset do_import = false>
<cfset willbe = "will be">
<cfset thisFileName = "upload_ccs#Replace(CGI.REMOTE_ADDR,'.','','ALL')#">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif CGI.REQUEST_METHOD EQ 'POST'>

	<cfif isDefined("form.submitUpload")>
		<cfif not isDefined("form.update_type")>
			<cfset alert_msg = "Please select Replace or Update.">
			<cfset pgfn = "upload">
		<cfelse>
			<cfset new_name = "">
			<cftry>
				<cfset results = FLGen_UploadThis("file_name","admin/upload/",thisFileName)>
				<cfset original = ListGetAt(results,1,",")>
				<cfset new_name = ListGetAt(results,2,",")>
				<cfcatch>
					<cfset alert_msg = "Error uploading file.">
					<cfset pgfn = "upload">
				</cfcatch>
			</cftry>
			
			<cfif new_name NEQ "">
				<!--- read the newly uploaded file --->
				<cffile action="read" file="#Application.FilePath#admin/upload/#new_name#" variable="the_file" />
				<!--- if the file is not a csv file, show an error message--->
				<cfif CFFILE.CLIENTFILEEXT NEQ 'csv'>
					<cfset FLGen_DeleteThisFile(new_name,"admin/upload/")>
					<cfset alert_msg = original & " is not a CSV file.">
					<cfset pgfn = "upload">
				<cfelse>
					<cfset pgfn = "import">
				</cfif>
			</cfif>
		</cfif>	
	</cfif>	
	
	<cfif isDefined("form.importCostCenters")>
		<cfset do_import = true>
		<cfset willbe = "">
		<cfset pgfn = "import">
	</cfif>

</cfif>


<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Upload Cost Centers</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<span class="pagetitle">
	Upload Cost Centers to <cfoutput>#request.program_name#</cfoutput> &nbsp;&nbsp;&nbsp;&nbsp;
	<cfif pgfn NEQ "upload">
		<a href="<cfoutput>#CurrentPage#</cfoutput>">Start Over</a>
	</cfif>
</span>
<br /><br />
<span class="pageinstructions">Return to <a href="cost_centers.cfm">Cost Center List</a> or <a href="program_list.cfm">Award Program List</a></span>
<br><br>

<cfif pgfn EQ "upload">
	<cfset FLGen_DeleteThisFile("#thisFileName#.csv","admin/upload/")>
	<!--- Page Title --->
	<span class="pageinstructions">
		The spreadsheet must be saved in CSV format.<br /><br />
	</span>
	<span class="pageinstructions">
		The file must have the following columns, in this order:<br><br>
		<div style="padding-left:10px; font-weight:bold;">
			Employee ID, Last Name, First Name, Email, CC Code, CC Description, MGR Last Name,<br>MGR First Name, MGR Email, MC Last Name, MC First Name, MC Email
		</div>
	</span>
	<br />
	<span class="pageinstructions">
	Before uploading the spreadsheet, please save it in the proper format.<br>
	<ol>
		<li>Open the file in Excel.</li>
		<li class="alert">Search for and remove all commas.</li>
		<li>Save the file as a comma-separated values (csv) file.
			<ul type="disc">
				<li>Click "File" (or Office Button in Office 2007) then "Save As".</li>
				<li>In the "Save As" dialog window, under the "File name" input field is a drop-down select box for "Save as type:".</li>
				<li>Scroll down to select the "CSV (Comma Delimited) (*.csv)" option.</li>
				<li>If the xls file has more than one worksheet you will get a window asking "The selected file type does not support ... multiple worksheets."  Click "OK".</li>
				<li>Then you'll probably get a message saying "export...csv may contain features that are incompatible..."  Click "Yes"</li>
			</ul>
		</li>
		<li>When you close Excel or close the file, Excel asks again to save the file.  There is no need to do this, so click "No".</li>
	</ol>
	</span>
	
	<form method="post" action="<cfoutput>#CurrentPage#</cfoutput>" name="uploadSpreadsheet" enctype="multipart/form-data">
		<b>Replace ALL</b> or <b>Simple Update</b>:<br><br>
		<input type="radio" name="update_type" value="replace"> Replace all current information with the contents of the uploaded spreadsheet.<br><br>
		<input type="radio" name="update_type" value="update"> Update / Add users from the uploaded spreadsheet, leaving everything else alone.<br><br><br>
		<input name="file_name" type="file" size="48" value=""><br><br><br>
		<input type="submit" name="submitUpload" value="  Upload  " >
	</form>
<cfelseif pgfn EQ "import">
	<cfset hasFile = true>
	<cftry>
		<cffile action="read" variable="thisData" file="#application.FilePath#admin/upload/#thisFileName#.csv">
		<cfcatch><cfset hasFile = false></cfcatch>
	</cftry>
	<cfif hasFile>
		<cfset thisData = Replace(thisData,"#CHR(13)##CHR(10)#","|","ALL")>
		<!---<cfset DeleteResults = '<table width="100%" cellpadding="3" cellspacing="0">'>--->
		<cfset DisplayResults = '<table width="100%" cellpadding="3" cellspacing="0"><tr class="contenthead"><td>1</td><td class="headertext">Emp ID</td><td class="headertext">Name</td><td class="headertext">Email</td><td class="headertext">Notes</td><tr>'>
		<cfset thisClass = "content">
		<cfset rownum = 1>
		
		<cfif isDefined("form.saveUpdateDate")>
			<cfset updateDate = form.saveUpdateDate>
		<cfelse>
			<cfset updateDate = DateFormat(Now(),"yyyy-mm-dd") & " " & TimeFormat(Now(),"HH:mm:ss")> <!---FLGen_DateTimeToMySQL()>--->
		</cfif>
		<!---<br>
		|<cfoutput>#updateDate#</cfoutput>|
		<br><br>--->
		<cfswitch expression="#form.update_type#">
			<cfcase value="replace">







				<cfloop list="#thisData#" index="thisLine" delimiters="|">
					<cfset this_user_ID = "">
					<cfif rownum GT 1>
						<cfset thisClass = Iif(rownum MOD 2 EQ 1,de('content'),de('content2'))>
						<cfif ListLen(thisLine) NEQ 12>
							<cfset errors_found = true>
							<cfset DisplayResults = DisplayResults & '<tr class="#thisClass#"><td>#rownum#</td><td colspan="4" class="alert">This line may have commas or has missing or extra data.</td></tr>'>
						<cfelse>
							<cfset thisNotes = "">
							<cfset thisEmployeeID = ListGetAt(thisLine,1)>
							<cfset thisLastName = ListGetAt(thisLine,2)>
							<cfset thisFirstName = ListGetAt(thisLine,3)>
							<cfset thisEmail = ListGetAt(thisLine,4)>
							<cfset thisCCCode = ListGetAt(thisLine,5)>
							<cfset thisCCDesc = ListGetAt(thisLine,6)>
							<cfset thisMgrLast = ListGetAt(thisLine,7)>
							<cfset thisMgrFirst = ListGetAt(thisLine,8)>
							<cfset thisMgrEmail = ListGetAt(thisLine,9)>
							<cfset thisMcLast = ListGetAt(thisLine,10)>
							<cfset thisMcFirst = ListGetAt(thisLine,11)>
							<cfset thisMcEmail = ListGetAt(thisLine,12)>
							<cfset DisplayResults = DisplayResults & '<tr class="#thisClass#"><td>#rownum#</td><td>#thisEmployeeID#</td><td>#thisLastName#, #thisFirstName#</td><td>#thisEmail#</td>'>
							<cfif trim(thisEmployeeID) EQ ''
								OR trim(thisLastName) EQ ''
								OR trim(thisFirstName) EQ ''
								OR trim(thisEmail) EQ ''
								OR trim(thisCCCode) EQ ''
								OR trim(thisCCDesc) EQ ''
								OR trim(thisMgrLast) EQ ''
								OR trim(thisMgrFirst) EQ ''
								OR trim(thisMgrEmail) EQ ''
								OR trim(thisMcLast) EQ ''
								OR trim(thisMcFirst) EQ ''
								OR trim(thisMcEmail) EQ ''
							>
								<cfset errors_found = true>
								<cfset thisNotes = thisNotes & '<span class="alert">Some fields are blank.</span><br>'>
							</cfif>
							<cfif not errors_found>
								<cfif NOT FLGen_IsValidEmail(thisEmail)>
									<cfset errors_found = true>
									<cfset thisNotes = thisNotes & '<span class="alert">#thisEmail# is not a valid email address.</span><br>'>
								</cfif>
								<cfif NOT FLGen_IsValidEmail(thisMgrEmail)>
									<cfset errors_found = true>
									<cfset thisNotes = thisNotes & '<span class="alert">#thisMgrEmail# is not a valid email address for Level 1 approver.</span><br>'>
								</cfif>
								<cfif NOT FLGen_IsValidEmail(thisMcEmail)>
									<cfset errors_found = true>
									<cfset thisNotes = thisNotes & '<span class="alert">#thisMcEmail# is not a valid email address for Level 2 approver.</span><br>'>
								</cfif>
							</cfif>
							<cfif not errors_found>
								<cfquery name="GetCostCenterUser" datasource="#application.DS#">
									SELECT
										t.ID,
										u.ID as user_ID,
										u.program_ID,
										t.employeeID,
										t.lastname,
										t.firstname,
										t.email,
										t.cc_code,
										t.cc_desc,
										t.mgr_lastname,
										t.mgr_firstname,
										t.mgr_email,
										t.mc_lastname,
										t.mc_firstname,
										t.mc_email
									FROM #application.database#.cost_center_user t
									LEFT JOIN #application.database#.program_user u ON u.email = t.email
									WHERE TRIM(t.email) = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">
									AND t.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
								</cfquery>
								<cfif GetCostCenterUser.recordcount EQ 1>
									<cfset this_user_ID = GetCostCenterUser.user_ID>
									<cfset thisNotes = thisNotes & "Cost Center user already uploaded<br>">
									<cfif GetCostCenterUser.program_ID NEQ '' AND GetCostCenterUser.program_ID neq request.selected_program_ID>
										<cfset errors_found = true>
										<cfset thisNotes = thisNotes & '<span class="alert">#thisEmail# is in a different program!!</span><br>'>
									<cfelse>
										<cfif GetCostCenterUser.user_ID EQ "">
											<cfset thisNotes = thisNotes & "User has not registered yet<br>">
										<cfelse>
											<cfset thisNotes = thisNotes & "User has registered<br>">
										</cfif>
										<cfif GetCostCenterUser.employeeID NEQ thisEmployeeID
											OR GetCostCenterUser.lastname NEQ thisLastName
											OR GetCostCenterUser.firstname NEQ thisFirstName
											OR GetCostCenterUser.cc_code NEQ thisCCCode
											OR GetCostCenterUser.cc_desc NEQ thisCCDesc
											OR GetCostCenterUser.mgr_lastname NEQ thisMgrLast
											OR GetCostCenterUser.mgr_firstname NEQ thisMgrFirst
											OR GetCostCenterUser.mgr_email NEQ thisMgrEmail
											OR GetCostCenterUser.mc_lastname NEQ thisMcLast
											OR GetCostCenterUser.mc_firstname NEQ thisMcFirst
											OR GetCostCenterUser.mc_email NEQ thisMcEmail
										>
											<cfif do_import>
												<cfquery name="UpdateCCUser" datasource="#application.DS#">
													UPDATE #application.database#.cost_center_user
													SET employeeID = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisEmployeeID#">,
														lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisLastName#">,
														firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisFirstName#">,
														cc_code = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisCCCode#">,
														cc_desc = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisCCDesc#">,
														mgr_lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrLast#">,
														mgr_firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrFirst#">,
														mgr_email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrEmail#">,
														mc_lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcLast#">,
														mc_firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcFirst#">,
														mc_email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcEmail#">
													WHERE TRIM(email) = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">
												</cfquery>
											</cfif>
										</cfif>
										<cfif NOT do_import>
											<cfquery name="UpdateCCUser" datasource="#application.DS#">
												UPDATE #application.database#.cost_center_user
												SET updated = '#updateDate#'
												WHERE TRIM(email) = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">
											</cfquery>
										</cfif>
									</cfif>
								<cfelseif GetCostCenterUser.recordcount GT 1>
									<cfset errors_found = true>
									<cfset thisNotes = thisNotes & '<span class="alert">#thisEmail# is duplicated!!</span><br>'>
								<cfelse>
									<cfif do_import>
										<!--- Look up the user --->
										<cfquery name="GetProgramUser" datasource="#application.DS#">
											SELECT ID
											FROM #application.database#.program_user
											WHERE email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">
											AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
										</cfquery>
										<cfif GetProgramUser.recordcount EQ 1>
											<cfset this_user_ID = GetProgramUser.ID>
										</cfif>
										<cfquery name="AddCCUser" datasource="#application.DS#">
											INSERT INTO #application.database#.cost_center_user (
												program_ID,
												employeeID,
												lastname,
												firstname,
												email,
												cc_code,
												cc_desc,
												mgr_lastname,
												mgr_firstname,
												mgr_email,
												mc_lastname,
												mc_firstname,
												mc_email
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisEmployeeID#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisLastName#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisFirstName#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisCCCode#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisCCDesc#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrLast#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrFirst#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMgrEmail#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcLast#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcFirst#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMcEmail#">
											)
										</cfquery>
									</cfif>
									<cfset thisNotes = thisNotes & "Cost Center user #willbe# uploaded<br>">
								</cfif>
								<!---Look up cost center--->
								<cfset this_cc_ID = 0>
								<cfquery name="GetCostCenter" datasource="#application.DS#">
									SELECT ID, description
									FROM #application.database#.cost_centers
									WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" maxlength="10" value="#request.selected_program_ID#">
									AND number = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="5" value="#thisCCCode#">
								</cfquery>
								<cfif GetCostCenter.recordcount EQ 1>
									<cfset this_cc_ID = GetCostCenter.ID>
									<cfif GetCostCenter.description EQ thisCCDesc>
										<cfset thisNotes = thisNotes & "Cost Center #thisCCCode# exists<br>">
									<cfelse>
										<cfif do_import>
											<cfquery name="UpdateCostCenter" datasource="#application.DS#">
												UPDATE #application.database#.cost_centers
												SET description = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="64" value="#thisCCDesc#">
												WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_cc_ID#">
											</cfquery>
										</cfif>
										<cfset thisNotes = thisNotes & "Cost Center #thisCCCode# #willbe# updated with new description<br>">
									</cfif>
									<cfif NOT do_import>
										<cfquery name="UpdateCostCenter" datasource="#application.DS#">
											UPDATE #application.database#.cost_centers
											SET updated = '#updateDate#'
											WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_cc_ID#">
										</cfquery>
									</cfif>
								<cfelse>
									<cfif do_import>
										<cfquery name="AddCostCenter" datasource="#application.DS#" result="stResult">
											INSERT INTO #application.database#.cost_centers (
												created_user_ID,
												created_datetime,
												program_ID,
												number,
												description
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
												NOW(),
												<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="5" value="#thisCCCode#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="64" value="#thisCCDesc#">
											)
										</cfquery>
										<cfset this_cc_ID = stResult.GENERATED_KEY>
									</cfif>
									<cfset thisNotes = thisNotes & "Cost Center #thisCCCode# #willbe# uploaded<br>">
								</cfif>
								<!--- Look up mgr email in admin_users --->
								<cfquery name="GetMgrProgramUser" datasource="#application.DS#">
									SELECT username
									FROM #application.database#.program_user
									WHERE email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMgrEmail#">
									AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
								</cfquery>
								<cfset this_mgr_ID = 0>
								<cfset this_mgr_username = thisMgrEmail><!---ListFirst(thisMgrEmail,'@')--->
								<cfif GetMgrProgramUser.recordCount EQ 1>
									<cfset this_mgr_password = FLGen_CreateHash(GetMgrProgramUser.username)>
								<cfelse>
									<cfset this_mgr_password = "">
								</cfif>
								<cfquery name="GetMgr" datasource="#application.DS#">
									SELECT ID, firstname, lastname, email
									FROM #application.database#.admin_users
									WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_username#">
								</cfquery>
								<cfif GetMgr.recordCount EQ 1>
									<cfset this_mgr_ID = GetMgr.ID>
									<cfset thisNotes = thisNotes & "Level 1 Approver exists<br>">
									<cfif GetMgr.lastname NEQ thisMgrLast
										OR GetMgr.firstname NEQ thisMgrFirst
										OR GetMgr.email NEQ thisMgrEmail
									>
										<cfif do_import>
											<cfquery name="UpdateMgr" datasource="#application.DS#">
												UPDATE #application.database#.admin_users
												SET firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMgrFirst#">,
													lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMgrLast#">,
													email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMgrEmail#">
												WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_username#">
											</cfquery>
										</cfif>
									</cfif>
									<cfif NOT do_import>
										<cfquery name="UpdateMgr" datasource="#application.DS#">
											UPDATE #application.database#.admin_users
											SET updated = '#updateDate#'
											WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_username#">
										</cfquery>
									</cfif>
								<cfelse>
									<cfif do_import>
										<cfquery name="AddMgr" datasource="#application.DS#" result="stResult">
											INSERT INTO #application.database#.admin_users (
												created_user_ID,
												created_datetime,
												firstname,
												lastname,
												username,
												password,
												email,
												program_ID,
												is_active
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
												NOW(),
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMgrFirst#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMgrLast#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_username#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_password#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMgrEmail#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
												<cfif this_mgr_password EQ "">0<cfelse>1</cfif>
											)
										</cfquery>
										<cfset this_mgr_ID = stResult.GENERATED_KEY>
									</cfif>
									<cfset thisNotes = thisNotes & "Level 1 Approver #willbe# uploaded<br>">
								</cfif>
								<cfif do_import>
									<cftry>
										<cfquery name="AddMgrToCC" datasource="#application.DS#">
											INSERT INTO #application.database#.xref_cost_center_approvers
												(cost_center_ID, admin_user_ID, level)
											VALUES
												(#this_CC_ID#, #this_mgr_ID#, 1)
										</cfquery>
										<cfcatch></cfcatch>
									</cftry>
								</cfif>
								<!--- Look up mc email in admin_users and program_users --->
								<cfquery name="GetMCProgramUser" datasource="#application.DS#">
									SELECT username
									FROM #application.database#.program_user
									WHERE email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMcEmail#">
									AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
								</cfquery>
								<cfset this_mc_ID = 0>
								<cfset this_mc_username = thisMcEmail><!---ListFirst(thisMcEmail,'@')--->
								<cfif GetMCProgramUser.recordCount EQ 1>
									<cfset this_mc_password = FLGen_CreateHash(GetMCProgramUser.username)>
								<cfelse>
									<cfset this_mc_password = "">
								</cfif>
								<cfquery name="GetMc" datasource="#application.DS#">
									SELECT ID, firstname, lastname, email
									FROM #application.database#.admin_users
									WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_username#">
								</cfquery>
								<cfif GetMc.recordCount EQ 1>
									<cfset this_mc_ID = GetMc.ID>
									<cfset thisNotes = thisNotes & "Level 2 Approver exists<br>">
									<cfif GetMc.lastname NEQ thisMcLast
										OR GetMc.firstname NEQ thisMcFirst
										OR GetMc.email NEQ thisMcEmail
									>
										<cfif do_import>
											<cfquery name="UpdateMgr" datasource="#application.DS#">
												UPDATE #application.database#.admin_users
												SET firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMcFirst#">,
													lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMcLast#">,
													email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMcEmail#">
												WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_username#">
											</cfquery>
										</cfif>
									</cfif>
									<cfif NOT do_import>
										<cfquery name="UpdateMgr" datasource="#application.DS#">
											UPDATE #application.database#.admin_users
											SET updated = '#updateDate#'
											WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_username#">
										</cfquery>
									</cfif>
								<cfelse>
									<cfif do_import>
										<cfquery name="AddMc" datasource="#application.DS#" result="stResult">
											INSERT INTO #application.database#.admin_users (
												created_user_ID,
												created_datetime,
												firstname,
												lastname,
												username,
												password,
												email,
												program_ID,
												is_active
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
												NOW(),
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMcFirst#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMcLast#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_username#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_password#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMcEmail#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
												<cfif this_mc_password EQ "">0<cfelse>1</cfif>
											)
										</cfquery>
										<cfset this_mc_ID = stResult.GENERATED_KEY>
									</cfif>
									<cfset thisNotes = thisNotes & "Level 2 Approver #willbe# uploaded<br>">
								</cfif>
								<cfif do_import>
									<cftry>
										<cfquery name="AddMcToCC" datasource="#application.DS#">
											INSERT INTO #application.database#.xref_cost_center_approvers
												(cost_center_ID, admin_user_ID, level)
											VALUES
												(#this_CC_ID#, #this_mc_ID#, 2)
										</cfquery>
										<cfcatch></cfcatch>
									</cftry>
								</cfif>
								<cfif isNumeric(this_user_ID)>
									<cfif do_import>
										<cftry>
										<cfquery name="AddUserToCC" datasource="#application.DS#">
											INSERT INTO #application.database#.xref_cost_center_users
												(cost_center_ID, program_user_ID)
											VALUES
												(#this_CC_ID#, #this_user_ID#)
										</cfquery>
										<cfcatch></cfcatch></cftry>
										<cfquery name="UpdateUser" datasource="#application.DS#">
											UPDATE #application.database#.program_user
											SET uses_cost_center = <cfqueryparam cfsqltype="cf_sql_tinyint" maxlength="1" value="#uses_cost_center#">,
											    is_active = 1
											WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_user_ID#">
										</cfquery>
									</cfif>
								<cfelse>
									<cfset thisNotes = thisNotes & "User has not registered yet<br>">
								</cfif>
							</cfif>
							<cfset DisplayResults = DisplayResults & '<td>#thisNotes#</td></tr>'>
						</cfif>				
					</cfif>
					<cfset rownum = rownum + 1>
				</cfloop>

				<!--- Below is buggy...  Supposed to be busing some update flag, but it simply deletes them all.  --->	
				<!--- show admins --->
				<!---
				<cfquery name="GetAdmins" datasource="#application.DS#">
					SELECT ID, lastname, firstname
					FROM #application.database#.admin_users
					WHERE (updated != '#updateDate#' OR updated IS NULL)
					AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
				</cfquery>
				<cfif GetAdmins.recordcount GT 0>
					<cfset DeleteResults = DeleteResults & '<tr><td class="alert">Admin Users not Approvers in Cost Centers</td><td></td></tr>'>
					<cfloop query="GetAdmins">
						<cfset thisClass = Iif(rownum MOD 2 EQ 1,de('content'),de('content2'))>
						<cfset DeleteResults = DeleteResults & '<tr class="#thisClass#"><td>#GetAdmins.lastname#, #GetAdmins.firstname#</td><td></td></tr>'>
						<cfset rownum = rownum + 1>
					</cfloop>
				</cfif>
				--->				
				<!--- Delete cc users --->
				<!---
				<cfquery name="GetCostCenterUsers" datasource="#application.DS#">
					SELECT ID, lastname, firstname
					FROM #application.database#.cost_center_user
					WHERE (updated != '#updateDate#' OR updated IS NULL)
					AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
				</cfquery>
				<cfif GetCostCenterUsers.recordcount GT 0>
					<cfset DeleteResults = DeleteResults & '<tr><td class="alert">Delete CC Users</td><td></td></tr>'>
					<cfloop query="GetCostCenterUsers">
						<cfset thisClass = Iif(rownum MOD 2 EQ 1,de('content'),de('content2'))>
						<cfset DeleteResults = DeleteResults & '<tr class="#thisClass#"><td>#GetCostCenterUsers.lastname#, #GetCostCenterUsers.firstname#</td><td></td></tr>'>
						<cfset rownum = rownum + 1>
						<cfif do_import>
							<cfquery name="DeleteCostCenterUser" datasource="#application.DS#">
								DELETE FROM #application.database#.cost_center_user
								WHERE ID = #GetCostCenterUsers.ID#
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>
				--->
				<!--- Delete ccs --->
				<!---
				<cfquery name="GetCostCenters" datasource="#application.DS#">
					SELECT ID, number, description
					FROM #application.database#.cost_centers
					WHERE (updated != '#updateDate#' OR updated IS NULL)
					AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
				</cfquery>
				<cfif GetCostCenters.recordcount GT 0>
					<cfset DeleteResults = DeleteResults & '<tr><td class="alert">Delete Cost Centers</td><td></td></tr>'>
					<cfloop query="GetCostCenters">
						<cfset thisClass = Iif(rownum MOD 2 EQ 1,de('content'),de('content2'))>
						<cfset DeleteResults = DeleteResults & '<tr class="#thisClass#"><td>#GetCostCenters.number# - #GetCostCenters.description#</td><td></td></tr>'>
						<cfset rownum = rownum + 1>
						<cfif do_import>
							<cfquery name="DeleteCostCenterUser" datasource="#application.DS#">
								DELETE FROM #application.database#.cost_centers
								WHERE ID = #GetCostCenters.ID#
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>
				<cfif do_import>
					<cfquery name="DeleteXREF1" datasource="#application.DS#">
						DELETE FROM #application.database#.xref_cost_center_users
						WHERE cost_center_ID NOT IN (
							SELECT ID FROM #application.database#.cost_centers
							WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
						)
					</cfquery>
					<cfquery name="DeleteXREF2" datasource="#application.DS#">
						DELETE FROM #application.database#.xref_cost_center_approvers
						WHERE cost_center_ID NOT IN (
							SELECT ID FROM #application.database#.cost_centers
							WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
						)
					</cfquery>
				</cfif>
				<cfset DeleteResults = DeleteResults & '</table>'>
				--->









			</cfcase>
			<cfcase value="update">
				<cfloop list="#thisData#" index="thisLine" delimiters="|">
					<cfset this_user_ID = "">
					<cfif rownum GT 1>
						<cfset thisClass = Iif(rownum MOD 2 EQ 1,de('content'),de('content2'))>
						<cfif ListLen(thisLine) NEQ 12>
							<cfset errors_found = true>
							<cfset DisplayResults = DisplayResults & '<tr class="#thisClass#"><td>#rownum#</td><td colspan="4" class="alert">This line may have commas or has missing or extra data.</td></tr>'>
						<cfelse>
							<cfset thisNotes = "">
							<cfset thisEmployeeID = ListGetAt(thisLine,1)>
							<cfset thisLastName = ListGetAt(thisLine,2)>
							<cfset thisFirstName = ListGetAt(thisLine,3)>
							<cfset thisEmail = ListGetAt(thisLine,4)>
							<cfset thisCCCode = ListGetAt(thisLine,5)>
							<cfset thisCCDesc = ListGetAt(thisLine,6)>
							<cfset thisMgrLast = ListGetAt(thisLine,7)>
							<cfset thisMgrFirst = ListGetAt(thisLine,8)>
							<cfset thisMgrEmail = ListGetAt(thisLine,9)>
							<cfset thisMcLast = ListGetAt(thisLine,10)>
							<cfset thisMcFirst = ListGetAt(thisLine,11)>
							<cfset thisMcEmail = ListGetAt(thisLine,12)>
							<cfset DisplayResults = DisplayResults & '<tr class="#thisClass#"><td>#rownum#</td><td>#thisEmployeeID#</td><td>#thisLastName#, #thisFirstName#</td><td>#thisEmail#</td>'>
							<cfif trim(thisEmployeeID) EQ ''
								OR trim(thisLastName) EQ ''
								OR trim(thisFirstName) EQ ''
								OR trim(thisEmail) EQ ''
								OR trim(thisCCCode) EQ ''
								OR trim(thisCCDesc) EQ ''
								OR trim(thisMgrLast) EQ ''
								OR trim(thisMgrFirst) EQ ''
								OR trim(thisMgrEmail) EQ ''
								OR trim(thisMcLast) EQ ''
								OR trim(thisMcFirst) EQ ''
								OR trim(thisMcEmail) EQ ''
							>
								<cfset errors_found = true>
								<cfset thisNotes = thisNotes & '<span class="alert">Some fields are blank.</span><br>'>
							</cfif>
							<cfif not errors_found>
								<cfif NOT FLGen_IsValidEmail(thisEmail)>
									<cfset errors_found = true>
									<cfset thisNotes = thisNotes & '<span class="alert">#thisEmail# is not a valid email address.</span><br>'>
								</cfif>
								<cfif NOT FLGen_IsValidEmail(thisMgrEmail)>
									<cfset errors_found = true>
									<cfset thisNotes = thisNotes & '<span class="alert">#thisMgrEmail# is not a valid email address for Level 1 approver.</span><br>'>
								</cfif>
								<cfif NOT FLGen_IsValidEmail(thisMcEmail)>
									<cfset errors_found = true>
									<cfset thisNotes = thisNotes & '<span class="alert">#thisMcEmail# is not a valid email address for Level 2 approver.</span><br>'>
								</cfif>
							</cfif>
							<cfif not errors_found>
								<cfquery name="GetCostCenterUser" datasource="#application.DS#">
									SELECT
										t.ID,
										u.ID as user_ID,
										u.program_ID,
										t.employeeID,
										t.lastname,
										t.firstname,
										t.email,
										t.cc_code,
										t.cc_desc,
										t.mgr_lastname,
										t.mgr_firstname,
										t.mgr_email,
										t.mc_lastname,
										t.mc_firstname,
										t.mc_email
									FROM #application.database#.cost_center_user t
									LEFT JOIN #application.database#.program_user u ON u.email = t.email
									WHERE TRIM(t.email) = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">
								</cfquery>
								<cfif GetCostCenterUser.recordcount EQ 1>
									<cfset this_user_ID = GetCostCenterUser.user_ID>
									<cfset thisNotes = thisNotes & "Cost Center user already uploaded<br>">
									<cfif GetCostCenterUser.program_ID NEQ '' AND GetCostCenterUser.program_ID neq request.selected_program_ID>
										<cfset errors_found = true>
										<cfset thisNotes = thisNotes & '<span class="alert">#thisEmail# is in a different program!!</span><br>'>
									<cfelse>
										<cfif GetCostCenterUser.user_ID EQ "">
											<cfset thisNotes = thisNotes & "User has not registered yet<br>">
										<cfelse>
											<cfset thisNotes = thisNotes & "User has registered<br>">
										</cfif>
										<cfif do_import>
											<cfif GetCostCenterUser.employeeID NEQ thisEmployeeID
												OR GetCostCenterUser.lastname NEQ thisLastName
												OR GetCostCenterUser.firstname NEQ thisFirstName
												OR GetCostCenterUser.cc_code NEQ thisCCCode
												OR GetCostCenterUser.cc_desc NEQ thisCCDesc
												OR GetCostCenterUser.mgr_lastname NEQ thisMgrLast
												OR GetCostCenterUser.mgr_firstname NEQ thisMgrFirst
												OR GetCostCenterUser.mgr_email NEQ thisMgrEmail
												OR GetCostCenterUser.mc_lastname NEQ thisMcLast
												OR GetCostCenterUser.mc_firstname NEQ thisMcFirst
												OR GetCostCenterUser.mc_email NEQ thisMcEmail
											>
												<cfquery name="UpdateCCUser" datasource="#application.DS#">
													UPDATE #application.database#.cost_center_user
													SET employeeID = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisEmployeeID#">,
														lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisLastName#">,
														firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisFirstName#">,
														cc_code = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisCCCode#">,
														cc_desc = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisCCDesc#">,
														mgr_lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrLast#">,
														mgr_firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrFirst#">,
														mgr_email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrEmail#">,
														mc_lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcLast#">,
														mc_firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcFirst#">,
														mc_email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcEmail#">
													WHERE TRIM(email) = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">
												</cfquery>
											</cfif>
										</cfif>
									</cfif>
								<cfelseif GetCostCenterUser.recordcount GT 1>
									<cfset errors_found = true>
									<cfset thisNotes = thisNotes & '<span class="alert">#thisEmail# is duplicated!!</span><br>'>
								<cfelse>
									<cfif do_import>
										<!--- Look up the user --->
										<cfquery name="GetProgramUser" datasource="#application.DS#">
											SELECT ID
											FROM #application.database#.program_user
											WHERE email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">
											AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
										</cfquery>
										<cfif GetProgramUser.recordcount EQ 1>
											<cfset this_user_ID = GetProgramUser.ID>
										</cfif>
										<cfquery name="AddCCUser" datasource="#application.DS#">
											INSERT INTO #application.database#.cost_center_user (
												employeeID,
												lastname,
												firstname,
												email,
												cc_code,
												cc_desc,
												mgr_lastname,
												mgr_firstname,
												mgr_email,
												mc_lastname,
												mc_firstname,
												mc_email
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisEmployeeID#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisLastName#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisFirstName#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisEmail#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisCCCode#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisCCDesc#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrLast#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMgrFirst#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMgrEmail#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcLast#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#thisMcFirst#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMcEmail#">
											)
										</cfquery>
									</cfif>
									<cfset thisNotes = thisNotes & "Cost Center user #willbe# uploaded<br>">
								</cfif>
								<!---Look up cost center--->
								<cfset this_cc_ID = 0>
								<cfquery name="GetCostCenter" datasource="#application.DS#">
									SELECT ID, description
									FROM #application.database#.cost_centers
									WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" maxlength="10" value="#request.selected_program_ID#">
									AND number = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="5" value="#thisCCCode#">
								</cfquery>
								<cfif GetCostCenter.recordcount EQ 1>
									<cfset this_cc_ID = GetCostCenter.ID>
									<cfif GetCostCenter.description EQ thisCCDesc>
										<cfset thisNotes = thisNotes & "Cost Center #thisCCCode# exists<br>">
									<cfelse>
										<cfif do_import>
											<cfquery name="UpdateCostCenter" datasource="#application.DS#">
												UPDATE #application.database#.cost_centers
												SET description = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="64" value="#thisCCDesc#">
												WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_cc_ID#">
											</cfquery>
										</cfif>
										<cfset thisNotes = thisNotes & "Cost Center #thisCCCode# #willbe# updated with new description<br>">
									</cfif>
								<cfelse>
									<cfif do_import>
										<cfquery name="AddCostCenter" datasource="#application.DS#" result="stResult">
											INSERT INTO #application.database#.cost_centers (
												created_user_ID,
												created_datetime,
												program_ID,
												number,
												description
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
												NOW(),
												<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="5" value="#thisCCCode#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="64" value="#thisCCDesc#">
											)
										</cfquery>
										<cfset this_cc_ID = stResult.GENERATED_KEY>
									</cfif>
									<cfset thisNotes = thisNotes & "Cost Center #thisCCCode# #willbe# uploaded<br>">
								</cfif>
								<!--- Look up mgr email in admin_users --->
								<cfquery name="GetMgrProgramUser" datasource="#application.DS#">
									SELECT username
									FROM #application.database#.program_user
									WHERE email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMgrEmail#">
									AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
								</cfquery>
								<cfset this_mgr_ID = 0>
								<cfset this_mgr_username = thisMgrEmail><!---ListFirst(thisMgrEmail,'@')--->
								<cfif GetMgrProgramUser.recordCount EQ 1>
									<cfset this_mgr_password = FLGen_CreateHash(GetMgrProgramUser.username)>
								<cfelse>
									<cfset this_mgr_password = "">
								</cfif>
								<cfquery name="GetMgr" datasource="#application.DS#">
									SELECT ID, firstname, lastname, email
									FROM #application.database#.admin_users
									WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_username#">
								</cfquery>
								<cfif GetMgr.recordCount EQ 1>
									<cfset this_mgr_ID = GetMgr.ID>
									<cfset thisNotes = thisNotes & "Level 1 Approver exists<br>">
									<cfif do_import>
										<cfif GetMgr.lastname NEQ thisMgrLast
											OR GetMgr.firstname NEQ thisMgrFirst
											OR GetMgr.email NEQ thisMgrEmail
										>
											<cfquery name="UpdateMgr" datasource="#application.DS#">
												UPDATE #application.database#.admin_users
												SET firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMgrFirst#">,
													lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMgrLast#">,
													email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMgrEmail#">
												WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_username#">
											</cfquery>
										</cfif>
									</cfif>
								<cfelse>
									<cfif do_import>
										<cfquery name="AddMgr" datasource="#application.DS#" result="stResult">
											INSERT INTO #application.database#.admin_users (
												created_user_ID,
												created_datetime,
												firstname,
												lastname,
												username,
												password,
												email,
												program_ID,
												is_active
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
												NOW(),
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMgrFirst#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMgrLast#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_username#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mgr_password#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMgrEmail#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
												<cfif this_mgr_password EQ "">0<cfelse>1</cfif>
											)
										</cfquery>
										<cfset this_mgr_ID = stResult.GENERATED_KEY>
									</cfif>
									<cfset thisNotes = thisNotes & "Level 1 Approver #willbe# uploaded<br>">
								</cfif>
								<cfif do_import>
									<cftry>
										<cfquery name="AddMgrToCC" datasource="#application.DS#">
											INSERT INTO #application.database#.xref_cost_center_approvers
												(cost_center_ID, admin_user_ID, level)
											VALUES
												(#this_CC_ID#, #this_mgr_ID#, 1)
										</cfquery>
										<cfcatch></cfcatch>
									</cftry>
								</cfif>
								<!--- Look up mc email in admin_users and program_users --->
								<cfquery name="GetMCProgramUser" datasource="#application.DS#">
									SELECT username
									FROM #application.database#.program_user
									WHERE email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMcEmail#">
									AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
								</cfquery>
								<cfset this_mc_ID = 0>
								<cfset this_mc_username = thisMcEmail><!---ListFirst(thisMcEmail,'@')--->
								<cfif GetMCProgramUser.recordCount EQ 1>
									<cfset this_mc_password = FLGen_CreateHash(GetMCProgramUser.username)>
								<cfelse>
									<cfset this_mc_password = "">
								</cfif>
								<cfquery name="GetMc" datasource="#application.DS#">
									SELECT ID, firstname, lastname, email
									FROM #application.database#.admin_users
									WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_username#">
								</cfquery>
								<cfif GetMc.recordCount EQ 1>
									<cfset this_mc_ID = GetMc.ID>
									<cfset thisNotes = thisNotes & "Level 2 Approver exists<br>">
									<cfif do_import>
										<cfif GetMc.lastname NEQ thisMcLast
											OR GetMc.firstname NEQ thisMcFirst
											OR GetMc.email NEQ thisMcEmail
										>
											<cfquery name="UpdateMgr" datasource="#application.DS#">
												UPDATE #application.database#.admin_users
												SET firstname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMcFirst#">,
													lastname = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMcLast#">,
													email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMcEmail#">
												WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_username#">
											</cfquery>
										</cfif>
									</cfif>
								<cfelse>
									<cfif do_import>
										<cfquery name="AddMc" datasource="#application.DS#" result="stResult">
											INSERT INTO #application.database#.admin_users (
												created_user_ID,
												created_datetime,
												firstname,
												lastname,
												username,
												password,
												email,
												program_ID,
												is_active
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
												NOW(),
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMcFirst#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="30" value="#thisMcLast#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_username#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#this_mc_password#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" maxlength="128" value="#thisMcEmail#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
												<cfif this_mc_password EQ "">0<cfelse>1</cfif>
											)
										</cfquery>
										<cfset this_mc_ID = stResult.GENERATED_KEY>
									</cfif>
									<cfset thisNotes = thisNotes & "Level 2 Approver #willbe# uploaded<br>">
								</cfif>
								<cfif do_import>
									<cftry>
										<cfquery name="AddMcToCC" datasource="#application.DS#">
											INSERT INTO #application.database#.xref_cost_center_approvers
												(cost_center_ID, admin_user_ID, level)
											VALUES
												(#this_CC_ID#, #this_mc_ID#, 2)
										</cfquery>
										<cfcatch></cfcatch>
									</cftry>
								</cfif>
								<cfif isNumeric(this_user_ID)>
									<cfif do_import>
										<cftry>
										<cfquery name="AddUserToCC" datasource="#application.DS#">
											INSERT INTO #application.database#.xref_cost_center_users
												(cost_center_ID, program_user_ID)
											VALUES
												(#this_CC_ID#, #this_user_ID#)
										</cfquery>
										<cfcatch></cfcatch></cftry>
										<cfquery name="UpdateUser" datasource="#application.DS#">
											UPDATE #application.database#.program_user
											SET uses_cost_center = <cfqueryparam cfsqltype="cf_sql_tinyint" maxlength="1" value="#uses_cost_center#">,
												is_active = 1
											WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_user_ID#">
										</cfquery>
									</cfif>
								<cfelse>
									<cfset thisNotes = thisNotes & "User has not registered yet<br>">
								</cfif>
							</cfif>
							<cfset DisplayResults = DisplayResults & '<td>#thisNotes#</td></tr>'>
						</cfif>				
					</cfif>
					<cfset rownum = rownum + 1>
				</cfloop>
			</cfcase>
			<cfdefaultcase>
				<cfoutput>#update_type#</cfoutput> is not a valid update type.
			</cfdefaultcase>
		</cfswitch>
		<cfset DisplayResults = DisplayResults & '</table>'>
		<br>
		<cfif do_import>
			<span class="pageinstructions"><strong>The following data was imported:</strong></span>
		<cfelse>
			<cfif errors_found>
				<span class="pageinstructions"><strong>Errors were found.  Please review the data below.</strong></span>
			<cfelse>
				<form method="post" action="<cfoutput>#CurrentPage#</cfoutput>" name="emailSetup">
					<input type="hidden" name="update_type" value="<cfoutput>#update_type#</cfoutput>">
					<input type="hidden" name="saveUpdateDate" value="<cfoutput>#updateDate#</cfoutput>">
					Set all uploaded users to:
					<select name="uses_cost_center">
						<option value="0"<cfif uses_cost_center EQ 0> selected</cfif>>May NOT use Cost Center</option>
						<option value="1"<cfif uses_cost_center EQ 1> selected</cfif>>May ONLY use Cost Center</option>
						<option value="2"<cfif uses_cost_center EQ 2> selected</cfif>>May use Points OR Cost Center</option>
						<option value="3"<cfif uses_cost_center EQ 3> selected</cfif>>May use any Combination of Points and Cost Center</option>
					</select>
					<br><br>
					<input type="submit" name="importCostCenters" value="   Update the data displayed below   " />
				</form>
			</cfif>
		</cfif>
	<cfelse>
		<span class="pageinstructions">Sorry, but the data was lost.  You'll have to upload it again.</span>
	</cfif>
<cfelseif pgfn EQ "done">
	<cfoutput>
	Done.<br><br>
	</cfoutput>
</cfif>

<br><br>
<cfif DeleteResults NEQ "">
	<cfoutput>#DeleteResults#</cfoutput>
	<br>
</cfif>
<cfoutput>#DisplayResults#</cfoutput>
</cfif>

<cfinclude template="includes/footer.cfm">
