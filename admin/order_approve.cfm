<!--- function library --->
<cfinclude template="/cfscripts/dfm_common/function_library_form.cfm">
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>

<!--- For now don't require permission, they will simply need to be assigned to this cost center --->
<!---<cfset FLGen_HasAdminAccess(1000000116,true)>--->

<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="index.cfm" addtoken="no">
<cfelse>
	<!--- get program information --->
	<cfquery name="ProgramInfo" datasource="#application.DS#">
		SELECT company_name, program_name, is_one_item, credit_desc, orders_from, orders_to,
			credit_multiplier, credit_desc, hide_points, signature_charge, has_address_verification
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
</cfif>

<cfset order_found = false>
<cfset has_cost_center = false>
<cfset has_level_two = false>
<cfset processed = false>
<cfset approve_levels = "">

<cfparam name="order_hash" default=""> 

<cfif isDefined("url.o")>
	<!--- First time here --->
	<cfset order_hash = url.o>
</cfif>

<cfif order_hash neq "">
	<!--- get order info --->
	<cfquery name="GetOrderInfo" datasource="#application.DS#">
		SELECT ID AS order_ID, order_number, is_valid, created_user_ID,
			cost_center_charge, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname,
			snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip,
			snap_phone, snap_email, snap_bill_company, snap_bill_fname, snap_bill_lname,
			snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip,
			snap_order_total, points_used,
			order_note, modified_concat, Date_Format(created_datetime,'%c/%d/%Y') AS created_date,
			shipping_charge, snap_signature_charge, shipping_desc, shipping_location_ID, cost_center_ID, approval
		FROM #application.database#.order_info
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND
		<cfif ProgramInfo.has_address_verification>
			ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_hash#" maxlength="10">
		<cfelse>
			cost_center_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#order_hash#" maxlength="32">
		</cfif>
	</cfquery>
	<cfif GetOrderInfo.recordcount eq 1>
		<cfset order_ID = GetOrderInfo.order_ID>
		<!--- find order items --->
		<cfquery name="FindOrderItems" datasource="#application.DS#">
			SELECT ID AS inventory_ID, snap_sku, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options, snap_is_dropshipped, CAST(IFNULL(ship_date,"") AS CHAR) AS ship_date, IFNULL(drop_date,"") AS drop_date, po_ID, po_rec_date 
			FROM #application.database#.inventory
			WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		</cfquery>
		<cfif FindOrderItems.recordcount GT 0>
			<cfset order_found = true>
			<cfset user_ID = GetOrderInfo.created_user_ID>
			<cfset is_valid = GetOrderInfo.is_valid>
			<cfset created_date = HTMLEditFormat(GetOrderInfo.created_date)>
			<cfset order_number = HTMLEditFormat(GetOrderInfo.order_number)>
			<cfset cost_center_ID = GetOrderInfo.cost_center_ID>
			<cfset approval = GetOrderInfo.approval>
			<cfset snap_fname = HTMLEditFormat(GetOrderInfo.snap_fname)>
			<cfset snap_lname = HTMLEditFormat(GetOrderInfo.snap_lname)>
			<cfset snap_phone = HTMLEditFormat(GetOrderInfo.snap_phone)>
			<cfset snap_email = HTMLEditFormat(GetOrderInfo.snap_email)>
			<cfset snap_ship_company = HTMLEditFormat(GetOrderInfo.snap_ship_company)>
			<cfset snap_ship_fname = HTMLEditFormat(GetOrderInfo.snap_ship_fname)>
			<cfset snap_ship_lname = HTMLEditFormat(GetOrderInfo.snap_ship_lname)>
			<cfset snap_ship_address1 = HTMLEditFormat(GetOrderInfo.snap_ship_address1)>
			<cfset snap_ship_address2 = HTMLEditFormat(GetOrderInfo.snap_ship_address2)>
			<cfset snap_ship_city = HTMLEditFormat(GetOrderInfo.snap_ship_city)>
			<cfset snap_ship_state = HTMLEditFormat(GetOrderInfo.snap_ship_state)>
			<cfset snap_ship_zip = HTMLEditFormat(GetOrderInfo.snap_ship_zip)>
			<cfset snap_bill_company = HTMLEditFormat(GetOrderInfo.snap_bill_company)>
			<cfset snap_bill_fname = HTMLEditFormat(GetOrderInfo.snap_bill_fname)>
			<cfset snap_bill_lname = HTMLEditFormat(GetOrderInfo.snap_bill_lname)>
			<cfset snap_bill_address1 = HTMLEditFormat(GetOrderInfo.snap_bill_address1)>
			<cfset snap_bill_address2 = HTMLEditFormat(GetOrderInfo.snap_bill_address2)>
			<cfset snap_bill_city = HTMLEditFormat(GetOrderInfo.snap_bill_city)>
			<cfset snap_bill_state = HTMLEditFormat(GetOrderInfo.snap_bill_state)>
			<cfset snap_bill_zip = HTMLEditFormat(GetOrderInfo.snap_bill_zip)>
			<cfset shipping_location_ID = GetOrderInfo.shipping_location_ID>
			<cfset snap_order_total = GetOrderInfo.snap_order_total>
			<cfset shipping_desc = GetOrderInfo.shipping_desc>
			<cfset shipping_charge = GetOrderInfo.shipping_charge>
			<cfset snap_signature_charge = GetOrderInfo.snap_signature_charge>
			<cfset order_note = HTMLEditFormat(GetOrderInfo.order_note)>
			<cfset modified_concat = HTMLEditFormat(GetOrderInfo.modified_concat)>
			<cfset cost_center_charge = HTMLEditFormat(GetOrderInfo.cost_center_charge)>
			<cfset points_used = HTMLEditFormat(GetOrderInfo.points_used)>
		</cfif>
	</cfif>
