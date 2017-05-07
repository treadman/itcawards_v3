<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000008,true)>

<cfparam name="where_string" default="">
<cfparam name="meta_ID" default="">
<cfparam name="set_ID" default="">
<cfparam name="pmoc_ID" default="">
<cfparam  name="pgfn" default="">
<cfparam name="thisProdsGroups" default="">
<cfparam name="thischecked" default="">
<cfparam name="b" default="1">
<cfparam name="tempos" default="0">
<cfparam name="QSnew" default="">
<cfparam name="ExistingOptions" default="">
<cfparam name="thisOptName" default="">
<cfparam name="thisOptSort" default="">
<cfparam name="thisnewOptName" default="">
<cfparam name="thisnewOptSort" default="">
<cfparam name="ThisOptionName" default="">
<cfparam name="ThisProdsOpts" default="">
<cfparam name="productvalue" default="">
<cfparam name="weight" default="1">
<cfif not isNumeric(weight) OR weight gt 999>
	<cfset weight = 1>
</cfif>

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="xW" default="">
<cfparam name="xA" default="">
<cfparam name="OnPage" default="">
<cfparam name="orderbyvar" default="">
<cfparam name="OptionList" default="">

<!--- param a/e form fields --->
<cfparam name="prod_ID" default="">
<cfparam name="sku" default="">
<cfparam name="is_dropship" default="">
<cfparam name="pack_size" default="">
<cfparam name="pack_desc" default="">
<cfparam name="sortorder" default="">
<cfparam name="is_dropshipped" default="">
<cfparam name="is_active" default="">
<cfparam name="is_discontinued" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfif is_discontinued EQ "1">
		<cfset is_active = 0>
	</cfif>
	<!--- update --->
	<cfif form.prod_ID IS NOT "">
		<cfquery name="UpdatePMOQuery" datasource="#application.DS#">
			UPDATE #application.database#.product
			SET	product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#meta_ID#" maxlength="10">,
				sku = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sku#" maxlength="64">,
				<cfif isNumeric(sortorder) and sortorder gte 0 and sortorder lte 99999>
				sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#sortorder#" maxlength="5">,
				</cfif>
				is_dropshipped = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_dropshipped#" maxlength="1">,
				is_active = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_active#" maxlength="1">,
				is_discontinued = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_discontinued#" maxlength="1">,
				productvalue = <cfqueryparam cfsqltype="cf_sql_integer" value="#productvalue#" maxlength="11" null="#NOT isNumeric(productvalue)#">,
				weight = <cfqueryparam cfsqltype="cf_sql_float" value="#weight#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10">
		</cfquery>
		<!--- delete all the options for this product --->
		<cfquery name="DeleteProdOptions" datasource="#application.DS#">
			DELETE FROM #application.database#.product_option
			WHERE product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelse>
		<!--- data massage --->
		<cfif sortorder EQ "">
			<cfset sortorder="0">
		</cfif>
		<cflock name="productLock" timeout="10">
			<cftransaction>
			<cfquery name="InsertQuery" datasource="#application.DS#">
				INSERT INTO #application.database#.product
					(created_user_ID, created_datetime, product_meta_ID, sku, sortorder, is_dropshipped, is_active, is_discontinued,productvalue,weight)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
					'#FLGen_DateTimeToMySQL()#', 
					<cfqueryparam cfsqltype="cf_sql_integer" value="#meta_ID#" maxlength="10">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sku#" maxlength="64">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#sortorder#" maxlength="5">,
					<cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_dropshipped#" maxlength="1">,
					<cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_active#" maxlength="1">,
					<cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_discontinued#" maxlength="1">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#productvalue#" maxlength="11" null="#NOT isNumeric(productvalue)#">,
					<cfqueryparam cfsqltype="cf_sql_float" value="#weight#" maxlength="10">
				)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.product
				</cfquery>
				<cfset prod_ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfif>
	<!--- save selected options --->
	<cfloop list="#Form.FieldNames#" index="ThisField">
		<cfif ThisField contains "OPT">
			<cfset thisOptValue = Evaluate(ThisField)>
			<cfquery name="InsertSelectedOptions" datasource="#application.DS#">
				INSERT INTO #application.database#.product_option
					(created_user_ID, created_datetime, product_ID, product_meta_option_ID)
				VALUES
				(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#',
				<cfqueryparam cfsqltype="cf_sql_integer" value="#prod_ID#" maxlength="10">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#thisOptValue#" maxlength="10">)
			</cfquery>
		</cfif>
	</cfloop>
		
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfset pgfn = "edit">

</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "products">
<cfinclude template="includes/header.cfm">

<!--- START pgfn ADD/EDIT --->

<span class="pagetitle">Individual Product Information</span>
<br /><br />
<span class="pageinstructions">Return to <a href="<cfoutput>product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product Detail</a> or <a href="<cfoutput>product.cfm?&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product List</a> without making changes.</span>
<br /><br />
<cfoutput>
<cfif isDefined("form.submit")>
	<span class="pageinstructions"><a href="#CurrentPage#?pgfn=add&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&OnPage=#OnPage#&set_ID=#set_ID#">Add</a> a new Individual Product.</span>
	<br /><br />
</cfif>
</cfoutput>

<cfquery name="SelectProdInfo" datasource="#application.DS#">
	SELECT meta_name, meta_sku
	FROM #application.database#.product_meta
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
</cfquery>
<cfset meta_name = SelectProdInfo.meta_name>

<cfif pgfn EQ "add">
	<!--- look to see if this meta product already has a indv prod to use as template --->
	<cfquery name="SelectTemplateProd" datasource="#application.DS#">
		SELECT ID AS prod_ID, sku, sortorder, is_dropshipped, is_active, is_discontinued, productvalue 
		FROM #application.database#.product
		WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
		ORDER BY ID DESC
	</cfquery>
	<cfif SelectTemplateProd.RecordCount NEQ 0>
		<cfset prod_ID = htmleditformat(SelectTemplateProd.prod_ID)>
		<cfset sku = htmleditformat(SelectTemplateProd.sku)>
		<cfset sortorder = htmleditformat(SelectTemplateProd.sortorder)>
		<cfset is_dropshipped = htmleditformat(SelectTemplateProd.is_dropshipped)>
		<cfset is_active = htmleditformat(SelectTemplateProd.is_active)>
		<cfset is_discontinued = htmleditformat(SelectTemplateProd.is_discontinued)>
		<cfset productvalue = SelectTemplateProd.productvalue>
	<cfelse>
		<cfset sku = htmleditformat(SelectProdInfo.meta_sku)>		
	</cfif>
	
<cfelseif pgfn EQ "edit" AND IsDefined('prod_ID') AND prod_ID IS NOT "">

	<cfquery name="SelectTemplateProd" datasource="#application.DS#">
		SELECT sku, sortorder, is_dropshipped, is_active, is_discontinued, productvalue, weight 
		FROM #application.database#.product
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10">
	</cfquery>
	<cfset sku = htmleditformat(SelectTemplateProd.sku)>
	<cfset sortorder = htmleditformat(SelectTemplateProd.sortorder)>
	<cfset is_dropshipped = htmleditformat(SelectTemplateProd.is_dropshipped)>
	<cfset is_active = htmleditformat(SelectTemplateProd.is_active)>
	<cfset is_discontinued = htmleditformat(SelectTemplateProd.is_discontinued)>
	<cfset productvalue = SelectTemplateProd.productvalue>
	<cfset weight = SelectTemplateProd.weight>
</cfif>

<cfquery name="FindOptionInfo" datasource="#application.DS#">
	SELECT pmoc.ID AS pmoc_ID, pmoc.category_name AS category_name, pmo.option_name AS option_name, pmo.ID AS pmo_ID
	FROM #application.database#.product_meta_option_category pmoc, #application.database#.product_meta_option pmo
	WHERE pmoc.product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10"> AND pmoc.ID = pmo.product_meta_option_category_ID
	ORDER BY pmoc.sortorder, pmo.sortorder
</cfquery>

<cfif SelectTemplateProd.RecordCount NEQ 0>
	<cfparam name="pmoc_ID" default="">
	<cfparam name="category_name" default="">
	<cfparam name="option_name" default="">

	<!--- if there are options for this metaproduct --->
	<!--- look in product_option and make a list of pmo_IDs for this prod_ID
			whether the passed id or the template prod id --->
	<cfif prod_ID NEQ "">
		<cfquery name="SelectThisProdsOpt" datasource="#application.DS#">
			SELECT product_meta_option_ID AS pmo_ID
			FROM #application.database#.product_option
			WHERE product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10">
		</cfquery>
		<cfif SelectThisProdsOpt.RecordCount NEQ 0>
			<cfloop query="SelectThisProdsOpt">
				<cfset ThisProdsOpts = ThisProdsOpts & " " & SelectThisProdsOpt.pmo_ID>
			</cfloop>
		</cfif>
	</cfif>
</cfif>

<cfoutput>
<form method="post" action="#CurrentPage#">


	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="content">
	<td colspan="2" class="headertext">Product: <span class="selecteditem">#meta_name# <cfif prod_ID NEQ "">#FindProductOptions(prod_ID)#</cfif></span></td>
	</tr>

	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "edit">Edit<cfelse>Add</cfif> Individual Product Information</td>
	</tr>

	<cfif pgfn EQ "add" AND SelectTemplateProd.RecordCount NEQ 0>
		<tr class="content2">
		<td align="right" valign="top">&nbsp;</td>
		<td valign="top"><br><span class="alert">!</span> You are adding a <b>new</b> individual product.<br><br>The information for the most recently entered individual product<br>for <b>#meta_name#</b> is pre-filled below for your convenience.
		<br><br>
		</td>
		</tr>
	</cfif>

	<tr class="content">
	<td align="right">ITC SKU: </td>
	<td valign="top" width="100%"><input type="text" name="sku" maxlength="64" size="40" value="#sku#">
	<input type="hidden" name="sku_required" value="Please enter an ITC SKU."></td>
	</tr>
		
	<tr class="content">
	<td align="right">Sort Order: </td>
	<td valign="top"><input type="text" name="sortorder" maxlength="5" size="7" value="#sortorder#"> <span class="sub">(sort order within this meta product)</span></td>
	</tr>
	
	<tr class="content">
	<td align="right">Inventory Type: </td>
	<td valign="top">
		<select name="is_dropshipped">
			<option value="0"<cfif is_dropshipped EQ 0> selected</cfif>>physical inventory</option>
			<option value="1"<cfif is_dropshipped EQ 1> selected</cfif>>dropshipped</option>
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right">Is Active?: </td>
	<td valign="top">
		<select name="is_active">
			<option value="1"<cfif is_active EQ 1> selected</cfif>>Yes</option>
			<option value="0"<cfif is_active EQ 0> selected</cfif>>No</option>
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right">Is&nbsp;Discontinued?: </td>
	<td valign="top">
		<select name="is_discontinued">
			<option value="0"<cfif is_discontinued EQ 0> selected</cfif>>No</option>
			<option value="1"<cfif is_discontinued EQ 1> selected</cfif>>Yes</option>
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right">Weight: </td>
	<td valign="top">
		<input type="text" name="weight" value="#weight#" maxlength="10" size="10">
	</td>
	</tr>
	</cfoutput>

	<cfif FindOptionInfo.RecordCount NEQ 0>
		<tr class="content2"> 
		<td align="right" valign="top">&nbsp;</td>
		<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6"> Please select one option from each<br>&nbsp;&nbsp;&nbsp;option category for this individual product.</td>
		</tr>
		<tr class="content">
		<td align="right" valign="top">Price override: </td>
		<td valign="top">
			$<input type="text" name="productvalue" value="<cfoutput>#productvalue#</cfoutput>" maxlength="11" size="5" />
		</td>
		</tr>
		<tr class="content">
		<td align="right" valign="top">Options: </td>
		<td valign="top">
			<cfoutput query="FindOptionInfo" group="pmoc_ID">
			<b>#HTMLEditFormat(category_name)#:</b><br>
			<input type="hidden" name="opt#pmoc_ID#_required" value="Please select one option from each option category.">
				<cfoutput>
					&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="opt#pmoc_ID#" value="#pmo_ID#"<cfif FindNoCase(pmo_ID,ThisProdsOpts)> checked</cfif>> #option_name#<br>
				</cfoutput>
				<br>
			</cfoutput>
		</td>
		</tr>
	</cfif>
	<cfoutput>
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="xS" value="#xS#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="xW" value="#xW#">
	<input type="hidden" name="xA" value="#xA#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="meta_ID" value="#meta_ID#">
	<input type="hidden" name="set_ID" value="#set_ID#">
	<input type="hidden" name="prod_ID" value="<cfif pgfn EQ "edit">#prod_ID#</cfif>">
			
	<input type="submit" name="submit" value="   Save <cfif pgfn EQ "edit">Edits<cfelseif pgfn EQ "add">New Individual Product</cfif>   " >
	
	</td>
	</tr>
		
	</table>
</form>
</cfoutput>

	
<!--- END pgfn ADD/EDIT --->

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->