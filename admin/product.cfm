<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000008,true)>

<cfparam name="where_string" default="">
<cfparam name="meta_ID" default="">
<cfparam name="delete_meta" default="">
<cfparam name="delete_indv" default="">
<cfparam name="delete_option" default="">
<cfparam name="delete_cat" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="name">
<cfparam name="xL" default="">
<cfparam name="xT" default="">
<cfparam name="xW" default="">
<cfparam name="xA" default="false">
<cfif NOT isBoolean(xA)>
	<cfset xA = false>
</cfif>
<cfparam name="OnPage" default="1">
<cfparam name="orderbyvar" default="">
<cfparam name="translate" default="">
<cfparam name="searchboxtext" default="">
<cfparam name="group_count" default="">

<!--- param display fields --->
<cfparam name="value" default="">
<cfparam name="productvalue_master_ID" default="">
<cfparam name="meta_name" default="">
<cfparam name="meta_sku" default="">
<cfparam name="description" default="">
<cfparam name="imagename_original" default="">
<cfparam name="thumbnailname_original" default="">
<cfparam name="sortorder" default="">
<cfparam name="manuf_name" default="">
<cfparam name="logoname" default="">
<cfparam name="de" default="">
<cfparam name="dis" default="">
<cfparam name="pgfn" default="list">
<cfparam name="weight" default="">

<!--- Set up Product Sets --->
<cfparam name="set_ID" default="">
<cfif isNumeric(set_ID) AND set_ID GT 0>
	<cfquery name="ProductSet" datasource="#application.DS#">
		SELECT ID, set_name, tab_label, note, sortorder
		FROM #application.database#.product_set
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#set_ID#" maxlength="10">
	</cfquery>
	<cfif ProductSet.recordcount NEQ 1>
		<cfset set_ID = 0>
	</cfif>
</cfif>

<cfset has_set = isNumeric(set_ID) AND set_ID GT 0>

<cfif isDefined("form.update_weight") AND isNumeric(weight) AND weight lt 1000>
	<cfquery name="UpdateIndividualWeights" datasource="#application.DS#">
		UPDATE #application.database#.product
		SET weight = <cfqueryparam cfsqltype="cf_sql_float" value="#weight#">
		WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
	</cfquery>
	<cfset alert_msg = "Weights updated">
</cfif>

<cfif isDefined("form.submit")>
	<cfparam name="form.ID" default="">
	<cfparam name="form.set_name" default="">
	<cfparam name="form.tab_label" default="">
	<cfparam name="form.note" default="">
	<cfparam name="form.sortorder" default="">
	<cfif pgfn EQ "add_set">
		<cflock name="product_setLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertProductSetQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.product_set
						(set_name, tab_label, sortorder, note, created_user_ID, created_datetime)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.set_name#" maxlength="60">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.tab_label#" maxlength="64">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#sortorder#" maxlength="10">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.note#" null = "#YesNoFormat(NOT Len(Trim(form.note)))#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						#FLGen_DateTimeToMySQL()#)
				</cfquery>
				<cfquery datasource="#application.DS#" name="getID">
					SELECT Max(ID) As MaxID FROM #application.database#.product_set
				</cfquery>
				<cfset form.ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	<cfelseif pgfn EQ "edit_set">
		<cfquery name="UpdateProductSetQuery" datasource="#application.DS#">
			UPDATE #application.database#.product_set
			SET	set_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.set_name#" maxlength="60">,
				tab_label = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.tab_label#" maxlength="64">,
				note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.note#" null = "#YesNoFormat(NOT Len(Trim(form.note)))#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.ID#" maxlength="10">
		</cfquery>
	</cfif>
	<!--- delete all exclude entries for this program --->
	<cfquery name="DeleteExProds" datasource="#application.DS#">
		DELETE FROM #application.database#.xref_product_set_group
		WHERE product_set_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.ID#" maxlength="10">
	</cfquery>
	
	<!--- loop through ExcludeThis and Insert into xref_program_product_set --->
	<cfif IsDefined('form.groups') AND form.groups IS NOT "">
		<cfloop list="#form.groups#" index="ThisProductGroup">
			<cfquery name="InsertQuery" datasource="#application.DS#">
				INSERT INTO #application.database#.xref_product_set_group
				(created_user_ID, created_datetime, product_set_ID, product_meta_group_ID)
				VALUES
				(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
				'#FLGen_DateTimeToMySQL()#', 
				<cfqueryparam cfsqltype="cf_sql_integer" value="#form.ID#" maxlength="10">, 
				<cfqueryparam cfsqltype="cf_sql_integer" value="#ThisProductGroup#" maxlength="10">)
			</cfquery>

		</cfloop>
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfif pgfn neq "edit_set">
		<cfset pgfn = "list">
		<cfset set_ID = 0>
	</cfif>
</cfif>

<cfif has_set AND set_ID GT 1>

<cfif pgfn EQ 'removevendor'>
	<cfquery name="RemoveVendor" datasource="#application.DS#">
		DELETE FROM #application.database#.vendor_lookup 
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#vl_ID#" maxlength="10">
			AND product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10">
	</cfquery>
	<cfset pgfn = "edit">
	<cfset alert_msg = "The vendor has been removed from the individual product.">
</cfif>

<!--- To DELETE:  1) individual product       2) options       3) meta product
		you will not be able to delete the individual prods if there are inventory entries for them. --->

<cfif delete_indv NEQ '' AND FLGen_HasAdminAccess(1000000054)>
	<cfquery name="DeleteIndvProd" datasource="#application.DS#">
		DELETE FROM #application.database#.product 
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_indv#" maxlength="10">
	</cfquery>
	<cfquery name="DeleteIndvProdVendorlink" datasource="#application.DS#">
		DELETE FROM #application.database#.vendor_lookup 
		WHERE product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_indv#" maxlength="10">
	</cfquery>
	<cfquery name="DeleteIndvProdOptionLink" datasource="#application.DS#">
		DELETE FROM #application.database#.product_option 
		WHERE product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_indv#" maxlength="10">
	</cfquery>
	<cfquery name="DeleteIndvProdExcludes" datasource="#application.DS#">
		DELETE FROM #application.database#.program_product_exclude  
		WHERE product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_indv#" maxlength="10">
	</cfquery>
</cfif>

<cfif delete_cat NEQ '' AND FLGen_HasAdminAccess(1000000054)>
	<cfquery name="DeleteCategory" datasource="#application.DS#">
		DELETE FROM #application.database#.product_meta_option_category 
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_cat#" maxlength="10">
	</cfquery>
	<cfquery name="DeleteCategoryOptions" datasource="#application.DS#">
		DELETE FROM #application.database#.product_meta_option 
		WHERE product_meta_option_category_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_cat#" maxlength="10">
	</cfquery>
