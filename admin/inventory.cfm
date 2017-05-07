<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000013,true)>

<cfparam name="where_string" default="">
<cfparam name="meta_ID" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="name">
<cfparam name="xL" default="">
<cfparam name="xT" default="">
<cfparam name="xW" default="">
<cfparam name="OnPage" default="1">
<cfparam name="orderbyvar" default="">
<cfparam name="translate" default="">
<cfparam name="searchboxtext" default="">
<cfparam name="group_count" default="">
<cfparam name="totalprods" default="0">

<!--- param display fields --->
<cfparam name="meta_ID" default="">	
<cfparam name="value" default="">
<cfparam name="productvalue_master_ID" default="">
<cfparam name="meta_name" default="">
<cfparam name="meta_sku" default="">
<cfparam name="description" default="">
<cfparam name="imagename_original" default="">
<cfparam name="thumbnailastname_original" default="">
<cfparam name="sortorder" default="">
<cfparam name="manuf_name" default="">
<cfparam name="de" default="">
<cfparam name="delete" default="">

<!--- *********************** --->
<!--- START form processing   --->
<!--- *********************** --->

<cfif IsDefined('form.Submit')>

	<!--- find product information for snaps --->
	<cfquery name="FindProductInfo" datasource="#application.DS#">
		SELECT 	m.meta_name, m.description, prod.sku, p.productvalue, prod.is_dropshipped 
		FROM #application.database#.product_meta m JOIN #application.database#.product prod ON prod.product_meta_ID = m.ID
			JOIN #application.database#.productvalue_master p ON m.productvalue_master_ID = p.ID
		WHERE prod.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
	</cfquery>
	<cfset this_meta_name = FindProductInfo.meta_name>
	<cfset this_description = HTMLEditFormat(FindProductInfo.description)>
	<cfset this_sku = HTMLEditFormat(FindProductInfo.sku)>
	<cfset this_productvalue = HTMLEditFormat(FindProductInfo.productvalue)>
	<cfset this_is_dropsbipped = FindProductInfo.is_dropshipped>
	
	<cfset FPO_theseoptions = FindProductOptions(product_ID)>
	
	<!--- massage quantity --->
	<cfif addsub EQ 'sub'>
		<cfset quantity = '-' & quantity>
	</cfif>

	<!--- insert the adjustment into the database --->
	<cfquery name="InsertInvAdj" datasource="#application.DS#">
		INSERT INTO #application.database#.inventory
		(created_user_ID, created_datetime, is_valid, product_ID, quantity, snap_meta_name, snap_description, snap_sku, snap_productvalue, snap_options, snap_is_dropshipped, note)
		VALUES
		('#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#',1, 
			<cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10">,
			<cfqueryparam cfsqltype="cf_sql_integer" value="#quantity#" maxlength="8">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#this_meta_name#" maxlength="64">,
			<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#this_description#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#this_sku#" maxlength="64">,
			<cfqueryparam cfsqltype="cf_sql_integer" value="#this_productvalue#" maxlength="8">, 
			<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FPO_theseoptions#" null="#YesNoFormat(NOT Len(Trim(FPO_theseoptions)))#">,
			<cfqueryparam cfsqltype="cf_sql_tinyint" value="#this_is_dropsbipped#" maxlength="1">,
			<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#note#">)
	</cfquery>
	<cfset alert_msg = "Your inventory adjustment was saved.">
	<cfset pgfn = "edit">
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000049)>
	<cfquery name="DeleteLineItem" datasource="#application.DS#">
		DELETE FROM #application.database#.inventory
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>
	<cfset pgfn = "edit">
</cfif>

<!--- *********************** --->
<!--- END form processing     --->
<!--- *********************** --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "inventory">
<cfinclude template="includes/header.cfm">

<SCRIPT LANGUAGE="JavaScript"><!-- 
function openURL() { 
	// grab index number of the selected option
	selInd = document.pageform.pageselect.selectedIndex; 
	// get value of the selected option
	goURL = document.pageform.pageselect.options[selInd].value;
	// redirect browser to the grabbed value (hopefully a URL)
	top.location.href = goURL; 
}
//--></SCRIPT>

