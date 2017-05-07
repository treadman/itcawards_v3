<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfparam name="search_text" default="">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">

<!--- ************************************ --->
<!--- get report info                      --->
<!--- ************************************ --->

<cfset List_ProductsWithInventory = "">

<!--- distinct list of ordered products that are not shipped ordered by product value --->
<cfquery name="SelectDistinctProducts" datasource="#application.DS#">
	SELECT DISTINCT product_ID
	FROM #application.database#.inventory
	WHERE is_valid = 1 
		AND quantity <> 0 
		AND snap_is_dropshipped = 0 
		AND order_ID <> 0 
		AND ship_date IS NULL
		AND po_ID = 0
		AND po_rec_date IS NULL
		AND upsgroup_ID IS NULL 
	ORDER BY snap_productvalue, snap_sku 
</cfquery>

<!--- calc physical inventory to see if available to ship --->
<cfloop query="SelectDistinctProducts">
	<cfset thisDistinctProduct = SelectDistinctProducts.product_ID>
	<cfset ProductPhysicalTotal = CalcPhysicalInventory(thisDistinctProduct)>
	<cfif ProductPhysicalTotal gt 0>
		<cfset List_ProductsWithInventory = ListAppend(List_ProductsWithInventory,thisDistinctProduct & "_" & ProductPhysicalTotal)>
	</cfif>
</cfloop>

<cfset List_MultiProductOrders = "">

<cfif List_ProductsWithInventory EQ "">

	<cfset alert_error = "There are no products with sufficient inventory waiting to be shipped from ITC.\n\nClick PO Builder to see if any physical stock needs to be ordered.">
	
