<cffunction name="AuthenticateProgramUserCookie" output="false" returntype="void">
	<cfset var LogThemOut = false>
	<cfif IsDefined('cookie.itc_user') AND cookie.itc_user IS NOT "">
		<!--- authenticate itc_user cookie --->
		<cfif FLGen_CreateHash(ListGetAt(cookie.itc_user,1,"_")) EQ ListGetAt(cookie.itc_user,2,"_")>
			<!--- set user vars --->
			<cfset user_ID = ListGetAt(cookie.itc_user,1,"-")>
			<cfset user_total = ListGetAt(cookie.itc_user,2,"-")>
			<cfset cc_max = ListGetAt(ListGetAt(cookie.itc_user,3,"-"),1,"_")>
		<cfelse>
			<!--- cookie not authentic, kick out --->
			<cfset LogThemOut = true>
		</cfif>
	</cfif>
	<cfif NOT LogThemOut AND isDefined("email_login") AND email_login EQ 1>
		<cfif NOT isDefined("cookie.itc_email") OR NOT isDefined("program_ID")>
			<!--- no email cookie, kick out --->
			<cfset LogThemOut = true>
		<cfelse>
			<cfquery name="CheckUserName" datasource="#application.DS#">
				SELECT ID 
				FROM #application.database#.program_user
				WHERE email = <cfqueryparam value="#cookie.itc_email#" cfsqltype="CF_SQL_VARCHAR">
				AND ID = <cfqueryparam value="#user_ID#" cfsqltype="CF_SQL_INTEGER">
				AND program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
			</cfquery>
		</cfif>
	</cfif>
	<cfif LogThemOut>
		<cflocation addtoken="no" url="logout.cfm">
	</cfif>
</cffunction>

<cffunction name="CustomerSurvey" output="true">
	<cfargument name="CustomerSurvey_action" type="string" required="yes">
	<table cellpadding="5" cellspacing="0" border="0" class="survey_box">
	<form method="post" action="#CurrentPage#" name="survey">
	<tr>
	<td colspan="2" align="left" valign="top"><b>Customer Satisfaction Survey</b></td>
	</tr>
	<tr>
	<td align="left">How would you rate the navigation of this website?</td>
	<td align="center" valign="top">Difficult 
	<img src="pics/worst-best.gif"> Easy<br>
	<input type="radio" name="navigation" value="1">1&nbsp;&nbsp;&nbsp;<input type="radio" name="navigation" value="2">2&nbsp;&nbsp;&nbsp;<input type="radio" name="navigation" value="3">3&nbsp;&nbsp;&nbsp;<input type="radio" name="navigation" value="4">4&nbsp;&nbsp;&nbsp;<input type="radio" name="navigation" value="5">5<input type="hidden" name="navigation_required" value="Please choose a website navigation rating">
	</td>
	</tr>
	<tr>
	<td align="left">How would you rate the product selection?</td>
	<td align="center" valign="top">Lowest 
	<img src="pics/worst-best.gif"> Highest<br>
	<input type="radio" name="selection" value="1">1&nbsp;&nbsp;&nbsp;<input type="radio" name="selection" value="2">2&nbsp;&nbsp;&nbsp;<input type="radio" name="selection" value="3">3&nbsp;&nbsp;&nbsp;<input type="radio" name="selection" value="4">4&nbsp;&nbsp;&nbsp;<input type="radio" name="selection" value="5">5<input type="hidden" name="selection_required" value="Please choose a product selection rating">
	</td>
	</tr>
	<tr>
	<td colspan="2" align="left">Please give us your suggestions for<br>website enhancements and/or product offerings.</td>
	</td>
	</tr>
	<tr>
	<td colspan="2" align="left"><textarea rows="5" cols="60" name="note"></textarea></td>
	</td>
	</tr>
	<tr>
	<td colspan="2" align="center">
		<input type="hidden" name="user_ID" value="#user_ID#">
		<input type="hidden" name="user_ID_required" value="User ID missing.">
		<input type="hidden" name="action" value="#CustomerSurvey_action#">
		<input type="hidden" name="action_required" value="Variable 'action' missing.">
		<input type="hidden" name="program_ID" value="#program_ID#">
		<input type="hidden" name="program_ID_required" value="Program ID missing.">
		<input type="submit" name="submitsurvey" value="Submit"> Thank you ... we value your feedback!
	</td>
	</td>
	</tr>
	</form>
	</table>
</cffunction>

