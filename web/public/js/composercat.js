var composerCat = function() {
    return {
	showPopup: function(event, element) {
	    $(element).toggle();
	},

	nextExplanation: function(event) {
	    return $(event.target).next('.explanation').get();
	} };
}();
