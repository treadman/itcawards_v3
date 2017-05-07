<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000008,true)>

<cfparam name="where_string" default="">
<cfparam name="meta_ID" default="">
<cfparam name="set_ID" default="">
<cfparam  name="pgfn" default="">
<cfparam name="thisProdsGroups" default="">
<cfparam name="gpgfn" default="">
<cfparam name="gID" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="xW" default="">
<cfparam name="xA" default="">
<cfparam name="OnPage" default="">
<cfparam name="orderbyvar" default="">

<!--- param a/e form fields --->
<cfparam name="meta_name" default="">	
<cfparam name="meta_sku" default="">	
<cfparam name="description" default="">
<cfparam name="manuf_logo_ID" default="">
<cfparam name="imagename" default="">
<cfparam name="thumbnailname" default="">
<cfparam name="productvalue_master_ID" default="">
<cfparam name="productvalue" default="0">
<cfparam name="retailvalue" default="0">
<cfparam name="never_show_inventory" default="0">
<cfparam name="product_meta_group_ID" default="">
<cfparam name="imagename_original" default="">
<cfparam name="thumbnailname_original" default="">
<cfparam name="images" default="">
<cfparam name="thumbnails" default="">

<!--- Set up Product Sets --->
<cfparam name="set_ID" default="">
<cfif isNumeric(set_ID) AND set_ID GT 0>
	<cfquery name="ProductSet" datasource="#application.DS#">
		SELECT ID, set_name, note, sortorder
		FROM #application.database#.product_set
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#set_ID#" maxlength="10">
	</cfquery>
	<cfif ProductSet.recordcount NEQ 1>
		<cfset set_ID = 0>
	</cfif>
</cfif>

<cfset has_set = isNumeric(set_ID) AND set_ID GT 0>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfset alert_error = "">

<cfif has_set AND set_ID GT 1>

