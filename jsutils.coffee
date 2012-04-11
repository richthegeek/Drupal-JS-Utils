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
)
