<cfabort showerror="itcawards_v3.com/admin/program_import.cfm is not ready for prime time!!">
<cfset pgfn = "start">

<!--- WJD SWS --->
<cfset thisProgramID = "1000000082">

<!--- Delete things first?!? --->

<cfif isDefined("form.submit") AND isDefined("form.ok2continue")>
	<!--- Import program --->
	<cfquery name="CreateProgram" datasource="#application.DS#">
		INSERT INTO #application.database#.program
			(ID, created_user_ID, created_datetime, modified_concat, company_name, program_name, expiration_date, is_one_item, can_defer, defer_msg, has_welcomepage,
				welcome_bg, welcome_instructions, welcome_message, welcome_congrats, welcome_button, welcome_admin_button, admin_logo, default_category, logo,
				cross_color, main_bg, main_congrats, main_instructions, return_button, text_active, bg_active, text_selected, bg_selected, cart_exceeded_msg,
				cc_exceeded_msg, orders_to, orders_from, conf_email_text, program_email_subject, has_survey, display_col, display_row, menu_text, credit_desc,
				accepts_cc, login_prompt, is_active, display_welcomeyourname, display_youhavexcredits, credit_multiplier, points_multiplier, email_form_button,
				email_form_message, email_form_recipient, additional_content_button, additional_content_message, help_button, help_message,
				additional_content_button_unapproved, additional_content_message_unapproved, additional_content_program_admin_ID, welcome_certificate,
				welcome_certificate_style, has_password_recovery, use_master_categories)
			SELECT ID, created_user_ID, created_datetime, modified_concat, company_name, program_name, expiration_date, is_one_item, can_defer, defer_msg, has_welcomepage,
				welcome_bg, welcome_instructions, welcome_message, welcome_congrats, welcome_button, welcome_admin_button, admin_logo, default_category, logo,
				cross_color, main_bg, main_congrats, main_instructions, return_button, text_active, bg_active, text_selected, bg_selected, cart_exceeded_msg,
				cc_exceeded_msg, orders_to, orders_from, conf_email_text, program_email_subject, has_survey, display_col, display_row, menu_text, credit_desc,
				accepts_cc, login_prompt, is_active, display_welcomeyourname, display_youhavexcredits, credit_multiplier, points_multiplier, email_form_button,
				email_form_message, email_form_recipient, additional_content_button, additional_content_message, help_button, help_message,
				additional_content_button_unapproved, additional_content_message_unapproved, additional_content_program_admin_ID, welcome_certificate,
				welcome_certificate_style, has_password_recovery, use_master_categories
			FROM #Application.product_database#.program
			WHERE ID = #thisProgramID#
	</cfquery>
	<!--- Import program_product_exclude --->
	<cfquery name="CreateProgramProductExclude" datasource="#application.DS#">
		INSERT INTO #application.database#.program_product_exclude
				(created_user_ID, created_datetime, program_ID, product_ID)
			SELECT created_user_ID, created_datetime, program_ID, product_ID
			FROM #Application.product_database#.program_product_exclude
			WHERE program_ID = #thisProgramID#
	</cfquery>
	<!--- Import program_login --->
	<cfquery name="CreateProgramLogin" datasource="#application.DS#">
		INSERT INTO #application.database#.program_login
				(created_user_ID, created_datetime, modified_concat, program_ID, username, password)
			SELECT created_user_ID, created_datetime, modified_concat, program_ID, username, password
			FROM #Application.product_database#.program_login
			WHERE program_ID = #thisProgramID#
	</cfquery>
	<!--- Get Program Users --->
	<cfquery name="ProgramUsers" datasource="#application.DS#">
		SELECT ID
		FROM #Application.product_database#.program_user
		WHERE program_ID = #thisProgramID#
	</cfquery>
	<cfloop query="ProgramUsers">
		<cfset oldProgramUserID = ProgramUsers.ID>
		<cfquery name="CreateUser" datasource="#application.DS#">
			INSERT INTO #application.database#.program_user
				(	created_user_ID, created_datetime, modified_concat, program_ID, username,
					nickname, fname, lname, ship_company, ship_fname, ship_lname, ship_address1,
					ship_address2, ship_city, ship_state, ship_zip, ship_country, phone, email,
					bill_company, bill_fname, bill_lname, bill_address1, bill_address2, bill_city,
					bill_state, bill_zip, cc_max, is_active, is_done, defer_allowed, expiration_date,
					entered_by_program_admin, supervisor_email, level_of_award
				)
				SELECT created_user_ID, created_datetime, modified_concat, program_ID, username,
					nickname, fname, lname, ship_company, ship_fname, ship_lname, ship_address1,
					ship_address2, ship_city, ship_state, ship_zip, ship_country, phone, email,
					bill_company, bill_fname, bill_lname, bill_address1, bill_address2, bill_city,
					bill_state, bill_zip, cc_max, is_active, is_done, defer_allowed, expiration_date,
					entered_by_program_admin, supervisor_email, level_of_award
				FROM #Application.product_database#.program_user
				WHERE ID = #oldProgramUserID#
		</cfquery>
		<cfquery datasource="#application.DS#" name="getID">
			SELECT Max(ID) As MaxID FROM #application.database#.program_user
		</cfquery>
		<cfset newProgramUserID = getID.MaxID>
		<!--- Create Awards Points --->
		<cfquery name="CreateAwardsPoints" datasource="#application.DS#">
			INSERT INTO #application.database#.awards_points
				(created_user_ID, created_datetime, modified_concat, user_ID, points, notes, is_defered)
				SELECT created_user_ID, created_datetime, modified_concat, #newProgramUserID#, points, notes, is_defered
				FROM #Application.product_database#.awards_points
				WHERE user_ID = #oldProgramUserID#
		</cfquery>
		<!--- Create orders --->
		<cfquery name="Orders" datasource="#application.DS#">
			SELECT ID
			FROM #Application.product_database#.order_info
			WHERE created_user_ID = #oldProgramUserID#
		</cfquery>
		<cfloop query="Orders">
			<cfset oldOrderID = Orders.ID>
			<cfquery name="CreateOrder" datasource="#application.DS#">
				INSERT INTO #application.database#.order_info
					(	created_user_ID, created_datetime, modified_concat, is_valid, program_ID, order_number, snap_order_total, points_used,
						credit_card_charge, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2,
						snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, order_note, snap_bill_fname, snap_bill_lname,
						snap_bill_company, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip, x_auth_code,
						x_tran_id, email_conf_sent, is_all_shipped, multiplier_used, credit_multiplier, points_multiplier
					)
					SELECT created_user_ID, created_datetime, modified_concat, is_valid, program_ID, order_number, snap_order_total, points_used,
						credit_card_charge, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2,
						snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, order_note, snap_bill_fname, snap_bill_lname,
						snap_bill_company, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip, x_auth_code,
						x_tran_id, email_conf_sent, is_all_shipped, multiplier_used, credit_multiplier, points_multiplier
					FROM #Application.product_database#.order_info
					WHERE ID = #oldOrderID#
			</cfquery>
			<cfquery datasource="#application.DS#" name="getNewOrderID">
				SELECT Max(ID) As MaxID FROM #application.database#.order_info
			</cfquery>
			<cfset newOrderID = getNewOrderID.MaxID>
			<!--- Create Inventory --->
			<cfquery name="CreateInventory" datasource="#application.DS#">
				INSERT INTO #application.database#.inventory
					(	created_user_ID, created_datetime, modified_concat, is_valid, product_ID, quantity, order_ID, snap_meta_name, snap_description,
						snap_sku, snap_productvalue, snap_options, snap_is_dropshipped, note, ship_date, tracking, po_ID, snap_vendor, drop_date, po_quantity,
						po_rec_date, snap_vendor_sku, upsgroup_ID)
					SELECT created_user_ID, created_datetime, modified_concat, is_valid, product_ID, quantity, #newOrderID#, snap_meta_name, snap_description,
						snap_sku, snap_productvalue, snap_options, snap_is_dropshipped, note, ship_date, tracking, po_ID, snap_vendor, drop_date, po_quantity,
						po_rec_date, snap_vendor_sku, upsgroup_ID
					FROM #Application.product_database#.inventory
					WHERE order_ID = #oldOrderID#
			</cfquery>
		</cfloop>
	</cfloop>
	<cfset pgfn = "done">
</cfif>

<span class="pagetitle">Import Program from Awards 2</span><br><br>

<cfif pgfn EQ "start">
	<cfoutput>
	<span class="alert">This will copy all program information from Awards 2.</span><br><br>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<form action="#CurrentPage#" method="post" name="importForm">
		Check to confirm: <input type="checkbox" name="ok2continue" value="1" />
		<input type="submit" name="submit" value="   Import   " />
	</form>
	</cfoutput>
<cfelseif pgfn EQ "done">
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Done Importing!
</cfif>

