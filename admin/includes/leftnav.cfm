
<!-- ----------------- -->
<!-- Start of left nav -->
<!-- ----------------- -->

<cfif isDefined("request.program.is_active") AND NOT request.program.is_active>
	<div style="text-align:center; font-weight:bold;">
		PROGRAM NOT ACTIVE
	</div>
</cfif>
<cfif isDefined("request.program.admin_logo") AND request.program.admin_logo NEQ "">
	<div align="center" style="background-color:##FFFFFF; padding:20px 5px 20px 5px;">
		<img src="../pics/program/<cfoutput>#request.program.admin_logo#</cfoutput>"<!---  width="170" height="43" --->>
	</div>
<cfelse>
	<br>
</cfif>


&nbsp;&nbsp;&nbsp;&nbsp;
<cfif leftnavon EQ 'index'>
	<b>Home &rsaquo;</b>
<cfelse>
	<a href="index.cfm">Home</a>
</cfif>
<br />

<cfif FLGen_HasAdminAccess("1000000006-1000000007-1000000033")>

	<br />
	<span class="leftnavhead">A D M I N&nbsp;&nbsp;&nbsp;S Y S T E M</span>
	<br />
		
	<cfif FLGen_HasAdminAccess(1000000006)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'admin_users'>
				<b>Admin Users &rsaquo;</b>
			<cfelse>
				<a href="admin_user.cfm">Admin Users</a>
			</cfif>
		<br />
		
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000007)>
		
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'admin_access_levels'>
				<b>Admin Access Levels &rsaquo;</b>
			<cfelse>
				<a href="admin_access_level.cfm">Admin Access Levels</a>
			</cfif>
		<br />
	
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000033)>
		
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'adminaccessreport'>
				<b>Admin Access Report &rsaquo;</b>
			<cfelse>
				<a href="report_adminaccess.cfm">Admin Access Report</a>
			</cfif>
		<br />
	
	</cfif>

</cfif>

<cfif FLGen_HasAdminAccess("1000000008-1000000009-1000000010-1000000011-1000000012-1000000013-1000000015")>

	<br />
	<span class="leftnavhead">P R O D U C T S</span>
	<br />

	<cfif FLGen_HasAdminAccess(1000000008)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'products'>
				<b>Products &rsaquo;</b>
			<cfelse>
				<a href="product.cfm">Products</a>
			</cfif>
		<br />
		
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000015)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'master_categories'>
				<b>Master Categories &rsaquo;</b>
			<cfelse>
				<a href="master_categories.cfm">Master Categories</a>
			</cfif>
		<br />
		
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000009)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'productsortorder'>
				<b>Product Sort Order &rsaquo;</b>
			<cfelse>
				<a href="product_order.cfm">Product Sort Order</a>
			</cfif>
		<br />
		
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000010)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'groups'>
				<b>Product Groups &rsaquo;</b>
			<cfelse>
				<a href="product_groups.cfm">Product Groups</a>
			</cfif>
		<br />
		
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000011)>
		
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'manuflogos'>
				<b>Manufacturer Logos &rsaquo;</b>
			<cfelse>
				<a href="product_manuflogo.cfm">Manufacturer Logos</a>
			</cfif>
		<br />
		
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000012)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'vendors'>
				<b>Vendors &rsaquo;</b>
			<cfelse>
				<a href="vendor.cfm">Vendors</a>
			</cfif>
		<br />
		
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000013)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'inventory'>
				<b>Inventory &rsaquo;</b>
			<cfelse>
				<a href="inventory.cfm?p=n">Inventory</a>
			</cfif>
		<br />
	
	</cfif>

</cfif>

<cfif FLGen_HasAdminAccess("1000000014-1000000016-1000000020-1000000063-1000000065-1000000088-1000000111")>

	<br />
	<span class="leftnavhead">A W A R D&nbsp;&nbsp;&nbsp;P R O G R A M S</span>
	<br />


	<cfif FLGen_HasAdminAccess(1000000065)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'meta_program'>
				<b>Program Meta Info &rsaquo;</b>
			<cfelse>
				<a href="program_meta.cfm">Program Meta Info</a>
			</cfif>
		<br />
	
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000014)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'programs'>
				<b>Programs &rsaquo;</b>
			<cfelse>
				<a href="program.cfm">Programs</a>
			</cfif>
		<br />
	
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000088)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'image_upload'>
				<b>Image Upload &rsaquo;</b>
			<cfelse>
				<a href="image_upload.cfm">Image Upload</a>
			</cfif>
		<br />
	
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000020)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'program_user'>
				<b>Program Users &rsaquo;</b>
			<cfelse>
				<a href="program_user.cfm">Program Users</a>
			</cfif>
		<br />
	
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000063)>
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'program_product'>
				<b>Exclude Products &rsaquo;</b>
			<cfelse>
				<a href="program_product.cfm">Exclude Products</a>
			</cfif>
		<br />
	</cfif>
	
	<cfif FLGen_HasAdminAccess(1000000016)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'report_survey'>
				<b>Surveys &rsaquo;</b>
			<cfelse>
				<a href="report_survey.cfm">Surveys</a>
			</cfif>
		<br />
	
	</cfif>

	<cfif FLGen_HasAdminAccess(1000000111)>
	
		&nbsp;&nbsp;&nbsp;&nbsp;
			<cfif leftnavon EQ 'upload_points'>
				<b>Upload Points &rsaquo;</b>
			<cfelse>
				<a href="upload_points.cfm">Upload Points</a>
			</cfif>
		<br />
	
	</cfif>

