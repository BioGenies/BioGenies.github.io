-- Run with the Pandoc bundled with Quarto:
-- pandoc --lua-filter scripts/check_related_filter.lua -t html subsite/topics/amyloids.qmd
local root = pandoc.path.directory(pandoc.path.directory(PANDOC_SCRIPT_FILE))
if root == '' then root = pandoc.system.get_working_directory() end
root = pandoc.path.normalize(root)

-- Loading a filter must work before Quarto exposes document/project context.
quarto = {project = {}}
dofile(pandoc.path.join({root, 'filters', 'related-content.lua'}))
local related_content = Pandoc
Pandoc = nil

return {{Pandoc = function(doc)
  quarto.json = {decode = pandoc.json.decode, encode = pandoc.json.encode}
  local function links(document)
    local result = {}
    document:walk({Link = function(link) result[link.target] = true end})
    return result
  end
  local function topic_document()
    return pandoc.Pandoc({}, {['research-topic'] = pandoc.MetaString('amyloids')})
  end
  quarto.doc = {input_file = pandoc.path.join({root, 'subsite', 'topics', 'amyloids.qmd'})}
  -- Individual rendering: locate resources by walking up from the input file.
  local standalone = pandoc.system.with_environment({QUARTO_PROJECT_DIR = ''}, function()
    return links(related_content(topic_document()))
  end)
  assert(standalone['../posts/amylograph.qmd'], 'Missing topic-to-story link without project context')
  assert(standalone['https://doi.org/10.1093/nar/gkac882'], 'Missing original paper link')
  -- Project rendering: use the project directory supplied by Quarto.
  quarto.project.directory = root
  local project = links(related_content(topic_document()))
  assert(project['../posts/amylograph.qmd'], 'Missing link with project context')
  -- Profile news titles also need the resolved root when project context is absent.
  quarto.project.directory = nil
  quarto.doc.input_file = pandoc.path.join({root, 'subsite', 'team', 'jc.qmd'})
  local profile = pandoc.Pandoc({}, {
    title = pandoc.MetaString('Jarosław Chilimoniuk'),
    ['related-news'] = pandoc.MetaList({pandoc.MetaString('2025_05_19_jarek_fellowship')})
  })
  assert(links(related_content(profile))['../posts/2025_05_19_jarek_fellowship.qmd'], 'Missing profile news link')
  -- Posts link back to their topic even without a project directory.
  quarto.doc.input_file = pandoc.path.join({root, 'subsite', 'posts', 'amylograph.qmd'})
  assert(links(related_content(pandoc.Pandoc({})))['../topics/amyloids.qmd'], 'Missing story-to-topic link')
  io.stderr:write('Related-content filter regression checks passed.\n')
  return doc
end}}