<cfparam  name="pgfn" default="list">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

	<!--- set ORDER BY --->
	<cfswitch expression="#xS#">
		<cfcase value="name">
			<cfset orderbyvar = "m.meta_name">
			<cfset orderbyclause = "m.meta_name, prod.sortorder">
			<cfset searchboxtext = "Product Name">
		</cfcase>
		<cfcase value="mcat">
			<cfset orderbyvar = "p.productvalue">
			<cfset orderbyclause = "p.productvalue, m.sortorder, prod.sortorder">
			<cfset searchboxtext = "Master Category">
		</cfcase>
		<cfcase value="sku">
			<cfset orderbyvar = "prod.sku">
			<cfset orderbyclause = "prod.sku, prod.sortorder">
			<cfset searchboxtext = "ITC SKU">
		</cfcase>
	</cfswitch>
	
	<!--- Set the WHERE clause --->
	<!--- First check if a search string passed --->
	<cfif LEN(xT) GT 0 AND IsDefined('form.submit1')>
		<cfset xW = "1">
	<cfelseif LEN(xT) GT 0 AND IsDefined('form.submit2')>
		<cfset xW = "2">
	</cfif>
	
	<!--- run query --->
	<cfif ListFindNoCase("m.meta_name,p.productvalue,prod.sku",orderbyvar)>
		<cfquery name="SelectList" datasource="#application.DS#">
			SELECT 	m.meta_name, 
					prod.sku, 
					prod.ID AS product_ID, 
					p.productvalue, 
					m.sortorder AS sortorder
			FROM #application.database#.product_meta m JOIN #application.database#.productvalue_master p ON m.productvalue_master_ID = p.ID
				JOIN #application.database#.product prod ON prod.product_meta_ID = m.ID
			WHERE prod.is_dropshipped = 0 
			AND prod.is_discontinued = 0 
			<cfif LEN(xT) GT 0 AND ((IsDefined('form.submit1') AND #form.submit1# IS NOT "") OR (xW EQ 1))>
				AND (m.meta_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> 
				OR prod.sku LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">)
			<cfelseif LEN(xT) GT 0 AND ((IsDefined('form.submit2') AND #form.submit2# IS NOT "") OR (xW EQ 2))>
				AND (p.productvalue = <cfqueryparam cfsqltype="cf_sql_varchar" value="#xT#">)
			</cfif>
			<cfif LEN(xL) GT 0>
				AND (#orderbyvar# LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xL#%" maxlength="3">)
			</cfif>
			ORDER BY #orderbyclause#
		</cfquery>
		<cfset totalprods = SelectList.RecordCount>
	</cfif>
	
	<!--- set the start/end/max display row numbers --->
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(totalprods,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,totalprods)>
	<cfset TotalPages_SelectList=Ceiling(totalprods/MaxRows_SelectList)>
	
	<cfoutput>
	<span class="pagetitle">Inventory List</span>
	<br /><br />
	</cfoutput>

	<!--- search box --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td class="headertext">Search Criteria</td>
	<td align="right"><a href="<cfoutput>#CurrentPage#</cfoutput>" class="headertext">view all</a></td>
	</tr>
	
	<cfoutput>	
	<tr class="contentsearch">
	<td align="center" colspan="2">
		<span class="searchcriteria">
			current search/sort &raquo;&nbsp;&nbsp;
		<!--- text--->
			<cfif xT NEQ "" AND xW EQ "1">
				[ find "#xT#" in SKU or Product Name ]&nbsp;&nbsp;
			<cfelseif xT NEQ "" AND xW EQ "2">
				[ select all products in Master Category #xT# ]&nbsp;&nbsp;
			</cfif>
		<!--- letter/number--->
			<cfif LEN(xL) GT 0>
				[ where #searchboxtext# starts with "#xL#" ]&nbsp;&nbsp;
			</cfif>
		<!--- sort--->
			[ sorted by #searchboxtext# ]
		</span>
	</td>
	</tr>
	</cfoutput>

	<tr class="content">
	<td align="center" colspan="2" height="5"></td>
	</tr>
	
	<tr>
	<td class="content" colspan="2" align="center">
		<cfoutput>
		<form action="#CurrentPage#" method="post">
			<input type="hidden" name="xL" value="#xL#">
			<input type="hidden" name="xS" value="#xS#">
			<input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20">
			<input type="submit" name="submit1" value="sku or name">
			<input type="submit" name="submit2" value="master category">
		</form>
		<br>		
		<cfif LEN(xL) IS 0><span class="ltrON">ALL</span><cfelse><a href="#CurrentPage#?xL=&xS=#xS#&xT=#xT#&xW=#xW#" class="ltr">ALL</a></cfif><span class="ltrPIPE">&nbsp;&nbsp;</span><cfloop index = "LoopCount" from = "0" to = "9"><cfoutput><cfif xL IS LoopCount><span class="ltrON">#LoopCount#</span><cfelse><a href="#CurrentPage#?xL=#LoopCount#&xS=#xS#&xT=#xT#&xW=#xW#" class="ltr">#LoopCount#</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span></cfloop><cfloop index = "LoopCount" from = "1" to = "26"><cfoutput><cfif xL IS CHR(LoopCount + 64)><span class="ltrON">#CHR(LoopCount + 64)#</span><cfelse><a href="#CurrentPage#?xL=#CHR(LoopCount + 64)#&xS=#xS#&xT=#xT#&xW=#xW#" class="ltr">#CHR(LoopCount + 64)#</a></cfif></cfoutput><cfif LoopCount NEQ 26><span class="ltrPIPE">&nbsp;&nbsp;</span></cfif></cfloop>
		</cfoutput>
	</td>
	</tr>
	
	</table>
	
	<br />
	
	<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0>
	<form name="pageform">
	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	<td>
		<cfif OnPage GT 1>
			<a href="<cfoutput>#CurrentPage#?OnPage=1&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
		</cfif>
	</td>
	<td align="center" class="sub">[ page 	
	<cfoutput>
		<select name="pageselect" onChange="openURL()"> 
				<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
			<option value="#CurrentPage#?OnPage=#this_i#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
				</cfloop>
		</select>
	
 of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
	</cfoutput>
	</td>
	<td align="right">
		<cfif OnPage LT TotalPages_SelectList>
			<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#</cfoutput>" class="pagingcontrols">&raquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
		</cfif>
	</td>
	</tr>
	</table>
	</form>
	</cfif>
	
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<!--- header row --->
	<cfoutput>	

	<tr class="contenthead">
	<td align="right" rowspan="2">&nbsp;</td>
	<td rowspan="2">
		<cfif xS IS "sku">
			<span class="headertext">ITC SKU</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xS=sku&xL=#xL#&xT=#xT#&xW=#xW#" class="headertext">ITC SKU</a>
		</cfif>
	</td>
	<td rowspan="2">
		<cfif xS IS "name">
			<span class="headertext">Product Name</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xS=name&xL=#xL#&xT=#xT#&xW=#xW#" class="headertext">Product Name</a>
		</cfif>
	</td>
	<td rowspan="2">
		<cfif xS IS "mcat">
			<span class="headertext">Master<br>Catgory</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xS=mcat&xL=#xL#&xT=#xT#&xW=#xW#" class="headertext">Master<br>Category</a>
		</cfif>
	</td>
	<td align="center" colspan="4"><span class="headertext">Physical Inventory</span></td>
	</tr>

	<tr class="contenthead">
	<td align="center"><span class="headertext">Real<br>Total</span></td>
	<td align="center"><span class="sub">POs<br>Out</span></td>
	<td align="center"><span class="sub">Unshipped<br>Orders</span></td>
	<td align="center"><span class="headertext">Virtual<br>Total</span></td>
	</tr>

	</cfoutput>
	
	<!--- if no records --->
	<cfif totalprods IS 0>
		<cfoutput>
		<tr class="content2">
		<td colspan="8" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
		</cfoutput>
	</cfif>

	<cfif totalprods NEQ 0>
		<!--- display found records --->
		<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
			<!--- find product's options --->
			<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
				SELECT pmoc.category_name AS category_name, pmo.option_name AS option_name
				FROM #application.database#.product_meta_option_category pmoc, #application.database#.product_meta_option pmo, #application.database#.product_option po
				WHERE pmo.ID = po.product_meta_option_ID AND po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#product_ID#" maxlength="10"> AND pmoc.ID = pmo.product_meta_option_category_ID
				ORDER BY pmoc.sortorder
			</cfquery>
			<!--- is the product active? --->
			<cfquery name="FindIfIsActive" datasource="#application.DS#">
				SELECT IF(is_active = 1, "true", "false" ) as is_active
				FROM #application.database#.product 
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#product_ID#" maxlength="10">
			</cfquery>
			<cfset is_active = FindIfIsActive.is_active>
			<tr class="#Iif(is_active,de(Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))), de('inactivebg'))#">
			<td align="right"><cfif FLGen_HasAdminAccess(1000000032)><a href="#CurrentPage#?pgfn=edit&product_ID=#product_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&OnPage=#OnPage#">+/-</a><cfelse><a href="#CurrentPage#?pgfn=edit&product_ID=#product_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&OnPage=#OnPage#">adj. history</a></cfif></td>
			<td valign="top">#HTMLEditFormat(sku)#</td>
			<td valign="top">#meta_name#
				<cfif FindProductOptionInfo.RecordCount NEQ 0><br>
					<cfloop query="FindProductOptionInfo">
				<span class="sub">[#category_name#: <span class="reg">#option_name#</span>]</span>&nbsp;
					</cfloop>
				</cfif>
			</td>
			<td valign="top">#HTMLEditFormat(productvalue)#</td>
			<cfset PhysicalInvCalc(product_ID)><!--- Breaks encapsulation --->
			<td valign="top" align="right"><b>#PIC_total_physical#</b></td>
			<td valign="top" align="right"><span class="sub">+ #PIC_total_ponotrec#</span></td>
			<td valign="top" align="right"><span class="sub">- #PIC_total_ordnotshipd#</span></td>
			<td valign="top" align="right"><b>#PIC_total_virtual#</b></td>
			</tr>
		</cfoutput>
	</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle">Adjust Inventory</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&OnPage=#OnPage#">Inventory List</a> without making changes.</span>
	<br /><br />
	<!--- find product name --->
	<cfquery name="FindProductInfo" datasource="#application.DS#">
		SELECT m.meta_name
		FROM #application.database#.product_meta m JOIN #application.database#.product p ON p.product_meta_ID = m.ID
		WHERE p.ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#product_ID#" maxlength="10">
	</cfquery>
	<!--- find product's options --->
	<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
		SELECT pmoc.category_name AS category_name, pmo.option_name AS option_name
		FROM #application.database#.product_meta_option_category pmoc, #application.database#.product_meta_option pmo, #application.database#.product_option po
		WHERE pmo.ID = po.product_meta_option_ID AND po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#product_ID#" maxlength="10"> AND pmoc.ID = pmo.product_meta_option_category_ID
		ORDER BY pmoc.sortorder
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="content">
	<td colspan="2" class="headertext">Product: <span class="selecteditem">#FindProductInfo.meta_name# #FindProductOptions(product_ID)#</span></td>
	</tr>
	<cfif FindProductOptionInfo.RecordCount NEQ 0><br>
		<tr class="content">
		<td colspan="2">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			&nbsp;&nbsp;&nbsp;
			<cfloop query="FindProductOptionInfo">
				<span class="sub">[#category_name#: <span class="reg">#option_name#</span>]</span>&nbsp;
			</cfloop>
		</td>
		</tr>
	</cfif>
	<cfif FLGen_HasAdminAccess(1000000032)>
	<form method="post" action="#CurrentPage#">
		<tr class="contenthead">
		<td colspan="2" class="headertext">Inventory Adjustment</td>
		</tr>
	
		<tr class="content">
		<td align="right" valign="top">
			<select name="addsub" size="2">
				<option value="add" selected>add (+)</option>
				<option value="sub">sub (-)</option>
			</select>
		</td>
		<td><input type="text" name="quantity" maxlength="8" size="9">
		<input type="hidden" name="quantity_required" value="Please enter a quantity to add or subtract."></td>
		</tr>
		
		<tr class="content">
		<td colspan="2" align="center"><b>required</b> note:<br>
		<span class="sub">(why are you adjusting the inventory?)</span><br>
		<textarea name="note" cols="40" rows="3"></textarea>
		<input type="hidden" name="note_required" value="Please enter a note that explains why you are adjusting the inventory."></td>
		</tr>
	
		<tr class="content">
		<td colspan="2" align="center">
		
		<input type="hidden" name="xS" value="#xS#">
		<input type="hidden" name="xL" value="#xL#">
		<input type="hidden" name="xT" value="#xT#">
		<input type="hidden" name="xW" value="#xW#">
		<input type="hidden" name="OnPage" value="#OnPage#">
		
		<input type="hidden" name="product_ID" value="#product_ID#">
				
		<input type="submit" name="submit" value="   Save Inventory Adjustment   " >
		
		</td>
		</tr>
	</form>
	</cfif>		
	</table>
	
	<!--- display the inventory adjustment history --->
	
	<cfquery name="GetInvHistory" datasource="#application.DS#">
	
  		<!--- manual adjustments --->
		SELECT inv.created_datetime, inv.quantity, inv.note, (SELECT CONCAT(ua.firstname,' ',ua.lastname) FROM #application.database#.admin_users ua WHERE ua.ID = inv.created_user_ID) AS persons_name, 'Manual Adjustment' AS ref_activity, '' AS ref_happen, 'man' AS activity, ID AS inv_ID
		FROM #application.database#.inventory inv
		WHERE inv.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
			AND inv.is_valid = 1 
			AND inv.quantity <> 0 
			AND inv.snap_is_dropshipped = 0 
			AND inv.order_ID = 0
			AND ship_date IS NULL
			AND inv.po_ID = 0 
			AND inv.po_rec_date IS NULL
			
		 UNION

		<!--- orders --->
		SELECT inv.created_datetime, inv.quantity, inv.note, (SELECT CONCAT(up.fname,' ',up.lname) FROM #application.database#.program_user up WHERE up.ID = inv.created_user_ID) AS persons_name, (SELECT CONCAT('Order ## ',CAST(oi.order_number AS CHAR),' from ',pg.company_name,' [',pg.program_name,']') FROM #application.database#.order_info oi JOIN #application.database#.program pg ON oi.program_ID = pg.ID WHERE oi.ID = inv.order_ID <cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0> AND oi.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" /></cfif>) AS ref_activity, IF(inv.ship_date IS NULL,'not shipped yet',CONCAT('shipped on ',CAST(Date_Format(inv.ship_date,'%c/%d/%Y') AS CHAR))) AS ref_happen, 'ord' AS activity, ID AS inv_ID
		FROM #application.database#.inventory inv
		WHERE inv.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
			AND inv.is_valid = 1 
			AND inv.quantity <> 0 
			AND inv.snap_is_dropshipped = 0 
			AND inv.order_ID <> 0
			AND inv.po_ID = 0 
			AND inv.po_rec_date IS NULL
			
		 UNION

		<!--- po s RECEIVED--->
		SELECT inv.created_datetime, inv.quantity, inv.note, (SELECT CONCAT(ua.firstname,' ',ua.lastname) FROM #application.database#.admin_users ua WHERE ua.ID = inv.created_user_ID) AS persons_name, CONCAT('PO ## ',CAST(inv.po_ID AS CHAR)) AS ref_activity, IF(inv.po_rec_date IS NULL,'not received yet',CONCAT('received on ',CAST(Date_Format(inv.po_rec_date,'%c/%d/%Y') AS CHAR))) AS ref_happen, 'pos' AS activity, ID AS inv_ID
		FROM #application.database#.inventory inv
		WHERE inv.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
			AND inv.is_valid = 1 
			AND inv.quantity <> 0 
			AND inv.snap_is_dropshipped = 0 
			AND inv.order_ID = 0
			AND ship_date IS NULL
			AND inv.po_ID <> 0 
			AND inv.po_rec_date IS NOT NULL
			
		 UNION

		<!--- po s *NOT* RECEIVED--->
		SELECT inv.created_datetime, inv.po_quantity, inv.note, (SELECT CONCAT(ua.firstname,' ',ua.lastname) FROM #application.database#.admin_users ua WHERE ua.ID = inv.created_user_ID) AS persons_name, CONCAT('PO ## ',CAST(inv.po_ID AS CHAR)) AS ref_activity, IF(inv.po_rec_date IS NULL,'not received yet',CONCAT('received on ',CAST(Date_Format(inv.po_rec_date,'%c/%d/%Y') AS CHAR))) AS ref_happen, 'pos' AS activity, ID AS inv_ID
		FROM #application.database#.inventory inv
		WHERE inv.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
			AND inv.is_valid = 1 
			AND inv.quantity = 0 
			AND inv.snap_is_dropshipped = 0 
			AND inv.order_ID = 0
			AND ship_date IS NULL
			AND inv.po_ID <> 0 
			AND inv.po_rec_date IS NULL
			
		ORDER BY created_datetime
		
	</cfquery>

	<cfif FLGen_HasAdminAccess(1000000032)><br></cfif>
	
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<tr class="contenthead">
	<td class="headertext">Date</td>
	<td class="headertext">Quantity</td>
	<cfif FLGen_HasAdminAccess(1000000049)>
	<td class="headertext" align="center"><span class="tooltip" title="Click the X to remove that line item.">?</span></td>
	</cfif>
	<td class="headertext">Activity</td>
	<td class="headertext">note</td>
	</tr>
	
	<cfloop query="GetInvHistory">
	<tr class="content">
	<td>#FLGen_DateTimeToDisplay(created_datetime)#</td>
	<td align="right"><cfif activity EQ 'ord'>-<cfelseif activity EQ 'pos'>+<cfelseif activity EQ 'man' AND quantity GT 0>+</cfif>#quantity#</td>
	<cfif FLGen_HasAdminAccess(1000000049)>
	<td class="headertext" align="center"><cfif ref_activity EQ 'Manual Adjustment'><a href="#CurrentPage#?delete=#inv_ID#&product_ID=#product_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&OnPage=#OnPage#" onclick="return confirm('Are you sure you want to delete this line item?  There is NO UNDO.')">X</a><cfelse>&nbsp;</cfif></td>
	</cfif>
	<td>#ref_activity# <cfif persons_name NEQ "">by #persons_name# </cfif><cfif ref_happen NEQ "">(#ref_happen#)</cfif></td>
	<td><cfif note NEQ ''>note: #note#</cfif></td>
	</tr>
	</cfloop>
	<cfset PhysicalInvCalc(product_ID)>
	<tr class="content2">
	<td align="right" class="headertext" colspan="2">#PIC_total_virtual#</td>
	<cfif FLGen_HasAdminAccess(1000000049)>
	<td class="headertext" align="center">&nbsp;</td>
	</cfif>
	<td class="headertext" colspan="2">Virtual Inventory Total</td>
	</tr>
		
	<tr class="content2">
	<td align="right" colspan="2">- #PIC_total_ponotrec#</td>
	<cfif FLGen_HasAdminAccess(1000000049)>
	<td class="headertext" align="center">&nbsp;</td>
	</cfif>
	<td colspan="2">POs not received</td>
	</tr>
		
	<tr class="content2">
	<td align="right" colspan="2">+ #PIC_total_ordnotshipd#</td>
	<cfif FLGen_HasAdminAccess(1000000049)>
	<td class="headertext" align="center">&nbsp;</td>
	</cfif>
	<td colspan="2">Unshipped Order Total</td>
	</tr>
		
	<tr class="content2">
	<td align="right" class="headertext" colspan="2">#PIC_total_physical#</td>
	<cfif FLGen_HasAdminAccess(1000000049)>
	<td class="headertext" align="center">&nbsp;</td>
	</cfif>
	<td class="headertext" colspan="2">Physical Inventory Total</td>
	</tr>
		
	</table>
	</cfoutput>
	<!--- END pgfn ADD/EDIT --->
</cfif>


<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->