<cfif IsDefined('form.Submit')>
	<cfset thisProductValue = form.productvalue>
	<cfset thisMasterID = 0>
	<cfif isNumeric(form.productvalue_master_ID)>
		<cfset thisMasterID =form.productvalue_master_ID>
	</cfif>
	<cfquery name="GetMasterProductValue" datasource="#application.DS#">
		SELECT productvalue
		FROM #application.database#.productvalue_master
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisMasterID#" maxlength="10">
	</cfquery>
	<cfif thisMasterID GT 0 AND GetMasterProductValue.recordcount EQ 0>
		<cfset thisProductValue = 0>
	<cfelse>
		<cfif NOT isNumeric(thisProductValue) OR thisProductValue LTE 0>
			<cfset thisProductValue = GetMasterProductValue.productvalue>
		<cfelseif GetMasterProductValue.productvalue NEQ thisProductValue>
			<cfquery name="GetMasterProductValue" datasource="#application.DS#">
				SELECT ID
				FROM #application.database#.productvalue_master
				WHERE productvalue >= <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisProductValue#" maxlength="10">
				ORDER BY productvalue ASC
				LIMIT 1
			</cfquery>
			<cfif GetMasterProductValue.recordcount EQ 1>
				<cfset thisMasterID = GetMasterProductValue.ID>
			<cfelse>
				<cfquery name="GetMaxProductValue" datasource="#application.DS#">
					SELECT ID
					FROM #application.database#.productvalue_master
					ORDER BY productvalue DESC
					LIMIT 1
				</cfquery>
				<cfif GetMaxProductValue.recordcount EQ 1>
					<cfset thisMasterID = GetMaxProductValue.ID>
				</cfif>
			</cfif>
		</cfif>
	</cfif>
	<!--- update --->
	<cfif form.meta_ID IS NOT "">
		<!--- delete existing group lookups --->
		<cfquery name="DeleteGroupLookup" datasource="#application.DS#">
			DELETE FROM #application.database#.product_meta_group_lookup
			WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.meta_ID#" maxlength="10">
		</cfquery>
		<!--- do product_meta update --->
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.product_meta
			SET	productvalue_master_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisMasterID#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(thisMasterID)))#">,
				productvalue = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisProductValue#" maxlength="10">,
				retailvalue = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.retailvalue#" maxlength="10">,
				manuf_logo_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.manuf_logo_ID#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.manuf_logo_ID)))#">,
				never_show_inventory = <cfqueryparam cfsqltype="cf_sql_integer" value="#never_show_inventory#" maxlength="1">,
				meta_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.meta_name#" maxlength="64">,
				meta_sku = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.meta_sku#" maxlength="64">,
				description = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.description#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.meta_ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelse>
		<cflock name="product_metaLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.product_meta
						(created_user_ID, created_datetime, productvalue, retailvalue, never_show_inventory, productvalue_master_ID, product_set_ID, manuf_logo_ID, meta_name, meta_sku, description, sortorder)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="cf_sql_integer" value="#thisProductValue#" maxlength="10">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#form.retailvalue#" maxlength="10">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#never_show_inventory#" maxlength="1">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#thisMasterID#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(thisMasterID)))#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#set_ID#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(set_ID)))#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#form.manuf_logo_ID#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.manuf_logo_ID)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.meta_name#" maxlength="64">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.meta_sku#" maxlength="64">, 
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.description#">,
						0
					)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.product_meta
				</cfquery>
				<cfset meta_ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfif>
	<!--- loop through comma delimited checkboxes that were passed and insert into group lookup --->
	<cfif IsDefined('form.product_meta_group_ID') AND form.product_meta_group_ID IS NOT "">
		<cfloop list="#form.product_meta_group_ID#" index="thisGroup">
			<cfquery name="InsertGroupLookup" datasource="#application.DS#">
				INSERT INTO #application.database#.product_meta_group_lookup
				(created_user_ID, created_datetime, product_meta_ID, product_meta_group_ID)
				VALUES
				(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
				 '#FLGen_DateTimeToMySQL()#',
				  <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">,
				 #thisGroup#)			
			</cfquery>
		</cfloop>
	</cfif>
	<!--- deal with the images if they were submitted --->
	<!--- upload image, name is #meta_ID#_image.ext --->
	<cfif form.imagename_original IS NOT "">
		<cfset results = FLGen_UploadThis("imagename_original","pics/products/",meta_ID & "_image")>
		<cfset original = ListGetAt(results,1,",")>
		<cfset image = ListGetAt(results,2,",")>
		<!--- update this field in the database --->
		<cfquery name="UpdateQueryImage" datasource="#application.DS#">
			UPDATE #application.database#.product_meta
			SET	imagename_original = <cfqueryparam cfsqltype="cf_sql_varchar" value="#original#" maxlength="64">,
				imagename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#image#" maxlength="25">
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
		</cfquery>
	</cfif>
	<!--- upload thumbnail, name is #meta_ID#_thumbnail.ext  --->
	<cfif form.thumbnailname_original IS NOT ""> 
		<cfset results = FLGen_UploadThis("thumbnailname_original","pics/products/",meta_ID & "_thumbnail")>
		<cfset original = ListGetAt(results,1,",")>
		<cfset image = ListGetAt(results,2,",")>
		<!--- update this field in the database --->
		<cfquery name="UpdateQueryImage" datasource="#application.DS#">
			UPDATE #application.database#.product_meta
			SET	thumbnailname_original = <cfqueryparam cfsqltype="cf_sql_varchar" value="#original#" maxlength="64">,
				thumbnailname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#image#" maxlength="25">
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
		</cfquery>
	</cfif>
	<cfif alert_error EQ "">
		<cfif gpgfn NEQ "">
			<cfset alert_msg = Application.DefaultSaveMessage>
			<cfset pgfn = "edit">
		<cfelse>
			<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#&alert_msg=#urlencodedformat(Application.DefaultSaveMessage)#">
		</cfif>
	</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

</cfif>
<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "products">
<cfinclude template="includes/header.cfm">

<cfset tinymce_fields = "description">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">

<cfif has_set>
	<span class="pageinstructions">Product Set: <strong><cfoutput>#ProductSet.set_name#</cfoutput></strong></span><br><br>
</cfif>

<!--- START pgfn ADD/EDIT --->

<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> Product Meta Information</span>
<br /><br />
<cfif gpgfn NEQ "">
	<span class="pageinstructions">Return to <a href="<cfoutput>product_groups.cfm?pgfn=#gpgfn#&ID=#gID#&set_ID=#set_ID#</cfoutput>">Group Product List</a>  without making changes.</span>
	<br /><br />
<cfelse>
	<span class="pageinstructions">Return to <cfif pgfn EQ "edit"><a href="<cfoutput>product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product Detail</a> or </cfif><a href="<cfoutput>product.cfm?&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product List</a> without making changes.</span>
	<br /><br />
</cfif>

<cfif NOT has_set OR set_ID EQ 1>
	<span class="alert">You may only edit <cfoutput>#ProductSet.set_name#</cfoutput> in the old Awards system.</span>
<cfelse>

<cfif pgfn EQ "edit">
	<cfquery name="ToBeEdited" datasource="#application.DS#">
		SELECT ID AS meta_ID, productvalue, retailvalue, never_show_inventory, productvalue_master_ID, meta_name, meta_sku, description, imagename_original, thumbnailname_original, imagename, thumbnailname, manuf_logo_ID
		FROM #application.database#.product_meta
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
	</cfquery>
	<cfset meta_ID = ToBeEdited.meta_ID>
	<cfset productvalue_master_ID = htmleditformat(ToBeEdited.productvalue_master_ID)>
	<cfset meta_name = htmleditformat(ToBeEdited.meta_name)>
	<cfset meta_sku = htmleditformat(ToBeEdited.meta_sku)>
	<cfset description = htmleditformat(ToBeEdited.description)>
	<cfset imagename_original = htmleditformat(ToBeEdited.imagename_original)>
	<cfset thumbnailname_original = htmleditformat(ToBeEdited.thumbnailname_original)>
	<cfset imagename = htmleditformat(ToBeEdited.imagename)>
	<cfset thumbnailname = htmleditformat(ToBeEdited.thumbnailname)>
	<cfset manuf_logo_ID = ToBeEdited.manuf_logo_ID>
	<cfset productvalue = ToBeEdited.productvalue>
	<cfset retailvalue = ToBeEdited.retailvalue>
	<cfset never_show_inventory = ToBeEdited.never_show_inventory>
	<!--- make list of the groups this meta_product is in --->
	<cfquery name="GetThisProdsGroups" datasource="#application.DS#">
		SELECT product_meta_group_ID
		FROM #application.database#.product_meta_group_lookup
		WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
	</cfquery>
	<cfloop query="GetThisProdsGroups">
		<cfset thisProdsGroups = thisProdsGroups & " " & GetThisProdsGroups.product_meta_group_ID>
	</cfloop>
</cfif>

<cfquery name="SelectGroups" datasource="#application.DS#">
	SELECT g.ID, g.name
	FROM #application.database#.xref_product_set_group x
	LEFT JOIN #application.database#.product_meta_group g ON g.ID = x.product_meta_group_ID
	WHERE x.product_set_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#set_ID#">
	ORDER BY g.sortorder
</cfquery>

<cfquery name="GetManufLogo" datasource="#application.DS#">
	SELECT ID AS getmanuflogo_ID, manuf_name, logoname, logoname_original
	FROM #application.database#.manuf_logo
	ORDER BY manuf_name ASC 
</cfquery>

<cfoutput>
<form name="ProductMetaForm" method="post" action="#CurrentPage#" enctype="multipart/form-data">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext">Meta Information</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Product Name: </td>
	<td valign="top"><input type="text" name="meta_name" value="#meta_name#" maxlength="64" size="64"></td>
	</tr>
	
	<cfif pgfn EQ 'add'>
		<cfquery name="GetSkus" datasource="#application.DS#">
			SELECT meta_sku, created_datetime
			FROM #application.database#.product_meta
			WHERE meta_sku NOT LIKE 'GC%'
			Order by created_datetime DESC
			limit 5
		</cfquery>
		<cfquery dbtype="query" name="GetSkusReordered">
			SELECT meta_sku
			FROM GetSkus
			Order by created_datetime ASC
		</cfquery>
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif"> The last five SKUs used: <cfloop query="GetSkusReordered">#meta_sku# </cfloop> <span class="tooltip" title="This list is to help you pick the next SKU">?</span>
	</td>
	</tr>
		<cfquery name="GetSkus" datasource="#application.DS#">
			SELECT meta_sku, created_datetime
			FROM #application.database#.product_meta
			WHERE meta_sku LIKE 'GC%'
			Order by created_datetime DESC
			limit 5
		</cfquery>
		<cfquery dbtype="query" name="GetSkusReordered">
			SELECT meta_sku
			FROM GetSkus
			Order by created_datetime ASC
		</cfquery>
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif"> The last five GETCO SKUs used: <cfloop query="GetSkusReordered">#meta_sku# </cfloop> <span class="tooltip" title="GETCO set">?</span>
	</td>
	</tr>
		
	</cfif>
	
	<tr class="content">
	<td align="right" valign="top">ITC SKU (meta): </td>
	<td valign="top"><input type="text" name="meta_sku" value="#meta_sku#" maxlength="64" size="64"></td>
	</tr>
	
	<!--- <tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif"> The only symbols that require special codes are:
	<br>
	&nbsp;&nbsp;&nbsp;&middot;&nbsp;&trade;&nbsp;&nbsp;&nbsp;#HTMLEditFormat("&trade;")#<br>
	&nbsp;&nbsp;&nbsp;&middot;&nbsp;&reg;&nbsp;&nbsp;&nbsp;#HTMLEditFormat("&reg;")#<br>
	&nbsp;&nbsp;&nbsp;&middot;&nbsp;&deg; (degrees)&nbsp;&nbsp;&nbsp;#HTMLEditFormat("&deg;")#
	</td>
	</tr> --->
	
	<tr class="content">
	<td align="right" valign="top">Description: </td>
	<td valign="top"><textarea name="description" rows="15" cols="42">#description#</textarea></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Manufacturer's Logo: </td>
	<td valign="top">
		<select name="manuf_logo_ID">
			<option value=""<cfif manuf_logo_ID EQ ""> selected</cfif>>-- Select a Manufacturer --</option>
		<cfloop query="GetManufLogo">
			<option value="#getmanuflogo_ID#"<cfif manuf_logo_ID EQ getmanuflogo_ID> selected</cfif>>#manuf_name#</option>
		</cfloop>
		</select>

	</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Master Category: </td>
	<td valign="top">
		<cfquery name="GetMasterPV" datasource="#application.DS#">
			SELECT ID, productvalue
			FROM #application.database#.productvalue_master
			ORDER BY sortorder ASC 
		</cfquery>
		<select name="productvalue_master_ID" onChange="document.ProductMetaForm.productvalue.value='';">
			<option value=""<cfif productvalue_master_ID EQ ""> selected</cfif>>-- Select a Master Category --</option>
			<cfloop query="GetMasterPV">
				<option value="#GetMasterPV.ID#"<cfif productvalue_master_ID EQ GetMasterPV.ID> selected</cfif>>#GetMasterPV.productvalue#</option>
			</cfloop>
		</select>
	</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Product Value: </td>
	<td valign="top"><input type="text" name="productvalue" value="#productvalue#" maxlength="10" size="10"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Retail Price: </td>
	<td valign="top"><input type="text" name="retailvalue" value="#retailvalue#" maxlength="10" size="10"></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Never Show Inventory?: </td>
	<td valign="top">
		<select name="never_show_inventory">
			<option value="1"<cfif never_show_inventory EQ 1> selected</cfif>>Yes
			<option value="0"<cfif never_show_inventory EQ 0> selected</cfif>>No
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Product Groups: </td>
	<td valign="top">
		<cfloop query="SelectGroups">
			<input type="checkbox" name="product_meta_group_ID" value="#ID#" <cfif Find(ID,thisProdsGroups)>checked</cfif>> #HTMLEditFormat(name)#<cfif SelectGroups.CurrentRow NEQ SelectGroups.RecordCount><br></cfif>
		</cfloop>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Upload Image: </td>
	<td valign="top"><input name="imagename_original" type="FILE" value="">
	<cfif imagename NEQ "">&nbsp;&nbsp;&nbsp;&nbsp;current image: <a href="../pics/products/#HTMLEditFormat(imagename)#" target="_blank">#htmleditformat(imagename_original)#</a></cfif></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Upload Thumbnail: </td>
	<td valign="top"><input name="thumbnailname_original" type="FILE" value="">
	<cfif thumbnailname NEQ "">&nbsp;&nbsp;&nbsp;&nbsp;current image: <a href="../pics/products/#HTMLEditFormat(thumbnailname)#" target="_blank">#htmleditformat(thumbnailname_original)#</a></cfif></td>
	</tr>
				
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
	<input type="hidden" name="gID" value="#gID#">
	<input type="hidden" name="gpgfn" value="#gpgfn#">
	
	<input type="hidden" name="meta_name_required" value="Please enter a product name.">
	<input type="hidden" name="description_required" value="Please enter a product description.">
		
	<input type="submit" name="submit" value="   Save Changes   " >
	
	</td>
	</tr>
		
	</table>
</form>
</cfoutput>
</cfif>
<!--- END pgfn ADD/EDIT --->

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->