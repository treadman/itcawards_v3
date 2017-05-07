<cfsetting requesttimeout="600">
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014, true)>

<cfparam name="pgfn" default="n/a">

<cfparam name="url.subdivision_ID" default="0">

<cfswitch expression="#pgfn#">
	<cfcase value="unassigned_orders">
		<cfquery name="getDefaultDiv" datasource="#application.DS#">
			SELECT default_division
			FROM #application.database#.program
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfquery>
		<cfset default_div = getDefaultDiv.default_division>
		<cfif default_div EQ 0>
			<cfabort showerror="Default division not set for #request.program_name#">
		</cfif>
		<cfquery name="getAllOrders" datasource="#application.DS#">
			SELECT o.ID, o.created_user_ID, o.created_datetime, o.order_number, o.points_used
			FROM #application.database#.order_info o
			WHERE o.program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" 
		              value="#request.selected_program_ID#" maxlength="10">
			AND o.is_valid = 1
			AND o.points_used > 0
			ORDER BY o.created_datetime ASC
		</cfquery>
		<cfloop query="getAllOrders">
			<cfset total_for_order = getAllOrders.points_used>
			<cfloop from="1" to="99" index="until_all_fixed">
				<cfset fix_it = false>
				<cfquery name="getDivOrders" datasource="#application.DS#">
					SELECT o.ID, o.created_user_ID, o.created_datetime, o.order_number, o.credit_card_charge,
					x.award_points AS points_used, x.division_id
					FROM #application.database#.xref_order_division x
					LEFT JOIN #application.database#.order_info o on x.order_ID = o.ID
					LEFT JOIN #application.database#.program p ON p.ID = x.division_ID
					WHERE o.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#getAllOrders.ID#">
					AND o.is_valid = 1
					ORDER BY x.division_ID ASC
				</cfquery>
				<cfoutput>
					<cfset total_points = 0>
					<cfif getDivOrders.recordcount gt 0>
						<cfloop query="getDivOrders">
							<cfset total_points = total_points + getDivOrders.points_used>
						</cfloop>
					</cfif>
					<cfif total_points NEQ total_for_order>
						<cfset fix_it = true>
					</cfif>
					<cfif fix_it>
						<cfset fixed_any = true>
						<!--- TODO: has_address_verification needs to be from parent --->
						<cfquery name="GetDivisionPoints" datasource="#application.DS#">
							SELECT p.ID, p.company_name, p.program_name, p.welcome_button, SUM(IFNULL(a.points,0)) AS points_awarded, p.has_address_verification
							FROM #application.database#.program p
							LEFT JOIN #application.database#.awards_points a ON a.division_ID = p.ID AND a.user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#getAllOrders.created_user_id#" maxlength="10">
							WHERE parent_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
							AND a.created_datetime < '#getAllOrders.created_datetime#'
							GROUP BY p.ID
							HAVING points_awarded > 0
						</cfquery>
						<cfset divOrderPoints = StructNew()>
						<cfloop query="GetDivisionPoints">
							<cfset divOrderPoints[GetDivisionPoints.ID] = GetDivisionPoints.points_awarded>
						</cfloop>
						<cfquery name="GetDivisionOrders" datasource="#application.DS#">
							SELECT p.ID, IFNULL(SUM(x.award_points),0) AS points_used, x.division_id
							FROM #application.database#.order_info o
							LEFT JOIN #application.database#.xref_order_division x ON x.order_ID = o.ID
							LEFT JOIN #application.database#.program p ON p.ID = x.division_ID
							WHERE o.created_user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#getAllOrders.created_user_id#" maxlength="10">
							AND ( o.is_valid = 1
							<cfif GetDivisionPoints.has_address_verification>
								OR o.approval = 1
							</cfif>
							)
							GROUP BY p.ID
						HAVING points_used > 0
						</cfquery>
						<cfif GetDivisionOrders.recordCount GT 0>
							<cfloop query="GetDivisionOrders">
								<cfset divOrderPoints[GetDivisionOrders.division_id] = divOrderPoints[GetDivisionOrders.division_id] - GetDivisionOrders.points_used>
							</cfloop>
						</cfif>
						<cfloop from="1" to="2" index="assign_div">
							<cfset points_added = 0>
							<cfset div_id = 0>
							<cfloop collection="#divOrderPoints#" item="this_div">
								<cfif assign_div EQ 2 OR this_div NEQ default_div>
									<cfset points_added = Min(total_for_order, divOrderPoints[this_div])>
									<cfset div_id = this_div>
								</cfif>
							</cfloop>
							<cfif points_added GT 0>
								<cfbreak>
							</cfif>
						</cfloop>
						<cfif points_added LTE 0>
							<cfabort showerror="Unable to assign points to order #getAllOrders.ID#!">
						</cfif>
						<cfquery name="AssignOrderToDiv" datasource="#application.DS#">
						    INSERT INTO #application.database#.xref_order_division
						        (created_user_ID, created_datetime, order_ID, division_ID, award_points)
						    VALUES (
						        <cfqueryparam cfsqltype="cf_sql_integer" value="#getAllOrders.created_user_ID#" maxlength="10">,
						        '#FLGen_DateTimeToMySQL()#',
						        <cfqueryparam cfsqltype="cf_sql_integer" value="#getAllOrders.ID#" maxlength="10">,
						        <cfqueryparam cfsqltype="cf_sql_integer" value="#div_id#" maxlength="10">,
						        <cfqueryparam cfsqltype="cf_sql_integer" value="#points_added#" maxlength="10">
						    )
						</cfquery>
						<cfset total_for_order = total_for_order - points_added>
						<cfif total_for_order LT 0>
							<cfabort showerror="Assign points too many points from division #GetDivisionPoints.division_id# on order #getAllOrders.ID#!">
						<cfelseif total_for_order EQ 0>
							<cfbreak>
						</cfif>
					<cfelse>
						<cfbreak>
					</cfif>
				</cfoutput>
			</cfloop>
			<cfif until_all_fixed GT 88>
				<cfabort showerror="Something wrong with order #getAllOrders.ID#!">
			</cfif>
		</cfloop>
		<cflocation url="report_bill_new.cfm" addtoken="false">
	</cfcase>
	<cfcase value="unassigned_points">
		<cfquery name="AssignPointsDivision" datasource="#application.DS#">
			UPDATE #application.database#.awards_points a
			INNER JOIN #application.database#.program_user u
			ON u.ID = a.user_ID
			AND u.program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
			AND a.division_ID = 0
			SET a.division_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">,
				a.subdivision_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#url.subdivision_ID#" maxlength="10">
		</cfquery>
		<cflocation url="program_details.cfm" addtoken="false">
	</cfcase>
	<cfcase value="add">
		<cfquery name="AddDivision" datasource="#application.DS#">
			INSERT INTO #application.database#.program
			(
			parent_ID,
			created_user_ID,
			created_datetime,
			modified_concat,
			company_name,
			program_name,
			expiration_date,
			is_one_item,
			can_defer,
			defer_msg,
			has_welcomepage,
			welcome_bg,
			welcome_instructions,
			welcome_message,
			welcome_congrats,
			welcome_button,
			welcome_admin_button,
			admin_logo,
			default_category,
			logo,
			cross_color,
			main_bg,
			main_congrats,
			main_instructions,
			return_button,
			text_active,
			bg_active,
			text_selected,
			bg_selected,
			cart_exceeded_msg,
			cc_exceeded_msg,
			orders_to,
			orders_from,
			conf_email_text,
			program_email_subject,
			has_survey,
			display_col,
			display_row,
			menu_text,
			credit_desc,
			accepts_cc,
			login_prompt,
			is_active,
			display_welcomeyourname,
			display_youhavexcredits,
			credit_multiplier,
			points_multiplier,
			email_form_button,
			email_form_message,
			email_form_recipient,
			additional_content_button,
			additional_content_message,
			help_button,
			help_message,
			additional_content_button_unapproved,
			additional_content_message_unapproved,
			additional_content_program_admin_ID,
			welcome_certificate,
			welcome_certificate_style,
			has_password_recovery,
			use_master_categories,
			show_landing_text,
			landing_text,
			has_register,
			register_email_domain,
			register_page_text,
			register_form_text,
			email_login,
			chooser_text,
			login_text,
			charge_shipping,
			hide_points,
			add_shipping,
			get_shipping_address,
			show_thumbnail_in_cart,
			one_item_over_message,
			bg_warning,
			delivery_message,
			cc_shipping,
			uses_shipping_locations,
			inactivate_zero_inventory,
			cost_center_notification,
			language_ID,
			forward_button,
			forwarder_ID,
			shipping_location_message1,
			shipping_location_message2,
			shipping_location_message3,
			signature_charge,
			product_set_tabs,
			product_set_text,
			show_inventory,
			has_main_menu_button,
			register_template_id,
			register_email_subject,
			register_get_shipping
			)
			SELECT #request.selected_program_id#,#FLGen_adminID#,
			NOW(),
			'',
			CONCAT(p.company_name,' - Division'),
			CONCAT(p.program_name,' - Division'),
			p.expiration_date,
			p.is_one_item,
			p.can_defer,
			p.defer_msg,
			p.has_welcomepage,
			p.welcome_bg,
			p.welcome_instructions,
			p.welcome_message,
			p.welcome_congrats,
			p.welcome_button,
			p.welcome_admin_button,
			p.admin_logo,
			p.default_category,
			p.logo,
			p.cross_color,
			p.main_bg,
			p.main_congrats,
			p.main_instructions,
			p.return_button,
			p.text_active,
			p.bg_active,
			p.text_selected,
			p.bg_selected,
			p.cart_exceeded_msg,
			p.cc_exceeded_msg,
			p.orders_to,
			p.orders_from,
			p.conf_email_text,
			p.program_email_subject,
			p.has_survey,
			p.display_col,
			p.display_row,
			p.menu_text,
			p.credit_desc,
			p.accepts_cc,
			p.login_prompt,
			p.is_active,
			p.display_welcomeyourname,
			p.display_youhavexcredits,
			p.credit_multiplier,
			p.points_multiplier,
			p.email_form_button,
			p.email_form_message,
			p.email_form_recipient,
			p.additional_content_button,
			p.additional_content_message,
			p.help_button,
			p.help_message,
			p.additional_content_button_unapproved,
			p.additional_content_message_unapproved,
			p.additional_content_program_admin_ID,
			p.welcome_certificate,
			p.welcome_certificate_style,
			p.has_password_recovery,
			p.use_master_categories,
			p.show_landing_text,
			p.landing_text,
			p.has_register,
			p.register_email_domain,
			p.register_page_text,
			p.register_form_text,
			p.email_login,
			p.chooser_text,
			p.login_text,
			p.charge_shipping,
			p.hide_points,
			p.add_shipping,
			p.get_shipping_address,
			p.show_thumbnail_in_cart,
			p.one_item_over_message,
			p.bg_warning,
			p.delivery_message,
			p.cc_shipping,
			p.uses_shipping_locations,
			p.inactivate_zero_inventory,
			p.cost_center_notification,
			p.language_ID,
			p.forward_button,
			p.forwarder_ID,
			p.shipping_location_message1,
			p.shipping_location_message2,
			p.shipping_location_message3,
			p.signature_charge,
			p.product_set_tabs,
			p.product_set_text,
			p.show_inventory,
			p.has_main_menu_button,
			p.register_template_id,
			p.register_email_subject,
			p.register_get_shipping
			FROM #application.database#.program p
			WHERE ID = #request.selected_program_id#
		</cfquery>
		<cflocation url="program_details.cfm" addtoken="false">
	</cfcase>
	<cfdefaultcase>
		<cfabort showerror="#pgfn# is not valid.">
	</cfdefaultcase>
</cfswitch>
