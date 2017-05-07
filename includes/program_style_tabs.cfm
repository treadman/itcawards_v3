<style type="text/css"> 
td, body, .reg, button, input, select, option, textarea {font-family:Verdana, Arial, Helvetica, sans-serif; font-size:8pt; color:#000000; font-weight:normal}


<cfoutput>

a {font-family:Verdana, Arial, Helvetica, sans-serif; font-size:8pt;color:###bg_active#;text-decoration:underline}
a:hover {font-family:Verdana, Arial, Helvetica, sans-serif; font-size:8pt;color:###bg_active#;text-decoration:none}

FORM {margin : 0px 0px 0px 0px}

.main_div_auto_margin { width: 980px; margin: 0 auto; }
.main_div { width: 980px;}
.main_menu {color:##FFFFFF; font-size:14px; font-weight:bold; background-color:##58585a; height:35px; cursor:pointer; padding-left:20px;}
.main_menu_selected {color:##FFFFFF; font-size:14px; font-weight:bold; background-color:##679147; height:35px; padding-left:20px;}
.main_menu_bottom {color:##FFFFFF; background-color:##679147; height:5px;}

.alert {font-weight:bold;color:##cb0400}
.message {font-weight:bold;color:##ff6600}
.sub {color:##666666}

.welcome {font-family:Verdana, Arial, Helvetica, sans-serif;font-weight:bold;font-size:12pt}
.welcome_instructions {background-color:###bg_active#;color:###text_active#}
.address_button {background-color:##E0E0E0;}

.main_instructions {color:###bg_active#;font-weight:bold}
.main_paging_active {color:###bg_active#;font-weight:bold;cursor:pointer}
.main_paging_selected {color:###bg_selected#;font-weight:bold}
.main_paging_number {color:##000000;font-weight:bold;font-size:10pt}

.main_cart_number {color:###bg_active#;font-weight:bold;font-size:10pt}

.filters {color:###bg_active#;font-weight:bold; text-decoration:none;}

.active_button {padding:20px 22px 20px 22px; background-color:###bg_active#;color:###text_active#;cursor:pointer;font-weight:bold;font-size:14px;}
.selected_button {padding:20px 22px 20px 22px; background-color:###bg_selected#;color:###text_selected#;cursor:pointer;font-weight:bold;font-size:14px;}

.active_product_button {background-color:###bg_active#;color:###text_active#;cursor:pointer;font-weight:bold;font-size:10px;}
.selected_product_button {background-color:###bg_selected#;color:###text_selected#;cursor:pointer;font-weight:bold;font-size:10px;}

.active_view {background-color:###bg_active#;color:###text_active#;font-weight:bold;cursor:pointer}
.selected_view {background-color:###bg_selected#;color:###text_selected#;font-weight:bold;cursor:pointer}

.active_cell {background-color:###bg_active#;color:###text_active#;font-weight:bold;}
.selected_cell {background-color:###bg_selected#;color:###text_selected#;font-weight:bold;}

<cfset border_line = bg_active>
<!--- padding:3px 7px 3px 7px --->
.active_group {
	padding:3px 10px 3px 10px;
	border-bottom: 1px solid ###border_line#;
	border-right:1px solid ##FFFFFF;
	border-left:1px solid ###border_line#;
	border-top:1px solid ##FFFFFF;
	background-color:###bg_active#;
	color:###text_active#;
	cursor:pointer;
	font-weight:bold;
	font-size:12px;
}
.selected_group {
	padding:3px 10px 3px 10px;
	border-bottom: 1px solid ##FFFFFF;
	border-right:1px solid ###border_line#;
	border-left:1px solid ###border_line#;
	border-top:1px solid ###border_line#;
	background-color:###bg_selected#;
	color:###text_selected#;
	cursor:pointer;
	font-weight: bold;
	font-size:12px;
}
.active_product_tab {
	padding:3px 10px 3px 10px;
	background-color:###bg_active#;
	color:###text_active#;
	cursor:pointer;
	font-weight:bold;
	font-size:12px;
}
.selected_product_tab {
	padding:3px 10px 3px 10px;
	background-color:###bg_selected#;
	color:###text_selected#;
	cursor:pointer;
	font-weight: bold;
	font-size:12px;
}

.main_panel_border {height:700px; padding: 0px 0px 0px 20px; border-left:1px solid ###border_line#; border-right:1px solid ###border_line#; border-bottom:1px solid ###border_line#;}
.main_panel {height:700px; padding: 0px 0px 0px 20px;}

.active_msg {background-color:###bg_selected#;color:###text_active#;font-weight:bold}
.selected_msg {background-color:###bg_selected#;color:###text_selected#;font-weight:bold}
.warning_msg {color:###bg_warning#;font-weight:bold}

.cart_cell {border:1px solid ###bg_active#}
.survey_box {border:1px solid ###bg_active#}

.checkout_off {height:34px; border:1px solid ###bg_active# ; background-color:###text_selected#;color:###bg_active#;cursor:pointer;font-weight:normal;font-size:8pt}
.checkout_over {height:34px; border:1px solid ###bg_active#;background-color:###bg_selected#;color:###bg_active#;cursor:pointer;font-weight: normal;font-size:8pt}

.product_name {font-family:Verdana, Arial, Helvetica, sans-serif; background-color:###bg_selected#;color:###text_selected#;font-weight:bold;font-size:12pt;padding:5px}
.product_select {border:1px solid ###bg_active#;padding:10px}
.product_description {}
.product_instructions {color:###bg_active#}
.product_value {color:###bg_active#; font-size:8pt; text-align:center;}
.product_thumb_name {font-weight:bold; font-size:11px; text-align:center;}

.main_login  {font-family:Verdana, Arial, Helvetica, sans-serif; font-size:10pt; color:###bg_active#}
</cfoutput>
</style>
