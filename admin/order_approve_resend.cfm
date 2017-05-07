<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- Verify that a program was selected --->

<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="index.cfm" addtoken="no">
</cfif>

<cfif NOT isDefined("url.sendit")>
	<cfset leftnavon = "pending">
	<cfinclude template="includes/header.cfm">
	<cfoutput>
	<span class="pagetitle">Resend Approval Email</span>
	<p class="pageinstructions">This will send an email to #url.approver# at #url.email#<cfif url.email_cc NEQ "">, cc to #url.email_cc#</cfif>.</p>
	<p class="pageinstructions">Click the "Resend Email" link below to resend the email, or "Cancel" to go back without sending.</p>
	<p class="pageinstructions">
	<a href="order_approve_resend.cfm?o=#url.o#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#&email=#url.email#&email_cc=#url.email_cc#&order_ID=#url.order_ID#&approver=#url.approver#&cc_number=#url.cc_number#&sendit=1">Resend Email</a>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<a href="order_pending.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">Cancel</a>
	</p>
	</cfoutput>
	<cfinclude template="includes/footer.cfm">

	
<cfelse>

<cfset this_carttotal = 0>

<!--- get order info --->
<cfquery name="FindOrderInfo" datasource="#application.DS#">
	SELECT snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip,
		snap_phone, snap_email, snap_bill_company, snap_bill_fname, snap_bill_lname, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip,
		order_note,	shipping_desc, shipping_charge, snap_signature_charge, credit_card_charge, cost_center_charge, order_number, program_ID
	FROM #application.database#.order_info
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#url.order_ID#" maxlength="10">
</cfquery>
<cfset snap_fname = HTMLEditFormat(FindOrderInfo.snap_fname)>
<cfset snap_lname = HTMLEditFormat(FindOrderInfo.snap_lname)>
<cfset snap_ship_company = HTMLEditFormat(FindOrderInfo.snap_ship_company)>
<cfset snap_ship_fname = HTMLEditFormat(FindOrderInfo.snap_ship_fname)>
<cfset snap_ship_lname = HTMLEditFormat(FindOrderInfo.snap_ship_lname)>
<cfset snap_ship_address1 = HTMLEditFormat(FindOrderInfo.snap_ship_address1)>
<cfset snap_ship_address2 = HTMLEditFormat(FindOrderInfo.snap_ship_address2)>
<cfset snap_ship_city = HTMLEditFormat(FindOrderInfo.snap_ship_city)>
<cfset snap_ship_state = HTMLEditFormat(FindOrderInfo.snap_ship_state)>
<cfset snap_ship_zip = HTMLEditFormat(FindOrderInfo.snap_ship_zip)>
<cfset snap_phone = HTMLEditFormat(FindOrderInfo.snap_phone)>
<cfset snap_email = HTMLEditFormat(FindOrderInfo.snap_email)>
<cfset snap_bill_company = HTMLEditFormat(FindOrderInfo.snap_bill_company)>
<cfset snap_bill_fname = HTMLEditFormat(FindOrderInfo.snap_bill_fname)>
<cfset snap_bill_lname = HTMLEditFormat(FindOrderInfo.snap_bill_lname)>
<cfset snap_bill_address1 = HTMLEditFormat(FindOrderInfo.snap_bill_address1)>
<cfset snap_bill_address2 = HTMLEditFormat(FindOrderInfo.snap_bill_address2)>
<cfset snap_bill_city = HTMLEditFormat(FindOrderInfo.snap_bill_city)>
<cfset snap_bill_state = HTMLEditFormat(FindOrderInfo.snap_bill_state)>
<cfset snap_bill_zip = HTMLEditFormat(FindOrderInfo.snap_bill_zip)>
<cfset order_note = HTMLEditFormat(FindOrderInfo.order_note)>
<cfset shipping_desc = FindOrderInfo.shipping_desc>
<cfset shipping_charge = FindOrderInfo.shipping_charge>
<cfset snap_signature_charge = FindOrderInfo.snap_signature_charge>
<cfset cost_center_charge = FindOrderInfo.cost_center_charge>
<cfset credit_card_charge = FindOrderInfo.credit_card_charge>
<cfset order_number = FindOrderInfo.order_number>

<!--- find all inventory items for this order for emails --->
<cfquery name="FindOrderItems" datasource="#application.DS#">
	SELECT quantity, snap_meta_name, snap_sku, snap_productvalue, snap_options
	FROM #application.database#.inventory
	WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#url.order_ID#" maxlength="10">
</cfquery>

	<cfset snap_order_total = 0>
	<cfloop query="FindOrderItems">
		<cfset snap_order_total = snap_order_total + (snap_productvalue * quantity)>
	</cfloop>

<cfquery name="SelectInfo" datasource="#application.DS#">
	SELECT meta_conf_email_text
	FROM #application.database#.program_meta
</cfquery>

<!--- get program information --->
<cfquery name="FindProgramInfo" datasource="#application.DS#">
	SELECT company_name, program_name, is_one_item, credit_desc, orders_from, hide_points,
		credit_multiplier, cost_center_notification, program_email_subject
	FROM #application.database#.program
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#FindOrderInfo.program_ID#" maxlength="10">
</cfquery>

<cfset meta_conf_email_text = HTMLEditFormat(SelectInfo.meta_conf_email_text)>

