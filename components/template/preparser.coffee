util = require 'util'

events = require 'events'
fs     = require 'fs'
path   = require 'path'


id = 0
class Node
    children: []
    parent: null

    constructor: ->
        @id = (id += 1)
        @children = []
        @parent = null

    appendNode: (node) ->
        node.parent = @
        @children.push(node)
        return node


class TextNode extends Node
    value: null

    constructor: (@value) ->
        super()

    render: ->
        return @value


class BlockNode extends Node
    name: null

    constructor: (@name) ->
        super()

    replaceWith: (newNode) ->
        i = 0
        for child in @parent.children
            if @ is child
                @parent.children[i] = newNode
                return newNode
            i += 1
        return false

    render: ->
        rv = ''
        for node in @children
            rv += node.render()
        return rv


class TemplateTree extends Node
    subtree: null

    constructor: (subtree) ->
        super(null)
        @subtree = null
        if subtree then @subtree = subtree

    find: (name, parent) ->
        parent or= @
        mynodes = parent.children
        nextNodes = []
        index = 0

        for node in mynodes
            index += 1
            if node.name is name
                parent.children = mynodes.slice(index)
                return node
            if node.children.length
                nextNodes.push(node)

        for node in nextNodes
            found = @find(name, node)
            if found then return found

        return null

    merge: (nodes) ->
        if not @subtree then return @
        @subtree.merge()

        nodes or= @children
        nextNodes = []

        for node in nodes
            if node instanceof BlockNode
                override = @subtree.find(node.name)
                if override then node.replaceWith(override)
                else if node.children.length
                    nextNodes = nextNodes.concat(node.children)

        if nextNodes.length then return @merge(nextNodes)
        return @

    render: ->
        rv = ''
        for node in @children
            rv += node.render()
        return rv


passthru      = 'passthru'
opentag       = 'maybe start of open tag'
tag           = 'open tag'
operator      = 'operator'
argument      = 'argument'
endtag        = 'maybe end of open tag'

leftCurly     = '{'
rightCurly    = '}'

whitespace    = '\r\n\t'
letters       = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
numbers       = '0123456789'
operatorChars = "/#{ letters }"

oneof = (charclass, c) ->
    return charclass.indexOf(c) isnt -1

notOneof = (charclass, c) ->
    return charclass.indexOf(c) is -1


class Lexer extends events.EventEmitter
    state: passthru
    buff: ''
    currentSection: null
    token: ''
    lastOperartor: null

    constructor: ->
        @state = passthru
        @buff = ''
        @currentSection = ''
        @token = ''
        @lastOperator = null
        @lastArgument = null

    doOperation: (operator, args) ->
        if args
            argstring = args.trim()
            args = argstring.split(' ').map (str) ->
                return str.replace(/^"/, '').replace(/"$/, '')

        if operator is 'extends'
            @emit('op', {operator: 'extends', args: args})
            return passthru

        if operator is 'block'
            @emit('op', {operator: 'block', args: args, section: @currentSection})
            @currentSection = ''
            return passthru

        if operator is '/block'
            @emit('op', {operator: '/block', section: @currentSection})
            @currentSection = ''
            return passthru

        return

    changeState: (state) ->
        @prevState = @state
        @state = state
        return

    revertState: ->
        @state = @prevState
        return

    handleChar: (c) ->
        switch @state
            when passthru
                if c is leftCurly
                    @buff = c
                    @changeState(opentag)
                else @currentSection += c
            when opentag
                @buff += c
                if c is leftCurly
                    @changeState(tag)
                else
                    @currentSection += @buff
                    @revertState()
            when tag
                @buff += c
                if oneof(operatorChars, c)
                    @changeState(operator)
                    @token = c
            when operator
                @buff += c
                if oneof(operatorChars, c)
                    @token += c
                else if c is rightCurly
                    @lastOperator = @token
                    @lastArgument = null
                    @changeState(endtag)
                else
                    @changeState(argument)
                    @lastOperator = @token
                    @token = c
            when argument
                @buff += c
                if c is rightCurly
                    @lastArgument = @token
                    @changeState(endtag)
                else
                    @token += c
            when endtag
                @buff += c
                if c is rightCurly
                    state = @doOperation(@lastOperator, @lastArgument)
                    if state then @changeState(state)
                    else
                        @currentSection += @buff
                        @changeState(passthru)
        return

    write: (chunk) ->
        if chunk is null then return @emit('op', null)
        @handleChar(char) for char in chunk
        return true


class TemplateFile
    tree: null
    lexer: null
    filepath: ''
    currentNode: null

    constructor: (@filepath, sub) ->
        @lexer       = new Lexer()
        @tree        = new TemplateTree((sub or {}).tree)
        @currentNode = @tree

        @lexer.on 'op', (spec) =>
            if spec is null and @lexer.currentSection
                @currentNode.appendNode(new TextNode(@lexer.currentSection))
                return
            if spec.operator is 'extends'
                @super = spec.args[0]
                return
            if spec.operator is 'block'
                @currentNode.appendNode(new TextNode(spec.section))
                @currentNode = @currentNode.appendNode(new BlockNode(spec.args[0]))
                return
            if spec.operator is '/block'
                @currentNode.appendNode(new TextNode(spec.section))
                @currentNode = @currentNode.parent
                return
            return

    parse: (callback) ->
        resolved = false
        opts =
            encoding:   'utf8'
            mode:       0444
            bufferSize: 512

        fileStream = fs.createReadStream(@filepath, opts)

        fileStream.on 'data', (chunk) =>
            return @lexer.write(chunk)

        fileStream.on 'error', (err) ->
            if resolved then return
            resolved = true
            return callback(err)

        fileStream.on 'end', =>
            if resolved then return
            @lexer.write(null)
            resolved = true
            return callback(null, @)

        return @

    render: ->
        return @tree.merge().render()

exports.TemplateFile = TemplateFile


preProcess = (file, callback) ->
    whenParsed = (err, template) ->
        if err then return callback(err)

        if template.super
            file = path.resolve(path.dirname(file), template.super)
            return new TemplateFile(file, template).parse(whenParsed)

        rv = template.render()
        return callback(null , rv)

    return new TemplateFile(file).parse(whenParsed)

exports.preProcess = preProcess
