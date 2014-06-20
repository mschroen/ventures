function elem(id) { return document.getElementById(id); }

function toggle(id, type) {
	if (!type ) type = 'block';
	var e = document.getElementById(id);
	e.style.display = e.style.display == type ? 'none' : type; }

function movetoc()
{
	var x = 0, y = 0;
	if( typeof( window.pageYOffset ) == 'number' ) {
		y = window.pageYOffset;
		x = window.pageXOffset;	}
	else if( document.body && ( document.body.scrollLeft || document.body.scrollTop ) ) {
		y = document.body.scrollTop;
		x = document.body.scrollLeft; }
	else if( document.documentElement && ( document.documentElement.scrollLeft || document.documentElement.scrollTop ) ) {
		y = document.documentElement.scrollTop;
		x = document.documentElement.scrollLeft; }
	document.getElementById('toc').style.top = (y+85)+"px";
}

function editcontent(id)
{
	var s = this;
	var req = false;
	var output = elem('contentedit_'+id);
	var status = elem('editcontent_'+id); status.innerHTML = '...';

	var file = IDS[id];

	if (window.XMLHttpRequest)     { s.req = new XMLHttpRequest(); }
	else if (window.ActiveXObject) { s.req = new ActiveXObject("Microsoft.XMLHTTP"); }

	s.req.open('POST', '/ventures/file.pl', true);
	s.req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	s.req.onreadystatechange = function() {
	
		if (s.req.readyState == 4)
		{
			output.innerHTML = s.req.responseText;
			status.innerHTML = '&#9998;';
			toggle('editcontent_'+id);
			toggle('savecontent_'+id);
			toggle('canceledit_'+id);
			toggle('content_'+id);
			toggle('contentedit_'+id);
			output.focus();
		}
		else { status.innerHTML = '...'; }}
  
	s.req.send('file='+file+'&read=1');
}

function canceledit(id)
{
	toggle('editcontent_'+id);
	toggle('savecontent_'+id);
	toggle('canceledit_'+id);
	toggle('contentedit_'+id);
	toggle('content_'+id);
}

function savecontent(id)
{
	var s = this;
	var req = false;
	var input = elem('contentedit_'+id).innerHTML;
	var output = elem('content_'+id);
	var status = elem('savecontent_'+id); status.innerHTML = '...';

	var file = IDS[id];

	if (window.XMLHttpRequest)     { s.req = new XMLHttpRequest(); }
	else if (window.ActiveXObject) { s.req = new ActiveXObject("Microsoft.XMLHTTP"); }

	s.req.open('POST', '/ventures/file.pl', true);
	s.req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	s.req.onreadystatechange = function() {
	
		if (s.req.readyState == 4)
		{
			output.innerHTML = s.req.responseText;
			MathJax.Hub.Queue(["Typeset",MathJax.Hub,'content_'+id]); //rerender
			status.innerHTML = 'Save';
			toggle('editcontent_'+id);
			toggle('savecontent_'+id);
			toggle('canceledit_'+id);
			toggle('contentedit_'+id);
			toggle('content_'+id);
		}
		else { status.innerHTML = '...'; }}
  
    s.req.send('file='+file+'&content='+encodeURIComponent(input));
}

// head edit

var HEADNAMES = new Array();

function rename(id)
{
	var e = elem('head_name_'+id); 
	HEADNAMES[id] = e.innerHTML;
	e.contentEditable = true;
	e.focus();
	toggle('head_edit_'+id, 'inline-block');
	toggle('head_save_'+id, 'inline-block');
}

function rename_cancel(id)
{
	var e = elem('head_name_'+id); 
	e.innerHTML = HEADNAMES[id];
	e.contentEditable = false;
	toggle('head_edit_'+id, 'inline-block');
	toggle('head_save_'+id, 'inline-block');
}

function savehead(id)
{
	var s = this;
	var req = false;
	var input = elem('head_name_'+id).innerHTML;
	var status = elem('head_edit_save_'+id); status.innerHTML = '...';

	var folder = IDS[id];

	if (window.XMLHttpRequest)     { s.req = new XMLHttpRequest(); }
	else if (window.ActiveXObject) { s.req = new ActiveXObject("Microsoft.XMLHTTP"); }

	s.req.open('POST', '/ventures/folder.pl', true);
	s.req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	s.req.onreadystatechange = function() {
	
		if (s.req.readyState == 4)
		{
			IDS[id] = s.req.responseText;
			elem('toc_name_'+id).innerHTML = input;
			status.innerHTML = 'Save';
			elem('head_name_'+id).contentEditable = false;
			toggle('head_edit_'+id, 'inline-block');
			toggle('head_save_'+id, 'inline-block');
		}
		else { status.innerHTML = '...'; }}
  
    s.req.send('folder='+folder+'&name='+encodeURIComponent(input));
}