</cfif>

<cfif order_found>
	<cfif ProgramInfo.has_address_verification>
		<cfquery name="GetAddress" datasource="#application.DS#">
			SELECT address1, address2, city, state, zip
			FROM #application.database#.program_user_address
			WHERE program_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">
		</cfquery>
		<cfquery name="GetUser" datasource="#application.DS#">
			SELECT fname, lname, username
			FROM #application.database#.program_user
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">
		</cfquery>
	<cfelse>
		<cfif isNumeric(cost_center_ID)>
			<cfquery name="GetCostCenter" datasource="#application.DS#">
				SELECT number, description
				FROM #application.database#.cost_centers
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
				AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
			</cfquery>
			<cfif GetCostCenter.recordcount eq 1>
				<cfset has_cost_center = true>
			</cfif>
		</cfif>
		<cfif has_cost_center and isNumeric(approval)>
			<cfquery name="GetApprover" datasource="#application.DS#">
				SELECT a.level, u.email
				FROM #application.database#.xref_cost_center_approvers a
				INNER JOIN #application.database#.admin_users u ON u.ID = a.admin_user_ID
				WHERE a.cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
				AND a.admin_user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#FLGen_adminID#" maxlength="10">
				ORDER BY level
			</cfquery>
			<cfif GetApprover.recordcount GT 0>
				<cfloop query="GetApprover">
					<cfquery name="GetCostCenterUser" datasource="#application.DS#">
						SELECT ID
						FROM #application.database#.cost_center_user
						WHERE <cfif approval EQ 1>mgr_email<cfelse>mc_email</cfif> = <cfqueryparam cfsqltype="varchar" value="#GetApprover.email#" >
						AND email = <cfqueryparam cfsqltype="varchar" value="#snap_email#" >
					</cfquery>
					<cfif GetCostCenterUser.recordCount GT 0>
						<cfset approve_levels = ListAppend(approve_levels,GetApprover.level)>
					</cfif>
				</cfloop>
			</cfif>
			<cfquery name="GetLevel2" datasource="#application.DS#">
				SELECT a.admin_user_ID, u.firstname, u.lastname, u.email, u.email_cc, c.number, c.description, u.password, u.is_active
				FROM #application.database#.xref_cost_center_approvers a
				INNER JOIN #application.database#.admin_users u ON u.ID = a.admin_user_ID
				INNER JOIN #application.database#.cost_centers c ON c.ID = a.cost_center_ID
				WHERE a.cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
				AND a.level = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="2" maxlength="1">
			</cfquery>
			<cfset has_level_two = false>
			<cfset email_list = "">
			<cfif GetLevel2.recordcount GT 0>
				<cfloop query="GetLevel2">
					<cfquery name="GetCostCenterUser" datasource="#application.DS#">
						SELECT ID
						FROM #application.database#.cost_center_user
						WHERE mc_email = <cfqueryparam cfsqltype="varchar" value="#GetLevel2.email#" >
						AND email = <cfqueryparam cfsqltype="varchar" value="#snap_email#" >
					</cfquery>
					<cfif GetCostCenterUser.recordCount GT 0>
						<cfset email_list = ListAppend(email_list,GetLevel2.email)>
						<cfset has_level_two = true>
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
	</cfif>
</cfif>

