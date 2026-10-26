"""Validate the event/project redesign against real rendered content and local assets."""
from html.parser import HTMLParser
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1] / 'docs'
class Page(HTMLParser):
    def __init__(self):
        super().__init__(); self.main = False; self.assets = []; self.links = []; self.events = []; self.current = None; self.depth = 0
    def handle_starttag(self, tag, pairs):
        a = dict(pairs)
        if tag == 'main': self.main = True
        if not self.main: return
        if tag == 'img':
            self.assets.append(a.get('src',''))
            assert a.get('alt') or a.get('aria-hidden') == 'true', ('Unlabelled content image', a.get('src'))
        if tag == 'a': self.links.append(a.get('href',''))
        if tag == 'article' and 'event-card' in a.get('class','').split(): self.current = []
    def handle_data(self, data):
        if self.current is not None: self.current.append(data)
    def handle_endtag(self, tag):
        if tag == 'article' and self.current is not None:
            self.events.append(' '.join(self.current)); self.current = None
        if tag == 'main': self.main = False

pages = ['subsite/about','index_projects','subsite/conferences','subsite/team','subsite/colab','subsite/alumni']
pages += ['subsite/projects/'+x for x in ('AMI-cryoEM','AmyloGraph2','imputomics2','LIMAD','OneTick','FIBREA')]
pages += [str(p.relative_to(ROOT).with_suffix('')) for d in ('team','colab') for p in (ROOT/'subsite'/d).glob('*.html')]
for name in pages:
    file = ROOT/(name+'.html'); content = file.read_text(encoding='utf-8'); page = Page(); page.feed(content)
    for ref in page.assets + page.links:
        url = urlsplit(ref)
        if url.scheme or url.netloc or not url.path: continue
        assert not url.path.endswith('.qmd'), (name,ref)
        target = ROOT/unquote(url.path.lstrip('/')) if url.path.startswith('/') else file.parent/unquote(url.path)
        assert target.exists(), (name,ref)
    education = re.search(r'<section id="education"[^>]*>(.*?)</section>', content, re.S)
    if education:
        assert '<pre' not in education[1] and '&lt;span' not in education[1], (name, 'Education rendered as source code')
    if name == 'subsite/conferences':
        assert 'datatables html-widget' not in content
        hupo = [e for e in page.events if 'Human Proteome Organisation World Congress' in e and '2024-10-20' in e]
        assert len(hupo) == 1, 'HUPO 2024 must appear once'
        for attendee in ('Weronika','Jarosław','Krystyna','Oriol','Michał'):
            assert attendee in hupo[0], ('HUPO attendee missing',attendee)
    if name.startswith('subsite/projects/') and not name.endswith('FIBREA'):
        assert 'grant-facts' in content and 'Grant ID' in content and 'Budget' in content
print(f'Checked {len(pages)} event, project and profile pages: assets, links, grant facts and shared HUPO attendees.')
