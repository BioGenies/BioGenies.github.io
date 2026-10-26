-- Emit ordinary HTML links at build time, including when JavaScript is disabled.
local function text(value) return pandoc.utils.stringify(value or '') end
local function link(label, url) return pandoc.Link(label, url) end
local people = {
  jc = 'Jarosław (Jarek) Chilimoniuk', mb = 'Michał Burdukiewicz',
  vi = 'Valentín Iglesias', kg = 'Krystyna (Krysia) Grzesiak',
  jp = 'Joanna Pokora', wp = 'Weronika Puchała', mr = 'Mariia Rutkowska',
  jk = 'Jakub Kołodziejczyk', lb = 'Laura Bąkała', sk = 'Dawid Sonor Kubkowski'
}
local function news_title(root, slug)
  local path = root .. '/subsite/posts/' .. slug .. '.qmd'
  local file = io.open(path, 'r')
  if not file then error('Related news does not exist: ' .. path) end
  local contents = file:read('*a'); file:close()
  return contents:match('title:%s*"(.-)"') or slug
end
-- Quarto fills its project context after loading user filters. Read resources
-- inside Pandoc, and support individual document renders without project context.
local function input_path()
  local input = (quarto.doc and quarto.doc.input_file) or PANDOC_STATE.input_files[1] or ''
  if pandoc.path.is_relative(input) then
    input = pandoc.path.join({pandoc.system.get_working_directory(), input})
  end
  return pandoc.path.normalize(input):gsub('\\', '/')
end

local function project_root(input)
  local root = (quarto.project and quarto.project.directory) or os.getenv('QUARTO_PROJECT_DIR')
  if root and root ~= '' then return root end
  local directory = pandoc.path.directory(input)
  while directory and directory ~= '' do
    local path = pandoc.path.join({directory, 'data', 'research-topics.json'})
    local file = io.open(path, 'r')
    if file then file:close(); return directory end
    local parent = pandoc.path.directory(directory)
    if parent == directory then break end
    directory = parent
  end
  error('Cannot find data/research-topics.json above input document: ' .. input)
end

local function load_topics(root)
  local path = pandoc.path.join({root, 'data', 'research-topics.json'})
  local file, reason = io.open(path, 'r')
  if not file then error('Cannot read research topic data: ' .. path .. ': ' .. tostring(reason)) end
  local contents = file:read('*a')
  file:close()
  return quarto.json.decode(contents)
end

function Pandoc(doc)
  local input = input_path()
  local profile = input:match('subsite/team/[^/]+%.qmd$') or input:match('subsite/colab/[^/]+%.qmd$')
  local post = input:match('subsite/posts/[^/]+%.qmd$')
  local topic_id = text(doc.meta['research-topic'])
  if not (profile or post or topic_id ~= '') then return doc end
  local root = project_root(input)
  local topics = load_topics(root)
  if profile then
    local person = {['@type'] = 'Person', name = text(doc.meta.title)}
    local schema = {['@context'] = 'https://schema.org', ['@type'] = 'ProfilePage', mainEntity = person}
    table.insert(doc.blocks, 1, pandoc.RawBlock('html', '<script type="application/ld+json">' .. quarto.json.encode(schema):gsub('<', '\\u003c') .. '</script>'))
    local intro = {}
    if doc.meta['profile-image'] then
      table.insert(intro, pandoc.Para({pandoc.Image({pandoc.Str(text(doc.meta.title))}, text(doc.meta['profile-image']))}))
    end
    table.insert(doc.blocks, 1, pandoc.Div(intro, pandoc.Attr('', {'profile-intro'})))
  end
  if topics[topic_id] then
    table.insert(doc.blocks, pandoc.Header(2, 'Publications & research stories'))
    local cards = {}
    for _, story in ipairs(topics[topic_id].stories) do
      local content = {
        pandoc.Header(3, story.title),
        pandoc.Para({pandoc.Str(story.description)}),
        pandoc.Para({link('Read the research story ↗', '../posts/' .. story.slug .. '.qmd')})
      }
      if story.doi then table.insert(content, pandoc.Para({link('Original publication ↗', story.doi)})) end
      table.insert(cards, pandoc.Div(content, pandoc.Attr('', {'topic-story'})))
    end
    table.insert(doc.blocks, pandoc.Div(cards, pandoc.Attr('', {'topic-story-grid'})))
    table.insert(doc.blocks, pandoc.Para({link('Explore all research & impact', '../research.qmd'), pandoc.Str(' · '), link('Full publication catalogue', '../publications.qmd')}))
  end
  if not (profile or post) then return doc end
  local blocks = {pandoc.Header(2, 'Explore related research', pandoc.Attr('related-research'))}
  local items = {}
  for _, slug in ipairs(doc.meta['related-news'] or {}) do
    slug = text(slug)
    table.insert(items, {pandoc.Plain({link(news_title(root, slug), '../posts/' .. slug .. '.qmd')})})
  end
  for _, code in ipairs(doc.meta['related-people'] or {}) do
    code = text(code)
    if not people[code] then error('Unknown related researcher: ' .. code) end
    table.insert(items, {pandoc.Plain({link(people[code] .. ' — academic CV and publications', '../team/' .. code .. '.qmd')})})
  end
  if post then
    local slug = input:match('([^/]+)%.qmd$')
    for _, key in ipairs({'amyloids', 'amp', 'llps', 'mvi', 'hdxms'}) do
      for _, story in ipairs(topics[key].stories) do
        if story.slug == slug then
          table.insert(items, {pandoc.Plain({link('Explore ' .. topics[key].title, '../topics/' .. key .. '.qmd')})})
          break
        end
      end
    end
  end
  if #items > 0 then table.insert(blocks, pandoc.BulletList(items)) end
  table.insert(blocks, pandoc.Para({link('BioGenies publications', '../publications.qmd'), pandoc.Str(' · '), link('Research & impact', '../research.qmd'), pandoc.Str(' · '), link('All research news', '../../index.qmd')}))
  table.insert(doc.blocks, pandoc.Div(blocks, pandoc.Attr('', {'related-research'})))
  return doc
end
