// Entry point for the build script in your package.json


require("bootstrap");
require("jquery");

import "@hotwired/turbo-rails";

import jquery from 'jquery'
window.jQuery = jquery
window.$ = jquery

import "bootstrap";

// import "./eduport/eduport";
// import "./eduport/functions";

// var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
// var tooltipList = tooltipTriggerList.map(function(tooltipTriggerEl) {
// 	return new bootstrap.Tooltip(tooltipTriggerEl)
// })

// var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
// var popoverList = popoverTriggerList.map(function(popoverTriggerEl) {
// 	return new bootstrap.Popover(popoverTriggerEl)
// })