<!--- send email confirmation, if requested --->
<cfset this_subject = Replace('Thank you for your [company_name] Award Program order.','[company_name]',FindProgramInfo.company_name)>
<cfset order_for = 'Order [order_number] for [user_name]'>
<cfset order_for = Replace(order_for,'[order_number]',order_number)>
<cfset order_for = Replace(order_for,'[user_name]',"#snap_fname# #snap_lname# (#snap_email#)")>

<!--- Send email to cost center --->
	<cfif application.OverrideEmail NEQ "">
		<cfset this_to = application.OverrideEmail>
		<cfset this_cc = application.OverrideEmail>
	<cfelse>
		<cfset this_to = url.email>
		<cfset this_cc = url.email_cc>
	</cfif>
	<cfmail to="#this_to#" from="#FindProgramInfo.orders_from#" subject="#FindProgramInfo.company_name# Cost Center order" cc="#this_cc#" failto="#Application.OrdersFailTo#" type="html">
		<cfif application.OverrideEmail NEQ "">
			Emails are being overridden.<br>
			Below is the email that would have been sent to #url.email# and cc to #url.email_cc#<br>
			<hr>
		</cfif>
		#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
		Dear #url.approver#,<br><br>
		An order was charged to cost center #url.cc_number#.<br><br>
		Log in to <a href="#application.SecureWebPath#/admin/index.cfm?o=#url.o#">#application.AdminName# admin</a> to approve or decline this order.<br><br>
		Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
		PHONE: #snap_phone#<br><br>
		<cfif snap_ship_address1 NEQ "">
			SHIPPING ADDRESS:<br>
			#snap_ship_fname# #snap_ship_lname#<br>
			#snap_ship_address1#<br>
			<cfif Trim(snap_ship_address2) NEQ "">
				#snap_ship_address2#<br>
			</cfif>
			#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br><br>
			<cfif shipping_desc NEQ "">
				Ship via #shipping_desc#: #shipping_charge#<br><br>
			</cfif>
			<cfif snap_signature_charge GT 0>
				Signature Required Charge: #snap_signature_charge#<br><br>
			</cfif>
		</cfif>
		ITEM(S) IN ORDER:
		<cfloop query="FindOrderItems">
			#quantity# - #snap_meta_name# #snap_options#
			<cfif FindProgramInfo.is_one_item EQ 0 AND NOT FindProgramInfo.hide_points>
				(#NumberFormat(snap_productvalue * FindProgramInfo.credit_multiplier)# #FindProgramInfo.credit_desc#)
			</cfif>
			<br>
		</cfloop>
		<br>
		<cfif FindProgramInfo.is_one_item EQ 0 AND NOT FindProgramInfo.hide_points>
			Order Total: #NumberFormat(snap_order_total* FindProgramInfo.credit_multiplier)#<br>
			<cfif cost_center_charge GT 0>
				Charged to Cost Center: #cost_center_charge#<br>
			</cfif>
			<cfif credit_card_charge GT 0>
				Charged to Credit Card: #credit_card_charge#<br>
			</cfif>
			<br>
		</cfif>
		ORDER NOTE:<br>
		<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
	</cfmail>
	<!--- send notification email(s) ---->
	<cfif FindProgramInfo.cost_center_notification neq "">
		<cfloop list="#FindProgramInfo.cost_center_notification#" index="thisemail">
			<cfif application.OverrideEmail NEQ "">
				<cfset this_to = application.OverrideEmail>
			<cfelse>
				<cfset this_to = thisemail>
			</cfif>
			<cfmail to="#this_to#" from="#FindProgramInfo.orders_from#" subject="#FindProgramInfo.program_email_subject# - Cost Center Order #order_number#" failto="#Application.OrdersFailTo#" type="html">
				<cfif application.OverrideEmail NEQ "">
					Emails are being overridden.<br>
					Below is the email that would have been sent to #thisemail#<br>
					<hr>
				</cfif>
				#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
				Cost Center Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
				This order needs to be approved by a cost center approver.<br><br>
				PHONE: #snap_phone#<br><br>
				<cfif snap_ship_address1 NEQ "">
					SHIPPING ADDRESS:<br>
					#snap_ship_fname# #snap_ship_lname#<br>
					#snap_ship_address1#<br>
					<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2#<br></cfif>
					#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br><br>
					<cfif shipping_desc NEQ "">
						Ship via #shipping_desc#: #shipping_charge#<br><br>
					</cfif>
					<cfif snap_signature_charge GT 0>
						Signature Required Charge: #snap_signature_charge#<br><br>
					</cfif>
				</cfif>
				ITEM(S) IN ORDER:
				<cfloop query="FindOrderItems">
					#quantity# - [sku:#snap_sku#] #snap_meta_name# #snap_options# (#snap_productvalue*FindProgramInfo.credit_multiplier# #FindProgramInfo.credit_desc#)<br>
				</cfloop>
				<br>
				<cfif FindProgramInfo.is_one_item EQ 0 AND NOT FindProgramInfo.hide_points>
					Order Total: #snap_order_total*FindProgramInfo.credit_multiplier#<br>
				</cfif>
				<cfif cost_center_charge GT 0>
					Charged to Cost Center: #cost_center_charge#<br>
				</cfif>
				<cfif credit_card_charge GT 0>
					Charged to Credit Card: #credit_card_charge#<br>
				</cfif>
				<br>
				ORDER NOTE:
				<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
			</cfmail>
		</cfloop>
	</cfif>
<cflocation url="order_pending.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#&sentit=1" addtoken="false">
</cfif>