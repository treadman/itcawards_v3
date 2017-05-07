<cfsetting showdebugoutput="no">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000008,true)>

<!--- Get the products from the import file --->
<cfquery name="products" datasource="#application.DS#">
	SELECT ID, manufacturer_ID, sku, description, comment, image, thumb, logo, price, weight
	FROM #application.database#.getco_product
</cfquery>

<cfloop query="products">
	<cfset thisProductID = products.ID>
	<cfoutput>#products.description#</cfoutput>:<br>&nbsp;&nbsp;
	<!--- Get the options from for the product --->
	<cfquery name="Getoptions" datasource="#application.DS#">
		SELECT code, choice, type
		FROM #application.database#.getco_options
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisProductID#" maxlength="10">
	</cfquery>
	<!--- Create a product_meta record --->
	<cfquery name="InsertProductMeta" datasource="#application.DS#">
		INSERT INTO #application.database#.product_meta
			(meta_name, meta_sku, description, imagename, imagename_original, thumbnailname, thumbnailname_original, product_set_ID, productvalue, created_user_ID, created_datetime)
		VALUES (
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left(products.description,64)#" maxlength="64">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left(products.sku,64)#" maxlength="64">,
			<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#products.comment#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left(products.image,25)#" maxlength="25">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left(products.image,25)#" maxlength="25">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left(products.thumb,30)#" maxlength="30">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left(products.thumb,30)#" maxlength="30">,
			<cfqueryparam cfsqltype="cf_sql_integer" value="2">,
			<cfqueryparam cfsqltype="cf_sql_integer" value="100">,
			<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
			'#FLGen_DateTimeToMySQL()#')
	</cfquery>
	<cfquery datasource="#application.DS#" name="getProductMetaID">
		SELECT Max(ID) As MaxID FROM #application.database#.product_meta
	</cfquery>
	[product_meta]
	<cfset thisProductMetaID = getProductMetaID.MaxID>
	<cfif Getoptions.recordcount EQ 0>
		<!--- If there are no options, simply create a product record. --->
		<cfquery name="InsertProduct" datasource="#application.DS#">
			INSERT INTO #application.database#.product
				(sku, product_meta_ID, is_active, created_user_ID, created_datetime)
			VALUES (
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#Left(products.sku,64)#" maxlength="64">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#thisProductMetaID#" maxlength="10">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="1">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
				'#FLGen_DateTimeToMySQL()#')
		</cfquery>
		[no option product]
	<cfelse>
		<!--- If there are options, loop over each option and create things --->
		<cfset thisCatSortOrder = 1>
		<cfset thisChoiceSortOrder = 1>
		<cfloop query="Getoptions">
			<cfset thisCategoryName = Left(Getoptions.type,30)>
			<cfset thisChoiceName = Left(Getoptions.choice,30)>
			<cfset thisSku = Getoptions.code>
			<!--- Find the category if already created --->
			<cfquery name="getCategory" datasource="#application.DS#">
				SELECT ID
				FROM #application.database#.product_meta_option_category
				WHERE product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisProductMetaID#" maxlength="10">
				AND category_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#thisCategoryName#" maxlength="30">
			</cfquery>
			<cfif getCategory.recordcount EQ 1>
				<cfset thisCategoryID = getCategory.ID>
				[cat found]
			<cfelseif getCategory.recordcount EQ 0>
				<!--- If not already created, insert it --->
				<cfquery name="InsertCategory" datasource="#application.DS#">
					INSERT INTO #application.database#.product_meta_option_category
						(product_meta_ID, category_name, sortorder, created_user_ID, created_datetime)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#thisProductMetaID#" maxlength="10">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisCategoryName#" maxlength="30">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#thisCatSortOrder#" maxlength="3">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#')
				</cfquery>
				<cfquery datasource="#application.DS#" name="getCategoryID">
					SELECT Max(ID) As MaxID FROM #application.database#.product_meta_option_category
				</cfquery>
				<cfset thisCategoryID = getCategoryID.MaxID>
				<cfset thisCatSortOrder = thisCatSortOrder + 1>
				[create cat]
			<cfelse>
				<!--- Shouldn't happen, but whatever --->
				<cfset thisCategoryID = getCategory.ID>
				<cfdump var="#getCategory#">
			</cfif>
			<!--- Create an option --->
			<cfquery name="InsertOption" datasource="#application.DS#">
				INSERT INTO #application.database#.product_meta_option
					(product_meta_option_category_ID, option_name, sortorder, created_user_ID, created_datetime)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#thisCategoryID#" maxlength="10">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisChoiceName#" maxlength="30">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#thisChoiceSortOrder#" maxlength="3">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
					'#FLGen_DateTimeToMySQL()#')
			</cfquery>
			<cfquery datasource="#application.DS#" name="getChoiceID">
				SELECT Max(ID) As MaxID FROM #application.database#.product_meta_option
			</cfquery>
			<cfset thisChoiceID = getChoiceID.MaxID>
			<cfset thisChoiceSortOrder = thisChoiceSortOrder + 1>
			[option]
			<!--- Create a product --->
			<cfquery name="InsertProduct" datasource="#application.DS#">
				INSERT INTO #application.database#.product
					(sku, product_meta_ID, is_active, created_user_ID, created_datetime)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisSku#" maxlength="64">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#thisProductMetaID#" maxlength="10">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="1">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
					'#FLGen_DateTimeToMySQL()#')
			</cfquery>
			<cfquery datasource="#application.DS#" name="getProductID">
				SELECT Max(ID) As MaxID FROM #application.database#.product
			</cfquery>
			<cfset thisProductID = getProductID.MaxID>
			[product]
			<!--- xref the product and option --->
			<cfquery name="InsertProductOption" datasource="#application.DS#">
				INSERT INTO #application.database#.product_option
					(product_ID, product_meta_option_ID, created_user_ID, created_datetime)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#thisProductID#" maxlength="10">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#thisChoiceID#" maxlength="10">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
					'#FLGen_DateTimeToMySQL()#')
			</cfquery>
			[link]<br>
		</cfloop>
		<br>
	</cfif>
	<br><br>
</cfloop>
DONE!
	