<!--- Form submit --->
<cfif ProgramInfo.has_address_verification>
	<!--- -------------------- --->
	<!--- Address Verification --->
	<!--- -------------------- --->
	<cfif order_found>
		<cfif isDefined("form.approve")>
			<cfset this_order_note = "">
			<cfset this_order_note = "Address Approved">
			<cfquery name="ApproveOrder" datasource="#application.DS#">
				UPDATE #application.database#.order_info
				SET approval = 0,
					is_valid = 1
					#FLGen_UpdateModConcatSQL(this_order_note)#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
			</cfquery>
			<cfquery name="UpdateInvItems" datasource="#application.DS#">
				UPDATE #application.database#.inventory
				SET	is_valid = 1
				WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			</cfquery>
			<cfset processed = true>
			<!--- ------------------- --->
			<!--- Notify ITC          --->
			<!--- ------------------- --->
			<cfloop list="#ProgramInfo.orders_to#" index="thisemail">
				<cfif application.OverrideEmail NEQ "">
					<cfset this_to = application.OverrideEmail>
				<cfelse>
					<cfset this_to = thisemail>
				</cfif>
				<cfmail to="#this_to#" from="#ProgramInfo.orders_from#" subject="#ProgramInfo.company_name# order #order_number#" failto="#Application.OrdersFailTo#">
					<cfif application.OverrideEmail NEQ "">
						Emails are being overridden.<br>
						Below is the email that would have been sent to #thisemail#<br>
						<hr>
					</cfif>
	#DateFormat(Now(),"mm/dd/yyyy")#
	
	Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)
	
	PHONE: #snap_phone#
	<cfif snap_ship_fname neq "">
	SHIPPING ADDRESS:
	#snap_ship_fname# #snap_ship_lname##CHR(10)#
	#snap_ship_address1##CHR(10)#
	<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2##CHR(10)#</cfif>
	#snap_ship_city#, #snap_ship_state# #snap_ship_zip#
	<cfif shipping_desc NEQ "">
	
	Ship via #shipping_desc#: #shipping_charge#
	<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
	</cfif>
	</cfif>
	
	ITEM(S) IN ORDER:
	<cfloop query="FindOrderItems">
		#quantity# - [sku:#snap_sku#] #snap_meta_name# #snap_options# (#snap_productvalue*ProgramInfo.credit_multiplier# #ProgramInfo.credit_desc#)#CHR(10)#
	</cfloop>
	
	Charged to Cost Center: #cost_center_charge#
	
	ORDER NOTE:
	<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
				</cfmail>
			</cfloop>
		</cfif>
	</cfif>
