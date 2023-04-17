//= require_tree .

import * as toastr from "toastr";
window.toastr = toastr;

// import "trix"
import "@rails/actiontext"


document.addEventListener("rails_admin.dom_ready", function() {
	$('[rel="tooltip"]').tooltip();
	$('[title!=""]').tooltip();
	$('#update_if_exists').removeClass('form-control');
	// $('[data-bs-toggle="collapse"]').click();

	$(".diplayModalBtn").on('click', function() {
		var idModal = $(this).attr('idmodal');
		$(`#${idModal}`).modal();

	});
});