</cfif>

<cfif delete_option NEQ '' AND FLGen_HasAdminAccess(1000000054)>
	<cfquery name="DeleteOption" datasource="#application.DS#">
		DELETE FROM #application.database#.product_meta_option 
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_option#" maxlength="10">
	</cfquery>
</cfif>

<cfif delete_meta NEQ '' AND FLGen_HasAdminAccess(1000000054)>
	<cfquery name="DeleteMetaProd" datasource="#application.DS#">
		DELETE FROM #application.database#.product_meta 
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_meta#" maxlength="10">
	</cfquery>
	<cfquery name="DeleteMetaProdGroupLookup" datasource="#application.DS#">
		DELETE FROM #application.database#.product_meta_group_lookup 
		WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete_meta#" maxlength="10">
	</cfquery>
	<cflocation url="#CurrentPage#?&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#" addtoken="no">
</cfif>

</cfif>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "products">
<cfif pgfn EQ "list">
	<cfset request.main_width = 900>
</cfif>
<cfinclude template="includes/header.cfm">

<SCRIPT LANGUAGE="JavaScript"><!-- 
	function openURL() { 
		// grab index number of the selected option
		selInd = document.pageform2.pageselect.selectedIndex; 
		// get value of the selected option
		goURL = document.pageform2.pageselect.options[selInd].value;
		// redirect browser to the grabbed value (hopefully a URL)
		top.location.href = goURL; 
	}

	function openURLAgain() { 
		// grab index number of the selected option
		selInd = document.pageform2.pageselect.selectedIndex; 
		// get value of the selected option
		goURL = document.pageform2.pageselect.options[selInd].value;
		// redirect browser to the grabbed value (hopefully a URL)
		top.location.href = goURL; 
	}

//--> </SCRIPT>

<cfif has_set>
	<span class="pageinstructions">Product Set: <strong><cfoutput>#ProductSet.set_name#</cfoutput></strong></span>
</cfif>
<cfif has_set OR pgfn EQ "add_set">
	&nbsp;&nbsp;&nbsp;&nbsp;
	<a href="<cfoutput>#CurrentPage#</cfoutput>">Return to Set List</a>
</cfif>
<br><br>

<cfif NOT has_set>
	<cfquery name="GetSets" datasource="#application.DS#">
		SELECT ID, set_name, tab_label, note
		FROM #application.database#.product_set
		ORDER BY sortorder
	</cfquery>
</cfif>

<cfif pgfn EQ "add_set" OR pgfn EQ "edit_set">
	<cfquery name="GetGroups" datasource="#application.DS#">
		SELECT ID, name
		FROM #application.database#.product_meta_group
		ORDER BY sortorder
	</cfquery>
	<cfif pgfn EQ "edit_set">
		<cfparam name="form.ID" default="#ProductSet.ID#">
		<cfparam name="form.set_name" default="#ProductSet.set_name#">
		<cfparam name="form.tab_label" default="#ProductSet.tab_label#">
		<cfparam name="form.note" default="#ProductSet.note#">
		<cfparam name="form.sortorder" default="#ProductSet.sortorder#">
		<cfquery name="SelectedProductGroups" datasource="#application.DS#">
			SELECT product_meta_group_ID
			FROM #application.database#.xref_product_set_group
			WHERE product_set_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ProductSet.ID#" maxlength="10">
		</cfquery>
		<cfset SelectedIDs = ValueList(SelectedProductGroups.product_meta_group_ID)>
	<cfelseif pgfn EQ "add_set">
		<cfparam name="form.ID" default="0">
		<cfparam name="form.set_name" default="">
		<cfparam name="form.tab_label" default="">
		<cfparam name="form.note" default="">
		<cfparam name="form.sortorder" default="#GetSets.recordcount+1#">
		<cfset SelectedIDs = "">
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0">
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add_set">Add<cfelse>Edit</cfif> a Product Set</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Product Set Name: </td>
	<td valign="top"><input type="text" name="set_name" value="#form.set_name#" maxlength="60" size="50"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Label for Tab (if using tabs): </td>
	<td valign="top"><input type="text" name="tab_label" value="#form.tab_label#" maxlength="64" size="50"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Description: </td>
	<td valign="top"><textarea name="note" cols="58" rows="3">#form.note#</textarea></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Product Categories:</td>
		<td>
		<cfloop query="GetGroups">
			<input type="checkbox" name="groups" value="#GetGroups.ID#" <cfif ListFind(SelectedIDs,GetGroups.ID)>checked</cfif>>&nbsp;&nbsp;&nbsp;#GetGroups.name#<br />
		</cfloop>
		</td>
	</tr>

	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="ID" value="#form.ID#">
	<input type="hidden" name="set_ID" value="#set_ID#">
	<input type="hidden" name="sortorder" value="#form.sortorder#">
	<input type="hidden" name="pgfn" value="#pgfn#">
	
	<input type="submit" name="submit" value="   Save Changes   " >
	
	</td>
	</tr>
		
	</table>
	</form>
	</cfoutput>
