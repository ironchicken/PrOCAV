jQuery.extend(
    {getUrlVars: function() {
	 var vars = [];
	 var hash;
	 var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
	 var i;
	 for (i = 0; i < hashes.length; i++) {
	     hash = hashes[i].split('=');
	     vars.push(hash[0]);
	     vars[hash[0]] = hash[1];
	 }
	 return vars;
     },
     getUrlVar: function(name) {
	 return jQuery.getUrlVars()[name];
     }});

var initialise_table = function(table_name) {
    var columns = null;
    var model = null;
    var table_made = false;

    jQuery.ajax(
	{type: 'POST',
	 url: '/table_columns',
	 data: 'table_name=' + table_name,
	 dataType: 'json',
	 success: function(data, status, request) {
	     columns = data;
	     make_table();
	 },
	 error: function(request, status, error) {
	     alert('Could not retrieve columns for ' + table_name + '\n' + status);
	 }});

    jQuery.ajax(
	{type: 'POST',
	 url: '/table_model',
	 data: 'table_name=' + table_name,
	 dataType: 'json',
	 success: function(data, status, request) {
	     model = data;
	     make_table();
	 },
	 error: function(request, status, error) {
	     alert('Could not retrieve model for ' + table_name + '\n' + status);
	 }});

    var make_table = function() {
	if ((table_made === false) && (columns !== null) && (model !== null)) {
	    table_made = true;
	    jQuery("#table").jqGrid(
		{url: '/table_data',
		 mtype: 'POST',
		 postData: {table_name: table_name},
		 datatype: 'json',
		 colNames: columns,
		 colModel: model,
		 pager: '#pager',
		 rowNum: 50,
		 rowList: [10,30,50,100],
		 sortname: 'ID',
		 sortorder: 'asc',
		 viewrecords: true,
		 gridview: true, // disables afterInsertRow event
		 caption: table_name,
		 height: 600,
		 width: 800});
	}
    };
};
