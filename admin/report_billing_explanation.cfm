<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000037-1000000076",true)>

<cfinclude template="includes/header_lite.cfm">

<span class="printhead">Explanation of Billing Report</span>
<br>
<br>
<br>
<span class="printlabel">Display Zero Point Users</span>
<br>
<span class="printtext">This report will display users who have used all of their points.  Their last order will be between the entered From and To dates.</span>
<br>
<br>
<span class="printlabel">Display Partial Point Users</span>
<br>
<span class="printtext">This report will display users who have used points, but not all of them.  Their last order will be between the entered From and To dates. <span class="alert">This means that users who partially used points who made their orders before or after the date range will not appear.</span></span>
<br>
<br>
<span class="printlabel">Display Users With Point Balance</span>
<br>
<span class="printtext">This report will display users who have points left to be used.</span>
<br>
<br>
<span class="printlabel">Display Order Transactions</span>
<br>
<span class="printtext">This report will display users who have made orders between the entered From and To dates.</span>

</p>
<cfinclude template="includes/footer.cfm">
