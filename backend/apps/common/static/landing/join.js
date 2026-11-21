// Tester sign-up: posts the form straight to Google Forms through a hidden iframe so
// the visitor stays on the page. Without JavaScript the form still works and simply
// opens Google's own confirmation page.
(function () {
  var form = document.getElementById("join-form");
  if (!form) return;

  var sink = document.getElementById("join-sink");
  var thanks = document.getElementById("join-thanks");
  var error = document.getElementById("join-error");
  var button = form.querySelector("button[type=submit]");
  var submitted = false;

  form.setAttribute("target", "join-sink");

  form.addEventListener("submit", function (event) {
    error.hidden = true;
    if (!form.checkValidity()) {
      event.preventDefault();
      form.reportValidity();
      return;
    }
    submitted = true;
    button.disabled = true;
    button.textContent = "Sending…";
    // If Google never answers (offline, blocked), let the visitor try again.
    window.setTimeout(function () {
      if (submitted) {
        submitted = false;
        button.disabled = false;
        button.textContent = "Join the test";
        error.hidden = false;
      }
    }, 15000);
  });

  // Google cannot report success to another site, so the iframe finishing its load
  // after a submit is the signal that the response was sent.
  sink.addEventListener("load", function () {
    if (!submitted) return;
    submitted = false;
    form.hidden = true;
    thanks.hidden = false;
    thanks.focus();
  });
})();