</cfif>


<cfif FLGen_HasAdminAccess("1000000017-1000000115")>

	<br />
	<span class="leftnavhead">O R D E R S</span>
	<br />
	
	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'orders'>
			<b>Orders &rsaquo;</b>
		<cfelse>
			<a href="order.cfm">Orders</a>
		</cfif>
	<br />
	
	<cfif FLGen_HasAdminAccess(1000000115)>
	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'pending'>
			<b>Pending &rsaquo;</b>
		<cfelse>
			<a href="order_pending.cfm">Pending</a>
		</cfif>
	<br />
	</cfif>
	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'labels'>
			<b>Labels &rsaquo;</b>
		<cfelse>
			<a href="labels.cfm">Labels</a>
		</cfif>
	<br />
	
	
	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'report_fulfillment'>
			<b>Ship From ITC &rsaquo;</b>
		<cfelse>
			<a href="report_fulfillment.cfm">Ship From ITC</a>
		</cfif>
	<br />
	
	
	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'po_builder'>
			<b>PO Builder &rsaquo;</b>
		<cfelse>
			<a href="report_po.cfm">PO Builder</a>
		</cfif>
	<br />
	
	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'purchase_orders'>
			<b>Purchase Orders &rsaquo;</b>
		<cfelse>
			<a href="po_list.cfm">Purchase Orders</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess("1000000072-1000000073-1000000074")>

	<br />
	<span class="leftnavhead">E M A I L&nbsp;&nbsp;&nbsp;A L E R T S</span>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000072)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'email_alert_templates'>
			<b>Templates &rsaquo;</b>
		<cfelse>
			<a href="email_alert_templates.cfm">Templates</a>
		</cfif>
	<br />

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'email_alert_groups'>
			<b>Groups &rsaquo;</b>
		<cfelse>
			<a href="email_alert_groups.cfm">Groups</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000073)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'email_alert_send'>
			<b>Send Email Alert &rsaquo;</b>
		<cfelse>
			<a href="email_alert_send.cfm">Send Email Alert</a>
		</cfif>
	<br />

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'email_spreadsheet'>
			<b>Email to Spreadsheet &rsaquo;</b>
		<cfelse>
			<a href="email_spreadsheet.cfm">Email to Spreadsheet</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000074)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'email_alert_report'>
			<b>Email Alert Report &rsaquo;</b>
		<cfelse>
			<a href="email_alert_report.cfm">Email Alert Report</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess("1000000035-1000000036-1000000037-1000000038-1000000039-1000000070-1000000110-1000000084-1000000087-1000000112")>

	<br />
	<span class="leftnavhead">R E P O R T S</span>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000036)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'program_user_points_report'>
			<b>User Points &rsaquo;</b>
		<cfelse>
			<a href="program_user_points_report.cfm">User Points</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000112)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'report_1099'>
			<b>1099 Report &rsaquo;</b>
		<cfelse>
			<a href="report_1099.cfm">1099 Report</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000035)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'ordertotalreport'>
			<b>Order Totals &rsaquo;</b>
		<cfelse>
			<a href="report_ordertotal.cfm">Order Totals</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000036)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'winprodreport'>
			<b>User/Product &rsaquo;</b>
		<cfelse>
			<a href="report_winprod.cfm">User/Product</a>
		</cfif>
	<br />
	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'registration_report'>
			<b>User Registrations &rsaquo;</b>
		<cfelse>
			<a href="report_registrations.cfm">User Registrations</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000037)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'newbillingreport'>
			<b>New Billing &rsaquo;</b>
		<cfelse>
			<a href="report_bill_new.cfm">New Billing</a>
		</cfif>
	<br />

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'billingreport'>
			<b>Old Billing &rsaquo;</b>
		<cfelse>
			<a href="report_billing.cfm">Old Billing</a>
		</cfif>
	<br />

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'costcenterreport'>
			<b>Cost Center Billing &rsaquo;</b>
		<cfelse>
			<a href="report_cost_center.cfm">Cost Center Billing</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000039)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'orderquanreport'>
			<b>Order Quantity &rsaquo;</b>
		<cfelse>
			<a href="report_ordquantities.cfm">Order Quantity</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000084)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'shipquanreport'>
			<b>Shipped Quantity &rsaquo;</b>
		<cfelse>
			<a href="report_shipquantities.cfm">Shipped Quantity</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000087)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'fulfilledordersreport'>
			<b>Fulfilled Orders &rsaquo;</b>
		<cfelse>
			<a href="report_fulfilledorders.cfm">Fulfilled Orders</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000038)>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'poquantities'>
			<b>PO Quantity &rsaquo;</b>
		<cfelse>
			<a href="report_poquantities.cfm">PO Quantity</a>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess(1000000070)>

	<cfquery name="ReportSelect" datasource="#application.DS#">
		SELECT COUNT(*) AS this_many 
		FROM #application.database#.program_user
		WHERE entered_by_program_admin = 1	
	</cfquery>

	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'verifyusers'>
			<b>Users To Verify &rsaquo;</b>
		<cfelse>
			<a href="report_verifyusers.cfm">Users To Verify</a><cfif ReportSelect.this_many GTE 1> <span class="alert">[<cfoutput>#ReportSelect.this_many#</cfoutput>]</span></cfif>
		</cfif>
	<br />

</cfif>

<cfif FLGen_HasAdminAccess("1000000067-1000000075-1000000076-1000000083-1000000089")>
	<br />
	<span class="leftnavhead">P R O G R A M&nbsp;&nbsp;&nbsp;A D M I N</span>
	<br />
	
	<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
		<cfif request.is_admin>
			<br /><div align="center" class="sub">Select a program to view the program admin section.</div>
		<cfelse>
			<cfabort showerror="This should not happen.  They are not an admin and have no program selected.  See the program admin section of leftnav.cfm">
		</cfif>

	<cfelse>
	
		<cfif FLGen_HasAdminAccess(1000000067)>
		&nbsp;&nbsp;&nbsp;&nbsp;
				<cfif leftnavon EQ 'programadminusers'>
					<b>Program Users &rsaquo;</b>
				<cfelse>
					<a href="program_admin_user.cfm">Program Users</a>
				</cfif>
		<br />
		</cfif>

		<cfif FLGen_HasAdminAccess(1000000075)>
		
			&nbsp;&nbsp;&nbsp;&nbsp;
				<cfif leftnavon EQ 'email_alert_send'>
					<b>Send Email Alert &rsaquo;</b>
				<cfelse>
					<a href="email_alert_send.cfm">Send Email Alert</a>
				</cfif>
			<br />
		
		</cfif>
	
		<cfif FLGen_HasAdminAccess(1000000076)>
		&nbsp;&nbsp;&nbsp;&nbsp;
				<cfif leftnavon EQ 'newbillingreport'>
					<b>Billing Report &rsaquo;</b>
				<cfelse>
					<a href="report_bill_new.cfm">Billing Report</a>
				</cfif>
		<br />
	&nbsp;&nbsp;&nbsp;&nbsp;
		<cfif leftnavon EQ 'report_redeemed'>
			<b>Redeemed Report &rsaquo;</b>
		<cfelse>
			<a href="report_redeemed.cfm">Redeemed Report</a>
		</cfif>
	<br />
		</cfif>
	
		<cfif FLGen_HasAdminAccess(1000000083)>
		&nbsp;&nbsp;&nbsp;&nbsp;
				<cfif leftnavon EQ 'report_survey'>
					<b>Surveys &rsaquo;</b>
				<cfelse>
					<a href="report_survey.cfm">Surveys</a>
				</cfif>
		<br />
		</cfif>
	
		<cfif FLGen_HasAdminAccess(1000000089)>
		&nbsp;&nbsp;&nbsp;&nbsp;
				<cfif leftnavon EQ 'programadmin_additionalcontent'>
					<b>Additional Content &rsaquo;</b>
				<cfelse>
					<a href="program_admin_additional_content.cfm">Additional Content</a>
				</cfif>
		<br />
		</cfif>
	
	</cfif>
	
</cfif>

<br /><br /><br /><br /><br />

<!-- --------------- -->
<!-- End of left nav -->
<!-- --------------- -->
