class Modules

	constructor: () ->
		@dependencies = {}
		@init_dependencies()
		if Drupal.modules
			mods = jQuery.extend({}, Drupal.modules)
			@attach(mod, fns) for mod, fns of mods when mods.hasOwnProperty(mod)

	#######################################################
	# DEPENDENCY MANAGEMENT
	#######################################################

	# load all dependencies from settings.
	init_dependencies: () ->
		if Drupal.settings.dependencies
			for stack, mods of Drupal.settings.dependencies when Drupal.settings.dependencies.hasOwnProperty(stack)
				for mod in mods
					@add_dependency(stack, mod)
		Drupal.settings.dependencies ?= {}

	# Initialise a dependency stack such that it fires
	# the "ready" event after the page has loaded, even
	# if not all dependencies were resolved.
	init_dependency: (stack, fallback = true) ->
		@dependencies[stack] ?= {}

		if Drupal.settings.dependencies[stack]?
			for mod in Drupal.settings.dependencies[stack]
				@add_dependency(stack, mod)

		if fallback
			callback = () ->
				if Drupal.modules.dependency_status(stack) != true
					jQuery(document).trigger(stack + '.ready')
			jQuery(window).load(callback)

	# Add a dependency to a stack.
	add_dependency: (stack, name) ->
		@dependencies[stack] ?= {}
		@dependencies[stack][name] ?= false
	
	# list stacks that depend on the named module.
	get_dependants: (name) ->
		stack for stack, mods of @dependencies when @dependencies.hasOwnProperty(stack) and mods[name]?

	# Resolve a dependency on all stacks.
	resolve_dependency: (name) ->
		for stack in @get_dependants(name)
			@dependencies[stack][name] = true
			jQuery(document).trigger(stack + '.update')
			jQuery(document).trigger(stack + '.ready') if @dependency_status(stack)

	# Check the status of a dependency stack
	dependency_status: (stack) ->
		count = 0
		if @dependencies[stack]
			for mod, status of @dependencies[stack]
				count++
				if @dependencies[stack].hasOwnProperty(mod) and not status
					return false
		return (if count then true else 1)

	#######################################################
	# MODULE MANAGEMENT
	#######################################################

	# Attach a module to the module list. Recommend using this
	# method in the event that there is a caching implementation
	# at a later date.
	attach: (module, fns) ->

		if not this[module]? or not this.hasOwnProperty(module)
			this[module] = fns
		else
			console.error('JSUtils - attempt to overwrite a reserved word')

	# Lists modules that implement a hook
	implements: (hook) ->
		module for module, fns of Drupal.modules when fns[hook]?

	# Invokes a hook on a named module, returning the result
	# Returns null if no such module exists.
	invoke: (module, hook) ->
		args = Array::slice.call(arguments, 2)
		if Drupal.modules[module] and Drupal.modules[module][hook]
			return Drupal.modules[module][hook].call(window, args)

	# Invokes a hook on all modules that implement it, returning
	# a merged object OR an array of results, hopefully acting
	# identically to the PHP version of the same name.
	invoke_all: (hook) ->
		args = Array::slice.call(arguments, 1)
		result = []
		for module in @implements(hook)
			result_inner = Drupal.modules[module][hook].apply(window, args)
			if result_inner and result_inner.join?
				result = jQuery.extend(true, result, result_inner)
			else if result_inner
				result.push(result_inner)
		return result

	# Similar to drupal_alter, with some changes.
	# Incoming data *must* be an object for referencing to work.
	# Probably requires more sanitation/de-packing on the caller.
	alter: (hook, data) ->
		hook = hook + '_alter'
		for module in @implements(hook)
			data = Drupal.modules[module][hook].call(window, data)
		return data

Drupal.modules = new Modules()
jQuery(() ->
	Drupal.modules.init_dependencies()

	Drupal.url = (path = null, options = {}) ->
		options.fragment ?= ''
		options.query ?= {}
		options.absolute ?= false
		options.alias ?= false
		options.prefix ?= ''

		if not options.external?
			colonpos = path.indexOf(':');
			options.external = (colonpos >= 0 and !path.substring(0, colonpos).match(/[/?#]/))
		
		original_path = path

		[path, options, original_path] = Drupal.modules.alter('url_outbound', [path, options, original_path])

		if options.fragment? and options.fragment != ''
			options.fragment = '#' + options.fragment
		
		options.param_string = jQuery.param(options.query)

		if options.external
			if path.indexOf('#') >= 0
				split = path.split('#')
				path = split.unshift()
				
				if split.length and not options.fragment
					options.fragment = '#' + split.join('#')
				
				if options.param_string.length
					path += (if path.indexOf('?') >= 0 then '&' else '?') + options.param_string
				
				if options.https? and options.https
					path = path.replace('http://', 'https://')
				else
					path = path.replace('https://', 'http://')
			
			return path = options.fragment
		
		if not options.base_url?
			if options.https?
				options.base_url = Drupal.settings.absolutePath
				options.absolute = true
				if options.https
					options.base_url = options.base_url.replace('http://', 'https://')
				else
					options.base_url = options.base_url.replace('https://', 'http://')
			else
				options.base_url = Drupal.settings.basePathResolved
		
		if path is '<front>'
			path = ''
		# no aliasing or langauge support yet

		base = if options.absolute then options.base_url + '/' else Drupal.settings.basePathResolved
		prefix = options.prefix.replace(/\/+$/, '')

		return base + prefix + path + (if options.param_string then '?' + options.param_string else '') + options.fragment
)
