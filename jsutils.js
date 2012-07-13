(function() {
  var Modules;
  Modules = (function() {
    function Modules() {
      var fns, mod, mods;
      this.dependencies = {};
      this.init_dependencies();
      if (Drupal.modules) {
        mods = jQuery.extend({}, Drupal.modules);
        for (mod in mods) {
          fns = mods[mod];
          if (mods.hasOwnProperty(mod)) {
            this.attach(mod, fns);
          }
        }
      }
    }
    Modules.prototype.init_dependencies = function() {
      var mod, mods, stack, _base, _i, _len, _ref, _ref2;
      if (Drupal.settings.dependencies) {
        _ref = Drupal.settings.dependencies;
        for (stack in _ref) {
          mods = _ref[stack];
          if (Drupal.settings.dependencies.hasOwnProperty(stack)) {
            for (_i = 0, _len = mods.length; _i < _len; _i++) {
              mod = mods[_i];
              this.add_dependency(stack, mod);
            }
          }
        }
      }
      return (_ref2 = (_base = Drupal.settings).dependencies) != null ? _ref2 : _base.dependencies = {};
    };
    Modules.prototype.init_dependency = function(stack, fallback) {
      var callback, mod, _base, _i, _len, _ref, _ref2;
      if (fallback == null) {
        fallback = true;
      }
      if ((_ref = (_base = this.dependencies)[stack]) == null) {
        _base[stack] = {};
      }
      if (Drupal.settings.dependencies[stack] != null) {
        _ref2 = Drupal.settings.dependencies[stack];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          mod = _ref2[_i];
          this.add_dependency(stack, mod);
        }
      }
      if (fallback) {
        callback = function() {
          if (Drupal.modules.dependency_status(stack) !== true) {
            return jQuery(document).trigger(stack + '.ready');
          }
        };
        return jQuery(window).load(callback);
      }
    };
    Modules.prototype.add_dependency = function(stack, name) {
      var _base, _base2, _ref, _ref2;
      if ((_ref = (_base = this.dependencies)[stack]) == null) {
        _base[stack] = {};
      }
      return (_ref2 = (_base2 = this.dependencies[stack])[name]) != null ? _ref2 : _base2[name] = false;
    };
    Modules.prototype.get_dependants = function(name) {
      var mods, stack, _ref, _results;
      _ref = this.dependencies;
      _results = [];
      for (stack in _ref) {
        mods = _ref[stack];
        if (this.dependencies.hasOwnProperty(stack) && (mods[name] != null)) {
          _results.push(stack);
        }
      }
      return _results;
    };
    Modules.prototype.resolve_dependency = function(name) {
      var stack, _i, _len, _ref, _results;
      _ref = this.get_dependants(name);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        stack = _ref[_i];
        this.dependencies[stack][name] = true;
        jQuery(document).trigger(stack + '.update');
        _results.push(this.dependency_status(stack) ? jQuery(document).trigger(stack + '.ready') : void 0);
      }
      return _results;
    };
    Modules.prototype.dependency_status = function(stack) {
      var count, mod, status, _ref;
      count = 0;
      if (this.dependencies[stack]) {
        _ref = this.dependencies[stack];
        for (mod in _ref) {
          status = _ref[mod];
          count++;
          if (this.dependencies[stack].hasOwnProperty(mod) && !status) {
            return false;
          }
        }
      }
      if (count) {
        return true;
      } else {
        return 1;
      }
    };
    Modules.prototype.attach = function(module, fns) {
      if (!(this[module] != null) || !this.hasOwnProperty(module)) {
        return this[module] = fns;
      } else {
        return console.error('JSUtils - attempt to overwrite a reserved word');
      }
    };
    Modules.prototype.implements = function(hook) {
      var fns, module, _ref, _results;
      _ref = Drupal.modules;
      _results = [];
      for (module in _ref) {
        fns = _ref[module];
        if (fns[hook] != null) {
          _results.push(module);
        }
      }
      return _results;
    };
    Modules.prototype.invoke = function(module, hook) {
      var args;
      args = Array.prototype.slice.call(arguments, 2);
      if (Drupal.modules[module] && Drupal.modules[module][hook]) {
        return Drupal.modules[module][hook].call(window, args);
      }
    };
    Modules.prototype.invoke_all = function(hook) {
      var args, module, result, result_inner, _i, _len, _ref;
      args = Array.prototype.slice.call(arguments, 1);
      result = [];
      _ref = this.implements(hook);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        module = _ref[_i];
        result_inner = Drupal.modules[module][hook].apply(window, args);
        if (result_inner && (result_inner.join != null)) {
          result = jQuery.extend(true, result, result_inner);
        } else if (result_inner) {
          result.push(result_inner);
        }
      }
      return result;
    };
    Modules.prototype.alter = function(hook, data) {
      var module, _i, _len, _ref;
      hook = hook + '_alter';
      _ref = this.implements(hook);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        module = _ref[_i];
        data = Drupal.modules[module][hook].call(window, data);
      }
      return data;
    };
    return Modules;
  })();
  Drupal.modules = new Modules();
  jQuery(function() {
    Drupal.modules.init_dependencies();
    return Drupal.url = function(path, options) {
      var base, colonpos, original_path, prefix, split, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      if (path == null) {
        path = null;
      }
      if (options == null) {
        options = {};
      }
      if ((_ref = options.fragment) == null) {
        options.fragment = '';
      }
      if ((_ref2 = options.query) == null) {
        options.query = {};
      }
      if ((_ref3 = options.absolute) == null) {
        options.absolute = false;
      }
      if ((_ref4 = options.alias) == null) {
        options.alias = false;
      }
      if ((_ref5 = options.prefix) == null) {
        options.prefix = '';
      }
      if (!(options.external != null)) {
        colonpos = path.indexOf(':');
        options.external = colonpos >= 0 && !path.substring(0, colonpos).match(/[/?#]/);
      }
      original_path = path;
      _ref6 = Drupal.modules.alter('url_outbound', [path, options, original_path]), path = _ref6[0], options = _ref6[1], original_path = _ref6[2];
      if ((options.fragment != null) && options.fragment !== '') {
        options.fragment = '#' + options.fragment;
      }
      options.param_string = jQuery.param(options.query);
      if (options.external) {
        if (path.indexOf('#') >= 0) {
          split = path.split('#');
          path = split.unshift();
          if (split.length && !options.fragment) {
            options.fragment = '#' + split.join('#');
          }
          if (options.param_string.length) {
            path += (path.indexOf('?') >= 0 ? '&' : '?') + options.param_string;
          }
          if ((options.https != null) && options.https) {
            path = path.replace('http://', 'https://');
          } else {
            path = path.replace('https://', 'http://');
          }
        }
        return path = options.fragment;
      }
      if (!(options.base_url != null)) {
        if (options.https != null) {
          options.base_url = Drupal.settings.absolutePath;
          options.absolute = true;
          if (options.https) {
            options.base_url = options.base_url.replace('http://', 'https://');
          } else {
            options.base_url = options.base_url.replace('https://', 'http://');
          }
        } else {
          options.base_url = Drupal.settings.basePathResolved;
        }
      }
      if (path === '<front>') {
        path = '';
      }
      base = options.absolute ? options.base_url + '/' : Drupal.settings.basePathResolved;
      prefix = options.prefix.replace(/\/+$/, '');
      return base + prefix + path + (options.param_string ? '?' + options.param_string : '') + options.fragment;
    };
  });
}).call(this);
