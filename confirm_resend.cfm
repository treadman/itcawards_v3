<cfabort showerror="confirm_resend.cfm should only be used by the developer!">



<!---  OVERRIDE EMAIL IS NOT IMPLEMENTED HERE YET --->



<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<cfset this_carttotal = 0>

<!--- Tom Hochleutner --->
<!---<cfset order_ID = 5298>
<cfset program_ID = 1000000096>
<cfset snap_order_total = 54>
<cfset points_used = 50>
<cfset user_total = 50>
<cfset cost_center_number = "">--->

<!--- Mike O'Callaghan --->
<!---<cfset order_ID = 5299>
<cfset program_ID = 1000000096>
<cfset snap_order_total = 13>
<cfset points_used = 13>
<cfset user_total = 50>
<cfset cost_center_number = "">--->


<cfquery name="SelectProgramInfo" datasource="#application.DS#">
	SELECT company_name, program_name, is_one_item, IF(can_defer=1,"true","false") AS can_defer, defer_msg,
			welcome_bg, welcome_instructions, welcome_message, welcome_congrats, welcome_button, welcome_admin_button, admin_logo, default_category,
			logo, cross_color, main_bg, main_congrats, main_instructions, return_button, text_active, bg_active, text_selected, bg_selected,
			cart_exceeded_msg, cc_exceeded_msg, orders_to, orders_from, conf_email_text, program_email_subject,show_landing_text, landing_text,
			IF(has_survey=1,"true","false") AS has_survey, has_password_recovery, display_col, display_row, menu_text, credit_desc, accepts_cc, login_prompt,
			display_welcomeyourname, display_youhavexcredits, credit_multiplier, points_multiplier, additional_content_button, additional_content_message,
			email_form_button, email_form_message, email_form_recipient, help_button, help_message, use_master_categories, has_register, register_email_domain,
			register_page_text, register_form_text, has_welcomepage, email_login, chooser_text, login_text, hide_points, get_shipping_address,show_thumbnail_in_cart,
			bg_warning,one_item_over_message, delivery_message, cc_shipping, uses_shipping_locations, inactivate_zero_inventory, cost_center_notification,
			language_ID, show_inventory,
			CASE
			 	WHEN charge_shipping <= CURDATE() THEN 1
				ELSE 0
			END AS charge_shipping,
			add_shipping, signature_charge
	FROM #application.database#.program
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
</cfquery>
<!--- set vars --->
<cfset company_name = HTMLEditFormat(SelectProgramInfo.company_name)>
<cfset program_name = HTMLEditFormat(SelectProgramInfo.program_name)>
<cfset is_one_item = SelectProgramInfo.is_one_item>
<cfset can_defer = SelectProgramInfo.can_defer>
<cfset defer_msg = SelectProgramInfo.defer_msg>
<cfset welcome_bg = HTMLEditFormat(SelectProgramInfo.welcome_bg)>
<cfset welcome_instructions = SelectProgramInfo.welcome_instructions>
<cfset welcome_message = SelectProgramInfo.welcome_message>
<cfset welcome_congrats = HTMLEditFormat(SelectProgramInfo.welcome_congrats)>
<cfset welcome_button = SelectProgramInfo.welcome_button>
<cfset welcome_admin_button = SelectProgramInfo.welcome_admin_button>
<cfset default_category = HTMLEditFormat(SelectProgramInfo.default_category)>
<cfset admin_logo = HTMLEditFormat(SelectProgramInfo.admin_logo)>
<cfset logo = HTMLEditFormat(SelectProgramInfo.logo)>
<cfset cross_color = HTMLEditFormat(SelectProgramInfo.cross_color)>
<cfset main_bg = HTMLEditFormat(SelectProgramInfo.main_bg)>
<cfset main_congrats = HTMLEditFormat(SelectProgramInfo.main_congrats)>
<cfset main_instructions = HTMLEditFormat(SelectProgramInfo.main_instructions)>
<cfset return_button = HTMLEditFormat(SelectProgramInfo.return_button)>
<cfset text_active = HTMLEditFormat(SelectProgramInfo.text_active)>
<cfset bg_active = HTMLEditFormat(SelectProgramInfo.bg_active)>
<cfset text_selected = HTMLEditFormat(SelectProgramInfo.text_selected)>
<cfset bg_selected = HTMLEditFormat(SelectProgramInfo.bg_selected)>
<cfset cart_exceeded_msg = HTMLEditFormat(SelectProgramInfo.cart_exceeded_msg)>
<cfset cc_exceeded_msg = HTMLEditFormat(SelectProgramInfo.cc_exceeded_msg)>
<cfset orders_to = HTMLEditFormat(SelectProgramInfo.orders_to)>		
<cfset orders_from = HTMLEditFormat(SelectProgramInfo.orders_from)>
<cfset conf_email_text = HTMLEditFormat(SelectProgramInfo.conf_email_text)>
<cfset program_email_subject = HTMLEditFormat(SelectProgramInfo.program_email_subject)>
<cfset has_survey = HTMLEditFormat(SelectProgramInfo.has_survey)>		
<cfset display_col = HTMLEditFormat(SelectProgramInfo.display_col)>
<cfset display_row = HTMLEditFormat(SelectProgramInfo.display_row)>
<cfset menu_text = HTMLEditFormat(SelectProgramInfo.menu_text)>
<cfset credit_desc = HTMLEditFormat(SelectProgramInfo.credit_desc)>
<cfset accepts_cc = HTMLEditFormat(SelectProgramInfo.accepts_cc)>
<cfset login_prompt = HTMLEditFormat(SelectProgramInfo.login_prompt)>
<cfset display_welcomeyourname = HTMLEditFormat(SelectProgramInfo.display_welcomeyourname)>
<cfset display_youhavexcredits = HTMLEditFormat(SelectProgramInfo.display_youhavexcredits)>
<cfset credit_multiplier = HTMLEditFormat(SelectProgramInfo.credit_multiplier)>
<cfset points_multiplier = HTMLEditFormat(SelectProgramInfo.points_multiplier)>
<cfset additional_content_button = SelectProgramInfo.additional_content_button>
<cfset additional_content_message = SelectProgramInfo.additional_content_message>
<cfset email_form_button = SelectProgramInfo.email_form_button>
<cfset email_form_message = SelectProgramInfo.email_form_message>
<cfset email_form_recipient = SelectProgramInfo.email_form_recipient>
<cfset help_button = SelectProgramInfo.help_button>
<cfset help_message = SelectProgramInfo.help_message>
<cfset use_master_categories = SelectProgramInfo.use_master_categories>
<cfset show_landing_text = SelectProgramInfo.show_landing_text>
<cfset landing_text = SelectProgramInfo.landing_text>
<cfset has_register = SelectProgramInfo.has_register>
<cfset email_login = SelectProgramInfo.email_login>
<cfset register_email_domain = SelectProgramInfo.register_email_domain>
<cfset register_page_text = SelectProgramInfo.register_page_text>
<cfset register_form_text = SelectProgramInfo.register_form_text>
<cfset has_welcomepage = SelectProgramInfo.has_welcomepage>
<cfset has_password_recovery = SelectProgramInfo.has_password_recovery>
<cfset chooser_text = SelectProgramInfo.chooser_text>
<cfset login_text = SelectProgramInfo.login_text>
<cfset cc_shipping = SelectProgramInfo.cc_shipping>
<cfset charge_shipping = SelectProgramInfo.charge_shipping>
<cfset add_shipping = SelectProgramInfo.add_shipping>
<cfset signature_charge = SelectProgramInfo.signature_charge>
<cfset hide_points = SelectProgramInfo.hide_points>
<cfset get_shipping_address = SelectProgramInfo.get_shipping_address>
<cfset show_thumbnail_in_cart = SelectProgramInfo.show_thumbnail_in_cart>
<cfset bg_warning = SelectProgramInfo.bg_warning>
<cfset one_item_over_message = SelectProgramInfo.one_item_over_message>
<cfset delivery_message = SelectProgramInfo.delivery_message>
<cfset uses_shipping_locations = SelectProgramInfo.uses_shipping_locations>
<cfset inactivate_zero_inventory = SelectProgramInfo.inactivate_zero_inventory>
<cfset cost_center_notification = HTMLEditFormat(SelectProgramInfo.cost_center_notification)>		
<cfset language_ID = SelectProgramInfo.language_ID>
<cfset show_inventory = SelectProgramInfo.show_inventory>


