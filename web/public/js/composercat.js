var composerCat = function() {
    return {
	togglePopup: function(event, text) {
	    var popup = $(event.target).parent().find('.popup');
	    if (popup.size() === 0) {
		$(event.target).append('<span class="popup">' + text + '</span>').show();
	    } else {
		popup.hide();
		popup.remove();
	    }
	},

	toggleRecords: function(event, records) {
	    $('#' + records).toggle();
	},

	nextExplanation: function(event) {
	    return $(event.target).next('.explanation').get();
	} };
}();