<!--- loop through products, build up order/program/quantity query object --->
<cfelse>

	<cfset OrdersToDisplay = QueryNew("product_ID, program_ID, order_ID, quantity, order_number, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, order_note,snap_order_total, points_used, credit_card_charge, shipping_charge, snap_signature_charge, shipping_desc","Integer, Integer, Integer, Integer, Integer, VarChar, VarChar, VarChar, VarChar, VarChar, VarChar, VarChar, VarChar, VarChar, VarChar, VarChar, VarChar, VarChar,Decimal, Integer, Decimal, Decimal, Decimal, VarChar")>
		

	<cfset loop_counter = 1>
	<cfloop list="#List_ProductsWithInventory#" index="loop_i">
		<cfset loop_product_ID = ListGetAt(loop_i,1,"_")>
		<cfset loop_physicaltotal = ListGetAt(loop_i,2,"_")>

		<cfquery name="SelectOrderID" datasource="#application.DS#" maxrows="#loop_physicaltotal#">
			SELECT inv.order_ID, ord.program_ID, inv.quantity, ord.order_number, ord.snap_fname, ord.snap_lname, ord.snap_ship_company, ord.snap_ship_fname,
					ord.snap_ship_lname, ord.snap_ship_address1, ord.snap_ship_address2, ord.snap_ship_city, ord.snap_ship_state, ord.snap_ship_zip,
					ord.snap_phone, ord.snap_email, ord.order_note, ord.snap_order_total, points_used, credit_card_charge, ord.shipping_charge, ord.snap_signature_charge, ord.shipping_desc
			FROM #application.database#.inventory inv
			JOIN #application.database#.order_info ord ON inv.order_ID = ord.ID
			WHERE inv.is_valid = 1 
				AND inv.quantity <> 0 
				AND inv.snap_is_dropshipped = 0 
				AND inv.order_ID <> 0 
				AND inv.ship_date IS NULL
				AND inv.po_ID = 0
				AND inv.po_rec_date IS NULL
				AND inv.product_ID = <cfqueryparam value="#loop_product_ID#" cfsqltype="cf_sql_integer">
				AND upsgroup_ID IS NULL
				<cfif search_text neq "">
					AND (
						<cfif isNumeric(search_text)>
							ord.order_number = <cfqueryparam value="#search_text#" cfsqltype="cf_sql_integer"> OR
						</cfif>
						ord.snap_fname = <cfqueryparam value="#search_text#" cfsqltype="cf_sql_varchar"> OR
						ord.snap_lname = <cfqueryparam value="#search_text#" cfsqltype="cf_sql_varchar">
					)
				</cfif>
			ORDER BY inv.created_datetime
		</cfquery>
		<cfif SelectOrderID.RecordCount GT 0>
			<cfset QueryAddRow(OrdersToDisplay,SelectOrderID.RecordCount)>
			
			<cfset QuantityCounter = 0>
			<cfloop query="SelectOrderID">
				
				<cfset QuantityCounter = QuantityCounter + SelectOrderID.quantity>
				
				<cfif QuantityCounter LTE loop_physicaltotal>
				
					<cfset QuerySetCell(OrdersToDisplay,"product_ID",loop_product_ID,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"program_ID",SelectOrderID.program_ID,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"order_ID",SelectOrderID.order_ID,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"quantity",SelectOrderID.quantity,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"order_number",SelectOrderID.order_number,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_fname",SelectOrderID.snap_fname,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_lname",SelectOrderID.snap_lname,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_ship_company",SelectOrderID.snap_ship_company,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_ship_fname",SelectOrderID.snap_ship_fname,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_ship_lname",SelectOrderID.snap_ship_lname,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_ship_address1",SelectOrderID.snap_ship_address1,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_ship_address2",SelectOrderID.snap_ship_address2,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_ship_city",SelectOrderID.snap_ship_city,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_ship_state",SelectOrderID.snap_ship_state,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_ship_zip",SelectOrderID.snap_ship_zip,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_phone",SelectOrderID.snap_phone,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_email",SelectOrderID.snap_email,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"order_note",SelectOrderID.order_note,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_order_total",SelectOrderID.snap_order_total,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"points_used",SelectOrderID.points_used,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"credit_card_charge",SelectOrderID.credit_card_charge,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"shipping_charge",SelectOrderID.shipping_charge,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"snap_signature_charge",SelectOrderID.snap_signature_charge,loop_counter)>
					<cfset QuerySetCell(OrdersToDisplay,"shipping_desc",SelectOrderID.shipping_desc,loop_counter)>
					
					<cfset loop_counter = IncrementValue(loop_counter)>
					
				<cfelse>
				
					<cfbreak>
					
				</cfif>
		
			</cfloop>
		</cfif>
	</cfloop>

</cfif>
		
<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "report_fulfillment">
<cfinclude template="includes/header.cfm">

<form method="post" name="hidden_form" action="report_fulfillment_printitem.cfm" target="_blank" onsubmit="window.open('', 'processor_window'); this.target = 'processor_window'">
	<input type="hidden" name="print_orders" />
	<input type="hidden" name="print_quantity" />
	<input type="hidden" name="print_product" />
</form>

<script language="javascript">
function submit_hidden_form(product,quantity,orders)
{
	f = document.hidden_form
	
	f.print_product.value = product
	f.print_quantity.value = quantity
	f.print_orders.value = orders
	f.submit()

}
</script>

<span class="pagetitle">Ship From ITC</span>
<br /><br />
	<!--- search box --->
	<table cellpadding="2" cellspacing="0" border="0" width="50%">
	<tr class="contenthead">
	<td><span class="headertext">Search Criteria</span></td>
	<td align="right"><a href="<cfoutput>#CurrentPage#</cfoutput>" class="headertext">view all</a></td>
	</tr>
	<tr>
	<td class="content" colspan="2" align="center">
		<cfoutput>
		<form action="#CurrentPage#" method="post">
			<table cellpadding="2" cellspacing="0" border="0" width="100%">
				<tr>
				<td>&nbsp;&nbsp;&nbsp;&nbsp;
					<span class="sub">order ## or user's name</span><br>
					&nbsp;&nbsp;&nbsp;&nbsp;
					<input type="text" name="search_text" value="#HTMLEditFormat(search_text)#" size="20">
					<!---
					<br><br>
					<span class="sub">From Date:</span> <input type="text" name="this_from_date" value="#this_from_date#" size="20" style="margin-bottom:5px"><br>
					<span class="sub">&nbsp;&nbsp;&nbsp;&nbsp;To Date:</span> <input type="text" name="this_to_date" value="#this_to_date#" size="20">
					--->
				</td>
				<td align="center">&nbsp;&nbsp;&nbsp;</td>
				</tr>
				<tr>
				<td colspan="2" align="center">
					<input type="submit" name="search" value="  Search  ">
				</td>
				</tr>
			</table>
		</form>
		</cfoutput>
	</td>
	</tr>
	</table>
<br><br>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<cfset javascript_counter = 1>
	<cfset found_any = false>
	
	<!--- loop through product list --->
	<cfloop list="#List_ProductsWithInventory#" index="listloop_prodinv">
	
		<!--- find product info --->
		<cfset individual_ID = ListGetAt(listloop_prodinv,1,"_")>
		<cfset phys_inv = ListGetAt(listloop_prodinv,2,"_")>
		<cfset List_IndividualShipOrders = "">
		<cfset List_IndividualShipQuantities = "">
		
		<cfquery name="SelectProdInfo" datasource="#application.DS#">
			SELECT 	meta.meta_name, prod.sku, pval.productvalue, prod.ID AS individual_ID, 
					IF((SELECT COUNT(*) FROM #application.database#.product_meta_option_category pm WHERE meta.ID = pm.product_meta_ID)=0,"false","true") AS has_options
			FROM #application.database#.product_meta meta
			JOIN #application.database#.product prod ON prod.product_meta_ID = meta.ID 
			JOIN #application.database#.productvalue_master pval ON pval.ID = meta.productvalue_master_ID
			WHERE prod.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#individual_ID#" maxlength="10"> 
		</cfquery>
		
		<cfset these_options = "">
		<cfif SelectProdInfo.has_options>
			<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
				SELECT CONCAT("[",pmoc.category_name,": ",pmo.option_name,"]") AS category_and_option
				FROM #application.database#.product_meta_option_category pmoc
				JOIN #application.database#.product_meta_option pmo ON pmoc.ID = pmo.product_meta_option_category_ID 
				JOIN #application.database#.product_option po ON pmo.ID = po.product_meta_option_ID
				WHERE po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#individual_ID#" maxlength="10"> 
				ORDER BY pmoc.sortorder
			</cfquery>
			<cfset these_options = ValueList(FindProductOptionInfo.category_and_option," ")>
		</cfif>
		
		<cfquery name="SelectProdsInUPSGroups" datasource="#application.DS#">
			SELECT COUNT(ID) AS ThisTotal
			FROM #application.database#.inventory
			WHERE is_valid = 1 
				AND quantity <> 0 
				AND snap_is_dropshipped = 0 
				AND order_ID <> 0 
				AND ship_date IS NULL
				AND po_ID = 0
				AND po_rec_date IS NULL
				AND upsgroup_ID IS NOT NULL
				AND product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#individual_ID#"> 
		</cfquery>
		
		<!--- find all the orders for this product --->
		<cfquery name="SelectProductsOrders" dbtype="query">
			SELECT product_ID,program_ID,order_ID,quantity
			FROM OrdersToDisplay
			WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#individual_ID#"> 
			ORDER BY order_ID
		</cfquery>

		<cfif search_text EQ "" OR SelectProductsOrders.recordcount gt 0>
			<cfset found_any = true>
			<!--- HEADER ROW --->
			<cfoutput>
				<tr class="contenthead">
				<td align="center"> <a href="##" onclick="submit_hidden_form('#individual_ID#',quantity_list#javascript_counter#,order_list#javascript_counter#);return false;" style="visibility:hidden" id="order_list_link#javascript_counter#">print</a></td>
				<td>CAT: #SelectProdInfo.productvalue#</td>
				<td>
					<b>#SelectProdInfo.meta_name#</b><cfif these_options NEQ ""> #these_options#</cfif><br />
					ITC SKU: #SelectProdInfo.sku#<br />
				</td>
				<td><b>#phys_inv#</b>&nbsp;in&nbsp;inventory&nbsp;<cfif SelectProdsInUPSGroups.ThisTotal GT 0><br><b>#SelectProdsInUPSGroups.ThisTotal#</b>&nbsp;in&nbsp;ups&nbsp;groups<br><b>#phys_inv - SelectProdsInUPSGroups.ThisTotal#</b>&nbsp;available</cfif></td>
				</tr>
			</cfoutput>
						
			<!---  loop through List_Orders, if this product, get order info --->
			<cfloop query="SelectProductsOrders">
	
				<!--- get product ID and order_ID vars --->
				<cfset thisindv_ID = SelectProductsOrders.product_ID>
				<cfset thisprogram_ID = SelectProductsOrders.program_ID>
				<cfset thisorder_ID = SelectProductsOrders.order_ID>
				<cfset thisindv_qty = SelectProductsOrders.quantity>
				
				<!--- check for multi products in ship list --->
				<cfquery name="MultiProdCheck" dbtype="query">
					SELECT product_ID
					FROM OrdersToDisplay
					WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisorder_ID#"> 
				</cfquery>
	
				<cfif MultiProdCheck.RecordCount GT 1>
				
					<!--- add to list if not already on list --->
					<cfif ListFind(List_MultiProductOrders,thisorder_ID) EQ 0>
						<cfset List_MultiProductOrders = ListAppend(List_MultiProductOrders,thisorder_ID)>
					</cfif>
								
					<cfquery name="FindOrderInfo" dbtype="query">
						SELECT program_ID AS this_program_ID, order_number
						FROM OrdersToDisplay
						WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisorder_ID#" maxlength="10">
					</cfquery>
												
				<tr class="content">
				<td colspan="4"><cfoutput><span class="sub">QTY: #thisindv_qty# to be shipped in the multi-item #GetProgramName(FindOrderInfo.this_program_ID)# Order #FindOrderInfo.order_number# (see below)</span></cfoutput></td>
				</tr>
								
				<cfelse>
						
					<cfset List_IndividualShipOrders = ListAppend(List_IndividualShipOrders,thisorder_ID)>
					<cfset List_IndividualShipQuantities = ListAppend(List_IndividualShipQuantities,thisindv_qty)>
																					
					<cfquery name="FindOrderInfo" dbtype="query">
						SELECT program_ID, order_ID, order_number, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, order_note 
						FROM OrdersToDisplay
						WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisorder_ID#" maxlength="10">
					</cfquery>
	
					<cfoutput>
				
			<tr class="content">
			<td colspan="4">
			
				<table cellpadding="0" cellspacing="0" border="0" width="100%">
				<tr>
				<td valign="top" width="40%">
					QTY: #thisindv_qty#<br>
					#GetProgramName(FindOrderInfo.program_ID)# Order #FindOrderInfo.order_number#<br>
					<cfif FindOrderInfo.snap_fname NEQ "">#FindOrderInfo.snap_fname#</cfif> <cfif FindOrderInfo.snap_lname NEQ "">#FindOrderInfo.snap_lname#<br></cfif>
					<cfif FindOrderInfo.snap_phone NEQ "">Phone: #FindOrderInfo.snap_phone#<br></cfif>
					<cfif FindOrderInfo.snap_email NEQ "">Email: #FindOrderInfo.snap_email#<br></cfif>
				</td>
				<td valign="top" width="60%">
					<a href="order_ship.cfm?shipID=#FindOrderInfo.order_ID#&back=report_fulfillment&ordit=#thisindv_ID#">SHIP TO</a><br>
					<cfif FindOrderInfo.snap_ship_company NEQ "">#FindOrderInfo.snap_ship_company#<br></cfif>
					<cfif FindOrderInfo.snap_ship_fname NEQ "">#FindOrderInfo.snap_ship_fname#</cfif> <cfif FindOrderInfo.snap_ship_lname NEQ "">#FindOrderInfo.snap_ship_lname#</cfif><br>
					<cfif FindOrderInfo.snap_ship_address1 NEQ "">#FindOrderInfo.snap_ship_address1#<br></cfif>
					<cfif FindOrderInfo.snap_ship_address2 NEQ "">#FindOrderInfo.snap_ship_address2#<br></cfif>
					<cfif FindOrderInfo.snap_ship_city NEQ "">#FindOrderInfo.snap_ship_city#</cfif>, <cfif FindOrderInfo.snap_ship_state NEQ "">#FindOrderInfo.snap_ship_state#</cfif> <cfif FindOrderInfo.snap_ship_zip NEQ "">#FindOrderInfo.snap_ship_zip#</cfif><br>
				<cfif FindOrderInfo.order_note NEQ "">#Replace(HTMLEditFormat(FindOrderInfo.order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(no order note)</span></cfif></td>
				</tr>
				</table>
				
	
			</td>
			</tr>
			
					</cfoutput>
	
				</cfif>
				
			</cfloop>

			<!--- USE JAVASCRIPT to put all the orders in a hidden form field --->
			<cfoutput>
			<script language="javascript">
				order_list#javascript_counter# = '#List_IndividualShipOrders#';
				quantity_list#javascript_counter# = '#List_IndividualShipQuantities#';
				document.getElementById("order_list_link#javascript_counter#").style.visibility = "visible";
			</script>
			</cfoutput>
				
			<cfset javascript_counter = IncrementValue(javascript_counter)>
		</cfif>
	</cfloop>
	
	</table>

			
	<!--- DISPLAY multi-product orders --->
	<cfset separate_table = "yes">
	
	<!--- loop through product list --->
	<cfloop list="#List_MultiProductOrders#" index="mpo_i">
	
		<!--- get product ID and physical inventory vars --->
		<cfset multi_order_ID = mpo_i>
		
		<cfif separate_table EQ "yes">

		<!--- separate the single item orders from the multi item orders --->
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr><td>&nbsp;</td></tr>
		<tr><td class="headertext">M U L T I&nbsp;&nbsp;&nbsp;P R O D U C T&nbsp;&nbsp;&nbsp;O R D E R S</td>
</tr>		
		<tr><td>&nbsp;</td></tr>
		</table>
		
			<cfset separate_table = "no">
			
		</cfif>
		
		<!--- get order info --->
		<cfquery name="FindMultiOrderInfo" dbtype="query">
			SELECT program_ID, order_ID, order_number, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, order_note, snap_order_total, points_used, credit_card_charge 
			FROM OrdersToDisplay
			WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#multi_order_ID#">
		</cfquery>
		<cfset order_ID = FindMultiOrderInfo.order_ID>
		<cfset this_program_ID = FindMultiOrderInfo.program_ID>
		<cfset order_number = HTMLEditFormat(FindMultiOrderInfo.order_number)>
		<cfset snap_order_total = HTMLEditFormat(FindMultiOrderInfo.snap_order_total)>
		<cfset points_used = HTMLEditFormat(FindMultiOrderInfo.points_used)>
		<cfset credit_card_charge = HTMLEditFormat(FindMultiOrderInfo.credit_card_charge)>
		<cfset snap_fname = HTMLEditFormat(FindMultiOrderInfo.snap_fname)>
		<cfset snap_lname = HTMLEditFormat(FindMultiOrderInfo.snap_lname)>
		<cfset snap_ship_company = HTMLEditFormat(FindMultiOrderInfo.snap_ship_company)>
		<cfset snap_ship_fname = HTMLEditFormat(FindMultiOrderInfo.snap_ship_fname)>
		<cfset snap_ship_lname = HTMLEditFormat(FindMultiOrderInfo.snap_ship_lname)>
		<cfset snap_ship_address1 = HTMLEditFormat(FindMultiOrderInfo.snap_ship_address1)>
		<cfset snap_ship_address2 = HTMLEditFormat(FindMultiOrderInfo.snap_ship_address2)>
		<cfset snap_ship_city = HTMLEditFormat(FindMultiOrderInfo.snap_ship_city)>
		<cfset snap_ship_state = HTMLEditFormat(FindMultiOrderInfo.snap_ship_state)>
		<cfset snap_ship_zip = HTMLEditFormat(FindMultiOrderInfo.snap_ship_zip)>
		<cfset snap_phone = HTMLEditFormat(FindMultiOrderInfo.snap_phone)>
		<cfset snap_email = HTMLEditFormat(FindMultiOrderInfo.snap_email)>
		<cfset order_note = HTMLEditFormat(FindMultiOrderInfo.order_note)>
				
		<cfoutput>
		
		<!--- header row with product name and productvalue --->
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		
		<tr class="contenthead">
		<td class="headertext" colspan="2"><a href="report_fulfillment_printorder.cfm?order=#order_ID#&" target="_blank"><span style="font-weight:normal">print</span></a>&nbsp;&nbsp;&nbsp;#GetProgramName(this_program_ID)# Order #order_number#</td>
		</tr>

		<tr class="content">
		<td valign="top" width="40%">
			<cfif snap_fname NEQ "">#snap_fname#</cfif> <cfif snap_lname NEQ "">#snap_lname#<br></cfif>
			<cfif snap_phone NEQ "">Phone: #snap_phone#<br></cfif>
			<cfif snap_email NEQ "">Email: #snap_email#<br></cfif>
		</td>
		<td valign="top" width="60%">
		
		<!--- find order items --->
		<cfquery name="FindOrderItems" datasource="#application.DS#">
			SELECT ID AS inventory_ID, product_ID, snap_sku, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options
			FROM #application.database#.inventory
			WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#multi_order_ID#" maxlength="10"> 
				AND is_valid = 1
		</cfquery>
		
		<cfset ordit = "">
		<cfloop query="FindOrderItems">
		
			<cfquery name="ShipableProdCheck" dbtype="query">
				SELECT product_ID
				FROM OrdersToDisplay
				WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
					AND order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#multi_order_ID#"> 
					AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_program_ID#"> 
					AND quantity = <cfqueryparam cfsqltype="cf_sql_integer" value="#quantity#"> 
			</cfquery>
			<cfif ShipableProdCheck.RecordCount EQ 1>
				<cfset ordit = ListAppend(ordit,"x" & product_ID)>
			</cfif>
		</cfloop>
		
				<a href="order_ship.cfm?shipID=#order_ID#&back=report_fulfillment&ordit=#ordit#">SHIP TO</a><br>
				<cfif snap_ship_company NEQ "">#snap_ship_company#<br></cfif>
				<cfif snap_ship_fname NEQ "">#snap_ship_fname#</cfif> <cfif snap_ship_lname NEQ "">#snap_ship_lname#</cfif><br>
				<cfif snap_ship_address1 NEQ "">#snap_ship_address1#<br></cfif>
				<cfif snap_ship_address2 NEQ "">#snap_ship_address2#<br></cfif>
				<cfif snap_ship_city NEQ "">#snap_ship_city#</cfif>, <cfif snap_ship_state NEQ "">#snap_ship_state#</cfif> <cfif snap_ship_zip NEQ "">#snap_ship_zip#</cfif><br>
			<cfif order_note NEQ "">#Replace(HTMLEditFormat(order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(no order note)</span></cfif>
		</td>
		</tr>
		
		<tr class="content">
		<td colspan="2">
			<table cellpadding="5" cellspacing="1" border="0" width="100%">
			<cfloop query="FindOrderItems">
			
				<!--- is this product marked as ready to be shipped out in the query --->
				<cfquery name="ProdToBeShippedCheck" dbtype="query">
					SELECT COUNT(product_ID) 
					FROM OrdersToDisplay
					WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#multi_order_ID#">  
						AND product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
						AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_program_ID#">
						AND quantity = <cfqueryparam cfsqltype="cf_sql_integer" value="#quantity#">
				</cfquery>

				<cfif ProdToBeShippedCheck.RecordCount GT 0>
			<tr>
			<td>CAT: #snap_productvalue#</td>
			<td>QTY: #quantity#</td>
			<td>SKU: #snap_sku#</td>
			<td>#snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
			</tr>
				</cfif>
			</cfloop>
			</table>
		</td>
		</tr>
		
		</cfoutput>
				
	</cfloop>
	<cfif NOT found_any AND List_ProductsWithInventory NEQ "">
		<span class="alert">Nothing found for your search parameters.<br><br>Click "View All" to see all inventory to be shipped.</span>
	</cfif>
	
		</table>
			
	</table>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->