(function () {
  var root = (typeof fragmentElement !== 'undefined' && fragmentElement) ? fragmentElement : document;
  var btn = root.querySelector ? root.querySelector('.nextds-tag__remove') : null;
  if (!btn) return;
  btn.addEventListener('click', function () {
    var t = btn.closest('.nextds-tag'); if (t) t.style.display = 'none';
  });
})();
