(function () {
  var root = (typeof fragmentElement !== 'undefined' && fragmentElement) ? fragmentElement : document;
  var acc = root.querySelector ? root.querySelector('[data-nextds-accordion]') : null;
  if (!acc && root.matches && root.matches('[data-nextds-accordion]')) acc = root;
  if (!acc || acc.getAttribute('data-nextds-exclusive') !== 'true') return;
  var items = acc.querySelectorAll('details.nextds-accordion__item');
  Array.prototype.forEach.call(items, function (d) {
    d.addEventListener('toggle', function () {
      if (d.open) Array.prototype.forEach.call(items, function (o) { if (o !== d) o.open = false; });
    });
  });
})();