function cut(id)
{
	var s = this;
	var req = false;
	var status = elem('head_edit_cut_'+id); status.innerHTML = '...';

	var folder = IDS[id];

	if (window.XMLHttpRequest)     { s.req = new XMLHttpRequest(); }
	else if (window.ActiveXObject) { s.req = new ActiveXObject("Microsoft.XMLHTTP"); }

	s.req.open('POST', '/ventures/folder.pl', true);
	s.req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	s.req.onreadystatechange = function() {
	
		if (s.req.readyState == 4)
		{
			elem('section_'+id).innerHTML = s.req.responseText;
			var tocitem = elem('toc_item_'+id); tocitem.parentNode.removeChild(tocitem);
		}
		else { status.innerHTML = '...'; }}
  
    s.req.send('folder='+folder+'&cut=1');
}

function remove(id)
{
	var s = this;
	var req = false;
	var status = elem('head_edit_delete_'+id); status.innerHTML = '...';

	var folder = IDS[id];

	if (window.XMLHttpRequest)     { s.req = new XMLHttpRequest(); }
	else if (window.ActiveXObject) { s.req = new ActiveXObject("Microsoft.XMLHTTP"); }

	s.req.open('POST', '/ventures/folder.pl', true);
	s.req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	s.req.onreadystatechange = function() {
	
		if (s.req.readyState == 4)
		{
			elem('section_'+id).innerHTML = s.req.responseText;
			var tocitem = elem('toc_item_'+id); tocitem.parentNode.removeChild(tocitem);
		}
		else { status.innerHTML = '...'; }}
  
    s.req.send('folder='+folder+'&delete=1');
}

function restore(id)
{
	var s = this;
	var req = false;
	var status = elem('head_edit_restore_'+id); status.innerHTML = '...';

	var folder = IDS[id];

	if (window.XMLHttpRequest)     { s.req = new XMLHttpRequest(); }
	else if (window.ActiveXObject) { s.req = new ActiveXObject("Microsoft.XMLHTTP"); }

	s.req.open('POST', '/ventures/add.pl', true);
	s.req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
	s.req.onreadystatechange = function() {
	
		if (s.req.readyState == 4)
		{
			window.location = s.req.responseText;
		}
		else { status.innerHTML = '...'; }}
  
    s.req.send('restore='+folder);
}

// add
var OLDAS = new Array();
var CLASSAS = new Array();

function addsection(id, ipos, dir)
{
	if (OLDAS[id])
	{
		var status = elem('addsection_'+id+'_'+ipos);
		status.innerHTML = OLDAS[id];
		status.childNodes[0].className = CLASSAS[id];
		OLDAS[id] = ''; CLASSAS[id] = '';
	}
	else
	{ 	var s = this;
		var req = false;
		var status = elem('addsection_'+id+'_'+ipos);
		OLDAS[id] = status.innerHTML; // cache button
		CLASSAS[id] = status.childNodes[0].className; // cache classes
		status.childNodes[0].className = status.childNodes[0].className + " addsection_active";
		status.childNodes[0].style.color = 'green';
		status.childNodes[0].innerHTML = '...';

		if (window.XMLHttpRequest)     { s.req = new XMLHttpRequest(); }
		else if (window.ActiveXObject) { s.req = new ActiveXObject("Microsoft.XMLHTTP"); }

		s.req.open('POST', '/ventures/add.pl', true);
		s.req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
		s.req.onreadystatechange = function() {
		
			if (s.req.readyState == 4)
			{
				status.innerHTML = OLDAS[id] + s.req.responseText;
				elem('addsection_input_'+id).focus();
			}
			else { status.childNodes[0].innerHTML = '...'; }}
	  
		s.req.send('menu='+id+'&ipos='+ipos+'&dir='+dir);
	}
}


document.getElementById("addventure").value = '+';
function addventure()
{
    var feld = document.getElementById('addventure');
    feld.value = '';
    feld.focus();
    feld.style.width = 'auto';
}
function addventure_go(e)
{
    if (e.keyCode == 13)
    {
        var xmlHttpReq = false;
        var self = this;
        var feld = document.getElementById("addventure");
        var dirname = feld.value;
        feld.value = '...';
        if (window.XMLHttpRequest) { self.xmlHttpReq = new XMLHttpRequest(); }
        else if (window.ActiveXObject) { self.xmlHttpReq = new ActiveXObject("Microsoft.XMLHTTP"); }
        self.xmlHttpReq.open('POST', '/ventures/add.pl', true);
        self.xmlHttpReq.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        self.xmlHttpReq.onreadystatechange = function() {
            if (self.xmlHttpReq.readyState == 4) { window.location.reload(); }
            else { feld.value = '...'; }}
        self.xmlHttpReq.send('dir=chapter/&ipos=-1&newsectionname='+dirname);
        return false; }
}