<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfparam name="po_ID" default="">
<cfif NOT isNumeric(po_ID)>
	<cflocation url="po_list.cfm?#CGI.QUERY_STRING#" addtoken="no">
</cfif>

<!--- param search criteria xS=ColumnSort xT=SearchString --->
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="v_ID" default="">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">
<cfparam name="alert_msg" default="">
<cfparam name="new" default="">
<cfparam name="OnPage" default="1">
<cfset po_total_cost = "0">

<!--- param a/e form fields --->
<cfparam name="status" default="">	
<cfparam name="vendor_ID" default="">	
<cfparam name="x_date" default="">
<cfparam name="rex" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<!--- get po info --->
<cfquery name="GetPOInfo" datasource="#application.DS#">
	SELECT vendor_ID, snap_vendor, snap_attention, snap_phone, snap_fax, is_dropship, po_rec_date, itc_name, itc_phone, itc_fax, itc_email, po_printed_note, po_hidden_note, IFNULL(po_rec_date ,"") AS po_rec_date, Date_Format(created_datetime,'%c/%d/%Y') AS this_po_date, modified_concat  
	FROM #application.database#.purchase_order 
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#" maxlength="10">
</cfquery>

<!--- Get Vendor info --->
<cfquery name="POVendor" datasource="#application.DS#">
	SELECT vendor, email, attention, notes, what_terms
	FROM #application.database#.vendor
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10"> 
</cfquery>

<cfparam name="form.emailto" default="#POVendor.email#">

<cfset alert_error = "">
<cfif IsDefined("form.Submit")>
	<cfif form.emailto EQ "" OR NOT FLGen_IsValidEmail(form.emailto)>
		<cfset alert_msg = "Please enter a valid email address.">
	</cfif>
	<cfif alert_msg EQ "">
		<cfsavecontent variable="emailBody">
