path = require 'path'

preparser = require '../../components/template/preparser'

fixtures = path.join(__dirname, 'fixtures', 'templates')

describe 'TemplateFile', ->
    it 'should create a tree of nodes', ->
        TemplateFile = preparser.TemplateFile
        file = path.join(fixtures, 'grandchild.html')
        baseTemplate = null

        whenParsed = (err, template) ->
            if err
                baseTemplate = err
                return

            if template.super
                file = path.resolve(path.dirname(file), template.super)
                return new TemplateFile(file, template).parse(whenParsed)

            baseTemplate = template
            return

        parsedBaseTemplate = ->
            return baseTemplate

        new TemplateFile(file).parse(whenParsed)
        waitsFor(parsedBaseTemplate, 'base template to be parsed', 300)

        runs ->
            tpl = baseTemplate
            expect(tpl.filepath).toBe(path.join(fixtures, 'base.html'))
            expect(tpl.super).toBeFalsy()

            base = tpl.tree
            kids = base.children
            expect(kids.length).toBe(5)
            expect(kids[0].value).toBe('<!doctype html>\n<html><head>\n<meta charset="utf-8">\n')
            expect(kids[1].name).toBe('head')
            expect(kids[2].value).toBe('\n</head><body>\n')
            expect(kids[3].name).toBe('body')
            expect(kids[4].value).toBe('\n</body></html>\n')
            kids = base.children[1].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\n\t<title>base</title>\n')
            kids = base.children[3].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\n\t<p>base</p>\n')

            child = base.subtree
            kids = child.children
            expect(kids.length).toBe(5)
            expect(kids[0].value).toBe('\n')
            expect(kids[1].name).toBe('head')
            expect(kids[2].value).toBe('\n')
            expect(kids[3].name).toBe('body')
            expect(kids[4].value).toBe('\n')
            kids = child.children[1].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\n<title>child</title>\n')
            kids = child.children[3].children
            expect(kids.length).toBe(3)
            expect(kids[0].value).toBe('\n\t<p>extended</p>\n\t')
            expect(kids[1].name).toBe('extend')
            expect(kids[2].value).toBe('\n')
            kids = child.children[3].children[1].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\n\t\t<p>null</p>\n\t')

            grandchild = child.subtree
            kids = grandchild.children
            expect(kids.length).toBe(7)
            expect(kids[0].value).toBe('\n')
            expect(kids[1].name).toBe('na')
            expect(kids[2].value).toBe('\n')
            expect(kids[3].name).toBe('head')
            expect(kids[4].value).toBe('\n')
            expect(kids[5].name).toBe('extend')
            expect(kids[6].value).toBe('\n')
            kids = grandchild.children[1].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\nNA\n')
            kids = grandchild.children[3].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\n<title>grandchild</title>\n')
            kids = grandchild.children[5].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\n\t<p>grandchild</p>\n')

            return

        return

    it 'should merge subtrees into a single tree', ->
        TemplateFile = preparser.TemplateFile
        file = path.join(fixtures, 'grandchild.html')
        baseTemplate = null

        whenParsed = (err, template) ->
            if err
                baseTemplate = err
                return

            if template.super
                file = path.resolve(path.dirname(file), template.super)
                return new TemplateFile(file, template).parse(whenParsed)

            baseTemplate = template
            return

        parsedBaseTemplate = ->
            return baseTemplate

        new TemplateFile(file).parse(whenParsed)
        waitsFor(parsedBaseTemplate, 'base template to be parsed', 300)

        runs ->
            baseTree = baseTemplate.tree
            baseTree.merge()
            kids = baseTree.children
            expect(kids.length).toBe(5)
            expect(kids[0].value).toBe('<!doctype html>\n<html><head>\n<meta charset="utf-8">\n')
            expect(kids[1].name).toBe('head')
            expect(kids[2].value).toBe('\n</head><body>\n')
            expect(kids[3].name).toBe('body')
            expect(kids[4].value).toBe('\n</body></html>\n')
            kids = baseTree.children[1].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\n<title>grandchild</title>\n')
            kids = baseTree.children[3].children
            expect(kids.length).toBe(3)
            expect(kids[0].value).toBe('\n\t<p>extended</p>\n\t')
            expect(kids[1].name).toBe('extend')
            expect(kids[2].value).toBe('\n')
            kids = baseTree.children[3].children[1].children
            expect(kids.length).toBe(1)
            expect(kids[0].value).toBe('\n\t<p>grandchild</p>\n')

            return

        return

    return

describe 'preparser::preProcess()', ->
    it 'passes an error to the callback in case of an invalid file path', ->
        error = false
        file = path.join(__filename, 'fixtures', 'base.html')
        preparser.preProcess file, (err, tpl) ->
            error = err
            expect(tpl).not.toBeDefined()
            return

        templateToBeParsed = ->
            return error

        waitsFor(templateToBeParsed, 'invalid template', 700)
        runs ->
            expect(error.code).toBe 'ENOTDIR'
        return


    it 'passes an error to the callback in case of non-existant file', ->
        error = false
        file = path.join(fixtures, 'na.html')
        preparser.preProcess file, (err, tpl) ->
            error = err
            expect(tpl).not.toBeDefined()
            return

        templateToBeParsed = ->
            return error

        waitsFor(templateToBeParsed, 'na template', 700)
        runs ->
            expect(error.code).toBe 'ENOENT'
        return


    it 'should return a string to a callback', ->
        template = false
        file = path.join(fixtures, 'base.html')
        preparser.preProcess file, (err, tpl) ->
            expect(err).toBeFalsy()
            template = tpl
            return

        templateToBeParsed = ->
            return template

        waitsFor(templateToBeParsed, 'single template', 700)
        runs ->
            expect(typeof template).toBe 'string'
        return


    it 'parses and compiles a template inheritance chain', ->
        template = false
        file = path.join(fixtures, 'grandchild.html')
        preparser.preProcess file, (err, tpl) ->
            expect(err).toBeFalsy()
            template = tpl
            return

        templateToBeParsed = ->
            return template

        waitsFor(templateToBeParsed, 'inheritence chain', 700)
        runs ->
            str = '<!doctype html>\n<html><head>\n<meta charset="utf-8">\n\n'
            str += '<title>grandchild</title>\n\n'
            str += '</head><body>\n\n'
            str += '\t<p>extended</p>\n\t\n'
            str += '\t<p>grandchild</p>\n\n\n'
            str += '</body></html>\n'
            expect(template).toBe str
        return

    it 'ignores embedded template syntax', ->
        template = false
        file = path.join(fixtures, 'mixed-child.html')
        preparser.preProcess file, (err, tpl) ->
            expect(err).toBeFalsy()
            template = tpl
            return

        templateToBeParsed = ->
            return template

        waitsFor(templateToBeParsed, 'mixed child', 700)
        runs ->
            str = '<!doctype html>\n<html><head>\n<meta charset="utf-8">\n'
            str += '<title>${ title }</title>\n'
            str += '</head><body>\n\n'
            str += '{{each(i, item) items}}<p>${ item }</p>{{/each}}\n\n'
            str += '</body></html>\n'
            expect(template).toBe str
        return

    return
    