<!--- START pgfn LIST --->
<cfelseif pgfn EQ "list">
	<cfif NOT has_set>
		<cfoutput>
		<span class="pagetitle">Product Sets</span>
		<br /><br />
		<table cellpadding="5" cellspacing="0" border="0" width="80%">
			<tr class="contenthead">
				<td width="18%" class="headertext"><a href="#CurrentPage#?pgfn=add_set">Add Set</a></td>
				<td width="36%" class="headertext">Set Name</td>
				<td width="46%" class="headertext">Description</td>
			</tr>
			<cfloop query="GetSets">
				<tr class="#Iif(((GetSets.CurrentRow MOD 2) is 1),de('content2'),de('content'))#">
					<td nowrap="nowrap"><a href="#CurrentPage#?pgfn=edit_set&set_ID=#GetSets.ID#">Edit</a>&nbsp;&nbsp;<a href="#CurrentPage#?set_ID=#GetSets.ID#">Products</a></td>
					<td>#GetSets.set_name#</td>
					<td>#GetSets.note#</td>
				</tr>
			</cfloop>
			<tr class="contenthead" height="5px;"><td colspan="100%"></td></tr>
		</table>
		</cfoutput>
	<cfelse>
		<!--- set ORDER BY --->
		<cfswitch expression="#xS#">
			<cfcase value="name">
				<cfset orderbyvar = "m.meta_name">
				<cfset orderbyclause = "m.meta_name">
				<cfset searchboxtext = "Product Name">
			</cfcase>
			<cfcase value="mcat">
				<cfset orderbyvar = "p.productvalue">
				<cfset orderbyclause = "p.productvalue, m.sortorder">
				<cfset searchboxtext = "Master Category">
			</cfcase>
			<cfcase value="sku">
				<cfset orderbyvar = "m.meta_sku">
				<cfset orderbyclause = "m.meta_sku">
				<cfset searchboxtext = "ITC SKU (meta)">
			</cfcase>
		</cfswitch>
	
		<!--- Set the WHERE clause --->
		<!--- Check if a search string passed --->
		<cfif LEN(xT) GT 0 AND (IsDefined('form.submit1') AND form.submit1 IS NOT "")>
			<cfset xW = "1">
		<cfelseif LEN(xT) GT 0 AND (IsDefined('form.submit2') AND form.submit2 IS NOT "")>
			<cfset xW = "2">
		<cfelseif LEN(xT) GT 0 AND (IsDefined('form.submit3') AND form.submit3 IS NOT "")>
			<cfset xW = "3">
		<cfelseif LEN(xT) GT 0 AND xW EQ ''>
			<cfset xW = "1">
		</cfif>
	
		<!--- run query --->
		<cfif ListFind("m.meta_name,p.productvalue,m.meta_sku",orderbyvar)>
			<cfquery name="SelectList" datasource="#application.DS#">
				SELECT 	m.ID AS meta_ID, m.meta_name, m.meta_sku, p.productvalue AS master_category_value, m.productvalue, m.sortorder AS sortorder
				FROM #application.database#.product_meta m
				LEFT JOIN #application.database#.productvalue_master p ON m.productvalue_master_ID = p.ID
				WHERE product_set_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#set_ID#" maxlength="10">
				<cfif LEN(xT) GT 0 AND ((IsDefined('form.submit1') AND form.submit1 IS NOT "") OR (xW EQ 1))>
					AND (m.meta_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> 
					OR m.meta_sku LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">)
				<cfelseif LEN(xT) GT 0 AND ((IsDefined('form.submit2') AND form.submit2 IS NOT "") OR (xW EQ 2))>
					AND (p.productvalue = <cfqueryparam cfsqltype="cf_sql_varchar" value="#xT#">)
				<cfelseif LEN(xT) GT 0 AND ((IsDefined('form.submit3') AND form.submit3 IS NOT "") OR (xW EQ 3)) AND xT contains "n">
					AND ((SELECT COUNT(*) FROM #Application.database#.product_meta_option_category pm WHERE m.ID = pm.product_meta_ID) = 0 )
				<cfelseif LEN(xT) GT 0 AND ((IsDefined('form.submit3') AND form.submit3 IS NOT "") OR (xW EQ 3)) AND xT contains "y">
					AND ((SELECT COUNT(*) FROM #Application.database#.product_meta_option_category pm WHERE m.ID = pm.product_meta_ID) > 0 )	
				</cfif>
				<cfif LEN(xL) GT 0>
					AND (#orderbyvar# LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xL#%" maxlength="3">)
				</cfif>
				ORDER BY #orderbyclause#
			</cfquery>
		</cfif>
	
		<!--- set the start/end/max display row numbers --->
		<cfset MaxRows_SelectList="50">
		<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
		<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
		<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	
		<cfoutput>
		<span class="pagetitle">Product List</span>
		<br /><br />
		<span class="pageinstructions">Products marked <span class="alert">set up &raquo; </span> are incomplete and need attention.</span>
		<br /><br />
	
		<!--- search box --->
		<table cellpadding="5" cellspacing="0" border="0" width="80%">
			<tr class="contenthead">
				<td><span class="headertext">Search Criteria</span></td>
				<td align="right"><a href="#CurrentPage#?set_ID=#set_ID#" class="headertext">view all</a></td>
			</tr>
			<tr class="contentsearch">
				<td align="center" colspan="2">
					<span class="searchcriteria">
						current search/sort &raquo;&nbsp;&nbsp;
						<!--- text--->
						<cfif xT NEQ "" AND xW EQ "1">
							[ find "#xT#" in SKU or Product Name ]&nbsp;&nbsp;
						<cfelseif xT NEQ "" AND xW EQ "2">
							[ select all products in Master Category #xT# ]&nbsp;&nbsp;
						<cfelseif xT contains "y" AND xW EQ "3">
							[ select all products with options ]&nbsp;&nbsp;
						<cfelseif xT contains "n" AND xW EQ "3">
							[ select all products without options ]&nbsp;&nbsp;
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
			<tr>
				<td class="content" colspan="2" align="center">
					<form action="#CurrentPage#" method="post">
						<select name="xA">
							<option value="false"<cfif NOT xA> selected</cfif>>List does not include discontinued products.</option>
							<option value="true"<cfif xA> selected</cfif>>List includes discontinued products</option>
						</select>
						<br><br>
						<input type="hidden" name="xL" value="#xL#">
						<input type="hidden" name="xS" value="#xS#">
						<input type="hidden" name="set_ID" value="#set_ID#">
						<input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20">
						<input type="submit" name="submit1" value="sku or name">
						<input type="submit" name="submit2" value="master category">
						<input type="submit" name="submit3" value="has options? (y/n)">
					</form>
					<br>
					<cfif LEN(xL) IS 0>
						<span class="ltrON">ALL</span>
					<cfelse>
						<a href="#CurrentPage#?xL=&xS=#xS#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#" class="ltr">ALL</a>
					</cfif>
					<span class="ltrPIPE">&nbsp;&nbsp;</span>
					<cfloop index = "LoopCount" from = "0" to = "9"><cfif xL IS LoopCount><span class="ltrON">#LoopCount#</span><cfelse><a href="#CurrentPage#?xL=#LoopCount#&xS=#xS#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#" class="ltr">#LoopCount#</a></cfif><span class="ltrPIPE">&nbsp;&nbsp;</span></cfloop>
					<cfloop index = "LoopCount" from = "1" to = "26"><cfif xL IS CHR(LoopCount + 64)><span class="ltrON">#CHR(LoopCount + 64)#</span><cfelse><a href="#CurrentPage#?xL=#CHR(LoopCount + 64)#&xS=#xS#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#" class="ltr">#CHR(LoopCount + 64)#</a></cfif><cfif LoopCount NEQ 26><span class="ltrPIPE">&nbsp;&nbsp;</span></cfif></cfloop>
				</td>
			</tr>
		</table>
		<br />
		<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0>
			<form name="pageform2">
				<table cellpadding="0" cellspacing="0" border="0" width="100%">
				<tr>
					<td><cfif OnPage GT 1><a href="#CurrentPage#?OnPage=1&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#" class="pagingcontrols">&lsaquo;</a><cfelse><span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span></cfif></td> 
					<td align="center" class="sub">[ page <select name="pageselect" onChange="openURL(document.pageform2.pageselect)"><cfloop from="1" to="#TotalPages_SelectList#" index="this_i"><option value="#CurrentPage#?OnPage=#this_i#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option></cfloop></select> of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]</td>
					<td align="right">
						<cfif OnPage LT TotalPages_SelectList><a href="#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?OnPage=#TotalPages_SelectList#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#" class="pagingcontrols">&raquo;</a><cfelse><span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span></cfif>
					</td>
				</tr>
				</table>
			</form>
		</cfif>
		</cfoutput>
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
			<!--- header row --->
			<cfoutput>
			<tr class="contenthead">
				<td align="right">
					<cfif has_set>
						<cfif set_ID GT 1><a href="#CurrentPage#?pgfn=add&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Add</a></cfif>
						<cfif set_ID EQ 1 AND FLGen_HasAdminAccess(1000000113)><a href="product_import.cfm">Import</a></cfif>
					</cfif>
				</td>
				<td class="headertext"><cfif xS IS "sku">ITC SKU (meta) <img src="../pics/contrls-asc.gif" width="7" height="6"><cfelse><a href="#CurrentPage#?xS=sku&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#">ITC SKU</a> (meta)</cfif></td>
				<td class="headertext"><cfif xS IS "name">Product Name <img src="../pics/contrls-asc.gif" width="7" height="6"><cfelse><a href="#CurrentPage#?xS=name&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#">Product Name</a></cfif></td>
				<td class="headertext">Value</td>
				<td class="headertext"><cfif xS IS "mcat">Master Category <img src="../pics/contrls-asc.gif" width="7" height="6"><cfelse><a href="#CurrentPage#?xS=mcat&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&set_ID=#set_ID#">Master Category</a></cfif></td>
				<td class="headertext">Has Options?</td>
				<td>&nbsp;</td>
			</tr>
			</cfoutput>
			<!--- display found records --->
			<cfset display_any_records = false>
			<cfset thisRow = 1>
			<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
				<cfset ThisMetaID = SelectList.meta_ID>
				<cfparam name="group_count" default="">
				<!--- check whether it's a discontinued product --->
				<cfquery name="AnyIndvProd" datasource="#application.DS#">
					SELECT ID 
					FROM #application.database#.product 
					WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#" maxlength="10"> 
				</cfquery>
				<cfif AnyIndvProd.RecordCount EQ 0>
					<cfset is_discontinued = "false">
				<cfelse>
					<cfquery name="IsDiscontinued" datasource="#application.DS#">
						SELECT ID 
						FROM #application.database#.product 
						WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#" maxlength="10"> 
							AND is_discontinued = 0
					</cfquery>
					<cfif IsDiscontinued.RecordCount EQ 0>
						<cfset is_discontinued = "true">
					<cfelse>
						<cfset is_discontinued = "false">
					</cfif>
				</cfif>
				<cfif xA OR (NOT is_discontinued AND NOT xA)>
					<cfquery name="FindIfGroupInfo" datasource="#application.DS#">
						SELECT COUNT(ID) AS group_count
						FROM #application.database#.product_meta_group_lookup
						WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#" maxlength="10">
					</cfquery>
					<!--- check whether it's an active product --->
					<cfquery name="IsActive" datasource="#application.DS#">
						SELECT ID 
						FROM #application.database#.product 
						WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#" maxlength="10"> 
							AND is_active = 1
					</cfquery>
					<cfif IsActive.RecordCount EQ 0>
						<cfset is_active = "false">
					<cfelse>
						<cfset is_active = "true">
					</cfif>
					<!--- check to see if meta has options --->
					<cfquery name="HasOptions" datasource="#application.DS#">
						SELECT ID 
						FROM #application.database#.product_meta_option_category 
						WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#" maxlength="10">
					</cfquery>
					<cfif HasOptions.RecordCount EQ 0>
						<cfset has_options = "no">
					<cfelse>
						<cfset has_options = "yes">
					</cfif>
					<!--- set prodnote --->
					<cfquery name="SetProdNote" datasource="#application.DS#">
						SELECT ID 
						FROM #application.database#.product
						WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#" maxlength="10">
					</cfquery>
					<cfif SetProdNote.RecordCount EQ 0>
						<cfset prodnote = "missing">
					<cfelseif SetProdNote.RecordCount EQ 1>
						<cfset prodnote = "single">
					<cfelseif SetProdNote.RecordCount GT 1>
						<cfset prodnote = "M&nbsp;U&nbsp;L&nbsp;T&nbsp;I">
					</cfif>
					<!--- if MULTI, are products sortorder-ed --->
					<cfset indvprodnotordered = false>
					<cfif SetProdNote.RecordCount GT 1>
						<cfquery name="FindIndvProdCount" datasource="#application.DS#">
							SELECT COUNT(ID) AS total_indv_prods
							FROM #application.database#.product
							WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#" maxlength="10">  
						</cfquery>
						<cfquery name="FindIndvProdDistinct" datasource="#application.DS#">
							SELECT DISTINCT sortorder
							FROM #application.database#.product
							WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#" maxlength="10">  
								AND sortorder <> 0
						</cfquery>
						<cfif FindIndvProdCount.total_indv_prods NEQ FindIndvProdDistinct.RecordCount>
							<cfset indvprodnotordered = true>
						</cfif>
					</cfif>
	
					<cfquery name="NoVendors" datasource="#application.DS#">
						SELECT p.ID
						FROM #application.database#.product p
						WHERE p.product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ThisMetaID#">
						AND NOT EXISTS (
							SELECT v.ID
							FROM #application.database#.vendor_lookup v
							WHERE  v.product_ID = p.id
							)
					</cfquery>
					<cfset thisRow = thisRow + 1>
					<tr class="#Iif(is_active AND NOT is_discontinued,de(Iif(((thisRow MOD 2) is 0),de('content2'),de('content'))), de('inactivebg'))#">
						<td valign="top" align="right">
							<cfif prodnote EQ "missing" OR sortorder EQ 0 OR FindIfGroupInfo.group_count EQ 0 OR indvprodnotordered OR NoVendors.recordcount GT 0>
								<span class="alert">set&nbsp;up</span><br>
							</cfif>
							<a href="#CurrentPage#?pgfn=edit&meta_id=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Edit</a>
						</td>
						<td valign="top">#HTMLEditFormat(meta_sku)#</td>
						<td valign="top"><cfif is_discontinued><b>DISCONTINUED</b><br /></cfif>#meta_name#</td>
						<td valign="top">#HTMLEditFormat(productvalue)#</td>
						<td valign="top">#HTMLEditFormat(master_category_value)#</td>
						<td valign="top"><cfif has_options EQ "yes">Y E S<cfelse>#HTMLEditFormat(has_options)#</cfif></td>
						<td valign="top"><span class="sub"><cfif prodnote NEQ "missing">#prodnote#<cfelse>&lsaquo;-- </cfif></span></td>
					</tr>
					<cfset display_any_records = true>
				</cfif>
			</cfoutput>
			<!--- if no records --->
			<cfif SelectList.RecordCount IS 0 OR NOT display_any_records>
				<tr class="content2">
					<td colspan="6" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
				</tr>
			</cfif>
			<tr>
				<td><img src="../pics/shim.gif" width="40" height="1"></td>
				<td><img src="../pics/shim.gif" width="60" height="1"></td>
				<td width="100%"><img src="../pics/shim.gif" width="20" height="1"></td>
				<td><img src="../pics/shim.gif" width="50" height="1"></td>
				<td><img src="../pics/shim.gif" width="50" height="1"></td>
				<td><img src="../pics/shim.gif" width="40" height="1"></td>
			</tr>
		</table>
		<!--- END pgfn LIST --->
	</cfif>
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<cfif NOT isNumeric(set_ID) OR set_ID LTE 0>
		<cflocation url="#CurrentPage#" addtoken="no">
	<cfelse>
		<!--- START pgfn ADD/EDIT --->
		<span class="pagetitle">Product Detail</span><br /><br />
		<span class="pageinstructions">To create a product, follow the three steps below in order.</span><br /><br />
		<span class="pageinstructions">Return to <a href="<cfoutput>#CurrentPage#?&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product List</a> without making changes.</span><br /><br />
		<cfif de NEQ "" OR dis NEQ "">
			<span class="alert">All individual products have been made <cfif de EQ "n">active<cfelseif de EQ "y">inactive<cfelseif dis EQ "y">discontinued<cfelseif dis EQ "n">not discontinued</cfif>.</span><br /><br />
		</cfif>
	
		<cfif pgfn EQ "edit">
	
			<cfquery name="FindMetaInfo" datasource="#application.DS#">
				SELECT p.ID AS meta_ID, v.productvalue AS master_category_value, p.productvalue, p.retailvalue, p.meta_name, p.meta_sku, p.description,
						p.imagename_original, p.thumbnailname_original, p.sortorder, p.manuf_logo_ID, p.imagename, p.thumbnailname, p.productvalue_master_ID, IF(never_show_inventory=1,"yes","no") AS never_show_inventory
				FROM #application.database#.product_meta p
				LEFT JOIN #application.database#.productvalue_master v ON v.ID = p.productvalue_master_ID
				WHERE p.ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
			</cfquery>
			<cfset meta_ID = FindMetaInfo.meta_ID>
			<cfset master_category_value = htmleditformat(FindMetaInfo.master_category_value)>
			<cfset productvalue = htmleditformat(FindMetaInfo.productvalue)>
			<cfset retailvalue = htmleditformat(FindMetaInfo.retailvalue)>
			<cfset productvalue_master_ID = htmleditformat(FindMetaInfo.productvalue_master_ID)>
			<cfset meta_name = FindMetaInfo.meta_name>
			<cfset meta_sku = htmleditformat(FindMetaInfo.meta_sku)>
			<cfset description = FindMetaInfo.description>
			<cfset imagename_original = htmleditformat(FindMetaInfo.imagename_original)>
			<cfset thumbnailname_original = htmleditformat(FindMetaInfo.thumbnailname_original)>
			<cfset imagename = htmleditformat(FindMetaInfo.imagename)>
			<cfset thumbnailname = htmleditformat(FindMetaInfo.thumbnailname)>
			<cfset sortorder = htmleditformat(FindMetaInfo.sortorder)>
			<cfset manuf_logo_ID = htmleditformat(FindMetaInfo.manuf_logo_ID)>
			<cfset never_show_inventory = htmleditformat(FindMetaInfo.never_show_inventory)>
	
			<cfquery name="FindGroupInfo" datasource="#application.DS#">
				SELECT pg.name AS group_name
				FROM #application.database#.product_meta_group pg, #application.database#.product_meta_group_lookup pgl
				WHERE pgl.product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10"> AND pgl.product_meta_group_ID = pg.ID
				ORDER BY pg.sortorder
			</cfquery>
	
			<cfquery name="FindOptionInfo" datasource="#application.DS#">
				SELECT pmoc.ID AS pmoc_ID, pmoc.category_name AS category_name, pmo.option_name AS option_name, pmoc.sortorder AS pmoc_sortorder, pmo.ID AS option_ID
				FROM #application.database#.product_meta_option_category pmoc, #application.database#.product_meta_option pmo
				WHERE pmoc.product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10"> AND pmoc.ID = pmo.product_meta_option_category_ID
				ORDER BY pmoc.sortorder, pmo.sortorder
			</cfquery>
			<cfparam name="pmoc_ID" default="">
			<cfparam name="category_name" default="">
			<cfparam name="option_name" default="">
	
			<cfquery name="FindProductInfo" datasource="#application.DS#">
				SELECT ID AS prod_ID, sku, sortorder, IF(is_dropshipped=1,"true", "false") AS is_dropshipped, IF(is_active=1,"yes","no") AS is_active, IF(is_discontinued=1,"true","false") AS is_discontinued, weight
				FROM #application.database#.product
				WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
				ORDER BY sortorder
			</cfquery>
	
			<cfif manuf_logo_ID NEQ "">
				<cfquery name="FindManufLogoInfo" datasource="#application.DS#">
					SELECT manuf_name, logoname
					FROM #application.database#.manuf_logo
					WHERE ID = #manuf_logo_ID#
				</cfquery>
				<cfset manuf_name = htmleditformat(FindManufLogoInfo.manuf_name)>
				<cfset logoname = htmleditformat(FindManufLogoInfo.logoname)>
			</cfif>
	
		</cfif>
	
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		
		<tr class="contenthead">
		<td colspan="2" class="headertext">(1) Meta Information</td>
		</tr>
		
		<cfif pgfn EQ "add">
			<tr class="content2">
			<cfoutput>
			<td colspan="2"><cfif has_set AND set_ID GT 1><a href="product_meta.cfm?pgfn=add&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Add A New Product</a></cfif></td>
			</cfoutput>
			</tr>
		<cfelse>
			<cfset show_delete_meta = false>
			<cfif FLGen_HasAdminAccess(1000000054)>
				<cfquery name="FindLinkMetaProd" datasource="#application.DS#">
					SELECT COUNT(ID) as thismany
					FROM #application.database#.product
					WHERE product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#meta_ID#" maxlength="10"> 
				</cfquery>
				<cfif FindLinkMetaProd.thismany EQ 0>
					<cfquery name="FindLinkMetaOptionCat" datasource="#application.DS#">
						SELECT COUNT(ID) as thismany
						FROM #application.database#.product_meta_option_category
						WHERE product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#meta_ID#" maxlength="10"> 
					</cfquery>
					<cfif FindLinkMetaOptionCat.thismany EQ 0>
						<cfset show_delete_meta = true>
					</cfif>
				</cfif>
			</cfif>
			<cfoutput>
			<tr class="content2">
			<td colspan="2">
				<a href="product_meta.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Edit</a>
				&nbsp;&nbsp;&nbsp;&nbsp;
				<cfif FLGen_HasAdminAccess(1000000054) and show_delete_meta>
					<a href="#CurrentPage#?delete_meta=#meta_ID#&pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#" onclick="return confirm('Are you sure you want to delete this meta product?  All options associated with this category will also be deleted. There is NO UNDO.')">Delete</a>
					&nbsp;&nbsp;&nbsp;&nbsp;
				</cfif>
				<a href="product_order.cfm?pv=#productvalue_master_ID#&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Set sort order</a>
				<cfif sortorder EQ 0>
					<span class="alert">&nbsp;&nbsp;&laquo; Click to set sort order in the #value# category.</span>
				</cfif>
			</td>
			</tr>
			<tr class="content">
			<td align="right" valign="top">Product Name:</td>
			<td valign="top">
				<b>#meta_name#</b>&nbsp;&nbsp;&nbsp;&nbsp;
				<cfif imagename NEQ "">
					<a href="../pics/products/#imagename#" target="_blank">image</a>
				<cfelse>
					<span class="sub">(no main image)</span>
				</cfif>
				&nbsp;&nbsp;&nbsp;&nbsp;
				<cfif imagename NEQ "">
					<a href="../pics/products/#thumbnailname#" target="_blank">thumbnail</a>
				<cfelse>
					<span class="sub">(no thumbnail image)</span>
				</cfif>
			</td>
			</tr>
	
			<tr class="content">
			<td align="right" valign="top">ITC SKU (meta):</td>
			<td valign="top" width="100%">#meta_sku#</td>
			</tr>
			
			<tr class="content">
			<td align="right" valign="top">Description:</td>
			<td valign="top">#Replace(description,chr(10),"<br>","ALL")#</td>
			</tr>
			
			<tr class="content">
			<td align="right" valign="top">Manufacturer:</td>
			<td valign="top"><cfif logoname NEQ "" AND manuf_name NEQ ""><a href="../pics/manuf_logos/#htmleditformat(logoname)#" target="_blank"></cfif>#manuf_name#<cfif logoname NEQ "" AND manuf_name NEQ ""></a></cfif> <cfif manuf_name NEQ "" AND logoname EQ "">(no logo)<cfelseif manuf_logo_ID EQ ""><span class="sub">-</span></cfif></td>
			</tr>
			
			<tr class="content">
			<td align="right" valign="top">Master&nbsp;Category:</td>
			<td valign="top">#master_category_value#</td>
			</tr>

			<tr class="content">
			<td align="right" valign="top">Product&nbsp;Value:</td>
			<td valign="top">#productvalue#</td>
			</tr>

			<tr class="content">
			<td align="right" valign="top">Retail Price:</td>
			<td valign="top">#retailvalue#</td>
			</tr>

			<tr class="content">
			<td align="right" valign="top">Never Show Inventory?</td>
			<td valign="top">#never_show_inventory#</td>
			</tr>
				
			<tr class="content">
			<td align="right" valign="top">Product Groups:</td>
			<td valign="top">
				<cfif FindGroupInfo.RecordCount EQ 0>
					<span class="alert">&nbsp;&nbsp;&laquo; Assign this product to a group.</span>
				<cfelse>
					<cfloop query="FindGroupInfo">[ #HTMLEditFormat(group_name)# ]&nbsp;&nbsp;&nbsp;&nbsp; </cfloop>
				</cfif>
			</td>
			</tr>
			<tr class="content">
			<td align="right" valign="top">Set Weights:</td>
			<td>
				<form method="post" action="#CurrentPage#">
					<input type="hidden" name="pgfn" value="edit">
					<input type="hidden" name="xA" value="#xA#">
					<input type="hidden" name="xA" value="#xA#">
					<input type="hidden" name="xL" value="#xL#">
					<input type="hidden" name="xS" value="#xS#">
					<input type="hidden" name="xT" value="#xT#">
					<input type="hidden" name="xW" value="#xW#">
					<input type="hidden" name="set_id" value="#set_id#">
					<input type="hidden" name="meta_id" value="#meta_id#">
					<input type="hidden" name="OnPage" value="#OnPage#">
					<input type="text" name="weight" value="" maxlength="10" size="10">
					<input type="submit" name="update_weight" value="   Update Weights   " >
				</form>
				<span class="sub">This will update all individual products to this weight.</span>
			</td>
			
			</cfoutput>
		</cfif>
		</table>
		<br />
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		
		<tr class="contenthead">
		<td colspan="2"><span class="headertext">(2) Options</span> <span class="sub">(if any)</span></td>
		</tr>
	<cfif pgfn EQ "edit">
		<tr class="content2">
		<cfoutput>
		<td colspan="2"><a href="product_option.cfm?pgfn=add&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Add An Option</a></td>
		</cfoutput>
		</tr>
		
		
		<cfif FindOptionInfo.RecordCount NEQ 0>
		<tr class="content">
		<td valign="top" align="right">Existing&nbsp;Options:</td>
		<td width="100%" valign="top">
		<table cellpadding="0" cellspacing="0" border="0"><tr>
		<cfoutput query="FindOptionInfo" group="pmoc_ID">
		
			<cfset show_delete_cat = false>
			<cfif FLGen_HasAdminAccess(1000000054)>
				<cfquery name="FindLinkCat" datasource="#application.DS#">
					SELECT COUNT(po.ID) as thismany
					FROM #application.database#.product_option po 
						JOIN #application.database#.product_meta_option pmo ON po.product_meta_option_ID = pmo.ID
					WHERE pmo.product_meta_option_category_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#pmoc_ID#" maxlength="10"> 
				</cfquery>
				<cfif FindLinkCat.thismany EQ 0>
					<cfset show_delete_cat = true>
				</cfif>
			</cfif>
	
		<td valign="top">
			<img src="../pics/contrls-desc.gif" width="7" height="6">
			<a href="product_option.cfm?pgfn=edit&pmoc_ID=#pmoc_ID#&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Edit</a>
			<cfif FLGen_HasAdminAccess(1000000054) AND show_delete_cat>
				&nbsp;&nbsp;
				<a href="#CurrentPage#?delete_cat=#pmoc_ID#&pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#" onclick="return confirm('Are you sure you want to delete this option category?  All options associated with this category will also be deleted. There is NO UNDO.')">Delete</a>
				&nbsp;&nbsp;&nbsp;
			</cfif>
			<br /><br />
			<b>#HTMLEditFormat(category_name)#</b>&nbsp;&nbsp;<span class="sub">[#HTMLEditFormat(pmoc_sortorder)#]</span>&nbsp;&nbsp;<br>
			<cfoutput>
			<cfset show_delete_option = false>
			<cfif FLGen_HasAdminAccess(1000000054)>
				<cfquery name="FindLinkOption" datasource="#application.DS#">
					SELECT COUNT(ID) as thismany
					FROM #application.database#.product_option
					WHERE product_meta_option_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#option_ID#" maxlength="10"> 
				</cfquery>
				<cfif FindLinkOption.thismany EQ 0>
					<cfset show_delete_option = true>
				</cfif>
			</cfif>
	
				&nbsp;&nbsp;&nbsp;&middot&nbsp;#option_name#<cfif FLGen_HasAdminAccess(1000000054) AND show_delete_option> <a href="#CurrentPage#?delete_option=#option_ID#&pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#" onclick="return confirm('Are you sure you want to delete this option?  There is NO UNDO.')">X</a></cfif><br>
			</cfoutput>
		</td>
		<td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
		</cfoutput>
		</tr></table>
		</td>
		</tr>
		</cfif>
	</cfif>
	
		</table>
		
	<br />
	
		<cfset indvprodnotordered = false>
	<cfif pgfn EQ "edit">
		<!--- if there are options and more than one product --->
		<cfif FindProductInfo.RecordCount GT 1 AND FindOptionInfo.RecordCount GT 1>
			<cfquery name="FindIndvProdCount" datasource="#application.DS#">
				SELECT COUNT(ID) AS total_indv_prods
				FROM #application.database#.product
				WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">  
			</cfquery>
	
			<cfquery name="FindIndvProdDistinct" datasource="#application.DS#">
				SELECT DISTINCT sortorder
				FROM #application.database#.product
				WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">  
					AND sortorder <> 0
			</cfquery>
			
			<cfif FindIndvProdCount.total_indv_prods NEQ FindIndvProdDistinct.RecordCount>
				<cfset indvprodnotordered = true>
			</cfif>
	
		</cfif>
	</cfif>
	
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
		<tr class="contenthead">
		<td colspan="2"><span class="headertext">(3) Individual Information</span><cfif indvprodnotordered><span class="alert">&nbsp;&nbsp;&nbsp;&laquo; set the sortorder of each product below, no duplicates</span></cfif></td>
		</tr>
		
	<cfif pgfn EQ "edit">
	
		<!--- if there are no products for this meta product --->
		<cfif FindProductInfo.RecordCount EQ 0>
			<tr class="content2">
				<td colspan="2">
					<cfoutput>
					<span class="alert">This product is not complete until you add individual information.</span><br><br>
					<a href="product_individual.cfm?pgfn=add&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Add An Individual Product</a>
					<cfif FindOptionInfo.RecordCount GT 1>
						<br><br>OR<br><br>
						Create all possible Individual Products as 
						<a href="product_make_all_individual.cfm?pgfn=1&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">dropship</a>
						&nbsp;&nbsp;
						<a href="product_make_all_individual.cfm?pgfn=0&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">ship from ITC</a>
					</cfif>
					</cfoutput>
					</td>
		</tr>
		</cfif>
		<!--- if there are options and there are not zero products --->
		<cfif FindProductInfo.RecordCount NEQ 0 AND FindOptionInfo.RecordCount NEQ 0>
		<tr class="content2">
			<cfoutput>
		<td><a href="product_individual.cfm?pgfn=add&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#">Add Another Product</a>
		</td>
		<td>
		<cfif FindProductInfo.RecordCount GT 1>
			&nbsp;&nbsp;&nbsp;&nbsp;Make all individual products: <a href="product_inactive.cfm?de=y&pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">inactive</a>/<a href="product_inactive.cfm?de=n&pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">active</a>
			<br>&nbsp;&nbsp;&nbsp;&nbsp;Make all individual products: <a href="product_discontinued.cfm?dis=y&pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">discontinued</a>/<a href="product_discontinued.cfm?dis=n&pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">not discontinued</a>
		<cfelse>&nbsp;</cfif>
		</td>
			</cfoutput>
		</tr>
		</cfif>
		
		<cfif FindProductInfo.RecordCount NEQ 0>
			<cfloop query="FindProductInfo">
				<cfoutput>
				
		<cfset prod_ID = prod_ID>
		
		<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
			SELECT pmoc.category_name AS category_name, pmo.option_name AS option_name 
			FROM #application.database#.product_meta_option_category pmoc, #application.database#.product_meta_option pmo, #application.database#.product_option po
			WHERE pmo.ID = po.product_meta_option_ID AND po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10"> AND pmoc.ID = pmo.product_meta_option_category_ID
			ORDER BY pmoc.sortorder
		</cfquery>
		
		<cfset show_delete_indv = false>
		<cfif FLGen_HasAdminAccess(1000000054)>
			<cfquery name="FindLinkIndvProd" datasource="#application.DS#">
				SELECT COUNT(ID) as thismany
				FROM #application.database#.inventory
				WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#prod_ID#" maxlength="10">
					AND is_valid = 1 
			</cfquery>
			<cfif FindLinkIndvProd.thismany EQ 0>
				<cfset show_delete_indv = true>
			</cfif>
		</cfif>
	
		<tr class="#Iif(is_active CONTAINS "no" OR is_discontinued, de('inactivebg'), de('content'))#">
		<td align="right">
			<a href="product_individual.cfm?pgfn=edit&prod_ID=#prod_ID#&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Edit</a>
			&nbsp;&nbsp;
			<cfif FLGen_HasAdminAccess(1000000054) and show_delete_indv>
				<a href="#CurrentPage#?delete_indv=#prod_ID#&pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#" onclick="return confirm('Are you sure you want to delete this individual product?  There is NO UNDO.')">Delete</a>
			<cfelse>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			</cfif>
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>ITC&nbsp;SKU:</b>
		</td>
		<td width="100%"><b>#sku#</b><cfif is_discontinued>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>DISCONTINUED</b></cfif></td>
		</tr>
			
		<tr class="content">
		<td align="right">Inventory Type:</td>
	<td><cfif is_dropshipped>dropshipped<cfelse>physical inventory</cfif><cfset is_dropshipped = is_dropshipped></td>
		</tr>
			
		<tr class="content">
		<td align="right">Is Active?:</td>
	<td>#is_active#</td>
		</tr>

		<tr class="content">
		<td align="right">Weight:</td>
	<td>#weight#</td>
		</tr>
		
		<!--- no need to show this if there is just one product --->
		<cfif FindProductInfo.RecordCount GT 1>
			
		<tr class="content">
		<td align="right">Sort Order:</td><td>#sortorder#&nbsp;&nbsp;&nbsp;&nbsp;<span class="sub">&laquo; Used only within meta product.</span></td>
		</tr>
		
		</cfif>
				
		</cfoutput>
		
		<cfif #FindProductOptionInfo.RecordCount# NEQ 0>
		
		<tr class="content">
		<td valign="top" align="right">Product Options:</td>
		<td>
			<cfoutput query="FindProductOptionInfo" group="category_name">
			#HTMLEditFormat(category_name)#:&nbsp;<b>#option_name#</b><br>
			</cfoutput>
		</td>
		</tr>
		
		</cfif>
		
		<cfoutput>
	
		<tr class="content">
		<td align="left" width="140" valign="top">
			<a href="product_vendor.cfm?prod_ID=#prod_ID#&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Assign a Vendor</a>
		</td>
		<td>
		
		<!--- find any existing assigned vendors --->
		<cfquery name="FindExistingVendors" datasource="#application.DS#">
			SELECT vl.ID AS vl_ID, v.vendor, IF(vl.is_default=1,"yes","no") AS is_default, IFNULL(vl.vendor_sku, "-") AS vendor_sku, vendor_PO_note, CAST(IFNULL(vl.vendor_cost, "-") AS CHAR) AS vendor_cost, CAST(IFNULL(vl.vendor_min_qty, "-") AS CHAR) AS vendor_min_qty, CAST(IFNULL(vl.pack_size, "") AS CHAR) AS pack_size, IFNULL(vl.pack_desc, "") AS pack_desc
			FROM #application.database#.vendor v JOIN #application.database#.vendor_lookup vl ON vl.vendor_ID = v.ID
			WHERE  vl.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10">
			ORDER BY vl.is_default DESC
		</cfquery>
		
		<cfif FindExistingVendors.RecordCount NEQ 0>
		
			<table cellpadding="2" cellspacing="0" border="0" width="100%">
			
		<cfloop query="FindExistingVendors">
			<tr>
			<td align="right">
				<a href="product_vendor.cfm?prod_ID=#prod_ID#&vl_ID=#vl_ID#&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Edit</a>
				&nbsp;&nbsp;&nbsp;
				<a href="#CurrentPage#?pgfn=removevendor&prod_ID=#prod_ID#&vl_ID=#vl_ID#&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#" onclick="return confirm('Are you sure you want to remove this vendor from this individual product?  There is NO UNDO.')">Remove</a>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;vendor:
			</td>
			<td width="100%">#vendor#<cfif is_default> [default]</cfif></td>
			</tr>
			
			<tr>
			<td align="right">Vendor SKU: </td>
			<td>#vendor_sku#</td>
			</tr>
			
		<cfif Trim(vendor_PO_note) NEQ ''>
			<tr>
			<td align="right">Vendor PO Note: </td>
			<td>#vendor_PO_note#</td>
			</tr>
		</cfif>		
		
			<tr>
			<td align="right" valign="top">ITC Cost: </td>
			<td>$#vendor_cost#</td>
			</tr>
			
		<cfif NOT is_dropshipped>
			<tr>
			<td align="right">Min Order Qty: </td>
			<td><cfif NOT is_dropshipped AND vendor_min_qty NEQ "-" AND vendor_min_qty NEQ "1">#vendor_min_qty#
			<cfelseif NOT is_dropshipped>(no minimum)<cfelse>&nbsp;</cfif></td>
			</tr>
		</cfif>
			
	<cfif NOT is_dropshipped AND pack_size NEQ "" AND pack_desc NEQ "">
			<tr>
			<td align="right" valign="top">Vendor Pack: </td>
			<td>
				<cfif NOT is_dropshipped AND pack_size NEQ "" AND pack_desc NEQ "">
					#pack_size# per #pack_desc#
				<cfelse>&nbsp;
				</cfif>
			</td>
			</tr>
	</cfif>
			
			<cfif FindExistingVendors.CurrentRow NEQ FindExistingVendors.RecordCount>
			
			<tr><td colspan="6" style="background-color:##FFFFFF; padding:0px"><img src="../pics/shim.gif" height="1" width="300"></td></tr>
			
			</cfif>
	
		</cfloop>
			
			</table>
		
		<cfelse>
		
			<span class="alert">&laquo; Assign a vendor to this product.</span>
			
		</cfif>
		
		</td>
		</tr>
				
		<cfif FindProductInfo.RecordCount NEQ #FindProductInfo.CurrentRow#>
		<tr class="content2">
		<td colspan="2">&nbsp;
					
		</td>
		</tr>
		</cfif>
	
				</cfoutput>
			</cfloop>
		</cfif>
		
	</cfif>
	
		</table>
	
	</cfif>
	<cfif meta_ID NEQ "">
	<cfoutput>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="contenthead"><td colspan="2"><span class="headertext">(4) Bulk Exclude</span></td></tr>
		<tr class="content2"><td colspan="2"><a href="product_bulk_exclude.cfm?pgfn=add&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">Exclude from Programs</a></td>	</tr>
	</table>
	</cfoutput>
</cfif>
</cfif>
	<!--- END pgfn ADD/EDIT --->
	
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->