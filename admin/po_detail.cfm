<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfparam name="po_ID" default="">
<cfif NOT isNumeric(po_ID)>
	<cflocation url="po_list.cfm" addtoken="no">
</cfif>

<!--- param search criteria xS=ColumnSort xT=SearchString --->
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="v_ID" default="">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">
<cfparam name="new" default="">
<cfparam name="OnPage" default="1">
<cfset was_deleted = "false">
<cfset po_total_cost = "0">

<!--- param a/e form fields --->
<cfparam name="status" default="">
<cfparam name="vendor_ID" default="">
<cfparam name="x_date" default="">
<cfparam name="rex" default="">

<cfparam name="set_ID" default="">
<cfif NOT isNumeric(set_ID) OR set_ID LT 1>
	<cfset set_ID = 0>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('rex') AND rex IS NOT "">
	<!--- set the inventory item back to not dropshipped --->
	<cfquery name="removeinvfromdropPO" datasource="#application.DS#">
		UPDATE #application.database#.inventory 
		SET po_ID = 0, snap_vendor = NULL, vendor_ID=0, drop_date = NULL
		WHERE is_valid = 1 
		AND quantity <> 0 
		AND snap_is_dropshipped = 1 
		AND order_ID <> 0 
		AND ship_Date IS NULL
		AND po_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
		AND po_rec_date IS NULL
		AND ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#rex#">
	</cfquery>
	<!--- if no more items in this po, delete it --->
	<cfquery name="checkPOitems" datasource="#application.DS#">
		SELECT ID 
		FROM #application.database#.inventory 
		WHERE po_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
	</cfquery>
	<cfif checkPOitems.RecordCount EQ 0>
		<cfquery name="DeleteEmptyPO" datasource="#application.DS#">
			DELETE FROM #application.database#.purchase_order 
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
		</cfquery>
		<cfset was_deleted = "true">
	</cfif>
</cfif>