<cffunction name="ProcessCustomerSurvey" output="false">
	<cfquery name="InsertNewSurvey" datasource="#application.DS#">
		INSERT INTO #application.database#.survey
		(created_user_ID, created_datetime, program_ID, action, navigation, selection, note)
		VALUES
		(<cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">, 
			'#FLGen_DateTimeToMySQL()#', 
			<cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">, 
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.action#" maxlength="20">, 
			<cfqueryparam cfsqltype="cf_sql_integer" value="#form.navigation#" maxlength="1">, 
			<cfqueryparam cfsqltype="cf_sql_integer" value="#form.selection#" maxlength="1">, 
			<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.note#" null="#YesNoFormat(NOT Len(Trim(form.note)))#">)
	</cfquery>
	<cflocation addtoken="no" url="logout.cfm?survey=yes">
</cffunction>

<cffunction name="WriteSurveyCookie" output="false">
	<cfparam name="order_ID" default="0">
	<!--- hash info --->	
	<cfset WriteSurveyCookie_Hash = FLGen_CreateHash(#user_ID# & "-" & #order_ID# & "-" & #user_total#)>
	<!--- write cookie --->
	<cfcookie name="itc_survey" value="#user_ID#-#order_ID#-#user_total#_#WriteSurveyCookie_Hash#">
</cffunction>

<cffunction name="AuthenticateSurveyCookie" output="false">
	<!--- get user info --->
	<cfif IsDefined('cookie.itc_survey') AND cookie.itc_survey IS NOT "">
		<cfif FLGen_CreateHash(ListGetAt(cookie.itc_survey,1,"_")) EQ ListGetAt(cookie.itc_survey,2,"_")>
			<!--- set user vars --->
			<cfset user_ID = ListGetAt(cookie.itc_survey,1,"-")>
			<cfset order_ID = ListGetAt(ListGetAt(cookie.itc_survey,2,"-"),1,"_")>
			<cfset user_total = ListGetAt(ListGetAt(cookie.itc_survey,3,"-"),1,"_")>
		</cfif>
	<cfelse>
		<cflocation url="logout.cfm" addtoken="no">
	</cfif>
</cffunction>

<cffunction name="GetProgramUserInfo" output="false">
	<cfargument name="ProgramUserInfo_userID" type="string" required="yes">
	<cfargument name="email_addr" type="string" required="no" default="">
	<cfquery name="GetCostCenterInfo" datasource="#application.DS#">
		SELECT program_ID, uses_cost_center
		FROM #application.database#.program_user
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProgramUserInfo_userID#">
	</cfquery>
	<cfquery name="GetProgramInfo" datasource="#application.DS#">
		SELECT has_address_verification
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetCostCenterInfo.program_ID#">
	</cfquery>
	<cfif GetCostCenterInfo.uses_cost_center NEQ 1>
		<!--- look in the points database for the starting point amount --->
		<cfquery name="PosPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM(points),0) AS pos_pt
			FROM #application.database#.awards_points
			WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProgramUserInfo_userID#">
			AND is_defered = 0
		</cfquery>
		<!--- look in the order database for orders/points_used --->
		<cfquery name="NegPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) AS neg_pt, IFNULL(SUM(credit_card_charge),0) AS neg_cc
			FROM #application.database#.order_info
			WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProgramUserInfo_userID#">
			AND ( is_valid = 1
			<!--- <cfif GetProgramInfo.has_address_verification> --->
				OR approval IN (1,2)
			<!--- </cfif> --->
			)
		</cfquery>
		<!--- find defered points --->
		<cfquery name="DefPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM(points),0) AS def_pt
			FROM #application.database#.awards_points
			WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProgramUserInfo_userID#">
			AND is_defered = 1
		</cfquery>
		<cfset user_totalpoints = PosPoints.pos_pt - NegPoints.neg_pt>
		<cfset user_deferedpoints = DefPoints.def_pt>
	<cfelse>
		<cfset user_totalpoints = 0>
		<cfset user_deferedpoints = 0>
	</cfif>
<cfset cookie_points = user_totalpoints>
<cfif user_totalpoints LT 0>
	<cfset cookie_points = 0>
</cfif>
	<!--- write itc_user cookie ([user_ID]-[points left]-[cc_max]_HASH (of ID and points w/ salt) --->
	<cfset UserHash = FLGen_CreateHash(ProgramUserInfo_userID & "-" & cookie_points & "-" & cc_max)>
	<cfcookie name="itc_user" value="#ProgramUserInfo_userID#-#cookie_points#-#cc_max#_#UserHash#">
	<cfif isDefined("email_login") AND email_login EQ 1 AND email_addr NEQ "">
		<cfcookie name="itc_email" value="#email_addr#">
	</cfif>
</cffunction>

<cffunction name="GetProgramInfo" output="true">
	<cfargument name="division_id" required="true" type="numeric" > 
	<cfif IsDefined('cookie.itc_pid') AND cookie.itc_pid IS NOT "">
		<!--- check itc_pid hash --->
		<cfif FLGen_CreateHash(ListGetAt(cookie.itc_pid,1,"-")) EQ ListGetAt(cookie.itc_pid,2,"-")>

			<cfset has_divisions = false>

			<cfset thisUserID = 0>
			<cfif IsDefined('cookie.itc_user') AND cookie.itc_user NEQ "">
				<cfset thisUserID = ListGetAt(cookie.itc_user,1,"-")>
			</cfif>
			
			<cfset order_ID = 0>
			<cfif IsDefined('cookie.itc_order') AND cookie.itc_order IS NOT "">
				<cfif FLGen_CreateHash(ListGetAt(cookie.itc_order,1,"-")) EQ ListGetAt(cookie.itc_order,2,"-")>
					<cfset order_ID = ListGetAt(cookie.itc_order,1,"-")>
				</cfif>
			</cfif>

			<cfset program_ID = ListGetAt(cookie.itc_pid,1,"-")>
			<!--- get program information  --->
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
						language_ID, forward_button, forwarder_ID, product_set_tabs, product_set_text, show_inventory, register_template_id, register_email_subject,
						shipping_location_message1, shipping_location_message2, shipping_location_message3, has_main_menu_button, register_get_shipping, has_promotion_button, assign_div_points,
						CASE
						 	WHEN charge_shipping <= CURDATE() THEN 1
							ELSE 0
						END AS charge_shipping,
						add_shipping, signature_charge, has_address_verification, require_email_address, show_divisions
				FROM #application.database#.program
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
			</cfquery>
			<cfquery name="GetSets" datasource="#application.DS#">
				SELECT product_set_ID
				FROM #application.database#.xref_program_product_set
				WHERE program_ID = 
				<cfif arguments.division_ID GT 0>
					<cfqueryparam cfsqltype="cf_sql_integer" value="#division_ID#" maxlength="10">
				<cfelse>
					<cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
				</cfif>
			</cfquery>
			<cfset product_set_IDs = ValueList(GetSets.product_set_ID)>
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
			<cfif one_item_over_message EQ "">
				<cfset one_item_over_message = "You may select only #is_one_item# gift(s). You will have to remove %OVER_NUMBER% gift%S% to check out.">
			</cfif>
			<cfset delivery_message = SelectProgramInfo.delivery_message>
			<cfset uses_shipping_locations = SelectProgramInfo.uses_shipping_locations>
			<cfset inactivate_zero_inventory = SelectProgramInfo.inactivate_zero_inventory>
			<cfset cost_center_notification = HTMLEditFormat(SelectProgramInfo.cost_center_notification)>		
			<cfset language_ID = SelectProgramInfo.language_ID>		
			<cfset shipping_location_message1 = SelectProgramInfo.shipping_location_message1>		
			<cfset shipping_location_message2 = SelectProgramInfo.shipping_location_message2>		
			<cfset shipping_location_message3 = SelectProgramInfo.shipping_location_message3>		
			<cfset forward_button = SelectProgramInfo.forward_button>		
			<cfset forwarder_ID = SelectProgramInfo.forwarder_ID>		
			<cfset product_set_tabs = SelectProgramInfo.product_set_tabs>		
			<cfset product_set_text = SelectProgramInfo.product_set_text>		
			<cfset show_inventory = SelectProgramInfo.show_inventory>
			<cfset has_main_menu_button = SelectProgramInfo.has_main_menu_button>
			<cfset register_template_id = SelectProgramInfo.register_template_id>
			<cfset register_email_subject = SelectProgramInfo.register_email_subject>
			<cfset register_get_shipping = SelectProgramInfo.register_get_shipping>
			<cfset has_address_verification = SelectProgramInfo.has_address_verification>
			<cfset require_email_address = SelectProgramInfo.require_email_address>
			<cfset show_divisions = SelectProgramInfo.show_divisions>
			<cfset has_promotion_button = SelectProgramInfo.has_promotion_button>
			<cfset assign_div_points = SelectProgramInfo.assign_div_points>

			<!--- massage the data --->
			<!--- <cfif welcome_bg NEQ "">
				<cfset welcome_bg = ' background="pics/program/' & welcome_bg & '"'>
			</cfif> --->
			<cfif welcome_congrats NEQ "">
				<cfset welcome_congrats = ' <img src="pics/program/#welcome_congrats#" style="padding: 0px 0px 5px 0px">'>
				<cfelse>
				<cfset welcome_congrats = "&nbsp;">
			</cfif>
			<!--- has the graphic cross? --->
			<cfif cross_color NEQ "">
				<cfset cross_color = ' style="background-color:###cross_color#"'>
			</cfif>
			<!--- set bg image --->
			<cfif main_bg NEQ "">
				<cfset main_bg = ' background="pics/program/' & main_bg & '"'>
			</cfif>
			<!---  get congrats image --->
			<cfif main_congrats NEQ "">
				<cfset main_congrats = ' <img src="pics/program/#main_congrats#" style="padding: 0px 0px 5px 0px">'>
			<cfelse>
				<cfset main_congrats = "&nbsp;">
			</cfif>
			<!--- Set up divisions --->
			<cfif thisUserID GT 0>
				<cfif order_ID GT 0>
					<cfquery name="GetDivisions" datasource="#application.DS#">
						SELECT p.ID, p.company_name, p.program_name, p.welcome_button, SUM(IFNULL(a.points,0)) AS points_awarded, IFNULL(x.award_points,0) AS points_assigned
						FROM #application.database#.program p
						LEFT JOIN #application.database#.awards_points a ON a.division_ID = p.ID AND a.user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisUserID#" maxlength="10">
						LEFT JOIN #application.database#.xref_order_division x ON x.division_ID = p.ID AND x.order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
						WHERE parent_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
						GROUP BY p.ID
					</cfquery>
				<cfelse>
					<cfquery name="GetDivisions" datasource="#application.DS#">
						SELECT p.ID, p.company_name, p.program_name, p.welcome_button, SUM(IFNULL(a.points,0)) AS points_awarded
						FROM #application.database#.program p
						LEFT JOIN #application.database#.awards_points a ON a.division_ID = p.ID AND a.user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisUserID#" maxlength="10">
						WHERE parent_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
						GROUP BY p.ID
					</cfquery>
				</cfif>
			<cfelse>
				<cfquery name="GetDivisions" datasource="#application.DS#">
					SELECT ID, company_name, program_name, welcome_button, 0 AS points_awarded
					FROM #application.database#.program
					WHERE parent_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
				</cfquery>
			</cfif>
			<cfif GetDivisions.recordcount GT 0>
				<cfset divOrderPoints = StructNew()>
				<cfloop query="GetDivisions">
					<cfset divOrderPoints[GetDivisions.ID] = 0>
				</cfloop>
				<cfset has_divisions = true>
				<cfif thisUserID GT 0>
					<cfquery name="GetDivOrders" datasource="#application.DS#">
						SELECT p.ID, IFNULL(SUM(x.award_points),0) AS points_used
						FROM #application.database#.order_info o
						LEFT JOIN #application.database#.xref_order_division x ON x.order_ID = o.ID
						LEFT JOIN #application.database#.program p ON p.ID = x.division_ID
						WHERE o.created_user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisUserID#" maxlength="10">
						AND ( o.is_valid = 1
						<cfif has_address_verification>
							OR o.approval = 1
						</cfif>
						)
						GROUP BY p.ID
					</cfquery>
					<cfif GetDivOrders.recordCount GT 0>
						<cfloop query="GetDivOrders">
							<cfset divOrderPoints[GetDivOrders.ID] = GetDivOrders.points_used>
						</cfloop>
					</cfif>
				</cfif>
			</cfif>
			<!--- welcome your name AND you have x credits messages --->
			<cfset display_message = "">
			<cfset subprogram_display_message = "">
			<cfif display_welcomeyourname EQ 1>
				<cfif thisUserID GT 0>
					<cfquery name="GetUserName" datasource="#application.DS#">
						SELECT fname, lname
						FROM #application.database#.program_user
						WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisUserID#" maxlength="10">
					</cfquery>
					<cfset welcome_text = Translate(language_ID,'welcome_user')>
					<cfif GetUserName.fname NEQ "" AND GetUserName.lname NEQ "">
						<cfset display_message = display_message & '#welcome_text# <span class="main_paging_number">#GetUserName.fname# #GetUserName.lname#</span>'>
					<cfelse>
						<cfset display_message = display_message & '#welcome_text#'>
					</cfif>
				</cfif>
			</cfif>
			<cfif IsDefined('cookie.itc_user') AND cookie.itc_user NEQ "" AND display_youhavexcredits EQ 1>
				<cfset F_carttotal = 0>
				<cfif order_ID GT 0>
					<cfquery name="FindOrderItems" datasource="#application.DS#">
						SELECT ID AS inventory_ID, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options
						FROM #application.database#.inventory
						WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
					</cfquery>
					<cfif FindOrderItems.RecordCount GT 0>
						<cfloop query="FindOrderItems">
							<cfset F_carttotal = F_carttotal + (snap_productvalue * quantity)>
						</cfloop>
					</cfif>
				</cfif>
				<cfif F_carttotal LTE ListGetAt(cookie.itc_user,2,"-")>
					<cfset display_message = display_message & ' ' & Translate(language_ID,'you_have_points') & ' <span class="main_cart_number">#points_multiplier*(ListGetAt(cookie.itc_user,2,"-") - F_carttotal)#</span> #credit_desc#.'>
					<cfset display_message = display_message & '<br>'>
					<cfif has_divisions and show_divisions>
						<cfset added_msg = false>
						<cfloop query="GetDivisions">
							<cfif GetDivisions.points_awarded GT 0>
								<cfset display_message = display_message & ' <span class="main_cart_number">#(GetDivisions.points_awarded - divOrderPoints[GetDivisions.ID])*points_multiplier#</span> for #GetDivisions.program_name# &bull; '>
								<cfset added_msg = true>
							</cfif>
						</cfloop>
						<cfif added_msg>
							<cfset display_message = RemoveChars(display_message,len(display_message)-7,8)>
						</cfif>
						<cfif F_carttotal GT 0>
							<cfset display_message = display_message & ' &bull; minus <span class="main_cart_number">#F_carttotal*points_multiplier#</span> in your cart.'>
						</cfif>
					</cfif>
				<cfelse>
					<cfset display_message = display_message & '  <span class="alert">#cart_exceeded_msg#</span>'>
				</cfif>
			</cfif>
			<cfif display_message NEQ "">
				<cfset display_message = '<span class="main_login">#display_message##subprogram_display_message#</span>'>
			</cfif>
			<!--- Get username to check for certificate --->
			<cfif thisUserID GT 0>
				<cfquery name="GetUsersUsername" datasource="#application.DS#">
					SELECT username
					FROM #application.database#.program_user
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisUserID#" maxlength="10">
				</cfquery>
				<cfset users_username = GetUsersUsername.username>
			<cfelse>
				<cfset users_username = "">
			</cfif>
		<cfelse>
			<!--- if program cookie not authentic, kickout --->
			<cflocation addtoken="no" url="logout.cfm">
		</cfif>
	<cfelse>
		<!--- if no program cookie, kickout --->
		<cflocation addtoken="no" url="logout.cfm">
	</cfif>
</cffunction>

<cffunction name="CartItemCount" output="false">
	<cfif IsDefined('cookie.itc_order') AND cookie.itc_order IS NOT "">
		<cfif FLGen_CreateHash(ListGetAt(cookie.itc_order,1,"-")) EQ ListGetAt(cookie.itc_order,2,"-")>
			<cfset order_ID = ListGetAt(cookie.itc_order,1,"-")>
			<!--- look in the points database for the starting point amount --->
			<cfquery name="CountCartItems" datasource="#application.DS#">
				SELECT IFNULL(SUM(quantity),0) AS itemcount
				FROM #application.database#.inventory 
				WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
			</cfquery>
			<cfset itemcount = CountCartItems.itemcount>
		</cfif>
	<cfelse>
		<cfset itemcount = 0>
	</cfif>
</cffunction>

<cffunction name="Translate" output="false" returntype="String">
	<cfargument name="language_ID" type="numeric" required="yes">
	<cfargument name="tag" type="string" required="yes">
	<cfset return_value = tag>
	<cfquery name="GetTranslation" datasource="#application.DS#">
		SELECT translation
		FROM #application.database#.language_translation 
		WHERE language_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#language_ID#">
		AND tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#tag#">
	</cfquery>
	<cfif GetTranslation.recordcount EQ 1>
		<cfset return_value = GetTranslation.translation>
	<cfelse>
		<cfmail to="#Application.ErrorEmailTo#" from="#Application.DefaultEmailFrom#" subject="Translation error in Awards 3" type="html">
			Tag #tag# for language ID #language_ID# <cfif GetTranslation.recordcount EQ 0>was not found<cfelse>has more than one row</cfif>	in the language_translation table.
		</cfmail>
	</cfif>
	<cfreturn return_value>
</cffunction>