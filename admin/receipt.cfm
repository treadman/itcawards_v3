<cfinclude template="../includes/function_library_local.cfm">
<cfparam name="ID" default=0>
<cfparam name="t" default="1">
<cfif NOT isBoolean(t)>
	<cfset t = 1>
</cfif>
<cfparam name="e" default="0">
<cfif NOT isBoolean(e)>
	<cfset e = 0>
</cfif>
<cfquery name="HeaderInfo" datasource="#application.DS#">
	SELECT order_number, created_datetime, snap_fname as firstname, snap_lname as lastname, snap_ship_company as company,
			snap_ship_address1 as address1, snap_ship_address2 as address2, snap_ship_city as city, snap_ship_state as state,
			snap_ship_zip as zipcode, snap_phone as phone_day, '' as phone_night, snap_email as email,
			shipping_desc, '' as payment_method, snap_bill_fname as billing_firstname,
			snap_bill_lname as billing_lastname, snap_bill_company as billing_company, snap_bill_address1 as billing_address1,
			snap_bill_address2 as billing_address2, snap_bill_city as billing_city, snap_bill_state as billing_state,
			snap_bill_zip as billing_zipcode, 0 as subtotal, shipping_charge as shipping, snap_signature_charge, credit_card_charge,
			order_note as comments, '' as gl_code, '' as state_code, '' as brand_code, program_ID
	FROM #application.database#.order_info
	WHERE ID = <cfqueryparam value="#ID#" cfsqltype="CF_SQL_INTEGER" maxlength="10">
</cfquery>
<!---
	SELECT ID, created_datetime, firstname, lastname, company, address1, address2, city, state, zipcode, email, phone_day, phone_night,
				ship_type, payment_method, billing_firstname, billing_lastname, billing_company, billing_address1, billing_address2,
				billing_city, billing_state, billing_zipcode, subtotal, shipping, total, comments, gl_code, state_code, brand_code
--->
<cfquery name="DetailInfo" datasource="#application.DS#">
	SELECT quantity, snap_meta_name as description, snap_options as options, snap_sku as sku, snap_productvalue as price, 0 as weight
	FROM #application.database#.inventory i
	WHERE order_ID = <cfqueryparam value="#ID#" cfsqltype="CF_SQL_INTEGER" maxlength="10">
</cfquery>
<!---
	SELECT i.sku, i.description, i.quantity, i.price, i.weight,	l.Description AS logo_description
	LEFT JOIN #application.database#.corp_logos l ON i.corp_logo = l.ID
--->

<cfquery name="ProgramInfo" datasource="#application.DS#">
	SELECT logo, cross_color
	FROM #application.database#.program
	WHERE ID = <cfqueryparam value="#HeaderInfo.program_ID#" cfsqltype="CF_SQL_INTEGER" maxlength="10">
</cfquery>
<cfoutput>

<cfset page_title = "Order Number #HeaderInfo.order_number#">
<cfinclude template="includes/header_lite.cfm">

<cfif NOT e AND ProgramInfo.logo NEQ ""><img src="../pics/program/#ProgramInfo.logo#"><br /><br /></cfif>
<font face="arial, verdana, helvetica">
<table width="600px;" cellpadding="0" cellspacing="0">
	<cfif NOT e AND ProgramInfo.logo NEQ "">
		<tr height="1px;"><td colspan="100%" bgcolor="###ProgramInfo.cross_color#"></td></tr>
		<tr height="13px;"><td colspan="100%"></td></tr>
	</cfif>
	<tr>
		<td align="left"><strong>ORDER NUMBER #HeaderInfo.order_number#</strong></td>
		<td align="right"><font size="-1">#DateFormat(HeaderInfo.created_datetime,"mm/dd/yyyy")# #TimeFormat(HeaderInfo.created_datetime)#</font></td>
	</tr>
	<cfif t>
	<tr>
		<td colspan="2">
			<br><br><strong>Thank you!  Your order has been processed.</strong>
		</td>
	</tr>
	</cfif>
	<!--- <tr><td height=10 colspan="2"></td></tr>
	<cfif t><tr><td colspan="2"><font size="+2" color=black>Receipt</font></td></tr></cfif> --->
</table>

