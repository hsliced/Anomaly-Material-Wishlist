# Portfolio site

The static overview adapts `site/index.md` from the user's full-conversation v2 handoff. The canonical long-form narrative lives at `portfolio/case-study.md`; the site is its public reading surface, not a second history.

## Edit and build

- Edit `site/index.template.html` for the concise overview.
- Edit `portfolio/case-study.md` for the full reading view.
- Edit `site/styles.css` for responsive presentation.
- Run `node scripts/build-portfolio.mjs` from the repository root and commit both the sources and generated `docs/` files.

The dependency-free renderer supports the Markdown features used by this case study: headings, paragraphs, lists, inline emphasis/code/links, fenced code, and the three selected images. Extend the renderer when introducing other Markdown features. Images are copied verbatim from `portfolio/screenshots/`; their dimensions are read from the PNG headers. Generated HTML needs no JavaScript, third-party fonts, analytics, package installation, or network access to build.

## GitHub Pages

Publish from **main → /docs** using **Deploy from a branch**. `docs/.nojekyll` serves the generated static files directly. The project URL is `https://hsliced.github.io/Anomaly-Material-Wishlist/`.

See GitHub's [publishing-source documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

Keep repository document links absolute in the public site: `portfolio/` and `archive/` are outside the Pages publishing folder. Generated long-form links are rewritten to the corresponding GitHub files.

## Validation

Check the overview and full case study on desktop and mobile. Verify image loading, internal links, table-of-contents anchors, keyboard focus, and no horizontal overflow. Preserve the evidence categories and future-work boundaries when editing. Site validation is not new mod runtime testing.
