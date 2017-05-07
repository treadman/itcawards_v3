function DisplayAlert(id,left,top) {
	document.getElementById(id).style.left=left+'px';
	document.getElementById(id).style.top=top+'px';
	document.getElementById(id).style.display='block';
}
var c=0;
var t;
var timer_is_on=0;
function timedCount() {
	c=c+1;
	t=setTimeout("timedCount()",1000);
	if (c > 5) {
		stopCount();
		document.getElementById('AlertBox').style.display='none';
	}
}
function doTimer() {
	if (!timer_is_on) {
		timer_is_on=1;
		timedCount();
	}
}
function stopCount() {
	clearTimeout(t);
	timer_is_on=0;
}