<cfif IsDefined('form.Submit')>
	<!--- edit po information --->
	<cfif IsDefined('form.edit') AND form.edit EQ 'poinformation'>
		<cfset this_mod_note = "(*auto* edited PO info)">
		<cfquery name="UpdatePOInfo" datasource="#application.DS#">
			UPDATE #application.database#.purchase_order 
				SET snap_vendor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_vendor#" maxlength="38">,
					snap_attention = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_attention#" maxlength="32">,
					snap_phone = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_phone#" maxlength="32">,
					snap_fax = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_fax#" maxlength="14">,
					itc_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#itc_name#" maxlength="64">,
					itc_phone = <cfqueryparam cfsqltype="cf_sql_varchar" value="#itc_phone#" maxlength="32">,
					itc_fax = <cfqueryparam cfsqltype="cf_sql_varchar" value="#itc_fax#" maxlength="32">,
					itc_email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#itc_email#" maxlength="64">,
					po_printed_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#po_printed_note#" null="#YesNoFormat(NOT Len(Trim(po_printed_note)))#">,
					po_hidden_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#po_hidden_note#" null="#YesNoFormat(NOT Len(Trim(po_hidden_note)))#">
					#FLGen_UpdateModConcatSQL(this_mod_note)#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#" maxlength="10">
		</cfquery>
		<cfset alert_msg = "The change to Purchase Order #po_ID-1000000000# was saved.">
		<cfset pgfn = "editpo">
	</cfif>
	<!--- edit po information --->
	<cfif IsDefined('form.edit') AND form.edit EQ 'iteminformation'>
		<!--- if ordered in packs and/or minimum, calculate new po qty --->
		<cfquery name="ProdVenLkup" datasource="#application.DS#">
			SELECT vl.vendor_sku, vl.vendor_min_qty, IFNULL(vl.pack_size,0) AS pack_size, vl.pack_desc 
			FROM #application.database#.vendor_lookup vl 
			WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
				AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_vendor_ID#">
		</cfquery>
		<cfset this_po_qty = new_quantity>
		<cfif ProdVenLkup.pack_size NEQ 0>
			<cfset this_po_qty = this_po_qty * ProdVenLkup.pack_size>
		</cfif>
		<cfset mod_note = "(*auto* changed po_quantity)">
		<!--- Update inventory entry for po --->
		<cfquery name="NewItemQty" datasource="#application.DS#">
			UPDATE #application.database#.inventory
			SET po_quantity = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_po_qty#" maxlength="10">
				#FLGen_UpdateModConcatSQL(mod_note)#
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#inventory_ID#">
		</cfquery>
		<cflocation addtoken="no" url="po_detail.cfm?pgfn=detail&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=1&set_ID=#set_ID#">
	</cfif>
	<!--- po received --->
	<cfif IsDefined('form.edit') AND form.edit EQ 'porec'>
		<!--- put in received quantities --->
		<cfif IsDefined('form.FieldNames') AND Trim(form.FieldNames) IS NOT "">
			<cfloop list="#form.FieldNames#" index="FormField">
				<cfif FormField CONTAINS "newqty_">
					<cfif Evaluate(FormField) NEQ "">
						<cfset mod_note = "(*auto* po received)">
						<cfquery name="RecItemQty" datasource="#application.DS#">
							UPDATE #application.database#.inventory
							SET	quantity = <cfqueryparam cfsqltype="cf_sql_integer" value="#Evaluate(FormField)#" maxlength="8">, 
								po_rec_date = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#form.recdate#">
								#FLGen_UpdateModConcatSQL(mod_note)#
							WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#RemoveChars(FormField,1,7)#">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		<!--- check to see if all the items on the PO were received --->
		<cfquery name="AllShipped" datasource="#application.DS#">
			SELECT ID 
			FROM #application.database#.inventory
			WHERE po_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
				AND po_rec_date IS NULL
		</cfquery>
		<cfif AllShipped.RecordCount EQ 0>
			<!--- update the po as received --->
			<cfset mod_note = "(*auto* all po items have been received)">
			<cfquery name="POdatereceived" datasource="#application.DS#">
				UPDATE #application.database#.purchase_order
				SET	po_rec_date = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#form.recdate#">
					#FLGen_UpdateModConcatSQL(mod_note)#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#" maxlength="10">
			</cfquery>
		</cfif>
		<cflocation addtoken="no" url="po_detail.cfm?pgfn=detail&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=1&set_ID=#set_ID#">
	</cfif>
	<!--- po dropshipment confirmation --->
	<cfif IsDefined('form.edit') AND form.edit EQ 'condrop'>
		<!--- put in tracking numbers --->
		<cfif IsDefined('form.FieldNames') AND Trim(form.FieldNames) IS NOT "">
			<cfloop list="#form.FieldNames#" index="FormField">
				<cfif FormField CONTAINS "inv_">
					<cfif Evaluate(FormField) NEQ "">
						<cfset inventory_tracking_number = Evaluate(FormField)>
						<cfset inventory_details = "form." & RemoveChars(FormField,1,4)>
						<cfset mod_note = "(*auto* po dropshipment confirmation)"  & Chr(13) & Chr(10) & Evaluate(inventory_details)  & Chr(13) & Chr(10) & "Tracking Number" & inventory_tracking_number>
						<cfquery name="ConDropItemQty" datasource="#application.DS#">
							UPDATE #application.database#.inventory
							SET tracking = <cfqueryparam cfsqltype="cf_sql_varchar" value="#inventory_tracking_number#" maxlength="32">, 
								po_rec_date = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#form.condrop_date#">
								#FLGen_UpdateModConcatSQL(mod_note)#
							WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#RemoveChars(FormField,1,4)#">
						</cfquery>
						<cfset inventory_order_ID = "form.order_" & RemoveChars(FormField,1,4)>
						<cfset inventory_order_ID = Evaluate(inventory_order_ID)>
						<cfset user_name = FLGen_GetAdminName(FLGen_adminID)>
						<cfset mod_note = Replace(mod_note, "'","''","all")>
						<cfquery name="UpdateOrderInfo" datasource="#application.DS#">
							UPDATE #application.database#.order_info 
							SET modified_concat = concat(IF(modified_concat IS NULL,"",CONCAT(modified_concat,CHAR(13),CHAR(10),CHAR(13),CHAR(10))), '[#user_name# #FLGen_DateTimeToDisplay(showtime=true)#]'<cfif mod_note NEQ "">,CHAR(13),CHAR(10),'#mod_note# '</cfif>)
							WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#inventory_order_ID#">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		<!--- check to see if all the items on the PO were dropshipped --->
		<cfquery name="AllDropped" datasource="#application.DS#">
			SELECT ID 
			FROM #application.database#.inventory
			WHERE po_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
				AND po_rec_date IS NULL
		</cfquery>
		<cfif AllDropped.RecordCount EQ 0>
			<!--- update the po as received --->
			<cfset mod_note = "(*auto* all po items have been dropshipped)">
			<cfquery name="POdateconfirmed" datasource="#application.DS#">
				UPDATE #application.database#.purchase_order
				SET po_rec_date = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">
					#FLGen_UpdateModConcatSQL(mod_note)#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
			</cfquery>
		</cfif>
		<!--- check to see if whole order(s) fulfilled --->
		<!--- find all orders associated with this PO --->
		<cfquery name="AllDroppedOrderID" datasource="#application.DS#">
			SELECT DISTINCT order_ID AS DROP_order_ID 
			FROM #application.database#.inventory
			WHERE po_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
				AND po_rec_date IS NOT NULL
		</cfquery>
		<cfloop query="AllDroppedOrderID">
			<!--- check for UNSHIPPED // UNDROPSHIPPED --->
			<cfquery name="ItemsNotShipped" datasource="#application.DS#">
				SELECT ID AS ItemsNotOut
				FROM #application.database#.inventory
				WHERE is_valid = 1 
					AND quantity <> 0 
					AND snap_is_dropshipped = 0  
					AND order_ID =  <cfqueryparam cfsqltype="cf_sql_integer" value="#DROP_order_ID#">
					AND ship_date IS NULL 
					AND po_ID = 0
					AND po_rec_date IS NULL 

				UNION

				SELECT ID AS ItemsNotOut
				FROM #application.database#.inventory
				WHERE is_valid = 1 
					AND quantity <> 0 
					AND snap_is_dropshipped = 1  
					AND order_ID =  <cfqueryparam cfsqltype="cf_sql_integer" value="#DROP_order_ID#">
					AND ship_date IS NULL 
					AND po_ID = 0
					AND po_rec_date IS NULL
			</cfquery>
			<cfif ItemsNotShipped.RecordCount EQ 0>
				<!--- insert order mod note --->
				<cfset mod_note = "(*auto* order completely fulfilled #FLGen_DateTimeToDisplay()#)">
				<!--- if appro, mark is_all_shipped (I checked for unshipped and undropshipped items above) --->
				<cfquery name="UpdateOrderInfo" datasource="#application.DS#">
					UPDATE #application.database#.order_info 
					SET is_all_shipped = 1 
					#FLGen_UpdateModConcatSQL(mod_note)#
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#DROP_order_ID#">
				</cfquery>
			</cfif>
		</cfloop>
		<cflocation addtoken="no" url="po_detail.cfm?pgfn=detail&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=1&set_ID=#set_ID#">
	</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "purchase_orders">