<cfelse>
	<!--- -------------------- --->
	<!--- Cost Center Approval --->
	<!--- -------------------- --->
	<cfif order_found AND has_cost_center AND approve_levels NEQ "" AND has_level_two AND ListFind(approve_levels,approval)>
		<cfif isDefined("form.approve") AND (approval EQ 1 OR approval EQ 2)>
			<cfset this_order_note = "">
			<cfset this_order_note = "Approved from level " & approval>
			<cfset approval = approval + 1>
			<cfif approval EQ 3>
				<cfset is_valid = 1>
				<cfset this_order_note = this_order_note & " and is now validated for processing">
			<cfelse>
				<cfset this_order_note = this_order_note & " to level " & approval>
			</cfif>
			<cfquery name="ApproveOrder" datasource="#application.DS#">
				UPDATE #application.database#.order_info
				SET approval = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#approval#">,
					is_valid = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_valid#">
					#FLGen_UpdateModConcatSQL(this_order_note)#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
			</cfquery>
			<cfif is_valid EQ 1>
				<cfquery name="UpdateInvItems" datasource="#application.DS#">
					UPDATE #application.database#.inventory
					SET	is_valid = 1
					WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
				</cfquery>
			</cfif>
			<cfset processed = true>
	
	<!--- ------------------- --->
	<!--- Notify Level 2      --->
	<!--- ------------------- --->
			<cfif approval EQ 2>
				<cfloop query="GetLevel2">
				<cfif ListFind(email_list,GetLevel2.email)>
					<cfif application.OverrideEmail NEQ "">
						<cfset this_to = application.OverrideEmail>
						<cfset this_cc = application.OverrideEmail>
					<cfelse>
						<cfset this_to = GetLevel2.email>
						<cfset this_cc = GetLevel2.email_cc>
					</cfif>
	<cfmail to="#this_to#" cc="#this_cc#" from="#ProgramInfo.orders_from#" subject="#ProgramInfo.company_name# Cost Center order" failto="#Application.OrdersFailTo#" type="html">
		<cfif application.OverrideEmail NEQ "">
			Emails are being overridden.<br>
			Below is the email that would have been sent to #GetLevel2.email# and cc to #GetLevel2.email_cc#<br>
			<hr>
		</cfif>
	#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
	Dear #GetLevel2.firstname# #GetLevel2.lastname#,<br><br>
	An order was charged to cost center #GetLevel2.number#<cfif GetLevel2.description neq ""> - #GetLevel2.description#</cfif>.<br><br>
	This order was approved by a level 1 approver.<br><br>
	Log in to <a href="#application.SecureWebPath#/admin/index.cfm?o=#order_hash#<cfif GetLevel2.is_active EQ 0>&v=#GetLevel2.password#&e=#GetLevel2.email#</cfif>">#application.AdminName# admin</a> to approve or decline this order.<br><br>
	Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br>
	PHONE: #snap_phone#<br>
	<cfif snap_ship_fname neq "">
	SHIPPING ADDRESS:<br>
	#snap_ship_fname# #snap_ship_lname##CHR(10)#<br>
	#snap_ship_address1##CHR(10)#<br>
	<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2##CHR(10)#</cfif>
	#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br>
	<cfif shipping_desc NEQ "">
	<br>
	Ship via #shipping_desc#: #shipping_charge#<br>
	<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#<br></cfif>
	</cfif>
	</cfif>
	<br>
	ITEM(S) IN ORDER:<br>
	<cfloop query="FindOrderItems">#quantity# - #snap_meta_name# #snap_options# <cfif ProgramInfo.is_one_item EQ 0 AND NOT ProgramInfo.hide_points>(#NumberFormat(snap_productvalue * ProgramInfo.credit_multiplier)# #ProgramInfo.credit_desc#)</cfif>#CHR(10)#<br></cfloop>
	<br>
	Order Total: #NumberFormat(snap_order_total* ProgramInfo.credit_multiplier)##CHR(10)#<br><br>
	Charged to Cost Center: #cost_center_charge#<br><br>
	ORDER NOTE:<br>
	<cfif order_note EQ "">(none)<cfelse>#order_note#<br></cfif>
	</cfmail>
				</cfif>
				</cfloop>
				<!--- Notify ITC --->
				<cfloop list="#ProgramInfo.orders_to#" index="thisemail">
					<cfif application.OverrideEmail NEQ "">
						<cfset this_to = application.OverrideEmail>
					<cfelse>
						<cfset this_to = thisemail>
					</cfif>
	<cfmail to="#this_to#" from="#ProgramInfo.orders_from#" subject="#ProgramInfo.company_name# Cost Center order #order_number#" failto="#Application.OrdersFailTo#">
		<cfif application.OverrideEmail NEQ "">
			Emails are being overridden.<br>
			Below is the email that would have been sent to #thisemail#<br>
			<hr>
		</cfif>
	#DateFormat(Now(),"mm/dd/yyyy")#
	
	Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)
	
	This order has been approved by level 1 and is now waiting for level 2 approval.
	
	PHONE: #snap_phone#
	<cfif snap_ship_fname neq "">
	SHIPPING ADDRESS:
	#snap_ship_fname# #snap_ship_lname##CHR(10)#
	#snap_ship_address1##CHR(10)#
	<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2##CHR(10)#</cfif>
	#snap_ship_city#, #snap_ship_state# #snap_ship_zip#
	<cfif shipping_desc NEQ "">
	
	Ship via #shipping_desc#: #shipping_charge#
	<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
	</cfif>
	</cfif>
	
	ITEM(S) IN ORDER:
	<cfloop query="FindOrderItems">
		#quantity# - [sku:#snap_sku#] #snap_meta_name# #snap_options# (#snap_productvalue*ProgramInfo.credit_multiplier# #ProgramInfo.credit_desc#)#CHR(10)#
	</cfloop>
	
	Charged to Cost Center: #cost_center_charge#
	
	ORDER NOTE:
	<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
	</cfmail>
				</cfloop>
			</cfif>
	
	<!--- ------------------- --->
	<!--- Notify ITC          --->
	<!--- ------------------- --->
			<cfif approval EQ 3>
				<cfloop list="#ProgramInfo.orders_to#" index="thisemail">
					<cfif application.OverrideEmail NEQ "">
						<cfset this_to = application.OverrideEmail>
					<cfelse>
						<cfset this_to = thisemail>
					</cfif>
	<cfmail to="#this_to#" from="#ProgramInfo.orders_from#" subject="#ProgramInfo.company_name# Cost Center order #order_number#" failto="#Application.OrdersFailTo#">
		<cfif application.OverrideEmail NEQ "">
			Emails are being overridden.<br>
			Below is the email that would have been sent to #thisemail#<br>
			<hr>
		</cfif>
	#DateFormat(Now(),"mm/dd/yyyy")#
	
	Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)
	
	This order has been approved by level 2 and is validated to be processed.
	
	PHONE: #snap_phone#
	<cfif snap_ship_fname neq "">
	SHIPPING ADDRESS:
	#snap_ship_fname# #snap_ship_lname##CHR(10)#
	#snap_ship_address1##CHR(10)#
	<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2##CHR(10)#</cfif>
	#snap_ship_city#, #snap_ship_state# #snap_ship_zip#
	<cfif shipping_desc NEQ "">
	
	Ship via #shipping_desc#: #shipping_charge#
	<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
	</cfif>
	</cfif>
	
	ITEM(S) IN ORDER:
	<cfloop query="FindOrderItems">
		#quantity# - [sku:#snap_sku#] #snap_meta_name# #snap_options# (#snap_productvalue*ProgramInfo.credit_multiplier# #ProgramInfo.credit_desc#)#CHR(10)#
	</cfloop>
	
	Charged to Cost Center: #cost_center_charge#
	
	ORDER NOTE:
	<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
	</cfmail>
				</cfloop>
				<!--- email the user --->
				<cfquery name="SelectInfo" datasource="#application.DS#">
					SELECT meta_conf_email_text
					FROM #application.database#.program_meta
				</cfquery>
				<!--- send email confirmation, if requested --->
				<cfset this_subject = "Thank you for your "&ProgramInfo.company_name&" Cost Center order.">
				<cfset order_for = "Order "&order_number&" for #snap_fname# #snap_lname# (#snap_email#)">
				<cfif application.OverrideEmail NEQ "">
					<cfset this_to = application.OverrideEmail>
				<cfelse>
					<cfset this_to = snap_email>
				</cfif>
				<cfmail to="#this_to#" from="#ProgramInfo.orders_from#" subject="#this_subject#" failto="#Application.OrdersFailTo#" type="html">
					<cfif application.OverrideEmail NEQ "">
						Emails are being overridden.<br>
						Below is the email that would have been sent to #snap_email#<br>
						<hr>
					</cfif>
					#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
					#this_subject#<br><br>
					<font color="##cb0400">Your order has been approved.</font><br><br>
					<cfif SelectInfo.meta_conf_email_text NEQ "">
						#SelectInfo.meta_conf_email_text#<br><br>
					</cfif>
					#order_for#<br><br>
					Phone: #snap_phone#<br><br>
						SHIPPING ADDRESS:<br>
						#snap_ship_fname# #snap_ship_lname##CHR(10)#<br>
						#snap_ship_address1##CHR(10)#<br>
						<cfif Trim(snap_ship_address2) NEQ "">
							#snap_ship_address2##CHR(10)#<br>
						</cfif>
						#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br><br>
						<cfif shipping_desc NEQ "">
							Ship via #shipping_desc#: #shipping_charge#<br><br>
							<cfif ProgramInfo.signature_charge GT 0>
								Signature Required Charge: #ProgramInfo.signature_charge#<br><br>
							</cfif>
						</cfif>
					ITEM(S) IN ORDER:<br>
					<cfloop query="FindOrderItems">
						#quantity# - #snap_meta_name# #snap_options#
						(#NumberFormat(snap_productvalue * ProgramInfo.credit_multiplier)# #ProgramInfo.credit_desc#)
						<br>
					</cfloop>
					<br>
					Order Total: #NumberFormat(snap_order_total* ProgramInfo.credit_multiplier)#<br>
					Charged to Cost Center: #cost_center_charge#<br>
					<br>
					ORDER NOTE:
					<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
				</cfmail>
			</cfif>
		</cfif>
		<cfif isDefined("form.reject")>
			<cfset this_order_note = "Declined at level " & approval>
			<cfset approval = 9>
			<cfquery name="RejectedOrder" datasource="#application.DS#">
				UPDATE #application.database#.order_info
				SET approval = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#approval#">
					#FLGen_UpdateModConcatSQL(this_order_note)#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
			</cfquery>
			<cfset processed = true>
	<!--- ------------------- --->
	<!--- Notify User         --->
	<!--- ------------------- --->
	<cfif application.OverrideEmail NEQ "">
		<cfset this_to = application.OverrideEmail>
	<cfelse>
		<cfset this_to = snap_email>
	</cfif>
	<cfmail to="#this_to#" from="#ProgramInfo.orders_from#" subject="RE: Your #ProgramInfo.company_name# Cost Center order" failto="#Application.OrdersFailTo#">
	<cfif application.OverrideEmail NEQ "">
		Emails are being overridden.<br>
		Below is the email that would have been sent to #snap_email#<br>
		<hr>
	</cfif>
	#DateFormat(Now(),"mm/dd/yyyy")#
	
	Dear #snap_fname# #snap_lname#,
	
	Your #ProgramInfo.company_name# Cost Center order has been declined.
	
	Order #order_number#
	
	<cfif snap_ship_fname neq "">
	SHIPPING ADDRESS:
	#snap_ship_fname# #snap_ship_lname##CHR(10)#
	#snap_ship_address1##CHR(10)#
	<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2##CHR(10)#</cfif>
	#snap_ship_city#, #snap_ship_state# #snap_ship_zip#
	<cfif shipping_desc NEQ "">
	Ship via #shipping_desc#: #shipping_charge#
	</cfif>
	<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
	</cfif>
	
	ITEM(S) IN ORDER:
	<cfloop query="FindOrderItems">#quantity# - #snap_meta_name# #snap_options# <cfif ProgramInfo.is_one_item EQ 0 AND NOT ProgramInfo.hide_points>(#NumberFormat(snap_productvalue * ProgramInfo.credit_multiplier)# #ProgramInfo.credit_desc#)</cfif>#CHR(10)#</cfloop>
	
	ORDER NOTE:
	<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
	</cfmail>
		</cfif>
	</cfif>
</cfif>

<!--- param search criteria xS=ColumnSort xT=SearchString --->
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="xOF" default="">
<cfparam name="OnPage" default="1">

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "pending">
<cfinclude template="includes/header.cfm">

<span class="pagetitle">Approve Order</span>
<br /><br />

<cfif not order_found>
	<span class="alert">Order not found!</span>
<cfelse>
	<cfparam name="pgfn" default="detail">
	
	<cfif pgfn EQ "detail">

		<cfif shipping_location_ID GT 0>
			<cfquery name="GetSelectedShippingLocation" datasource="#application.DS#">
				SELECT location_name, company, attention, address1, address2, city, state, zip, phone
				FROM #application.database#.shipping_locations
				WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
				AND ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#shipping_location_ID#" maxlength="10">
			</cfquery>
			<cfif GetSelectedShippingLocation.recordcount eq 0>
				<cfset shipping_location_ID = 0>
			</cfif>
		</cfif>
	
		<cfoutput>
		<cfif request.is_admin>
			<span class="pageinstructions">Return to the <a href="order_pending.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">Pending Order List</a> without making changes.</span>
			<br /><br />
		</cfif>
	
		<table cellpadding="3" cellspacing="1" border="0" width="100%">
	
		<tr>
		<td colspan="2" class="content2"><b>Award Program:</b> <span class="selecteditem">#ProgramInfo.company_name# [#ProgramInfo.program_name#]</span><cfif ProgramInfo.is_one_item GT 0> <span class="sub">(this is a one-item program)</span></cfif></td>
		</tr>
				
		<tr>
		<td colspan="2" class="contenthead"><b>Order #order_number#</b> on #created_date# for #snap_fname# #snap_lname# (#snap_email#)</td>
		</tr>
				
		<tr class="contenthead">
		<td>Shipping Information</td>
		<td><cfif snap_bill_fname NEQ "">Billing Information<cfelse>&nbsp;</cfif></td>
		</tr>
		
		<tr class="content">
		<td>
	
		<cfif shipping_location_ID GT 0>
			<cfif GetSelectedShippingLocation.company NEQ "">#GetSelectedShippingLocation.company#<br></cfif>
		<cfelse>
			<cfif snap_ship_company NEQ "">#snap_ship_company#<br></cfif>
		</cfif>
		<cfif shipping_location_ID GT 0>Order for: </cfif><cfif snap_ship_fname NEQ "">#snap_ship_fname#</cfif> <cfif snap_ship_lname NEQ "">#snap_ship_lname#</cfif><br>
		<cfsavecontent variable="snap_ship_full_address">
		<cfif snap_ship_address1 NEQ "">#snap_ship_address1#<br></cfif>
		<cfif snap_ship_address2 NEQ "">#snap_ship_address2#<br></cfif>
		<cfif snap_ship_city NEQ "">#snap_ship_city#</cfif>, <cfif snap_ship_state NEQ "">#snap_ship_state#</cfif> <cfif snap_ship_zip NEQ "">#snap_ship_zip#</cfif><br>
		</cfsavecontent>
		#snap_ship_full_address#
		<cfif shipping_location_ID GT 0 AND GetSelectedShippingLocation.attention NEQ "">ATTN: #GetSelectedShippingLocation.attention#<cfif GetSelectedShippingLocation.phone NEQ ""> -  #GetSelectedShippingLocation.phone#</cfif><br></cfif>
		<cfif snap_phone NEQ "">Phone: #snap_phone#</cfif><br>
		<cfif shipping_desc NEQ "">Ship via #shipping_desc#: #shipping_charge#</cfif>
		<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
		</td>
		<td>
		<cfif snap_bill_fname NEQ "">
			<cfif snap_bill_company NEQ "">#snap_bill_company#<br></cfif>
			<cfif snap_bill_fname NEQ "">#snap_bill_fname#</cfif> <cfif snap_bill_lname NEQ "">#snap_bill_lname#</cfif><br>
			<cfif snap_bill_address1 NEQ "">#snap_bill_address1#<br></cfif>
			<cfif snap_bill_address2 NEQ "">#snap_bill_address2#<br></cfif>
			<cfif snap_bill_city NEQ "">#snap_bill_city#</cfif>, <cfif snap_bill_state NEQ "">#snap_bill_state#</cfif> <cfif snap_bill_zip NEQ "">#snap_bill_zip#</cfif><br>
		<cfelse>
			&nbsp;
		</cfif>
		</td>
		</tr>
		
		<tr>
		<td colspan="2" class="contenthead">Order Note</td>
		</tr>
	
		<tr>
		<td colspan="2" class="content"><cfif order_note NEQ "">#Replace(HTMLEditFormat(order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(none)</span></cfif></td>
		</tr>
	
		<tr class="contenthead">
		<td colspan="2" class="contenthead">Order Modification History </td>
		</tr>
	
		<tr class="content">
		<td colspan="2"><cfif TRIM(modified_concat) NEQ "">#FLGen_DisplayModConcat(modified_concat)#<cfelse><span class="sub">(none)</span></cfif></td>
		</tr>
	
		</table>
		<br><br>
		
		<cfif FindOrderItems.RecordCount EQ 0>
			There are no products in this order.
		<cfelse>
			<table cellpadding="3" cellspacing="1" border="0" width="100%">
			<tr class="contenthead">
			<td></td>
			<td><b>SKU</b></td>
			<td width="100%"><b>Description</b></td>
			<td align="center"><b>Qty</b></td>
			<cfif ProgramInfo.is_one_item EQ 0>
				<td colspan="2" align="center"><b>#ProgramInfo.credit_desc#</b></td>
			</cfif>
			</tr>
			<cfset carttotal = 0>
		 	<cfloop query="FindOrderItems">
				<tr class="content">
				<td></td>
				<td>#snap_sku#</td>
				<td>#snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
				<td align="center" nowrap>#quantity#</td>
				<cfif ProgramInfo.is_one_item EQ 0>
				<td nowrap align="right">#snap_productvalue# <span class="sub">each</span></td>
				<td align="right">#snap_productvalue*quantity#</td>
				</cfif>
				</tr>
				<cfif ProgramInfo.is_one_item EQ 0>
					<cfset carttotal = carttotal + (snap_productvalue * quantity)>
				</cfif>
			</cfloop>
			<cfif ProgramInfo.is_one_item EQ 0>
				<tr>
				<td align="right" colspan="5"><b>Order Total:</b> </td>
				<td align="right" class="content"><b>#carttotal#</b></td>
				</tr>
				<cfif shipping_charge GT 0>
					<tr>
						<td align="right" colspan="5"><b>Ship via #shipping_desc#:</b></td>
						<td align="right" class="content"><b>#shipping_charge#</b></td>
					</tr>
				</cfif>
				<cfif snap_signature_charge GT 0>
					<tr>
						<td align="right" colspan="5"><b>Signature Required Charge:</b></td>
						<td align="right" class="content"><b>#snap_signature_charge#</b></td>
					</tr>
				</cfif>
				<tr>
				<td align="right" colspan="5"> <cfif has_cost_center><b>Charge to cost center #GetCostCenter.number#:</b></cfif> </td>
				<td align="right" class="content"><b>#NumberFormat(cost_center_charge,'_.__')#</b></td>
				</tr>
			
			</cfif>
			</table>
		</cfif>
		<cfif ProgramInfo.has_address_verification>
			<cfif processed>
				<p>Order Approved.  Thank you.</p>
			<cfelse>
				<cfset anyway = "">

				<!--- User inits is a hack.  This whole address verification is a hack --->
				<cfset user_inits = "x">
				<cfset name_inits = "y">
				<cfif GetUser.recordcount EQ 1>
					<cfset user_inits = left(GetUser.username,2)>
					<cfset name_inits = left(GetUser.fname,1) & left(GetUser.lname,1)>
				</cfif>
				<cfif GetAddress.recordCount EQ 0 AND user_inits NEQ name_inits>
					<p class="alert">User does not have an address on file to verify their shipping address.</p>
					<cfset anyway = " Anyway">
				<!--- End(ish) of hack --->

				<cfelseif GetAddress.recordCount GT 1>
					<p class="alert">User has multiple addresses on file!</p>
					<cfset anyway = " Anyway">
				<cfelse>
					<cfif GetAddress.recordCount NEQ 0>
						<cfset state_abbr = trim(GetAddress.state)>
						<cfif len(state_abbr) GT 2>
							<cfset state_abbr = FLGen_GetStateAbbr(GetAddress.state)>
						</cfif>
						<p>The user entered a different address than the one on file.</p>
						<table cellpadding="5" cellspacing="1" border="0" width="60%">
							<tr class="contenthead">
								<td class="headertext">User Entered</td>
								<td class="headertext">Address on File</td>
							</tr>
							<tr>
								<td class="content2">
								#snap_ship_full_address#	
								</td>
								<td class="content2">
								#GetAddress.address1#<br>
								<cfif trim(GetAddress.address2) NEQ "">
									#GetAddress.address2#<br>
								</cfif>
								#GetAddress.city#, #state_abbr# #GetAddress.zip#<br>
								</td>
							</tr>
						</table>
					<cfelse>
						#GetUser.username# is a user that does not need address verification.  (Send Tracy a screen shot of this entire page.  Thanks!)
					</cfif>
				</cfif>
				<br><br>
				<form method="post" action="#CurrentPage#">
					<input type="hidden" name="xOF" value="#xOF#">
					<input type="hidden" name="xFD" value="#xFD#">
					<input type="hidden" name="xTD" value="#xTD#">
					<input type="hidden" name="xT" value="#xT#">
					<input type="hidden" name="OnPage" value="#OnPage#">
					<input type="hidden" name="order_hash" value="#order_hash#">
					<input type="submit" name="approve" value="  Approve#anyway#  ">
				</form>
			</cfif>
		<cfelse>
			<cfif is_valid and not processed>
				<p class="alert">This order has already been validated.</p>
			<cfelse>
				<cfif processed>
					<p>Thank you.</p>
					<cfif approval eq 2>
						<p>This order has been approved by level 1.</p>
					<cfelseif approval eq 3>
						<p>This order is now validated and ready to be processed.</p>
					</cfif>
				</cfif>
				<cfif ListFind(approve_levels,approval)>
					<p>This pending order requires level #approval# approval.</p>
					<cfif approval EQ 2 OR has_level_two>
						<form method="post" action="#CurrentPage#">
							<input type="hidden" name="xOF" value="#xOF#">
							<input type="hidden" name="xFD" value="#xFD#">
							<input type="hidden" name="xTD" value="#xTD#">
							<input type="hidden" name="xT" value="#xT#">
							<input type="hidden" name="OnPage" value="#OnPage#">
							<input type="hidden" name="order_hash" value="#order_hash#">
							<input type="submit" name="approve" value="  Approve  ">
							&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
							<input type="submit" name="reject" value="  Decline  ">
						</form>
					<cfelseif NOT has_level_two>
						<p class="alert">Level 2 approvers not set up!</p>
					</cfif>
				<cfelseif not has_cost_center>
					<p class="alert">Cost center was not found!</p>
				<cfelse>
					<cfif approval eq 0>
						<p class="alert">This order does not require approval.</p>
					<cfelseif approval eq 9>
						<p class="alert">This order has been declined.</p>
					<cfelseif approval eq 3>
						<p class="alert">This order has been approved.</p>
					<cfelseif approval gt 3>
						<p class="alert">"#approval#" IS NOT A VALID APPROVAL CODE!</p>
					<cfelse>
						<p>
							<cfif approve_levels EQ "">
								Either you are not assigned to cost center #GetCostCenter.number#,<br>or you are not an approver for #snap_email#
							<cfelse>
								This order is pending approval by level #approval#.&nbsp;&nbsp;&nbsp;
								<!---You are level<cfif ListLen(approve_levels) GT 1>s</cfif> #approve_levels#.--->
							</cfif>
						</p>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
		</cfoutput>
	</cfif>

</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->