<!--- get order info --->
<cfquery name="FindOrderInfo" datasource="#application.DS#">
	SELECT snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip,
		snap_phone, snap_email, snap_bill_company, snap_bill_fname, snap_bill_lname, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip,
		order_note,	shipping_desc, shipping_charge, snap_signature_charge, credit_card_charge, cost_center_charge, order_number
	FROM #application.database#.order_info
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
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
	WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
</cfquery>

<cfquery name="SelectInfo" datasource="#application.DS#">
	SELECT meta_conf_email_text
	FROM #application.database#.program_meta
</cfquery>

<cfset meta_conf_email_text = HTMLEditFormat(SelectInfo.meta_conf_email_text)>

<!--- send email confirmation, if requested --->
<cfset this_subject = Replace(Translate(language_ID,'confirmation_email_subject'),'[company_name]',company_name)>
<cfset order_for = Translate(language_ID,'order_number_for')>
<cfset order_for = Replace(order_for,'[order_number]',order_number)>
<cfset order_for = Replace(order_for,'[user_name]',"#snap_fname# #snap_lname# (#snap_email#)")>

<cfoutput>Send to #snap_email#</cfoutput>
<!---<cfset snap_email = 'treadmen@hotmail.com'>--->

<cfmail to="#snap_email#" from="#orders_from#" subject="#this_subject#" failto="#Application.OrdersFailTo#" type="html">
	#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
	#this_subject#<br><br>
	<cfif delivery_message NEQ "" AND meta_conf_email_text NEQ "">
		#meta_conf_email_text#<br><br>
	</cfif>
	<cfif conf_email_text NEQ "">
		#conf_email_text#<br><br>
	</cfif>
	#order_for#<br><br>
	#Translate(language_ID,'phone_text')#: #snap_phone#<br><br>
	<cfif get_shipping_address>
		#Translate(language_ID,'shipping_address')#:<br>
		#snap_ship_fname# #snap_ship_lname##CHR(10)#<br>
		#snap_ship_address1##CHR(10)#<br>
		<cfif Trim(snap_ship_address2) NEQ "">
			#snap_ship_address2##CHR(10)#<br>
		</cfif>
		#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br><br>
		<cfif shipping_desc NEQ "">
			#Translate(language_ID,'ship_via')# #shipping_desc#: #shipping_charge#<br><br>
		</cfif>
		<cfif snap_signature_charge GT 0>
			Signature Required Charge: #snap_signature_charge#<br><br>
		</cfif>
	</cfif>
	#Translate(language_ID,'item_in_order')#:<br>
	<cfloop query="FindOrderItems">
		#quantity# - #snap_meta_name# #snap_options#
		<cfif is_one_item EQ 0 AND NOT hide_points>
			(#NumberFormat(snap_productvalue * credit_multiplier)# #credit_desc#
		</cfif>
		<br>
	</cfloop>
	<br>
	<cfif is_one_item EQ 0 AND NOT hide_points>
		#Translate(language_ID,'order_total')#: #NumberFormat(snap_order_total* credit_multiplier)#<br>
		#credit_desc# Used: #NumberFormat(points_used * credit_multiplier)#<br>
		#credit_desc# Left: #NumberFormat((user_total* points_multiplier) - (points_used*credit_multiplier))#<br>
		<cfif cost_center_charge GT 0>
			Charged to Cost Center: #cost_center_charge#<br>
		</cfif>
		<cfif credit_card_charge GT 0>
			Charged to Credit Card: #credit_card_charge#<br>
		</cfif>
	</cfif>
	<br>
	#Translate(language_ID,'order_note')#:
	<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
</cfmail>

<!--- Send email to cost center --->
<cfif cost_center_number neq "">
	<cfloop query="GetLevel1">
		<cfset this_email = GetLevel1.email>
		<!---<cfset this_email = 'treadmen@hotmail.com'>--->
		<cfmail to="#this_email#" from="#orders_from#" subject="#company_name# Cost Center order" failto="#Application.OrdersFailTo#" type="html">
			#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
			Dear #GetLevel1.firstname# #GetLevel1.lastname#,<br><br>
			An order was charged to cost center #GetLevel1.number#<cfif GetLevel1.description neq ""> - #GetLevel1.description#</cfif>.<br><br>
			Log in to <a href="#application.SecureWebPath#/admin/index.cfm?o=#cost_center_code#">#application.AdminName# admin</a> to approve or decline this order.<br><br>
			Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
			PHONE: #snap_phone#<br><br>
			<cfif get_shipping_address>
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
				<cfif is_one_item EQ 0 AND NOT hide_points>
					(#NumberFormat(snap_productvalue * credit_multiplier)# #credit_desc#)accepts_cc
				</cfif>
				<br>
			</cfloop>
			<br>
			<cfif is_one_item EQ 0 AND NOT hide_points>
				Order Total: #NumberFormat(snap_order_total* credit_multiplier)#<br>
				#credit_desc# Used: #NumberFormat(points_used * credit_multiplier)#<br>
				#credit_desc# Left: #NumberFormat((user_total* points_multiplier) - (points_used*credit_multiplier))#<br>
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
	</cfloop>
	<!--- send notification email(s) ---->
	<cfif cost_center_notification neq "">
		<cfloop list="#cost_center_notification#" index="thisemail">
			<cfset this_email = thisemail>
			<!---<cfset this_email = 'treadmen@hotmail.com'>--->
			<cfmail to="#this_email#" from="#orders_from#" subject="#program_email_subject# - Cost Center Order #order_number#" failto="#Application.OrdersFailTo#" type="html">
				#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
				Cost Center Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
				This order needs to be approved by a cost center approver.<br><br>
				PHONE: #snap_phone#<br><br>
				<cfif get_shipping_address>
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
					#quantity# - [sku:#snap_sku#] #snap_meta_name# #snap_options# (#snap_productvalue*credit_multiplier# #credit_desc#)<br>
				</cfloop>
				<br>
				<cfif is_one_item GT 0>
					This is a #is_one_item#-ITEM award program<br>
				<cfelseif NOT hide_points>
					Order Total: #snap_order_total*credit_multiplier#<br>
					#credit_desc# Used: #points_used*credit_multiplier#<br>
					#credit_desc# Left: #(user_total*points_multiplier) - (points_used*credit_multiplier)#<br>
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
</cfif>

<!--- Send email to ITC --->
<cfif cost_center_number eq "">
	<!--- send New Order email(s) ---->
	<cfloop list="#orders_to#" index="thisemail">
		<cfset this_email = thisemail>
		<!---<cfset this_email = 'treadmen@hotmail.com'>--->
		<cfmail to="#this_email#" from="#orders_from#" subject="#program_email_subject# - Order #order_number#" failto="#Application.OrdersFailTo#" type="html">
			#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
			Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
			PHONE: #snap_phone#<br><br>
			<cfif get_shipping_address>
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
				#quantity# - [sku:#snap_sku#] #snap_meta_name# #snap_options# (#snap_productvalue*credit_multiplier# #credit_desc#)<br>
			</cfloop>
			<br>
			<cfif is_one_item GT 0>
				This is a #is_one_item#-ITEM award program<br>
			<cfelseif NOT hide_points>
				Order Total: #snap_order_total*credit_multiplier#<br>
				#credit_desc# Used: #points_used*credit_multiplier#<br>
				#credit_desc# Left: #(user_total*points_multiplier) - (points_used*credit_multiplier)#<br>
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
