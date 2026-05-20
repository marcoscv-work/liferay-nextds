(function () {
  function init(root) {
    if (!root) return;
    var hdr = root.matches && root.matches('[data-nextds-site-header]') ? root : root.querySelector('[data-nextds-site-header]');
    if (!hdr || hdr.__nextdsBound) return;
    hdr.__nextdsBound = true;

    var burger = hdr.querySelector('[data-nextds-burger]');
    var menu   = hdr.querySelector('[data-nextds-menu]');
    var searchToggle = hdr.querySelector('[data-nextds-search-toggle]');
    var searchClose  = hdr.querySelector('[data-nextds-search-close]');
    var searchPanel  = hdr.querySelector('[data-nextds-search]');

    function setMenu(open) {
      if (!burger || !menu) return;
      burger.setAttribute('aria-expanded', open ? 'true' : 'false');
      burger.setAttribute('aria-label', open ? 'Close menu' : 'Menu');
      burger.setAttribute('data-title', open ? 'Close menu' : 'Menu');
      if (open) menu.removeAttribute('hidden');
      else      menu.setAttribute('hidden', '');
    }
    function setSearch(open) {
      if (!searchToggle || !searchPanel) return;
      searchToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      searchToggle.setAttribute('aria-label', open ? 'Close search' : 'Open search');
      searchToggle.setAttribute('data-title', open ? 'Close search' : 'Search');
      if (open) {
        searchPanel.removeAttribute('hidden');
        setTimeout(function () {
          var input = searchPanel.querySelector('input[type="search"], input[type="text"]');
          if (input) input.focus();
        }, 30);
      } else {
        searchPanel.setAttribute('hidden', '');
      }
    }

    if (burger && menu) {
      burger.addEventListener('click', function () {
        var willOpen = burger.getAttribute('aria-expanded') !== 'true';
        if (willOpen) setSearch(false);
        setMenu(willOpen);
      });
    }
    if (searchToggle && searchPanel) {
      searchToggle.addEventListener('click', function () {
        var willOpen = searchToggle.getAttribute('aria-expanded') !== 'true';
        if (willOpen) setMenu(false);
        setSearch(willOpen);
      });
      if (searchClose) searchClose.addEventListener('click', function () { setSearch(false); searchToggle.focus(); });
    }

    document.addEventListener('keydown', function (e) {
      if (e.key !== 'Escape') return;
      if (burger && burger.getAttribute('aria-expanded') === 'true')             { setMenu(false); burger.focus(); }
      if (searchToggle && searchToggle.getAttribute('aria-expanded') === 'true') { setSearch(false); searchToggle.focus(); }
    });

    document.addEventListener('click', function (e) {
      if (hdr.contains(e.target)) return;
      if (burger && burger.getAttribute('aria-expanded') === 'true')             setMenu(false);
      if (searchToggle && searchToggle.getAttribute('aria-expanded') === 'true') setSearch(false);
    });
  }

  var root = (typeof fragmentElement !== 'undefined' && fragmentElement) ? fragmentElement : null;
  if (root) init(root);
  else {
    var nodes = document.querySelectorAll('[data-nextds-site-header]');
    for (var i = 0; i < nodes.length; i++) init(nodes[i]);
  }
})();
