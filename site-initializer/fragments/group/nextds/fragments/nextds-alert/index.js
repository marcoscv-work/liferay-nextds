(function () {
  var root = (typeof fragmentElement !== 'undefined' && fragmentElement) ? fragmentElement : document;
  var btn = root.querySelector ? root.querySelector('.nextds-alert__close') : null;
  if (!btn) return;
  btn.addEventListener('click', function () {
    var a = btn.closest('[data-nextds-alert]'); if (a) a.style.display = 'none';
  });
})();