<cfinclude template="includes/header.cfm">

<script src="../includes/showhide.js"></script>

<cfparam name="pgfn" default="detail">

<cfif pgfn EQ "detail">
	<!--- START pgfn DETAIL --->
	<!--- get po info --->
	<cfquery name="GetPOInfo" datasource="#application.DS#">
		SELECT vendor_ID, snap_vendor, snap_attention, snap_phone, snap_fax, is_dropship, po_rec_date, itc_name, itc_phone, itc_fax, itc_email, po_printed_note, po_hidden_note, IFNULL(po_rec_date ,"") AS po_rec_date, Date_Format(created_datetime,'%c/%d/%Y') AS this_po_date, modified_concat  
		FROM #application.database#.purchase_order 
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
	</cfquery>
	<span class="pagetitle">Purchase Order Detail</span>
	<br /><br />
	<cfoutput>
	<span class="pageinstructions">Open <a href="po_detail_print.cfm?po_ID=#po_ID#" target="_blank">printable PO</a></span>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<span class="pageinstructions">Export <a href="po_detail_csv.cfm?po_ID=#po_ID#" target="_blank">PO to Excel</a></span>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<span class="pageinstructions">Send <a href="po_detail_email.cfm?po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">PO via email</a></span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="po_list.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order List</a> without making changes.</span>
	<br /><br />
	<cfif new EQ "yes">
		<cfset alert_msg = "The new Purchase Order #po_ID-1000000000# was created.">
	</cfif>
	<cfif GetPOInfo.RecordCount EQ 0 AND was_deleted> 
		<span class="alert">Purchase Order #po_ID-1000000000# was deleted because there were no more products in it.</span>
	<cfelseif GetPOInfo.RecordCount EQ 0>
		<span class="alert">There is no Purchase Order #po_ID-1000000000# </span>
	<cfelse>
		<table cellpadding="3" cellspacing="1" border="0" width="100%">
			<tr>
			<td colspan="2" class="contenthead"><b>#po_ID-1000000000# Purchase Order #po_ID-1000000000# for #GetPOInfo.snap_vendor#</b> created #GetPOInfo.this_po_date#</td>
			</tr>
			<tr>
			<td colspan="2" class="content2">
				<a href="#CurrentPage#?pgfn=editpo&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#&set_ID=#set_ID#">Edit PO Information</a>&nbsp;&nbsp;&nbsp;
				<cfif GetPOInfo.is_dropship EQ 1 AND GetPOInfo.po_rec_date EQ "">
					<a href="#CurrentPage#?pgfn=condrop&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#&set_ID=#set_ID#">PO - Confirm Dropship</a>
				<cfelseif GetPOInfo.is_dropship EQ 1 AND GetPOInfo.po_rec_date NEQ "">
				All items confirmed dropshipped as of #FLGen_DateTimeToDisplay(GetPOInfo.po_rec_date)#
				<cfelseif GetPOInfo.is_dropship EQ 0 AND GetPOInfo.po_rec_date EQ "">
					<a href="#CurrentPage#?pgfn=recpo&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#&set_ID=#set_ID#">PO - Inventory Received</a>
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
			WHERE po_ID =<cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
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
					WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
						AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#">
				</cfquery>
				<tr class="content">
				<td>
					<cfif GetPOInfo.is_dropship EQ 1 AND  GetPOInvItems.po_rec_date EQ "">
						<a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#&rex=#GetPOInvItems.inventory_ID#&po_ID=#po_ID#&set_ID=#set_ID#">remove</a>
					<cfelseif GetPOInfo.is_dropship EQ 1 AND  GetPOInvItems.po_rec_date NEQ "">
						drop conf'd #FLGen_DateTimeToDisplay(GetPOInvItems.po_rec_date)#
					<cfelseif GetPOInfo.is_dropship EQ 0 AND GetPOInvItems.po_rec_date EQ "">
						<a href="#CurrentPage#?pgfn=editqty&editinv=#inventory_ID#&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#&set_ID=#set_ID#">Edit&nbsp;Qty</a>
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
						WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
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
						FROM #application.database#.inventory i
						JOIN #application.database#.order_info o
							ON i.order_ID = o.ID 
						WHERE i.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
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
							<!--- [+] or "show xyz" --->
							<cfset ID = product_ID>
							<a href="##" ID="show_#ID#" onClick="showThis('row_#ID#');showThis('hide_#ID#');hideThis('show_#ID#');hideThis('msg_#ID#'); return false">show</a>
							<!--- [-] or "hide xyz" --->
							<a href="##" ID="hide_#ID#" onClick="hideThis('row_#ID#');hideThis('hide_#ID#');showThis('show_#ID#');showThis('msg_#ID#'); return false" style="display:none">hide</a>
						</td>
						<td colspan="3" class="selectedbgcolor">
							<span ID="msg_#ID#">there are outstanding orders for this product</span>
							<span ID="row_#ID#" style="display:none"><cfloop query="FindOrders"><a href="order.cfm?pgfn=detail&order_ID=#order_ID#&xT=&xTD=&xFD=&OnPage=1&set_ID=#set_ID#">#GetProgramName(FindOrders.program_ID)# Order #order_number#</a> #FLGen_DateTimeToDisplay(created_datetime)#<br />#snap_fname# #snap_lname#&nbsp;&nbsp;&nbsp;#snap_email#&nbsp;&nbsp;&nbsp;#snap_phone#<br /><br /></cfloop></span>
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
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#">
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
	</cfif>
	</cfoutput>
	<!--- END pgfn DETAIL --->