<table cellpadding="0" cellspacing="0" border="0" width="600px;">
	<cfif NOT e><tr height="3px;"><td colspan="100%" bgcolor="###ProgramInfo.cross_color#"></td></tr></cfif>
	<tr>
		<td width="299px;" valign="top">
			<table cellspacing=0 cellpadding=6 border=0>
				<tr><td colspan="100%"><strong>Ship to:</strong></td></tr>
				<tr><td align=right><strong>Name</strong></td><td>#HeaderInfo.firstname# #HeaderInfo.lastname#</td></tr>
				<cfif HeaderInfo.company neq "">
					<tr><td align=right><strong>Company</strong></td><td>#HeaderInfo.company#</td></tr>
				</cfif>
				<tr><td align=right valign="top"><strong>Address</strong></td><td>#HeaderInfo.address1#<br /><cfif HeaderInfo.address2 neq "">#HeaderInfo.address2#<br /></cfif>#HeaderInfo.city#, #HeaderInfo.state# #HeaderInfo.zipcode#</td></tr>
				<tr><td align=right><strong>Email</strong></td><td>#HeaderInfo.email#</td></tr>
				<tr><td align=right><strong>Phone</strong></td><td>#HeaderInfo.phone_day#</td></tr>
				<cfif HeaderInfo.shipping_desc NEQ "">
					<tr><td align=right><strong>Ship via</strong></td><td>#HeaderInfo.shipping_desc#</td></tr>
				</cfif>
			</table>
		</td>
		<cfif HeaderInfo.comments neq "" OR HeaderInfo.credit_card_charge gt 0>
			<td width="1px;" <cfif NOT e>bgcolor="###ProgramInfo.cross_color#"</cfif>>&nbsp;</td>
			<td width="299px;" valign="top">
				<table cellspacing=0 cellpadding=6 border=0>
					<cfif HeaderInfo.credit_card_charge gt 0>
						<tr><td colspan="100%"><strong>Bill to:</strong></td></tr>
						<tr><td align=right><strong>Name</strong></td><td>#HeaderInfo.billing_firstname# #HeaderInfo.billing_lastname#</td></tr>
						<cfif HeaderInfo.billing_company neq "">
							<tr><td align=right><strong>Company</strong></td><td>#HeaderInfo.billing_company#</td></tr>
						</cfif>
						<tr><td align=right valign="top"><strong>Address</strong></td><td>#HeaderInfo.billing_address1#<br /><cfif HeaderInfo.billing_address2 neq "">#HeaderInfo.billing_address2#<br /></cfif>#HeaderInfo.billing_city#, #HeaderInfo.billing_state# #HeaderInfo.billing_zipcode#</td></tr>
					</cfif>
					<cfif HeaderInfo.comments neq "">
						<tr><td align="right" valign="top"><strong>Comments</strong></td><td>#HeaderInfo.comments#</td></tr>
					</cfif>
				</table>
			</td>
		</cfif>
	</tr>
	<cfif NOT e><tr height="3px;"><td colspan="100%" bgcolor="###ProgramInfo.cross_color#"></td></tr></cfif>
</table>
<table cellspacing="5" cellpadding="1" border="0" width="600px;">
	<tr><td><strong>Qty</strong></td><td><strong>Item</strong></td><td align="right"><strong>Price</strong></td><td align="right"><strong>Ext</strong></td></tr>
	<cfset total = 0>
	<cfloop query="DetailInfo">
		<cfset total = total + (price * quantity)>
		<tr><td>#quantity#</td><td>#ListFirst(sku,"-")# - #description#<cfif options NEQ ""><br>#options#</cfif><!--- <br />Logo: #logo_description#<cfif NOT t><br />(#weight*quantity# lbs.)</cfif> ---></td><td align="right">#price#</td><td align="right">#(price * quantity)#</td></tr>
	</cfloop>
	<cfif NOT e><tr height="1px;"><td colspan="6" bgcolor="###ProgramInfo.cross_color#"></td></tr></cfif>
		<tr><td colspan="3" align="right"><strong>POINTS USED</strong></td><td align="right">#total#</td></tr>
		<cfset total_charge = 0>
		<cfif HeaderInfo.shipping_desc NEQ "">
			<cfset total_charge = total_charge + HeaderInfo.shipping>
			<tr><td colspan="3" align="right"><strong>SHIPPING</strong></td><td align="right">#DollarFormat(HeaderInfo.shipping)#</td></tr>
		</cfif>
		<cfif HeaderInfo.credit_card_charge GT 0 AND HeaderInfo.credit_card_charge NEQ HeaderInfo.shipping>
			<cfset total_charge = total_charge + HeaderInfo.credit_card_charge>
			<tr><td colspan="3" align="right"><strong>CREDIT CARD</strong></td><td align="right">#DollarFormat(HeaderInfo.credit_card_charge)#</td></tr>
		</cfif>
		<cfif total_charge GT 0>
			<tr><td colspan="3" align="right"><strong>ORDER TOTAL</strong></td><td align="right">#DollarFormat(total_charge)#</td></tr>
		</cfif>
	<cfif NOT e><tr height="3px;"><td colspan="6" bgcolor="###ProgramInfo.cross_color#"></td></tr></cfif>
</table>
</font>
</cfoutput>
<cfinclude template="includes/footer.cfm">


