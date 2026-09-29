import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

// Dependency-free rendering for the Markdown features used by this case study.
// The canonical long-form content remains portfolio/case-study.md.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(root, 'docs');
const assets = path.join(output, 'assets');
fs.mkdirSync(assets, {recursive: true});
const repo = 'https://github.com/hsliced/Anomaly-Material-Wishlist';
const esc = value => value.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const slug = value => value.toLowerCase().replace(/[^a-z0-9\s-]/g,'').trim().replace(/\s+/g,'-');
const imageNames = ['01_smithy_editor_corrected_x2.png','02_smithy_passive_hud.png','03_village_passive_hud_v067.png'];
for (const name of imageNames) fs.copyFileSync(path.join(root,'portfolio/screenshots',name),path.join(assets,name));
for (const [from,to] of [['styles.css','styles.css'],['favicon.svg','favicon.svg']]) fs.copyFileSync(path.join(root,'site',from),path.join(assets,to));
fs.writeFileSync(path.join(output,'.nojekyll'),'');

function imageAttributes(name) {
  const png=fs.readFileSync(path.join(assets,name));
  return `width="${png.readUInt32BE(16)}" height="${png.readUInt32BE(20)}"`;
}
function rewriteLink(href) {
  if (/^https:\/\//.test(href) || href.startsWith('#')) return href;
  const resolved=path.posix.normalize(path.posix.join('portfolio',href));
  if (resolved.startsWith('../')) throw new Error(`Link escapes repository: ${href}`);
  return `${repo}/blob/main/${resolved}`;
}
function inline(value) {
  return esc(value)
    .replace(/`([^`]+)`/g,'<code>$1</code>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g,(_,label,href)=>`<a href="${rewriteLink(href)}">${label}</a>`)
    .replace(/\*\*([^*]+)\*\*/g,'<strong>$1</strong>')
    .replace(/\*([^*]+)\*/g,'<em>$1</em>');
}
const md = fs.readFileSync(path.join(root,'portfolio/case-study.md'),'utf8');
const lines = md.trim().split(/\r?\n/);
const blocks=[], headings=[];
let i=0;
while(i<lines.length){
  const line=lines[i];
  if(!line.trim()){i++;continue;}
  if(line.startsWith('# ')){i++;continue;}
  if(line.startsWith('```')){
    const code=[];i++;
    while(i<lines.length&&!lines[i].startsWith('```'))code.push(lines[i++]);
    if(i===lines.length)throw new Error('Unclosed code fence');
    blocks.push(`<pre><code>${esc(code.join('\n'))}</code></pre>`);i++;continue;
  }
  const heading=line.match(/^(#{2,3}) (.+)$/);
  if(heading){
    const level=heading[1].length, title=heading[2], id=slug(title);
    if(level===2)headings.push({id,title});
    blocks.push(`<h${level} id="${id}">${inline(title)}</h${level}>`);i++;continue;
  }
  const image=line.match(/^!\[([^\]]*)\]\(screenshots\/([^)]+)\)$/);
  if(image){
    if(!imageNames.includes(image[2]))throw new Error(`Unmapped case-study image: ${image[2]}`);
    blocks.push(`<figure><a href="assets/${image[2]}" aria-label="Open full-resolution screenshot"><img src="assets/${image[2]}" alt="${esc(image[1])}" ${imageAttributes(image[2])} loading="lazy"></a></figure>`);i++;continue;
  }
  if(line.startsWith('- ')){
    const items=[];
    while(i<lines.length&&lines[i].startsWith('- '))items.push(`<li>${inline(lines[i++].slice(2))}</li>`);
    blocks.push(`<ul>${items.join('')}</ul>`);continue;
  }
  const paragraph=[];
  while(i<lines.length&&lines[i].trim())paragraph.push(lines[i++]);
  blocks.push(`<p>${inline(paragraph.join(' '))}</p>`);
}
const article=`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>The full case study — Anomaly Material Wishlist</title><meta name="description" content="The decisions, constraints, evidence, and iterations behind Anomaly Material Wishlist, a human-directed and AI-assisted Sunbreak mod."><link rel="canonical" href="https://hsliced.github.io/Anomaly-Material-Wishlist/case-study.html"><link rel="icon" href="assets/favicon.svg" type="image/svg+xml"><link rel="stylesheet" href="assets/styles.css"></head><body>
<a class="skip" href="#main">Skip to case study</a>
<header class="site-header wrap"><a class="identity" href="./"><span class="mark" aria-hidden="true">◇</span><span>hsliced <span class="muted">/ selected work</span></span></a><nav aria-label="Main navigation"><a href="./">Overview</a><a href="${repo}">GitHub ↗</a></nav></header>
<div class="article-header wrap"><p class="eyebrow">The full case study · v0.6.7 working milestone</p><h1>Anomaly Material Wishlist</h1></div>
<div class="article-layout wrap"><nav class="toc" aria-label="Case study sections"><p class="eyebrow">In this story</p>${headings.map(h=>`<a href="#${h.id}">${esc(h.title)}</a>`).join('')}</nav><main id="main" class="prose">${blocks.join('\n')}<div class="article-footer"><a href="./">← Back to overview</a><a href="${repo}/blob/main/portfolio/case-study.md">Canonical Markdown ↗</a></div></main></div>
<footer class="site-footer wrap"><p>hsliced / Anomaly Material Wishlist</p><p class="fine">Unofficial fan project. Monster Hunter Rise: Sunbreak imagery belongs to Capcom.</p></footer></body></html>`;
fs.writeFileSync(path.join(output,'case-study.html'),article);
let index=fs.readFileSync(path.join(root,'site/index.template.html'),'utf8');
index=index.replace(/<img src="assets\/([^"]+)"/g,(_,name)=>`<img ${imageAttributes(name)} src="assets/${name}"`);
fs.writeFileSync(path.join(output,'index.html'),index);
console.log(`Built portfolio overview and ${headings.length}-section case study with 3 original screenshots.`);