<cfelseif pgfn EQ "editpo">
	<!--- START pgfn EDIT PO --->
	<!--- get po info --->
	<cfquery name="GetPOInfo" datasource="#application.DS#">
		SELECT snap_vendor, snap_attention, snap_phone, snap_fax, po_rec_date, itc_name, itc_phone, itc_fax, itc_email, po_printed_note, po_hidden_note, modified_concat
		FROM #application.database#.purchase_order 
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
	</cfquery>
	<cfset snap_vendor = HTMLEditFormat(GetPOInfo.snap_vendor)>
	<cfset snap_attention = HTMLEditFormat(GetPOInfo.snap_attention)>
	<cfset snap_phone = HTMLEditFormat(GetPOInfo.snap_phone)>
	<cfset snap_fax = HTMLEditFormat(GetPOInfo.snap_fax)>
	<cfset po_rec_date = HTMLEditFormat(GetPOInfo.po_rec_date)>
	<cfset itc_name = HTMLEditFormat(GetPOInfo.itc_name)>
	<cfset itc_phone = HTMLEditFormat(GetPOInfo.itc_phone)>
	<cfset itc_fax = HTMLEditFormat(GetPOInfo.itc_fax)>
	<cfset itc_email = HTMLEditFormat(GetPOInfo.itc_email)>
	<cfset po_printed_note = HTMLEditFormat(GetPOInfo.po_printed_note)>
	<cfset po_hidden_note = HTMLEditFormat(GetPOInfo.po_hidden_note)>
	<cfset modified_concat = HTMLEditFormat(GetPOInfo.modified_concat)>
	<cfoutput>
	<span class="pagetitle">Edit A Purchase Order</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order #po_ID-1000000000# Detail</a> or <a href="po_list.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order List</a> without making changes.</span>
	<br /><br />
	<span class="pageinstructions"><span class="alert">WARNING</span>: Changes only effect this PO.  This page does not change the</span>
	<br />
	<span class="pageinstructions">vendor's information in their Vendor record.</span>
	<br /><br />
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="contenthead">
	<td colspan="2" class="headertext">Purchase Order Information</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Purchase Order Number: </td>
	<td valign="top">#po_ID-1000000000#</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Vendor's Name: </td>
	<td valign="top"><input type="text" name="snap_vendor" value="#snap_vendor#" maxlength="38" size="60">
		<input type="hidden" name="snap_vendor_required" value="Please enter a vendor name."></td>
	</tr>
	<tr class="content">
	<td align="right">Vendor Contact: </td>
	<td><input type="text" size="60" maxlength="32" name="snap_attention" value="#snap_attention#">
		<input type="hidden" name="snap_attention_required" value="Please enter a vendor contact."></td>
	</tr>
	<tr class="content">
	<td align="right">Vendor Phone: </td>
	<td><input type="text" size="60" maxlength="32" name="snap_phone" value="#snap_phone#">
		<input type="hidden" name="snap_phone_required" value="Please enter a vendor phone."></td>
	</tr>
	<tr class="content">
	<td align="right">Vendor Fax: </td>
	<td><input type="text" size="60" maxlength="14" name="snap_fax" value="#snap_fax#">
		<input type="hidden" name="snap_fax_required" value="Please enter a vendor fax."></td>
	</tr>
	<tr class="content">
	<td align="right">ITC Contact: </td>
	<td><input type="text" size="60" maxlength="64" name="itc_name" value="#itc_name#">
		<input type="hidden" name="itc_name_required" value="Please enter an ITC contact."></td>
	</tr>
	<tr class="content">
	<td align="right">ITC Phone: </td>
	<td><input type="text" size="60" maxlength="32" name="itc_phone" value="#itc_phone#"
		<input type="hidden" name="itc_phone_required" value="Please enter an ITC phone."></td>
	</tr>
	<tr class="content">
	<td align="right">ITC Fax: </td>
	<td><input type="text" size="60" maxlength="32" name="itc_fax" value="#itc_fax#">
		<input type="hidden" name="itc_fax_required" value="Please enter an ITC fax."></td>
	</tr>
	<tr class="content">
	<td align="right">ITC Email: </td>
	<td><input type="text" size="60" maxlength="64" name="itc_email" value="#itc_email#">
		<input type="hidden" name="itc_email_required" value="Please enter an ITC email."></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">PO Printed Note: </td>
	<td valign="top"><textarea name="po_printed_note" cols="58" rows="4">#po_printed_note#</textarea></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">PO Hidden Note: </td>
	<td valign="top"><textarea name="po_hidden_note" cols="58" rows="4">#po_hidden_note#</textarea></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">PO Modification History: </td>
	<td valign="top"><cfif modified_concat NEQ "">#modified_concat#<cfelse><span class="sub">(none)</span></cfif></td>
	</tr>
	<tr class="content">
	<td colspan="2" align="center">
		<input type="hidden" name="edit" value="poinformation">
		<input type="hidden" name="xT" value="#xT#">
		<input type="hidden" name="xFD" value="#xFD#">
		<input type="hidden" name="xTD" value="#xTD#">
		<input type="hidden" name="v_ID" value="#v_ID#">
		<input type="hidden" name="OnPage" value="#OnPage#">
		<input type="hidden" name="po_ID" value="#po_ID#">
		<input type="submit" name="submit" value="   Save Changes   " >
	</td>
	</tr>
	<!--- ON WISHLIST... 
	<cfif modified_concat NEQ "">
	<tr>
	<td colspan="4">&nbsp;</td>
	</tr>
	<tr class="contenthead">
	<td colspan="4" class="headertext">Order Modification History </td>
	</tr>
	<tr class="content">
	<td colspan="4">#FLGen_DisplayModConcat(modified_concat)#</td>
	</tr>
	</cfif>
	 --->
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn EDIT PO --->


