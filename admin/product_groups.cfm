<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000010,true)>

<cfparam name="ID" default="">
<cfparam name="delete" default="">

<cfparam name="name" default="">
<cfparam name="sortorder" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="username">
<cfparam name="xT" default="">
<cfparam name="xL" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- update --->
	<cfif form.ID IS NOT "">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.product_meta_group
			SET	name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.name#" maxlength="32">,
				sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.sortorder#" maxlength="5">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelse>
		<cflock name="product_meta_groupLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.product_meta_group
						(created_user_ID, created_datetime, name, sortorder)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.name#" maxlength="32">,<cfqueryparam cfsqltype="cf_sql_integer" value="#form.sortorder#" maxlength="5">
					)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.product_meta_group
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfif>
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000050)>
	<cfquery name="DeleteGroup" datasource="#application.DS#">
		DELETE FROM #application.database#.product_meta_group
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "groups">
<cfinclude template="includes/header.cfm">

<cfparam  name="pgfn" default="list">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">
	<span class="pagetitle">Product Group List</span>
	<br /><br />
	<span class="alert">Updates can only be made in www2.</span>
	<br /><br />
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID, name, sortorder
		FROM #application.database#.product_meta_group
		ORDER BY sortorder
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<cfoutput>
	<tr class="contenthead">
	<td><!---<a href="#CurrentPage#?pgfn=add">Add</a>---></td>
	<td><span class="headertext">Sort&nbsp;Order</span></td>
	<td width="100%"><span class="headertext">Name</span></td>
	</tr>
	</cfoutput>
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="3" align="center"><span class="alert"><br>No groups found.  Click "add" enter a product group.<br><br></span></td>
		</tr>
	<cfelse>
		<cfoutput query="SelectList">
			<cfset show_delete = false>
			<cfif FLGen_HasAdminAccess(1000000050)>
				<cfquery name="FindLinks" datasource="#application.DS#">
					SELECT COUNT(ID) as thismany
					FROM #application.database#.product_meta_group_lookup
					WHERE product_meta_group_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10"> 
				</cfquery>
				<cfif FindLinks.thismany EQ 0>
					<cfset show_delete = true>
				</cfif>
			</cfif>
			<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
			<td nowrap><!---<a href="#CurrentPage#?pgfn=edit&ID=#ID#">Edit</a>&nbsp;&nbsp;&nbsp;---><a href="#CurrentPage#?pgfn=prodlist&ID=#ID#">View List</a><!---<cfif FLGen_HasAdminAccess(1000000050) and show_delete>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#ID#" onclick="return confirm('Are you sure you want to delete this product group?  There is NO UNDO.')">Delete</a></cfif>---></td>
			<td align="center">#HTMLEditFormat(sortorder)#</td>
			<td>#HTMLEditFormat(name)#</td>
			</tr>
		</cfoutput>
	</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
<!---	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Product Group</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#">Product Group List</a> without making changes.</span>
	<br /><br />
	</cfoutput>
	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, name, sortorder
			FROM #application.database#.product_meta_group
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset name = htmleditformat(ToBeEdited.name)>
		<cfset sortorder = htmleditformat(ToBeEdited.sortorder)>
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0">
	
	<tr class="contenthead">
	<td colspan="2"><span class="headertext"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Product Category</span></td>
	</tr>
	
	<tr class="content">
	<td align="right">Sort Order: </td>
	<td><input type="text" name="sortorder" value="#sortorder#" maxlength="5" size="7"></td>
	</tr>
	
	<tr class="content">
	<td align="right">Group Name: </td>
	<td><input type="text" name="name" value="#name#" maxlength="30" size="40"></td>
	</tr>
		
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="ID" value="#ID#">
	
	<input type="hidden" name="name_required" value="Please enter a category name.">
	<input type="hidden" name="sortorder_required" value="Please enter a sort order.">
		
	<input type="submit" name="submit" value="   Save Changes   " >

	</td>
	</tr>
		
	</table>
	</form>
	</cfoutput>--->
	<!--- END pgfn ADD/EDIT --->
<cfelseif pgfn EQ "prodlist">
	<!--- START pgfn LIST --->
	<cfquery name="SelectGroupName" datasource="#application.DS#">
		SELECT name
		FROM #application.database#.product_meta_group
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">
	</cfquery>
	<cfset groupname = HTMLEditFormat(SelectGroupName.name)>
	<cfoutput>
	<span class="pagetitle">List of Products in this Group [<span class="selecteditem">#groupname#</span>]</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#">Product Group List</a> without making changes.</span>
	<br /><br />
	</cfoutput>
	<!--- find all the products in this group sorted by master category, then name alpha --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT pm.meta_name, pm.meta_sku, pv.productvalue, pm.ID AS this_meta_ID, pm.product_set_ID
		FROM #application.database#.product_meta pm
		JOIN #application.database#.productvalue_master pv  ON pm.productvalue_master_ID = pv.ID
		JOIN #application.database#.product_meta_group_lookup pmgl ON pm.ID = pmgl.product_meta_ID
		WHERE pmgl.product_meta_group_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">
		ORDER BY pv.sortorder ASC, meta_name ASC
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
		<tr class="contenthead">
		<td>&nbsp;</td>
		<td><span class="headertext">Category</span></td>
		<td width="100%"><span class="headertext">Product</span></td>
		</tr>
		<cfif SelectList.RecordCount IS 0>
			<tr class="content2">
				<td colspan="3" align="center"><span class="alert"><br>No products were found in this group.  Click "Product Group List" to return to the list.<br><br></span></td>
			</tr>
		<cfelse>
			<cfoutput query="SelectList">
				<cfquery name="ThisProdsGroups" datasource="#application.DS#">
					SELECT g.name
					FROM #application.database#.product_meta_group g
					JOIN #application.database#.product_meta_group_lookup gl ON g.ID = gl.product_meta_group_ID
					WHERE gl.product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_meta_ID#" maxlength="10">
					ORDER BY g.sortorder ASC 
				</cfquery>
				<cfset this_group_list = ValueList(ThisProdsGroups.name)>
				<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
				<td nowrap><!---<a href="product_meta.cfm?pgfn=edit&meta_ID=#this_meta_ID#&gpgfn=prodlist&gID=#ID#&set_id=#SelectList.product_set_ID#">Edit</a>---></td>
				<td align="center">#HTMLEditFormat(productvalue)#</td>
				<td>#meta_name# [SKU: #HTMLEditFormat(meta_sku)#]<br><span class="sub">#this_group_list#</span></td>
				</tr>
			</cfoutput>	
		</cfif>
	</table>
	<!--- END pgfn LIST --->
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->