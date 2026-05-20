(function () {
  function init(root) {
    if (!root) return;
    var tabs = root.matches && root.matches('[data-nextds-tabs]') ? root : root.querySelector('[data-nextds-tabs]');
    if (!tabs || tabs.__nextdsBound) return;
    tabs.__nextdsBound = true;
    var btns = tabs.querySelectorAll('[role="tab"]');
    var panels = tabs.querySelectorAll('[role="tabpanel"]');
    if (!btns.length || !panels.length) return;
    function activate(i) {
      for (var j = 0; j < btns.length; j++) {
        var on = (j === i);
        btns[j].setAttribute('aria-selected', on ? 'true' : 'false');
        btns[j].setAttribute('tabindex', on ? '0' : '-1');
      }
      for (var k = 0; k < panels.length; k++) {
        if (k === i) panels[k].removeAttribute('hidden');
        else         panels[k].setAttribute('hidden', '');
      }
    }
    for (var i = 0; i < btns.length; i++) (function (i) {
      btns[i].addEventListener('click', function (e) { e.preventDefault(); activate(i); btns[i].focus(); });
      btns[i].addEventListener('keydown', function (e) {
        if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft' && e.key !== 'Home' && e.key !== 'End') return;
        e.preventDefault();
        var n = i;
        if (e.key === 'ArrowRight') n = (i + 1) % btns.length;
        else if (e.key === 'ArrowLeft') n = (i - 1 + btns.length) % btns.length;
        else if (e.key === 'Home') n = 0;
        else if (e.key === 'End') n = btns.length - 1;
        activate(n); btns[n].focus();
      });
    })(i);
  }
  var root = (typeof fragmentElement !== 'undefined' && fragmentElement) ? fragmentElement : null;
  if (root) init(root);
  else {
    var nodes = document.querySelectorAll('[data-nextds-tabs]');
    for (var i = 0; i < nodes.length; i++) init(nodes[i]);
  }
})();