<!---
<cfelseif pgfn EQ "additem">
	<!--- START pgfn ADD ITEM --->
	<!--- get user's total available points --->
	<cfquery name="GetUserID" datasource="#application.DS#">
		SELECT created_user_ID
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
	</cfquery>
	<cfset ProgramUserInfo(GetUserID.created_user_ID)>
	<cfquery name="FindOrderInfo" datasource="#application.DS#">
		SELECT order_number
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
	</cfquery>
	<cfset order_number = HTMLEditFormat(FindOrderInfo.order_number)>
	<!--- Find all indv products --->
	<cfquery name="AllProductList" datasource="#application.DS#">
		SELECT meta.meta_name, prod.sku, pval.productvalue, prod.ID AS individual_ID, 
			IF((SELECT COUNT(*) FROM #application.database#.product_meta_option_category pm WHERE meta.ID = pm.product_meta_ID)=0,"false","true") AS has_options
		FROM #application.database#.product_meta meta JOIN #application.database#.product prod ON prod.product_meta_ID = meta.ID 
		JOIN #application.database#.productvalue_master pval ON pval.ID = meta.productvalue_master_ID
		WHERE prod.is_active = 1 AND prod.is_discontinued = 0 
		ORDER BY pval.sortorder, meta.sortorder, prod.sortorder
	</cfquery>
	<cfoutput>
	<span class="pagetitle">Add Order Item</span>
	<br /><br />
	<span class="pageinstructions">This user has <span class="selecteditem">#user_totalpoints#</span> points available.</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Order #order_number# Detail</a> or <a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Order List</a> without making changes.</span>
	<br /><br />
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0">
	</cfoutput>
	<cfoutput query="AllProductList" group="productvalue">
	<tr class="contenthead">
	<td colspan="3" class="headertext">Master Category #productvalue#</td>
	</tr>
	<cfoutput>
		<cfif has_options>
			<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
				SELECT pmoc.category_name AS category_name, pmo.option_name AS option_name
				FROM #application.database#.product_meta_option_category pmoc JOIN #application.database#.product_meta_option pmo ON pmoc.ID = pmo.product_meta_option_category_ID 
				 JOIN  #application.database#.product_option po ON pmo.ID = po.product_meta_option_ID
				WHERE po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#individual_ID#">
				ORDER BY pmoc.sortorder
			</cfquery>
			<cfset optioncount = FindProductOptionInfo.RecordCount>
		<cfelse>
			<cfset optioncount = 0>
		</cfif>
		<tr class="content">
		<td><input type="submit" name="add_#individual_ID#_#productvalue#" value="Add To Order" ></td>
		<td>SKU: #sku#</td>
		<td>#meta_name#<cfif optioncount NEQ 0><cfloop query="FindProductOptionInfo"> [#category_name#: #option_name#] </cfloop></cfif></td>
		</tr>
	</cfoutput>
	<tr>
	<td colspan="3">&nbsp;</td>
	</tr>
	</cfoutput>
	<cfoutput>
	<input type="hidden" name="submit" value="submit">
	<input type="hidden" name="edit" value="addorderitem">
	<input type="hidden" name="order_ID" value="#order_ID#">
	<input type="hidden" name="xFD" value="#xFD#">
	<input type="hidden" name="xTD" value="#xTD#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn ADD ITEM --->
--->

<cfelseif pgfn EQ "editqty">
	<!--- START pgfn EDIT PO-SHIP TO ITC ITEM QTY --->
	<cfset inventory_ID = editinv>
	<!--- find item information --->
	<cfquery name="FindPOItem" datasource="#application.DS#">
		SELECT snap_sku, snap_meta_name, snap_productvalue, po_quantity, snap_options, note AS inv_note, product_ID, snap_vendor_sku 
		FROM #application.database#.inventory
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#inventory_ID#">
	</cfquery>
	<cfset snap_sku = HTMLEditFormat(FindPOItem.snap_sku)>
	<cfset snap_meta_name = HTMLEditFormat(FindPOItem.snap_meta_name)>
	<cfset snap_productvalue = HTMLEditFormat(FindPOItem.snap_productvalue)>
	<cfset qty = FindPOItem.po_quantity>
	<cfset snap_options = HTMLEditFormat(FindPOItem.snap_options)>
	<cfset inv_note = HTMLEditFormat(FindPOItem.inv_note)>
	<cfset product_ID = HTMLEditFormat(FindPOItem.product_ID)>
	<cfset snap_vendor_sku = HTMLEditFormat(FindPOItem.snap_vendor_sku)>
	<!--- get po info --->
	<cfquery name="GetPOInfo" datasource="#application.DS#">
		SELECT vendor_ID, snap_vendor, snap_attention, snap_phone, snap_fax, po_rec_date, itc_name, itc_phone, itc_fax, itc_email, po_printed_note, po_hidden_note, is_dropship 
		FROM #application.database#.purchase_order 
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
	</cfquery>
	<cfset vendor_ID = HTMLEditFormat(GetPOInfo.vendor_ID)>
	<cfset snap_vendor = HTMLEditFormat(GetPOInfo.snap_vendor)>
	<cfset snap_attention = HTMLEditFormat(GetPOInfo.snap_attention)>
	<cfset snap_phone = HTMLEditFormat(GetPOInfo.snap_phone)>
	<cfset snap_fax = HTMLEditFormat(GetPOInfo.snap_fax)>
	<cfset po_rec_date = HTMLEditFormat(GetPOInfo.po_rec_date)>
	<cfset itc_name = HTMLEditFormat(GetPOInfo.itc_name)>
	<cfset itc_phone = HTMLEditFormat(GetPOInfo.itc_phone)>
	<cfset itc_fax = HTMLEditFormat(GetPOInfo.itc_fax)>
	<cfset itc_email = HTMLEditFormat(GetPOInfo.itc_email)>
	<cfset po_printed_note = HTMLEditFormat(GetPOInfo.po_printed_note)>
	<cfset po_hidden_note = HTMLEditFormat(GetPOInfo.po_hidden_note)>
	<cfset is_dropship = HTMLEditFormat(GetPOInfo.is_dropship)>
	<!--- Get the pack size/desc, min qty, and min order $ --->
	<cfquery name="ProdVenLkup" datasource="#application.DS#">
		SELECT is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc 
		FROM #application.database#.vendor_lookup 
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
			AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#">
	</cfquery>
	<cfoutput>
	<span class="pagetitle">Edit Purchase Order Item</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order #po_ID-1000000000# Detail</a> or <a href="po_list.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order List</a> without making changes.</span>
	<br /><br />
	<cfif FindPOItem.RecordCount EQ 1>
		<form method="post" action="#CurrentPage#">
		<table cellpadding="5" cellspacing="1" border="0">
			<tr class="contenthead">
				<td colspan="6" class="headertext">Edit Purchase Order Item</td>
			</tr>
			<tr class="contentsearch">
			<td class="headertext">Price</td>
			<td class="headertext">Quantity<cfif NOT ProdVenLkup.pack_size EQ ""><br><span class="reg">#ProdVenLkup.pack_desc# of #ProdVenLkup.pack_size#</span></cfif></td>
			<td class="headertext">PO Qty</td>
			<td class="headertext">Vendor SKU</td>
			<td class="headertext">ITC SKU</td>
			<td class="headertext">Product</td>
			</tr>
			<tr class="content">
			<td align="right">$#ProdVenLkup.vendor_cost#</td>
			<cfif NOT ProdVenLkup.pack_size EQ "">
				<cfset input_quantity = qty / ProdVenLkup.pack_size>
			<cfelse>
				<cfset input_quantity = qty>
			</cfif> 
			<td><input type="text" name="new_quantity" value="#input_quantity#" maxlength="8" size="5"></td>
			<td>
				<b>#qty#</b><cfif NOT ProdVenLkup.pack_size EQ ""> pieces</cfif>
				<cfif ProdVenLkup.vendor_min_qty NEQ "1" AND ProdVenLkup.vendor_min_qty NEQ "">
					&nbsp;<span class="alert">&laquo; Minimum&nbsp;of #ProdVenLkup.vendor_min_qty#</span>
				</cfif>
				<cfif NOT ProdVenLkup.pack_size EQ "">
					<br>#qty / ProdVenLkup.pack_size# &nbsp;#ProdVenLkup.pack_desc#(s) of #ProdVenLkup.pack_size#
				</cfif>
			</td>
			<td>#snap_vendor_sku#</td>
			<td>#snap_sku#</td>
			<td><b>#snap_meta_name#</b> #snap_options#</td>
			</tr>
			<cfif GetPOInfo.is_dropship EQ 1>
				<!--- find the shipto address --->
				<cfquery name="OrderInfo" datasource="#application.DS#">
					SELECT snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, 
						snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone 
					FROM #application.database#.order_info
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
				</cfquery>
				<tr class="content">
				<td colspan="3">&nbsp;</td>
				<td colspan="3">SHIP TO: #OrderInfo.snap_ship_fname# #OrderInfo.snap_ship_lname#, #OrderInfo.snap_ship_address1# #OrderInfo.snap_ship_address2#, #OrderInfo.snap_ship_city#, #OrderInfo.snap_ship_state# #OrderInfo.snap_ship_zip#, phone: #OrderInfo.snap_phone#</td>
				</tr>
			</cfif>
			<tr class="content">
			<td colspan="6" align="center">
			<input type="hidden" name="edit" value="iteminformation">
			<input type="hidden" name="xT" value="#xT#">
			<input type="hidden" name="xFD" value="#xFD#">
			<input type="hidden" name="xTD" value="#xTD#">
			<input type="hidden" name="v_ID" value="#v_ID#">
			<input type="hidden" name="OnPage" value="#OnPage#">
			<input type="hidden" name="product_ID" value="#product_ID#">
			<input type="hidden" name="this_vendor_ID" value="#GetPOInfo.vendor_ID#">
			<input type="hidden" name="inventory_ID" value="#inventory_ID#">
			<input type="hidden" name="po_ID" value="#po_ID#">
			<input type="submit" name="submit" value="   Save Changes   " >
			</td>
			</tr>
		</table>
		</form>
	</cfif>
	</cfoutput>
	<!--- END pgfn EDIT SHIP QTY --->   
<cfelseif pgfn EQ "recpo">
	<!--- START pgfn RECEIVED PO --->
	<!--- get po info --->
	<cfquery name="GetPOInfo" datasource="#application.DS#">
		SELECT vendor_ID, snap_vendor, snap_attention, snap_phone, snap_fax, is_dropship, po_rec_date, itc_name, itc_phone, itc_fax, itc_email, po_printed_note, po_hidden_note, modified_concat 
		FROM #application.database#.purchase_order
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
	</cfquery>
	<cfoutput>
	<span class="pagetitle">Purchase Order - Received Inventory</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order #po_ID-1000000000# Detail</a> or <a href="po_list.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order List</a> without making changes.</span>
	<br /><br />
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
		<tr>
		<td colspan="2" class="contenthead"><b>Purchase Order #po_ID-1000000000# for #GetPOInfo.snap_vendor#</b></td>
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
		SELECT <cfif GetPOInfo.is_dropship EQ 1>quantity<cfelse>po_quantity</cfif> AS qty, snap_meta_name, snap_description, snap_sku, snap_vendor_sku, snap_sku, snap_is_dropshipped, snap_options, snap_productvalue , order_ID, ID AS inventory_ID, product_ID, po_rec_date, <cfif GetPOInfo.is_dropship EQ 0>quantity<cfelse>'0'</cfif> AS rec_qty
		FROM #application.database#.inventory
		WHERE po_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
			AND is_valid = 1
		ORDER BY product_ID
	</cfquery>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
	<tr class="contenthead">
	<td colspan="6" class="headertext">Products</td>
	</tr>
	<tr class="contentsearch">
	<td class="headertext" align="center">Quantity<br>Received</td>
	<td class="headertext">Qty Ordered on PO</td>
	<td class="headertext">Vendor SKU</td>
	<td class="headertext">ITC SKU</td>
	<td class="headertext">Product</td>
	</tr>
	<cfloop query="GetPOInvItems">
		<!--- Get the pack size/desc, min qty, and min order $ --->
		<cfquery name="ProdVenLkup" datasource="#application.DS#">
			SELECT is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc 
			FROM #application.database#.vendor_lookup 
			WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
				AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10"> 
		</cfquery>
		<tr class="content">
		<td align="center"><cfif snap_is_dropshipped EQ 0 AND rec_qty EQ 0><input type="text" name="newqty_#inventory_ID#" maxlength="8" size="5"><cfelseif snap_is_dropshipped EQ 0 AND rec_qty NEQ 0>recieved #rec_qty#<br>#FLGen_DateTimeToDisplay(po_rec_date)#<cfelse><span class="sub">(drop)</span></cfif></td>
		<td>
			<b>#qty#</b><cfif NOT ProdVenLkup.pack_size EQ ""> pieces</cfif>
			<cfif NOT ProdVenLkup.pack_size EQ "">
				<br>#qty / ProdVenLkup.pack_size# &nbsp;#ProdVenLkup.pack_desc#(s) of #ProdVenLkup.pack_size#
			</cfif>
		</td>
		<td>#snap_vendor_sku#</td>
		<td>#snap_sku#</td>
		<td><b>#snap_meta_name#</b> #snap_options#</td>
		</tr>
	</cfloop>
	<tr class="content">
	<td colspan="2" align="center"><input type="text" name="recdate" maxlength="32" size="14" value="#FLGen_DateTimeToDisplay()#"></td>
	<td colspan="3"> <b>Received Date</b></td>
	</tr>
	<tr class="contenthead">
	<td colspan="6" class="content" align="center">
		<input type="hidden" name="edit" value="porec">
		<input type="hidden" name="xT" value="#xT#">
		<input type="hidden" name="xFD" value="#xFD#">
		<input type="hidden" name="xTD" value="#xTD#">
		<input type="hidden" name="v_ID" value="#v_ID#">
		<input type="hidden" name="OnPage" value="#OnPage#">
		<input type="hidden" name="po_ID" value="#po_ID#">
		<input type="submit" name="submit" value="   Save Changes   " >
	</td>
	</tr>
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn RECEIVED PO --->
<cfelseif pgfn EQ "condrop">
	<!--- START pgfn CONFIRM A DROPSHIP PO --->
	<!--- get po info --->
	<cfquery name="GetPOInfo" datasource="#application.DS#">
		SELECT vendor_ID, snap_vendor, snap_attention, snap_phone, snap_fax, is_dropship, po_rec_date, itc_name, itc_phone, itc_fax, itc_email, po_printed_note, po_hidden_note, modified_concat    
		FROM #application.database#.purchase_order 
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
	</cfquery>
	<cfoutput>
	<span class="pagetitle">Purchase Order - Confirm Dropshipment</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order #po_ID-1000000000# Detail</a> or <a href="po_list.cfm?xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Purchase Order List</a> without making changes.</span>
	<br /><br />
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
	<tr>
	<td colspan="2" class="contenthead"><b>Purchase Order #po_ID-1000000000# for #GetPOInfo.snap_vendor#</b></td>
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
		SELECT <cfif GetPOInfo.is_dropship EQ 1>quantity<cfelse>po_quantity</cfif> AS qty, snap_meta_name, snap_description, snap_sku, snap_vendor_sku, snap_sku, snap_is_dropshipped, snap_options, snap_productvalue , order_ID, ID AS inventory_ID, product_ID, IFNULL(tracking,"") AS tracking, order_ID 
		FROM #application.database#.inventory
		WHERE po_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#">
			AND is_valid = 1
		ORDER BY product_ID
	</cfquery>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
	<tr class="contenthead">
	<td colspan="6" class="headertext">Products</td>
	</tr>
	<tr class="contentsearch">
	<td class="headertext" align="center">Tracking Number</td>
	<td class="headertext">PO Qty</td>
	<td class="headertext">Product</td>
	</tr>
	<cfloop query="GetPOInvItems">
		<tr class="content">
		<td align="center">
			<cfif snap_is_dropshipped EQ 1 AND tracking EQ "">
				<input type="text" name="inv_#inventory_ID#" maxlength="32" size="14">
				<input type="hidden" name="#inventory_ID#" value="QTY: #qty# CAT: #snap_productvalue# SKU: #HTMLEditFormat(snap_sku)# PRODUCT: #snap_meta_name#<cfif snap_options NEQ ""> #snap_options#</cfif>">
				<input type="hidden" name="order_#inventory_ID#" value="#order_ID#">
			<cfelse>
				#tracking#
			</cfif>
		</td>
		<td align="center"><b>#qty#</b></td>
		<td>
			<b>#snap_meta_name#</b> #snap_options#<br>
			ITC SKU : #snap_sku#<br>
			Vendor SKU: #snap_vendor_sku#
		</td>
		</tr>
		<!--- find the shipto address --->
		<cfquery name="OrderInfo" datasource="#application.DS#">
			SELECT snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, 
				snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, program_ID, order_number  
			FROM #application.database#.order_info
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
		</cfquery>
		<tr class="content">
		<td colspan="2">&nbsp;</td>
		<td>
			#GetProgramName(OrderInfo.program_ID)# Order #OrderInfo.order_number#<br>
			SHIP TO: #OrderInfo.snap_ship_fname# #OrderInfo.snap_ship_lname#, #OrderInfo.snap_ship_address1# #OrderInfo.snap_ship_address2#, #OrderInfo.snap_ship_city#, #OrderInfo.snap_ship_state# #OrderInfo.snap_ship_zip#, phone: #OrderInfo.snap_phone#
		</td>
		</tr>
	</cfloop>
	<tr class="content">
	<td align="center"><input type="text" name="condrop_date" maxlength="32" size="14" value="#FLGen_DateTimeToDisplay()#"></td>
	<td colspan="2"> <b>Confirmation/Shipment Date</b></td>
	</tr>
	<tr class="contenthead">
	<td colspan="6" class="content" align="center">
		<input type="hidden" name="edit" value="condrop">
		<input type="hidden" name="xT" value="#xT#">
		<input type="hidden" name="xFD" value="#xFD#">
		<input type="hidden" name="xTD" value="#xTD#">
		<input type="hidden" name="v_ID" value="#v_ID#">
		<input type="hidden" name="OnPage" value="#OnPage#">
		<input type="hidden" name="po_ID" value="#po_ID#">
		<input type="submit" name="submit" value="   Save Changes   " >
	</td>
	</tr>
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn CONFIRM A DROPSHIP PO --->
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->