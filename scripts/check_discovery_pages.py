"""Check the discovery routes without losing the established news archive."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit,unquote
import json,re
ROOT=Path(__file__).resolve().parents[1]/'docs'
class Page(HTMLParser):
    def __init__(self, require_alt=False):
        super().__init__();self.require_alt=require_alt;self.routes=0;self.links=[];self.images=[];self.ids=[];self.scripts=[];self.in_main=False
    def handle_starttag(self,tag,pairs):
        a=dict(pairs)
        if a.get('id'):self.ids.append(a['id'])
        if 'visitor-route' in a.get('class','').split():self.routes+=1
        if tag=='main':self.in_main=True
        if tag=='a' and a.get('href'):self.links.append(a['href'])
        if tag=='script' and a.get('src'):self.scripts.append(a['src'])
        if tag=='img' and self.in_main:
            ref=a.get('src') or a.get('data-src')
            if ref:self.images.append(ref)
            assert not self.require_alt or a.get('alt') or a.get('aria-hidden')=='true',a
    def handle_endtag(self,tag):
        if tag=='main':self.in_main=False
cache={}
def read(path):
    path=path.resolve()
    if path not in cache:
        parser=Page(path.stem in {"start","stories","imputation-demo"});parser.feed(path.read_text());cache[path]=parser
    return cache[path]
names=['index','subsite/start','subsite/stories','subsite/imputation-demo','subsite/research','subsite/software','subsite/topics/mvi','subsite/posts/imputomics','subsite/posts/amylograph','subsite/posts/hadex2']
for name in names:
    file=ROOT/(name+'.html');page=read(file)
    for ref in page.links+page.images+page.scripts:
        u=urlsplit(ref.replace('\\','/'))
        if u.scheme or u.netloc:continue
        assert not u.path.endswith('.qmd'),(name,ref)
        target=(ROOT/u.path.lstrip('/') if u.path.startswith('/') else file.parent/unquote(u.path)) if u.path else file
        assert target.exists(),(name,ref)
        if u.fragment and target.suffix=='.html':assert unquote(u.fragment) in read(target).ids,(name,ref)
    ids=[i for i in page.ids if i not in {'quarto-bootstrap','quarto-text-highlighting-styles'}]
    assert len(ids)==len(set(ids)),(name,'Duplicate DOM identifiers')
    assert 'dropdown-text"></span>' not in file.read_text(),(name,'Empty navigation label')
home=(ROOT/'index.html').read_text()
assert read(ROOT/'index.html').routes==3
listing=next(e for e in json.loads((ROOT/'listings.json').read_text()) if e['listing']=='/index.html')
assert len(listing['items'])>=60,'The existing news archive has been lost'
assert home.count('class="quarto-grid-item card')==len(listing['items'])
assert home.index('id="start-here"')<home.index('id="listing-listing"')
search=json.loads((ROOT/'search.json').read_text());assert len({e['objectID'] for e in search})==len(search)
for name in ['subsite/start.html','subsite/stories.html','subsite/imputation-demo.html']:
    assert any(e['href'].split('#')[0].lstrip('/')==name for e in search),('Not searchable',name)
    assert 'https://biogenies.info/'+name in (ROOT/'sitemap.xml').read_text(),('Not in sitemap',name)
assert 'html-table-processing: none' in (ROOT.parent/'subsite/imputation-demo.qmd').read_text()
print(f'Checked {len(names)} discovery pages, their local links/anchors/assets, {len(listing["items"])} news items and search/sitemap coverage.')
