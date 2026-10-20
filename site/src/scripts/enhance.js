// Progressive enhancement: turns tile anchors into buttons that swap the one visible readout.
const board = document.getElementById('board');
const readout = document.getElementById('readout');
if (board && readout) {
  const panels = Array.from(readout.querySelectorAll('.readout-panel'));
  const anchors = Array.from(board.querySelectorAll('a.tile'));

  // The first tile in board order is selected on load.
  const initiallySelected = anchors[0]?.dataset.slug ?? panels[0]?.dataset.slug;

  const buttons = anchors.map((anchor) => {
    const button = document.createElement('button');
    // Copy every attribute so Astro's scoped-style data attribute comes along too.
    for (const { name, value } of anchor.attributes) {
      if (name === 'href') continue;
      button.setAttribute(name, value);
    }
    button.type = 'button';
    button.innerHTML = anchor.innerHTML;
    anchor.replaceWith(button);
    return button;
  });

  function select(slug) {
    for (const button of buttons) {
      const isSelected = button.dataset.slug === slug;
      button.setAttribute('aria-pressed', String(isSelected));
      button.classList.toggle('is-selected', isSelected);
    }
    for (const panel of panels) {
      panel.hidden = panel.dataset.slug !== slug;
    }
  }

  select(initiallySelected);

  for (const button of buttons) {
    button.addEventListener('click', () => {
      select(button.dataset.slug);

      // Phone layout: the readout wrapped below the board; scroll it into view without moving focus.
      if (readout.offsetTop > board.offsetTop) {
        const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        readout.scrollIntoView({ block: 'start', behavior: reduceMotion ? 'auto' : 'smooth' });
      }
    });
  }
}
