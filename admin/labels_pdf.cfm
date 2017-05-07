<cfsetting enablecfoutputonly="true">
<cfparam name="xS" default="program">
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">
<cfparam name="only_unfulfilled" default="false">
<cfparam name="addr1" default="0">
<cfparam name="dept" default="0">

<!--- param a/e form fields --->
<cfparam name="status" default="">	
<cfparam name="x_date" default="">
	<cfif this_from_date NEQ "" AND IsDate(this_from_date)>
		<cfset xFD = FLGen_DateTimeToMySQL(this_from_date,'startofday')>
	</cfif>
	<cfif this_to_date NEQ "" AND IsDate(this_to_date)>
		<cfset xTD = FLGen_DateTimeToMySQL(this_to_date,'endofday')>
	</cfif>
	<cfif xFD NEQ "">
		<cfset x_date =  RemoveChars(Insert(',', Insert(',', xFD, 6),4),11,16)>
		<cfset this_from_date = ListGetAt(x_date,2) & '/' & ListGetAt(x_date,3) & '/' & ListGetAt(x_date,1)>
	</cfif>
	<cfif xTD NEQ "">
		<cfset x_date =  RemoveChars(Insert(',', Insert(',', xTD, 6),4),11,16)>
		<cfset this_to_date = ListGetAt(x_date,2) & '/' & ListGetAt(x_date,3) & '/' & ListGetAt(x_date,1)>
	</cfif>
		<!--- run query --->
		<!--- CASE WHEN oi.snap_ship_address1 IS NULL OR oi.snap_ship_address1 = ''
					THEN u.ship_address1
					ELSE oi.snap_ship_address1
					END,'' --->
		<cfquery name="SelectList" datasource="#application.DS#">
			SELECT
			IFNULL(
				CASE WHEN u.ship_address1 IS NULL OR u.ship_address1 = ''
					THEN oi.snap_ship_address1
					ELSE u.ship_address1
					END,''
			) AS final_address1,
				u.department,
				pg.company_name,
				pg.program_name,
				oi.ID AS order_ID,
				oi.order_number,
				Date_Format(oi.created_datetime,'%c/%d/%Y') AS created_date,
				CONCAT(oi.snap_fname,' ',oi.snap_lname) AS users_name,
				i.snap_sku, i.snap_meta_name, i.snap_description, i.snap_productvalue, i.quantity, i.snap_options, i.snap_is_dropshipped, 
				u.fname, u.lname,
				u.ship_address1, u.ship_address2, u.ship_city, u.ship_state, u.ship_zip,
				oi.snap_ship_address1, oi.snap_ship_address2, oi.snap_ship_city, oi.snap_ship_state, oi.snap_ship_zip

			FROM #application.database#.order_info oi
			INNER JOIN #application.database#.program_user u ON u.ID = oi.created_user_ID 
			INNER JOIN #application.database#.program pg ON oi.program_ID = pg.ID

			LEFT JOIN #application.database#.inventory i ON i.order_ID = oi.ID 
			WHERE oi.is_valid = 1 
	
			<cfif LEN(xT) GT 0>
				AND (oi.order_number LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> 
				OR oi.snap_fname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> 
				OR oi.snap_lname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">) 
			</cfif>
	
			<cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>
				AND oi.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			</cfif>
	
			<cfif this_from_date NEQ "">
				AND oi.created_datetime >= <cfqueryparam value="#xFD#">
			</cfif>
	
			<cfif this_to_date NEQ "">
				AND oi.created_datetime <= <cfqueryparam value="#xTD#">
			</cfif>
	
			<cfif only_unfulfilled>
				AND oi.is_all_shipped = 0
			</cfif>
	
			<cfif dept eq "99">
				AND (u.department = '' OR u.department IS NULL)
			<cfelseif dept neq "" and dept neq "0">
				AND u.department = <cfqueryparam cfsqltype="cf_sql_varchar" value="#dept#">
			</cfif>
	
			<cfif addr1 eq "99">
				HAVING final_address1 = ''
			<cfelseif addr1 neq "" and addr1 neq "0">
				HAVING final_address1 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#addr1#">
			</cfif>
			ORDER BY final_address1, u.department, u.lname
		</cfquery>
		<!--- set the start/end/max display row numbers --->
		<cfparam name="OnPage" default="1">
		<cfset MaxRows_SelectList="50">
		<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
		<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
		<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	<!--- </cfif> --->
	<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0>

	<cfset filename = "labels.pdf">
	
<cfcontent type="application/pdf">
<cfheader name="Content-Disposition" value="attachment;filename=""#filename#""" charset="utf-8" > 

<cfdocument format="PDF" marginTop=".5" marginLeft="1.12" marginRight="0" marginBottom="0">
<cfoutput>
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Labels</title>
	<style>
		body { font-family: Verdana,Arial,Helvetica; }
	</style>
</head>
<body>
</cfoutput>
	
		<cfset rmax = 2>
		<cfset cmax = 5>
		<cfset r=1>
		<cfset c=1>
			<cfoutput query="SelectList">
				<cfset this_department = SelectList.department>
				<cfset this_firstname = SelectList.fname> 
				<cfset this_lastname = SelectList.lname>
				<cfset this_address1 = SelectList.ship_address1>
				<cfif this_address1 eq ''>
					<cfset this_address1 = SelectList.snap_ship_address1>
				</cfif>
				<cfset this_address2 = SelectList.ship_address2>
				<cfif this_address2 eq ''>
					<cfset this_address2 = SelectList.snap_ship_address2>
				</cfif>
				<cfset this_city = SelectList.snap_ship_city>
				<cfif this_city eq ''>
					<cfset this_city = SelectList.ship_city>
				</cfif>
				<cfset this_state = SelectList.snap_ship_state>
				<cfif this_state eq ''>
					<cfset this_state = SelectList.ship_state>
				</cfif>
				<cfset this_zip = SelectList.snap_ship_zip>
				<cfif this_zip eq ''>
					<cfset this_zip = SelectList.ship_zip>
				</cfif>
				<cfset doit = true>
				<cfif doit>
				<cfif r gt rmax>
					</tr>
					<cfset r=1>
					<cfset c=c+1>
				</cfif>
				<cfif c gt cmax>
					</table>
					<cfdocumentitem type="pagebreak"></cfdocumentitem>
					<cfset c=1>
				</cfif>
				<cfif c eq 1 and r eq 1>
					<table cellpadding="0" cellspacing="0" border="0">
				</cfif>
				<cfif r eq 1>
					<tr>
				</cfif>
				<cfset h = 200>
				<cfif c eq 5>
					<cfset h = 100>
				</cfif>
				<!---<cfset this_name = Replace(SelectList.snap_meta_name,'[Color: ','')>---> 
				<cfset this_options = Replace(Replace(Replace(SelectList.snap_options,'[Color:',''),'[Size:',' - '),']','','all' )>
				<!--- [Size: 42]  [Color: Black]--->
				<!---<cfset this_desc = Replace(SelectList.snap_meta_name,"Championship","")>
				<cfset this_desc = Replace(this_desc,"Advantage","")>--->
				<td>
					<div style="height:#h#px; width:305px; font-size:16px;">
					<span style="font-size:20px;">#this_firstname# #this_lastname#</span><br>
					#this_department#<br>
					<cfif trim(this_address1) NEQ ""> 
						#this_address1#<br>
					</cfif>
					<b>
					<!---<cfif ListLen(SelectList.snap_meta_name," ") GT 1>
						#ListGetAt(SelectList.snap_meta_name,1," ")# #ListGetAt(SelectList.snap_meta_name,2," ")#
					<cfelse>--->
						#SelectList.snap_meta_name#
						<!---#this_desc#--->
					<!---</cfif>--->
					</b><br>
					#this_options#<br>
					</div>
				</td>
				<!---<cfif r eq 1>
					<td>
						
					</td>
				</cfif>--->
				<cfset r=r+1>
				</cfif>
			</cfoutput>
		<cfoutput>
        	</body>
			</html>
        </cfoutput>
		</cfdocument>
	<cfelse>
		<cfoutput>No orders match your selections.
		<br><br>	
			<button onclick="goBack()">Go Back</button>

<script>
function goBack() {
    window.history.back();
}
</script>
		</cfoutput>
	</cfif>
