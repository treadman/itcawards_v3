<cfset FLGen_AuthenticateAdmin()>

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="xW" default="">
<cfparam name="xA" default="">
<cfparam name="OnPage" default="">
<cfparam name="meta_ID" default="">
<cfparam name="set_ID" default="">
<cfparam name="pgfn" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('meta_ID') AND meta_ID IS NOT "" AND IsDefined('pgfn') AND pgfn IS NOT "">

	<!--- find meta sku --->
	<cfquery name="FindOptionCategories" datasource="#application.DS#">
		SELECT meta_sku
		FROM #Application.database#.product_meta
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
	</cfquery>
	<cfset meta_sku = FindOptionCategories.meta_sku>

	<!--- find the meta option categories --->
	<cfquery name="FindOptionCategories" datasource="#application.DS#">
		SELECT ID AS cat_ID
		FROM #Application.database#.product_meta_option_category 
		WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
		ORDER BY sortorder
	</cfquery>
	<cfset category_list = ValueList(FindOptionCategories.cat_ID)>
	<cfset CatArray = ListToArray(category_list)>
	<cfset this_many_option_categories = FindOptionCategories.RecordCount>
	
	<!--- <cfoutput>this_many_option_categories: #this_many_option_categories#<br><br></cfoutput> --->

	<!--- there are too many individual products to make --->
	<cfif this_many_option_categories GT 3>
		<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&alert_error=The%20individual%20products%20could%20not%20be%20made.%20Please%20call%20Tracy.[message3]">
	</cfif>
	
	<!--- find the meta option IDs for each category --->
	<cfset counter = 0>
	<cfset this_many_individual = 1>
	<cfloop list="#category_list#" index="thisone">
		<cfset counter = IncrementValue(counter)>
		<cfset option_list_name = "option_list#counter#">
		<cfset option_array_name = "OptionArray_#counter#">
		<cfquery name="FindOptions" datasource="#application.DS#">
			SELECT ID AS opt_ID
			FROM #Application.database#.product_meta_option 
			WHERE product_meta_option_category_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisone#" maxlength="10">
			ORDER BY sortorder
		</cfquery>
		<cfset "#option_list_name#" = ValueList(FindOptions.opt_ID)>
		<cfset "#option_array_name#" = ListToArray("#Evaluate(option_list_name)#")>
		<cfset this_many_individual = this_many_individual * FindOptions.RecordCount>
		 <!--- <cfoutput>#option_list_name#: #Evaluate(option_list_name)#<br> array name: #option_array_name#<br><cfdump var="#Evaluate(option_array_name)#"><br></cfoutput> ---> 
		
	</cfloop>
	
	<!--- there are too many individual products to make --->
	<cfif this_many_individual GT 104>
		<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&alert_error=The%20individual%20products%20could%20not%20be%20made.%20Please%20call%20Tracy.[message1]">
	</cfif>

	<!--- <cfoutput>[#this_many_individual#]<br></cfoutput> --->

	<!--- create alpha array --->
	<cfset AlphaArray = ArrayNew(1)>
	<cfloop index="LoopCount" from="1" to="104">
		<cfif LoopCount LTE 26>
			<cfset use_this_letter = CHR(LoopCount + 96)>
		<cfelseif LoopCount LTE 52>
			<cfset use_this_letter = CHR((LoopCount - 26) + 96) & CHR((LoopCount - 26) + 96)>
		<cfelseif LoopCount LTE 78>
			<cfset use_this_letter = CHR((LoopCount - 52) + 96) & CHR((LoopCount - 52) + 96) & CHR((LoopCount - 52) + 96)>
		<cfelseif LoopCount LTE 104>
			<cfset use_this_letter = CHR((LoopCount - 78) + 96) & CHR((LoopCount - 78) + 96) & CHR((LoopCount - 78) + 96) & CHR((LoopCount - 78) + 96)>
		</cfif>
		<cfset AlphaArray[LoopCount] = use_this_letter>
	</cfloop>
	
	<!--- <cfoutput><cfdump var="#AlphaArray#"><br></cfoutput> --->

	<!--- loop through the categories and create each individual --->
	<cfset IndvArray = ArrayNew(1)>
	<cfloop from="1" to="#this_many_individual#" index="i">
		<cflock name="productLock" timeout="10">
			<cftransaction>
				<cfset this_indv_sku = "#meta_sku##AlphaArray[i]#">
				<cfquery name="InsertIndividual" datasource="#application.DS#">
					INSERT INTO #Application.database#.product
						(created_user_ID, created_datetime, product_meta_ID, sku, sortorder, is_dropshipped, is_active, is_discontinued)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">, 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#this_indv_sku#" maxlength="60">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#i#" maxlength="5">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pgfn#" maxlength="1">, 
						0,
						0)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #Application.database#.product
				</cfquery>
				<cfset IndvArray[i] = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfloop>
	
	<!--- <cfoutput><cfdump var="#IndvArray#"><br></cfoutput> --->

	<!--- dyanamic loop function --->
	<cfif this_many_option_categories EQ 1>

		<cfset counter = 0>
		<cfloop from="1" to="#ArrayLen(OptionArray_1)#" index="a">
			<cfset counter = IncrementValue(counter)>

			<cfquery name="InsertIndividual_1" datasource="#application.DS#">
				INSERT INTO #application.database#.product_option
				(created_user_ID, created_datetime, product_ID, product_meta_option_ID)
				VALUES
				(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
					'#FLGen_DateTimeToMySQL()#', 
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#IndvArray[counter]#" maxlength="10">, 
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#OptionArray_1[a]#" maxlength="10">)
			</cfquery>
		
		</cfloop>	
		 
		<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#&alert_msg=The%20individual%20products%20were%20created.">
	
	<cfelseif this_many_option_categories EQ 2>

		<cfset counter = 0>
		<cfloop from="1" to="#ArrayLen(OptionArray_1)#" index="a">
			<cfloop from="1" to="#ArrayLen(OptionArray_2)#" index="b">
				<cfset counter = IncrementValue(counter)>

				<cfquery name="InsertIndividual_1" datasource="#application.DS#">
					INSERT INTO #application.database#.product_option
					(created_user_ID, created_datetime, product_ID, product_meta_option_ID)
					VALUES
					(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#IndvArray[counter]#" maxlength="10">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#OptionArray_1[a]#" maxlength="10">)
				</cfquery>
				<cfquery name="InsertIndividual_2" datasource="#application.DS#">
					INSERT INTO #application.database#.product_option
					(created_user_ID, created_datetime, product_ID, product_meta_option_ID)
					VALUES
					(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#IndvArray[counter]#" maxlength="10">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#OptionArray_2[b]#" maxlength="10">)
				</cfquery>
		
			</cfloop>
		</cfloop>	
		 
		<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#&alert_msg=The%20individual%20products%20were%20created.">

	
	<cfelseif this_many_option_categories EQ 3>

		<cfset counter = 0>
		<cfloop from="1" to="#ArrayLen(OptionArray_1)#" index="a">
			<cfloop from="1" to="#ArrayLen(OptionArray_2)#" index="b">
				<cfloop from="1" to="#ArrayLen(OptionArray_3)#" index="c">
					<cfset counter = IncrementValue(counter)>

					<cfquery name="InsertIndividual_1" datasource="#application.DS#">
						INSERT INTO #application.database#.product_option
						(created_user_ID, created_datetime, product_ID, product_meta_option_ID)
						VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
							'#FLGen_DateTimeToMySQL()#', 
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#IndvArray[counter]#" maxlength="10">, 
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#OptionArray_1[a]#" maxlength="10">)
					</cfquery>
					<cfquery name="InsertIndividual_2" datasource="#application.DS#">
						INSERT INTO #application.database#.product_option
						(created_user_ID, created_datetime, product_ID, product_meta_option_ID)
						VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
							'#FLGen_DateTimeToMySQL()#', 
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#IndvArray[counter]#" maxlength="10">, 
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#OptionArray_2[b]#" maxlength="10">)
					</cfquery>
					<cfquery name="InsertIndividual_3" datasource="#application.DS#">
						INSERT INTO #application.database#.product_option
						(created_user_ID, created_datetime, product_ID, product_meta_option_ID)
						VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
							'#FLGen_DateTimeToMySQL()#', 
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#IndvArray[counter]#" maxlength="10">, 
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#OptionArray_3[c]#" maxlength="10">)
					</cfquery>
		
	 			</cfloop>
			</cfloop>
		</cfloop>	 
		
		<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#&alert_msg=The%20individual%20products%20were%20created.">
	
	</cfif>
	
<cfelse>

	<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#&alert_error=The%20individual%20products%20could%20not%20be%20made.%20Please%20call%20Tracy.[message2]">

</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->