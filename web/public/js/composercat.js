var composerCat = function() {
    return {
	showPopup: function(event, element) {
	    $(element).toggle();
	},

	nextAnnotation: function(event) {
	    return $(event.target).next('.annotation').get();
	} };
}();
