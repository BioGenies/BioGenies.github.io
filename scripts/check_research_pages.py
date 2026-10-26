"""Check the build-time navigation and profile markup in rendered research pages."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import json
import re

ROOT = Path(__file__).resolve().parents[1] / 'docs'
class ResearchParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.depth = 0
        self.stack = []
        self.links = []
        self.images = []
        self.schema = False
        self.schemas = []
        self.schema_text = ''
        self.intro = False
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        classes = set(attrs.get('class', '').split())
        if tag in ('div', 'section'):
            self.stack.append(self.depth)
            if classes & {'profile-intro', 'related-research', 'achievement-card', 'people-grid', 'topic-story-grid', 'research-feature', 'hub-index', 'pet-grid'}:
                self.depth += 1
        if self.depth and tag == 'a' and attrs.get('href'):
            self.links.append(attrs['href'])
        if self.depth and tag == 'img' and attrs.get('src'):
            self.images.append(attrs['src'])
            assert attrs.get('alt'), 'Profile image needs alternative text'
        if 'profile-intro' in classes:
            self.intro = True
        if tag == 'script' and attrs.get('type') == 'application/ld+json':
            self.schema = True
            self.schema_text = ''
    def handle_endtag(self, tag):
        if tag in ('div', 'section') and self.stack:
            self.depth = self.stack.pop()
        if tag == 'script' and self.schema:
            self.schemas.append(json.loads(self.schema_text))
            self.schema = False
    def handle_data(self, data):
        if self.schema:
            self.schema_text += data

pages = [ROOT/'subsite/research.html', ROOT/'subsite/team.html', ROOT/'subsite/colab.html', ROOT/'subsite/alumni.html', ROOT/'subsite/guest.html']
pages += list((ROOT/'subsite/topics').glob('*.html'))
pages += list((ROOT/'subsite/team').glob('*.html'))
pages += list((ROOT/'subsite/colab').glob('*.html'))
checked = 0
for page in pages:
    parser = ResearchParser()
    content = page.read_text(encoding='utf-8')
    parser.feed(content)
    assert not re.search(r'href="[^"]*\.qmd"', content), f'{page}: source-file navigation link'
    if page.parent.name in ('team', 'colab'):
        assert 'datatables html-widget' not in content, f'{page}: CV still contains a data table'
        assert parser.intro, f'{page}: missing profile introduction'
        assert any(s.get('@type') == 'ProfilePage' and s['mainEntity']['name'] for s in parser.schemas), f'{page}: missing profile schema'
    for src in parser.images:
        assert (page.parent / unquote(urlsplit(src).path)).is_file(), f'{page}: missing image {src}'
    for href in parser.links:
        url = urlsplit(href)
        if url.scheme or url.netloc or not url.path:
            continue
        target = (ROOT / unquote(url.path).lstrip('/')) if url.path.startswith('/') else (page.parent / unquote(url.path))
        assert target.is_file(), f'{page}: broken related link {href}'
        checked += 1
assert checked > 0
print(f'Checked {len(pages)} research pages and {checked} internal links.')

# Verify both directions of each curated topic/publication relationship.
topics = json.loads((ROOT.parent/'data/research-topics.json').read_text())
for key, topic in topics.items():
    content = (ROOT/f'subsite/topics/{key}.html').read_text()
    for story in topic['stories']:
        assert story['slug'] + '.html' in content, f"{key}: missing research story"
        if story['doi']:
            assert story['doi'] in content, f"{key}: missing original paper"
        article = (ROOT/f"subsite/posts/{story['slug']}.html").read_text()
        assert 'topics/' + key + '.html' in article, f"{story['slug']}: missing topic backlink"
print('All topic/publication links are reciprocal.')