<style>
td {font-family:Verdana, Arial, Helvetica, sans-serif; font-size:8pt; color:#000000;font-weight:normal}
.printtext {font-weight:normal;font-size:10pt}
.printhead {font-weight:bold;font-size:14pt}
.printlabel {font-weight:bold;font-size:10pt}
</style>
<table cellpadding="0" cellspacing="0" border="0" width="593" align="center">
<tr>
	<td colspan="2" align="left"><img src="<cfoutput>#application.SecureWebPath#</cfoutput>/pics/itclogo.jpg" width="794" height="149"></td>
</tr>
<tr>
	<td colspan="2" align="left">
		<table cellspacing="0" cellpadding="6" width="593" style="border:2px solid #000000;">
		<cfoutput>
		<tr>
			<td align="left" width="297" class="printhead" style="border-bottom:2px solid ##000000">Purchase Order</td>
			<td align="right" width="296" class="printlabel" style="border-bottom:2px solid ##000000;border-left:2px solid ##000000">#GetPOInfo.this_po_date#</td>
		</tr>
		<tr>
		<td align="left" width="297" valign="top" class="printlabel">
			For: #GetPOInfo.snap_vendor#<br /><br />
			Attn: #GetPOInfo.snap_attention#<br /><br />
			Phone: #GetPOInfo.snap_phone#<br /><br />
			Fax: #GetPOInfo.snap_fax#
		</td>
		<td align=left width=296 valign="top" class="printlabel" style="border-left:2px solid ##000000">
			From: #GetPOInfo.itc_name#<br /><br />
			Phone: #GetPOInfo.itc_phone#<br /><br />
			Fax: #GetPOInfo.itc_fax#<br /><br />
			Email: #GetPOInfo.itc_email#
		</td>
		</tr>
		</cfoutput>
		</table>
	</td>
</tr>
<tr>
	<td colspan=2 align=center height=10>&nbsp;</td>
</tr>
<tr>
	<td colspan="2" align="center" class="printlabel">Purchase Order <cfoutput>#po_ID-1000000000#</cfoutput></td>
</tr>
<tr>
	<td colspan=2 align="center" height="20">&nbsp;</td>
</tr>
<cfquery name="GetPOInvItems" datasource="#application.DS#">
	SELECT <cfif GetPOInfo.is_dropship EQ 1>quantity<cfelse>po_quantity</cfif> AS qty, snap_meta_name, snap_description, snap_sku, snap_vendor_sku, snap_sku, snap_options, snap_productvalue , order_ID, ID AS inventory_ID, product_ID 
	FROM #application.database#.inventory
	WHERE po_ID =<cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#" maxlength="10"> 
		AND is_valid = 1 
	ORDER BY product_ID
</cfquery>
<cfset old_product_id = "">
<cfset old_ship_to = "FIRST_TIME">
<cfloop query="GetPOInvItems">
	<!--- need to get the pack size/desc, min qty, and min order $ --->
	<cfquery name="ProdVenLkup" datasource="#application.DS#">
		SELECT is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc 
		FROM #application.database#.vendor_lookup 
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
		AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10"> 
	</cfquery>
	<cfif GetPOInfo.is_dropship EQ 1>
		<!--- find the shipto address --->
		<cfquery name="OrderInfo" datasource="#application.DS#">
			SELECT snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, 
				snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone 
			FROM #application.database#.order_info
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		</cfquery>
		<cfset this_ship_to = "#OrderInfo.snap_ship_fname# #OrderInfo.snap_ship_lname#<br>#OrderInfo.snap_ship_address1#<br>">
		<cfif OrderInfo.snap_ship_address2 NEQ ""><cfset this_ship_to = this_ship_to & "#OrderInfo.snap_ship_address2#<br>"></cfif>
		<cfset this_ship_to = this_ship_to & "#OrderInfo.snap_ship_city#, #OrderInfo.snap_ship_state# #OrderInfo.snap_ship_zip#<br>#OrderInfo.snap_phone#">
		<cfif old_ship_to NEQ "FIRST_TIME" AND old_ship_to NEQ this_ship_to>
			<tr>
				<td class="printtext" align="right" valign="top">SHIP TO:&nbsp;&nbsp;&nbsp;</td>
				<td valign="top">
					<cfoutput>#old_ship_to#</cfoutput>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
				</td>
			</tr>
			<tr>
				<td colspan="2">&nbsp;</td>
			</tr>
		</cfif>
		<cfset old_ship_to = this_ship_to>
	</cfif>
	<!---<cfif old_product_id NEQ product_ID>--->
		<tr>
			<td colspan="2" class="printlabel"><cfoutput>#snap_meta_name# #snap_options#<cfif snap_vendor_sku NEQ ""><br><span class="printtext">Vendor SKU: #snap_vendor_sku#</span></cfif></cfoutput></td>
		</tr>
	<!---</cfif>--->
	<!--- if this prod has packs, make adjustment to qty --->
	<cfif ProdVenLkup.pack_size NEQ "">
		<cfset qty_display = "#qty / ProdVenLkup.pack_size# #ProdVenLkup.pack_desc#(s) (#qty# pieces)">
	<cfelse>
		<cfset qty_display = qty>
	</cfif>
	<tr>
		<td colspan="2" class="printtext" valign="top">Quantity: <cfoutput>#qty_display#</cfoutput></td>
	</tr>
	<tr>
		<td colspan="2">&nbsp;</td>
	</tr>
	<cfset old_product_id = product_ID>
</cfloop>
<tr>
	<td class="printtext" align="right" valign="top">SHIP TO:&nbsp;&nbsp;&nbsp;</td>
	<td valign="top">
		<cfif GetPOInfo.is_dropship EQ 0>
			ITC Specialty<br>Attn: Awards<br>13 Garfield Way<br>Newark, DE 19713
		<cfelse>
			<cfif old_ship_to NEQ "FIRST_TIME">
				<cfoutput>#old_ship_to#</cfoutput>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			</cfif>
		</cfif>
	</td>
</tr>
<tr>
	<td colspan="2">&nbsp;</td>
</tr>
<cfquery name="FindVendor" datasource="#application.DS#">
	SELECT what_terms   
	FROM #application.database#.vendor 
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10">
</cfquery>
<cfset what_terms = HTMLEditFormat(FindVendor.what_terms)>
<tr>
	<td colspan="2" align="left" class="printtext">
		<cfoutput>
		Terms: #what_terms#
		<cfif GetPOInfo.po_printed_note NEQ ''>
			<br><br>
			Note:<br>
			#Replace(HTMLEditFormat(GetPOInfo.po_printed_note),chr(10),"<br>","ALL")#
		</cfif>
		</cfoutput>
		<br><br>
		Thank you
	</td>
</tr>
</table>
		</cfsavecontent>
		<cfquery name="GetAdminEmail" datasource="#application.DS#">
			SELECT U.email
			FROM #application.database#.admin_login L
			LEFT JOIN #application.database#.admin_users U ON U.ID = L.created_user_ID
			WHERE L.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListFirst(cookie.admin_login,'-')#" maxlength="10">
		</cfquery>
		<cfif GetAdminEmail.recordcount GT 0>
			<cfset thisFrom = GetAdminEmail.email>
		</cfif>
		<cfif NOT FLGen_IsValidEmail(thisFrom)>
			<cfset thisFrom = application.AwardsProgramAdminEmail>
			<cfif FLGen_IsValidEmail(GetPOInfo.itc_email)>
				<cfset thisFrom = GetPOInfo.itc_email>
			</cfif>
		</cfif>
		<cfif Application.OverrideEmail NEQ "">
			<cfset this_to = Application.OverrideEmail>
			<cfset this_cc = Application.OverrideEmail>
		<cfelse>
			<cfset this_to = form.emailto>
			<cfset this_cc = thisFrom>
		</cfif>
		<cfmail from="#Application.DefaultEmailFrom#" bcc="#this_cc#" to="#this_to#" subject="PO From ITC" type="html">
			<cfif Application.OverrideEmail NEQ "">
				Emails are being overridden.<br>
				Below is the email that would have been sent to #form.emailto# and bcc to #thisFrom#<br>
				<hr>
			</cfif>
#emailBody#
		</cfmail>
		<cflocation url="po_detail.cfm?po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#&alert_msg=Email%20sent%20to%20#form.emailto#." addtoken="no">
	</cfif>
</cfif>

<cfset leftnavon = "purchase_orders">
<cfinclude template="includes/header.cfm">

<script src="../includes/showhide.js"></script>

<cfoutput>
<span class="pagetitle">Send Purchase Order via Email</span>
<br /><br />

<span class="pageinstructions">Return to <a href="po_detail.cfm?po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order Detail</a></span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<span class="pageinstructions">Return to <a href="po_list.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order List</a></span>
<br /><br />

<cfif POVendor.recordcount NEQ 1>
	<span class="alert">Vendor not found!</span>
<cfelseif NOT FLGen_IsValidEmail(POVendor.email)>
	<cfif POVendor.email EQ "">
		<span class="alert">Vendor has no email address.</span>
	<cfelse>
		<span class="alert">#POVendor.email# is not a valid email address.</span>
	</cfif>
<cfelse>
	<form name="emailPOForm" action="#CurrentPage#?#CGI.QUERY_STRING#" method="post">
		<table cellpadding="5" cellspacing="0" border="0">
			<tr class="content">
				<td align="right">Send PO to:</td>
				<td class="content2"><input type="text" name="emailto" value="#form.emailto#" size="50" maxlength="128"></td>
			</tr>
			<tr class="content">
				<td align="right">Vendor:</td>
				<td class="content2">#POVendor.vendor#</td>
			</tr>
			<cfif trim(POVendor.attention) NEQ "">
				<tr class="content">
					<td align="right">Attention:</td>
					<td class="content2">#POVendor.attention#</td>
				</tr>
			</cfif>
			<cfif trim(POVendor.what_terms) NEQ "">
				<tr class="content">
					<td align="right">What Terms:</td>
					<td class="content2">#POVendor.what_terms#</td>
				</tr>
			</cfif>
			<!--- <cfif trim(POVendor.notes) NEQ "">
				<tr class="content">
					<td colspan="100%" align="center">
						#POVendor.notes#
					</td>
				</tr>
			</cfif> --->
			<tr>
				<td colspan="100%" align="center">
					<input name="submit" type="submit" value=" Send Purchase Order " />
				</td>
			</tr>
		</table>
	</form>
</cfif>
<br><br>
<table cellpadding="3" cellspacing="1" border="0" width="100%">
	<tr>
		<td colspan="2" class="contenthead"><b>Purchase Order #po_ID-1000000000# for #GetPOInfo.snap_vendor#</b> created #GetPOInfo.this_po_date#</td>
	</tr>
	<tr>
		<td colspan="2" class="content2">
			<cfif GetPOInfo.is_dropship EQ 1 AND GetPOInfo.po_rec_date EQ "">
				Need to "PO - Confirm Dropship"
			<cfelseif GetPOInfo.is_dropship EQ 1 AND GetPOInfo.po_rec_date NEQ "">
				All items confirmed dropshipped as of #FLGen_DateTimeToDisplay(GetPOInfo.po_rec_date)#
			<cfelseif GetPOInfo.is_dropship EQ 0 AND GetPOInfo.po_rec_date EQ "">
				Need to "PO - Inventory Received"
			<cfelse>
				Inventory Received #FLGen_DateTimeToDisplay(GetPOInfo.po_rec_date)#
			</cfif>
		</td>
	</tr>
	<tr class="content">
		<td>
			For: #HTMLEditFormat(GetPOInfo.snap_vendor)#<br>
			Attn: #HTMLEditFormat(GetPOInfo.snap_attention)#<br>
			Phone: #HTMLEditFormat(GetPOInfo.snap_phone)#<br>
			Fax: #HTMLEditFormat(GetPOInfo.snap_fax)#<br>
		</td>
		<td>
			From: #HTMLEditFormat(GetPOInfo.itc_name)#<br>
			Phone: #HTMLEditFormat(GetPOInfo.itc_phone)#<br>
			Fax: #HTMLEditFormat(GetPOInfo.itc_fax)#<br>
			Email: #HTMLEditFormat(GetPOInfo.itc_email)#<br>
		</td>
	</tr>
	<tr>
		<td colspan="2" class="content"><span class="sub">PO Printed Note:</span><cfif Trim(GetPOInfo.po_printed_note) NEQ ""><br>#Replace(HTMLEditFormat(GetPOInfo.po_printed_note),chr(10),"<br>","ALL")#<cfelse><span class="sub"> (none)</span></cfif></td>
	</tr>
	<tr>
		<td colspan="2" class="content"><span class="sub">PO Hidden Note:</span><cfif Trim(GetPOInfo.po_hidden_note) NEQ ""><br>#Replace(HTMLEditFormat(GetPOInfo.po_hidden_note),chr(10),"<br>","ALL")#<cfelse><span class="sub"> (none)</span></cfif></td>
	</tr>
	<tr>
		<td colspan="2" class="content"><span class="sub">PO Modification History:</span><cfif Trim(GetPOInfo.modified_concat) NEQ ""><br>#Replace(HTMLEditFormat(GetPOInfo.modified_concat),chr(10),"<br>","ALL")#<cfelse><span class="sub"> (none)</span></cfif></td>
	</tr>
</table>
<br>
<cfquery name="GetPOInvItems" datasource="#application.DS#">
	SELECT <cfif GetPOInfo.is_dropship EQ 1>quantity<cfelse>po_quantity</cfif> AS qty, snap_meta_name, snap_description, snap_sku, snap_vendor_sku, snap_sku, snap_options, snap_productvalue , order_ID, ID AS inventory_ID, product_ID, CAST(IFNULL(po_rec_date,"") AS CHAR) AS po_rec_date, CAST(IF(po_rec_date IS NOT NULL, quantity, "") AS CHAR) AS po_got, tracking 
	FROM #application.database#.inventory
	WHERE po_ID =<cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#" maxlength="10"> 
		AND is_valid = 1 
	ORDER BY product_ID
</cfquery>
<table cellpadding="3" cellspacing="1" border="0" width="100%">
	<tr class="contenthead">
		<td colspan="6" class="headertext">Products</td>
	</tr>
	<tr class="contentsearch">
		<td><!--- <cfif GetPOInfo.is_dropship EQ 0>ADD LINK</cfif> ---></td>
		<td class="headertext">Price</td>
		<td class="headertext">PO Qty</td>
		<td class="headertext">Product</td>
	</tr>
	<cfloop query="GetPOInvItems">
		<!--- Get the pack size/desc, min qty, and min order $ --->
		<cfquery name="ProdVenLkup" datasource="#application.DS#">
			SELECT is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc, vendor_po_note 
			FROM #application.database#.vendor_lookup 
			WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
				AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10"> 
		</cfquery>
		<tr class="content">
			<td>
				<cfif GetPOInfo.is_dropship EQ 1 AND  GetPOInvItems.po_rec_date EQ "">
					<!--- Remove not allowed --->
				<cfelseif GetPOInfo.is_dropship EQ 1 AND  GetPOInvItems.po_rec_date NEQ "">
					drop conf'd #FLGen_DateTimeToDisplay(GetPOInvItems.po_rec_date)#
				<cfelseif GetPOInfo.is_dropship EQ 0 AND GetPOInvItems.po_rec_date EQ "">
					<!--- Edit quantity not allowed --->
				<cfelse>
					received #GetPOInvItems.po_got#<br>#FLGen_DateTimeToDisplay(GetPOInvItems.po_rec_date)#
				</cfif>
			</td>
			<td align="right">$#ProdVenLkup.vendor_cost#</td>
			<td>
				<b>#qty#</b><cfif NOT ProdVenLkup.pack_size EQ ""> pieces</cfif>
				<cfif NOT ProdVenLkup.pack_size EQ "">
					<br>#qty / ProdVenLkup.pack_size# &nbsp;#ProdVenLkup.pack_desc#(s) of #ProdVenLkup.pack_size#
				</cfif>
				<cfif ProdVenLkup.vendor_min_qty NEQ "1" AND ProdVenLkup.vendor_min_qty NEQ "">
					&nbsp;<span class="alert">&laquo; min.&nbsp;#ProdVenLkup.vendor_min_qty#<cfif ProdVenLkup.pack_desc NEQ ""> #ProdVenLkup.pack_desc#(s)</cfif></span>
				</cfif>
			</td>
			<td>
				<b>#snap_meta_name#</b> #snap_options#<br />
				ITC SKU: #snap_sku#<br />
				Vendor SKU: #snap_vendor_sku#
				<cfif ProdVenLkup.vendor_po_note NEQ ''>
					<br />
					<span class="selecteditem">Vendor PO Note</span> <span class="sub">(not on printable)</span>: #Replace(HTMLEditFormat(ProdVenLkup.vendor_po_note),chr(10),"<br>","ALL")#
				</cfif>
			</td>
		</tr>
		<cfif GetPOInfo.is_dropship EQ 1>
			<!--- find the shipto address --->
			<cfquery name="OrderInfo" datasource="#application.DS#">
				SELECT snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, 
				snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, program_ID, order_number  
				FROM #application.database#.order_info
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			</cfquery>
			<tr class="content">
				<td colspan="3">
					<cfif tracking NEQ "">
						<br>Tracking ##: #tracking#
					<cfelse>
						&nbsp;
					</cfif>
				</td>
				<td>
					#GetProgramName(OrderInfo.program_ID)# Order #OrderInfo.order_number#<br>
					SHIP TO: #OrderInfo.snap_ship_fname# #OrderInfo.snap_ship_lname#, #OrderInfo.snap_ship_address1# #OrderInfo.snap_ship_address2#, #OrderInfo.snap_ship_city#, #OrderInfo.snap_ship_state# #OrderInfo.snap_ship_zip#, phone: #OrderInfo.snap_phone#, email: #OrderInfo.snap_email#
				</td>
			</tr>
		<cfelseif GetPOInfo.is_dropship EQ 0>
			<!--- find all the orders for this product that haven't been shipped --->
			<cfquery name="FindOrders" datasource="#application.DS#">
				SELECT i.order_ID, o.snap_fname, o.snap_lname, o.snap_phone, o.snap_email, 
						o.created_datetime, o.order_number, o.program_ID 
				FROM #application.database#.inventory i JOIN #application.database#.order_info o
					ON i.order_ID = o.ID 
				WHERE i.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10">
					AND i.is_valid = 1 
					AND i.quantity <> 0 
					AND i.snap_is_dropshipped = 0 
					AND i.order_ID <> 0 
					AND i.ship_date IS NULL
					AND i.po_ID = 0
					AND i.po_rec_date IS NULL
				ORDER BY o.created_datetime ASC 
			</cfquery>
			<cfif FindOrders.RecordCount GT 0>
				<tr class="content">
					<td>
						<cfset ID = product_ID> &nbsp;
					</td>
					<td colspan="3" class="selectedbgcolor">
						<span ID="msg_#ID#">there are outstanding orders for this product</span>
						<span ID="row_#ID#" style="display:none"><cfloop query="FindOrders">#GetProgramName(FindOrders.program_ID)# Order #order_number# #FLGen_DateTimeToDisplay(created_datetime)#<br />#snap_fname# #snap_lname#&nbsp;&nbsp;&nbsp;#snap_email#&nbsp;&nbsp;&nbsp;#snap_phone#<br /><br /></cfloop></span>
					</td>
				</tr>
			<cfelse>
				<tr class="content">
					<td>&nbsp;</td>
					<td>&nbsp;</td>
					<td>&nbsp;</td>
					<td><span class="sub">no outstanding orders for this product</span></td>
				</tr>
	
			</cfif>
		</cfif>
		<cfif isNumeric(ProdVenLkup.vendor_cost)>
			<cfset po_lineitem_cost = qty * ProdVenLkup.vendor_cost>
		<cfelse>
			<cfset po_lineitem_cost = 0>
		</cfif>
		<cfset po_total_cost = po_total_cost + po_lineitem_cost>
	</cfloop>
	<tr class="content">
		<td>&nbsp;</td>
		<td align="right" class="headertext">$#po_total_cost#</td>
		<td colspan="4" class="headertext">Total</td>
	</tr>
	<cfquery name="FindVendor" datasource="#application.DS#">
		SELECT min_order  
		FROM #application.database#.vendor 
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10">
	</cfquery>
	<cfset min_order = HTMLEditFormat(FindVendor.min_order)>
	<cfif min_order NEQ 0>
		<tr class="content">
			<td>&nbsp;</td>
			<td class="alert" align="right">$#min_order#</td>
			<td colspan="4" class="alert">Minimum Order</td>
		</tr>
	</cfif>
</table>

</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->
