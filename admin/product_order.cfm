<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000009,true)>

<cfparam name="MetaArray" type="array" default="#ArrayNew(1)#">
<cfparam name="meta_ID" default="">
<cfparam name="set_ID" default="">
<cfparam name="pv" default="">
<cfparam name="err" default="">
<cfparam name="oap" default="">
<cfparam name="order_all" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="xW" default="">
<cfparam name="xA" default="">
<cfparam name="OnPage" default="1">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif CGI.REQUEST_METHOD EQ "post" AND IsDefined('form.itemstosort') AND form.itemstosort NEQ "">
	<cfloop index="i" from="1" to="#ListLen(form.itemstosort)#">
		<cfquery name="UpdateQueryorderall" datasource="#application.DS#">
			UPDATE #application.database#.product_meta
			SET	sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#i#" maxlength="5">
				#FLGen_UpdateModConcatSQL()#
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(form.itemstosort,i)#" maxlength="10">
		</cfquery>
	</cfloop>
</cfif>

<!--- cfif IsDefined('form.pv') AND #form.pv# IS NOT "" AND IsDefined('form.xml_MetaArray') AND #form.xml_MetaArray# IS NOT "">

	<cfif order_all EQ "order_all">

		<!--- retrieve array --->
		<cfwddx input="#form.xml_MetaArray#" action="WDDX2CFML" output="PassedMetaArray">

		<!--- loop through array and update sortorder field, unless it's already zero, unless it's the MOVED one --->
		<cfoutput>
			<cfloop index="ThisOne" from="1" to="#ArrayLen(PassedMetaArray)#">
					<cfquery name="UpdateQueryorderall" datasource="#application.DS#">
						UPDATE #application.database#.product_meta
						SET	sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#ThisOne#" maxlength="5">
							#FLGen_UpdateModConcatSQL()#
							WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#PassedMetaArray[ThisOne]#" maxlength="10">
					</cfquery>
			</cfloop>
		</cfoutput>
	
		<cfset alert_msg = Application.DefaultSaveMessage>

	<cfelse>
		<!--- find the MOVED meta_product  --->
		<cfloop list="#Form.FieldNames#" index="ThisField">
			<cfif #ThisField# contains "move" AND Evaluate(ThisField) NEQ "">
				<!--- parse out the meta_ID and get the value/new index --->
				<cfset MovedMetaID = ListGetAt(ThisField,3,"_")>
				<cfset MovedNewIndex = Evaluate(ThisField)>
				<cfset MovedOldIndex = ListGetAt(ThisField,2,"_")>
			</cfif>
		</cfloop>
		
		<!--- retrieve array --->
		<cfwddx input="#form.xml_MetaArray#" action="WDDX2CFML" output="PassedMetaArray">
		
		<!--- delete meta_ID at old index (if inserted before old index, delete at index+1 --->
		<cfset ArrayDeleteAt(PassedMetaArray,MovedOldIndex)>	
		
		<!--- insert meta_ID into array at new index --->
		<cfif MovedNewIndex gt ArrayLen(PassedMetaArray)>
			<cfset ArrayAppend(PassedMetaArray,MovedMetaID)>
		<cfelse>
			<cfset ArrayInsertAt(PassedMetaArray,MovedNewIndex,MovedMetaID)>
		</cfif>
		
		<!--- loop through array and update sortorder field, unless it's already zero, unless it's the MOVED one --->
		<cfoutput>
			<cfloop index="ThisOne" from="1" to="#ArrayLen(PassedMetaArray)#">
				<cfif PassedMetaArray[ThisOne] NEQ MovedMetaID>
					<cfquery name="UpdateQuery1" datasource="#application.DS#">
						UPDATE #application.database#.product_meta
						SET	sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#ThisOne#" maxlength="5">
							#FLGen_UpdateModConcatSQL()#
							WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#PassedMetaArray[ThisOne]#" maxlength="10"> AND sortorder <> 0
					</cfquery>
				<cfelse>
					<cfquery name="UpdateQuery2" datasource="#application.DS#">
						UPDATE #application.database#.product_meta
						SET	sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#ThisOne#" maxlength="5">
							#FLGen_UpdateModConcatSQL()#
							WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#PassedMetaArray[ThisOne]#" maxlength="10">
					</cfquery>
				</cfif>
			</cfloop>
		</cfoutput>
	
		<cfset alert_msg = Application.DefaultSaveMessage>
	
	</cfif>

</cfif>

<cfif IsDefined('oap') AND oap EQ "yes">

		<cfquery name="SelectListProdToSort4" datasource="#application.DS#">
			SELECT ID AS change_meta_ID 
			FROM #application.database#.product_meta
			WHERE productvalue_master_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pv#" maxlength="10">
			ORDER BY sortorder ASC
		</cfquery>
		
		<cfset mod_note = "(*auto* changed meta sort order within category)">
		<cfset this_counter = 0>
		<cfloop query="SelectListProdToSort4">
			<cfset this_counter = IncrementValue(this_counter)>
				<cfquery name="UpdateQuery2" datasource="#application.DS#">
					UPDATE #application.database#.product_meta
					SET	sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_counter#" maxlength="5">
						#FLGen_UpdateModConcatSQL(mod_note)#
						WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#change_meta_ID#" maxlength="10">
				</cfquery>
		</cfloop>


</cfif --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "productsortorder">
<cfinclude template="includes/header.cfm">

<script language="JavaScript">
function Submit() {
	f = document.forms["sortForm"]
	if (document.all) { // IE only
		SelectCode = document.getElementById("SelectSpan").innerHTML.replace(/^<select/i,"<select multiple ")
		document.getElementById("SelectSpan").innerHTML = SelectCode
	} else {
		f.ItemsToSort.multiple = true
	}
	for (i=0; i<f.ItemsToSort.options.length; i++) {
		f.ItemsToSort.options[i].selected = true
	}
	f.submit()
}

function MoveItem(Direction) {
	FormInfo = document.forms["sortForm"].ItemsToSort
	if (FormInfo.selectedIndex == -1) {
		alert("Select an item.  Then use the arrows to change the display order.")
		return false
	}
	// Move Selection Up
	if (Direction == "up" && FormInfo.selectedIndex != 0) {
		i = FormInfo.selectedIndex - 1
		SavedValue = FormInfo.options[i].value
		SavedText = FormInfo.options[i].text
		FormInfo.options[i].value = FormInfo.options[FormInfo.selectedIndex].value
		FormInfo.options[i].text = FormInfo.options[FormInfo.selectedIndex].text
		FormInfo.options[FormInfo.selectedIndex].value = SavedValue
		FormInfo.options[FormInfo.selectedIndex].text = SavedText
		FormInfo.selectedIndex = i
	}
	// Move Selection Down
	if (Direction == "down" && FormInfo.selectedIndex != FormInfo.options.length - 1) {
		i = FormInfo.selectedIndex + 1
		SavedValue = FormInfo.options[i].value
		SavedText = FormInfo.options[i].text
		FormInfo.options[i].value = FormInfo.options[FormInfo.selectedIndex].value
		FormInfo.options[i].text = FormInfo.options[FormInfo.selectedIndex].text
		FormInfo.options[FormInfo.selectedIndex].value = SavedValue
		FormInfo.options[FormInfo.selectedIndex].text = SavedText
		FormInfo.selectedIndex = i
	}
	// Move Selection To Bottom
	if (Direction == "bottom" && FormInfo.selectedIndex != FormInfo.options.length - 1) {
		FormInfo.options[FormInfo.options.length] = new Option(FormInfo.options[FormInfo.selectedIndex].text ,FormInfo.options[FormInfo.selectedIndex].value )
		FormInfo.options[FormInfo.selectedIndex] = null
		FormInfo.selectedIndex = FormInfo.options.length - 1
	}
	// Move Selection To Top
	if (Direction == "top" && FormInfo.selectedIndex != 0) {
		for (i=FormInfo.selectedIndex; i>-1; i--) {
			MoveItem('up')
		}
	}
}
</script>


<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<cfif pv NEQ "">
	<cfquery name="SelectListProdToSort4" datasource="#application.DS#">
		SELECT pm.ID AS list_meta_ID, pm.meta_name AS list_meta_name, pm.sortorder, pm.meta_sku 
		FROM #application.database#.product_meta pm 
		WHERE pm.productvalue_master_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pv#"> 
		AND pm.product_set_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#set_ID#"> 
		AND 
		IF(
		(SELECT COUNT(ID) FROM #application.database#.product WHERE product_meta_ID = pm.ID) = 0,
		true
		,
		IF(
		(SELECT COUNT(ID) FROM #application.database#.product WHERE product_meta_ID = pm.ID AND is_active = 0)
		=
		(SELECT COUNT(ID) FROM #application.database#.product WHERE product_meta_ID = pm.ID),false,true)
		)
		ORDER BY sortorder ASC	
	</cfquery>

	<cfquery name="SelectCatName" datasource="#application.DS#">
		SELECT productvalue
		FROM #application.database#.productvalue_master
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pv#" maxlength="10">
	</cfquery>

	<!--- If there aren't any prods in this cat,  set pv var to "" --->
	<cfif SelectListProdToSort4.RecordCount EQ 0>
		<cfset pv = "">
		<cfset err = "none">
	</cfif>
	
</cfif>

<cfif meta_ID NEQ "">
	<cfquery name="SelectMetaName" datasource="#application.DS#">
		SELECT meta_name, meta_sku
		FROM #application.database#.product_meta
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
	</cfquery>
	<cfset meta_name = SelectMetaName.meta_name>
</cfif>
<cfoutput>
<span class="pagetitle">Set Sort Order for Products within a Master Category</span>
<br /><br />
<cfif meta_ID NEQ "">
	<span class="pageinstructions">Return to <a href="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Product Detail for #meta_name#</a>
	<br /><br />
</cfif>
<cfif err EQ "none">
	<span class="alert">There are no products Master Category #HTMLEditFormat(SelectCatName.productvalue)#. Please select another category.</span>
	<br /><br />
</cfif>
</cfoutput>

<cfif pv NEQ "">

	<!--- populate MetaArray with data --->
	<cfloop query="SelectListProdToSort4">
		<cfset MetaArray[CurrentRow] = list_meta_ID>
	</cfloop>
	
	<cfquery name="SelectCatName" datasource="#application.DS#">
		SELECT productvalue
		FROM #application.database#.productvalue_master
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pv#" maxlength="10">
	</cfquery>

	<cfoutput>
	<span class="pageinstructions">This sort order is used to display products within Master Category #HTMLEditFormat(SelectCatName.productvalue)# on the</span>
	<br>
	<span class="pageinstructions">Admin Product List and in the Awards Programs catalog pages.</span>
	<br /><br />
	<span class="pageinstructions">Pick a different <a href="product_order.cfm?xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&OnPage=#OnPage#&meta_ID=#meta_ID#&set_ID=#set_ID#">Master Category</a> to sort.</span>
	<br /><br />
	<form name="sortForm" method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		
	<tr class="contenthead">
	<td colspan="2"><span class="headertext">Master Category #HTMLEditFormat(SelectCatName.productvalue)#</span> <button name="order_all" onClick="Submit()" style="margin-left:250px">Save Sort Order</button><!--- <button name="order_all" value="order_all" onClick="window.location='#CurrentPage#?xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&OnPage=#OnPage#&meta_ID=#meta_ID#&oap=yes&pv=#pv#'" style="margin-left:210px">Set Order For All Products</button> ---></td>
	</tr>

	<tr class="content">
		<td valign="top" rowspan="2">
		<span id="SelectSpan">
		<select name="ItemsToSort" ID="ItemsToSort" size="20" style="width:530px">
			<cfloop query="SelectListProdToSort4">
				<option value="#list_meta_ID#">[#CurrentRow#] <cfif sortorder EQ 0>NO SORT &raquo; </cfif>#list_meta_name#</option>
			</cfloop>
		</select>
		</span>
		</td>
		<td valign="top">
			<a href="##" onClick="MoveItem('top');this.blur();return false" title="Move To Top"><img src="pics/MoveTop.gif" border="0" width="20" height="15"></a><br><br><br>
			<a href="##" onClick="MoveItem('up');this.blur();return false" title="Move Up"><img src="pics/MoveUp.gif" border="0" width="20" height="13"></a>
		</td>
	</tr>
	
	<tr class="content">
		<td valign="bottom">
			<a href="##" onClick="MoveItem('down');this.blur();return false" title="Move Down"><img src="pics/MoveDown.gif" border="0" width="20" height="13"></a><br><br><br>
			<a href="##" onClick="MoveItem('bottom');this.blur();return false" title="Move To Bottom"><img src="pics/MoveBottom.gif" border="0" width="20" height="15"></a>
			<input type="hidden" name="xS" value="#xS#">
			<input type="hidden" name="xL" value="#xL#">
			<input type="hidden" name="xT" value="#xT#">
			<input type="hidden" name="xW" value="#xW#">
			<input type="hidden" name="OnPage" value="#OnPage#">
			<input type="hidden" name="meta_ID" value="#meta_ID#">
			<input type="hidden" name="set_ID" value="#set_ID#">
			<input type="hidden" name="pv" value="#pv#">
		</td>
	</tr>
	</table>
	</form>
	</cfoutput>

	<!--- **************************************************************** --->
	<!--- if pv doesn't equal anything and we need to make them choose one --->
	<!--- **************************************************************** --->

<cfelse>

	<cfquery name="SelectAllCatName" datasource="#application.DS#">
		SELECT ID AS pv_ID, productvalue
		FROM #application.database#.productvalue_master
		ORDER BY sortorder
	</cfquery>

	<cfoutput>
	<form method="post" action="#CurrentPage#">

		<select name="pv" onChange="submit()">
			<option value="">-- Set the sort order for Master Category --</option>
			<cfloop query="SelectAllCatName">
				<cfoutput>
					<option value="#SelectAllCatName.pv_ID#">#SelectAllCatName.productvalue#</option>
				</cfoutput>
			</cfloop>
		</select>
		
	<input type="hidden" name="xS" value="#xS#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="xW" value="#xW#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	<input type="hidden" name="meta_ID" value="#meta_ID#">
	<input type="hidden" name="set_ID" value="#set_ID#">
	</form>
	</cfoutput>

</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->