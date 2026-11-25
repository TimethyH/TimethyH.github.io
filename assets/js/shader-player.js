/*
 * shader-player.js — "click to play" live Shadertoy shaders on project pages.
 *
 * What it does
 *   Every element with class "shader-player" starts out as a plain poster
 *   image with a play button. Nothing else is downloaded and no GPU work
 *   happens until the visitor clicks play. Only then does this script fetch
 *   the GLSL source and the iChannel textures, compile the shader with WebGL2
 *   and start rendering it into a <canvas> that replaces the poster.
 *
 * Where it runs
 *   In the visitor's browser. _layouts/project.html loads it only on pages
 *   whose front matter has `shader_player: true`.
 *
 * What it talks to
 *   - the .glsl file named in data-shader (served from this site)
 *   - the images named in data-channel0..3 (this site or shadertoy.com,
 *     which sends CORS headers so WebGL may read them)
 *   - the GPU, through a WebGL2 context
 *
 * Markup it expects (see _projects/09-shadertoy.md)
 *   <div class="shader-player"
 *        data-shader="/assets/shaders/x.glsl"     required: Shadertoy "Image" code
 *        data-channel0="/path/tex.jpg"           optional: texture for iChannel0 (also 1..3)
 *        data-channel0-filter="mipmap"           optional: mipmap | linear | nearest
 *        data-channel0-wrap="repeat"             optional: repeat | clamp
 *        data-channel0-vflip="true"              optional: flip rows like Shadertoy does
 *        data-mouse="drag"                       optional: iMouse.xy = total drag distance
 *                                                (for "drag to look around" cameras)
 *        data-shadertoy="https://shadertoy.com/view/ID">  optional: "open on Shadertoy" link
 *     <img class="shader-poster" src="poster.webp" alt="...">
 *   </div>
 *
 * Performance rules it follows
 *   - one shader runs at a time: pressing play on one pauses the others
 *   - a shader pauses by itself when scrolled off screen, and resumes when
 *     it comes back (only if it was playing before)
 *   - it renders at a reduced resolution and the browser scales the canvas
 *     up; in "Auto" quality it lowers the resolution further if the frame
 *     rate stays low
 */
(function () {
  'use strict';

  /* ------------------------------------------------------------------ */
  /* Shader source wrapping                                              */
  /* ------------------------------------------------------------------ */

  // Shadertoy code only contains mainImage(). Shadertoy itself wraps it in a
  // header (GLSL version, precision, the i* uniforms) and a main() that calls
  // it. We recreate that wrapper so the code can be pasted in unchanged.
  // "#version 300 es" means GLSL ES 3.00, the language WebGL2 speaks.
  var FRAGMENT_HEADER = [
    '#version 300 es',
    'precision highp float;',
    'precision highp int;',
    'precision mediump sampler3D;',
    '#define HW_PERFORMANCE 1',
    'uniform vec3  iResolution;',
    'uniform float iTime;',
    'uniform float iTimeDelta;',
    'uniform float iFrameRate;',
    'uniform int   iFrame;',
    'uniform float iChannelTime[4];',
    'uniform vec3  iChannelResolution[4];',
    'uniform vec4  iMouse;',
    'uniform vec4  iDate;',
    'uniform float iSampleRate;',
    'uniform sampler2D iChannel0;',
    'uniform sampler2D iChannel1;',
    'uniform sampler2D iChannel2;',
    'uniform sampler2D iChannel3;',
    'out vec4 shaderPlayerOutColor;',
    ''
  ].join('\n');

  // Number of lines the header adds, so compile errors can be reported with
  // the line numbers you see in the Shadertoy editor.
  var HEADER_LINES = FRAGMENT_HEADER.split('\n').length - 1;

  // main() calls the Shadertoy entry point once per pixel. Alpha is forced
  // to 1, like Shadertoy's own display does.
  var FRAGMENT_FOOTER = [
    '',
    'void main() {',
    '  vec4 color = vec4(0.0, 0.0, 0.0, 1.0);',
    '  mainImage(color, gl_FragCoord.xy);',
    '  shaderPlayerOutColor = vec4(color.rgb, 1.0);',
    '}'
  ].join('\n');

  // A vertex shader that draws one triangle big enough to cover the whole
  // screen. It needs no vertex buffer: the 3 corners are computed from
  // gl_VertexID (0, 1, 2) -> (-1,-1), (3,-1), (-1,3).
  var VERTEX_SOURCE = [
    '#version 300 es',
    'void main() {',
    '  vec2 p = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);',
    '  gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);',
    '}'
  ].join('\n');

  // Names of all uniforms we feed every frame. Ones the shader does not use
  // are optimised away by the GPU driver; their location is then null and
  // setting them does nothing, which is fine.
  var UNIFORM_NAMES = [
    'iResolution', 'iTime', 'iTimeDelta', 'iFrameRate', 'iFrame',
    'iChannelTime', 'iChannelResolution', 'iMouse', 'iDate', 'iSampleRate',
    'iChannel0', 'iChannel1', 'iChannel2', 'iChannel3'
  ];

  // Resolution choices in the quality menu (fraction of the canvas size).
  var QUALITY_STEPS = [0.5, 0.75, 1.0];
  var AUTO_START_SCALE = 0.75;   // where "Auto" begins
  var AUTO_MIN_SCALE = 0.35;     // "Auto" never goes below this
  var AUTO_LOW_FPS = 45;         // below this average, "Auto" steps down

  // Every player on the page, so one can pause the others.
  var allPlayers = [];

  /* ------------------------------------------------------------------ */
  /* Small helpers                                                       */
  /* ------------------------------------------------------------------ */

  // Creates an element with a class name and optional inner HTML.
  function makeElement(tag, className, html) {
    var el = document.createElement(tag);
    if (className) el.className = className;
    if (html) el.innerHTML = html;
    return el;
  }

  // Compiles one shader stage. Returns the shader, or throws an Error whose
  // message holds the driver's log with line numbers shifted back to the
  // user's own code.
  function compileShader(gl, type, source) {
    var shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      var log = gl.getShaderInfoLog(shader) || 'unknown compile error';
      gl.deleteShader(shader);
      // Driver logs look like "ERROR: 0:123: ..."; subtract the header.
      if (type === gl.FRAGMENT_SHADER) {
        log = log.replace(/(\d+):(\d+):/g, function (all, file, line) {
          return file + ':' + (parseInt(line, 10) - HEADER_LINES) + ':';
        });
      }
      throw new Error(log);
    }
    return shader;
  }

  // Links the full-screen vertex shader with the wrapped Shadertoy code.
  function buildProgram(gl, userCode) {
    var vs = compileShader(gl, gl.VERTEX_SHADER, VERTEX_SOURCE);
    var fs = compileShader(gl, gl.FRAGMENT_SHADER,
      FRAGMENT_HEADER + userCode + FRAGMENT_FOOTER);
    var program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);
    // Once linked, the separate stages are no longer needed.
    gl.deleteShader(vs);
    gl.deleteShader(fs);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Error(gl.getProgramInfoLog(program) || 'unknown link error');
    }
    return program;
  }

  // Downloads an image. crossOrigin = 'anonymous' asks the server for CORS
  // permission; without it WebGL refuses to read pixels from another site.
  function loadImage(url) {
    return new Promise(function (resolve, reject) {
      var img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = function () { resolve(img); };
      img.onerror = function () { reject(new Error('could not load texture ' + url)); };
      img.src = url;
    });
  }

  // Uploads an image as a GPU texture with Shadertoy-style sampler settings.
  function createTexture(gl, img, options) {
    var tex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex);
    // Shadertoy flips textures vertically by default ("vflip").
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, options.vflip);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);

    // Filtering: how the GPU blends texels when the texture is scaled.
    var minFilter = gl.LINEAR;
    var magFilter = gl.LINEAR;
    if (options.filter === 'mipmap') {
      gl.generateMipmap(gl.TEXTURE_2D);
      minFilter = gl.LINEAR_MIPMAP_LINEAR;
    } else if (options.filter === 'nearest') {
      minFilter = gl.NEAREST;
      magFilter = gl.NEAREST;
    }
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, minFilter);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magFilter);

    // Wrapping: what happens outside the 0..1 texture coordinate range.
    var wrap = options.wrap === 'clamp' ? gl.CLAMP_TO_EDGE : gl.REPEAT;
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap);
    return tex;
  }

  /* ------------------------------------------------------------------ */
  /* ShaderPlayer: one poster/canvas pair on the page                    */
  /* ------------------------------------------------------------------ */

  // Sets up the poster state for one .shader-player element. Nothing is
  // downloaded here; that waits for the first click on play.
  function ShaderPlayer(root) {
    this.root = root;
    this.poster = root.querySelector('.shader-poster');
    this.gl = null;          // WebGL2 context, created on first play
    this.canvas = null;
    this.program = null;
    this.uniforms = {};
    this.channels = [];      // [{ texture, width, height } | null] x4
    this.loaded = false;     // shader compiled and textures uploaded
    this.loading = false;
    this.playing = false;
    this.pausedByScroll = false;  // paused only because it left the screen
    this.onScreen = true;
    this.frameRequest = 0;   // id from requestAnimationFrame, to cancel it

    // Timing state: time only advances while playing.
    this.time = 0;
    this.frame = 0;
    this.lastNow = 0;
    this.lastDelta = 0;

    // Quality: 'auto' or a fixed scale from QUALITY_STEPS.
    this.qualityMode = 'auto';
    this.scale = AUTO_START_SCALE;

    // Frame-rate meter, measured over ~1 second windows.
    this.fpsFrames = 0;
    this.fpsStart = 0;
    this.fps = 0;
    this.fpsWarmup = true;   // skip the first window after (re)starting
    this.lowFpsWindows = 0;  // consecutive slow windows seen by "Auto"

    // Shadertoy mouse: xy = position while dragging, zw = where the click
    // started. z is negative when the button is up, w negative after the
    // first frame of a click.
    this.mouse = [0, 0, 0, 0];

    // data-mouse="drag": instead of the cursor position, iMouse.xy holds the
    // total distance dragged so far (starting at 0, 0). A camera can turn
    // that into angles, and a new drag continues from where the last one
    // stopped instead of jumping to the spot that was clicked.
    this.dragMouse = root.getAttribute('data-mouse') === 'drag';
    this.lastPointer = null;  // previous pointer position during a drag
    if (this.dragMouse) root.classList.add('is-drag-look');

    this.buildOverlay();
    allPlayers.push(this);
  }

  // Adds the big play button over the poster.
  ShaderPlayer.prototype.buildOverlay = function () {
    var self = this;
    this.playButton = makeElement('button', 'shader-play-button',
      '<i class="fa-solid fa-play"></i><span>Run live shader</span>');
    this.playButton.type = 'button';
    this.playButton.setAttribute('aria-label', 'Run this shader live in your browser');
    this.playButton.addEventListener('click', function () { self.start(); });
    this.root.appendChild(this.playButton);

    // Status line for "Loading…" and error messages.
    this.status = makeElement('div', 'shader-status');
    this.root.appendChild(this.status);
  };

  // Shows a message over the player. kind = 'loading' | 'error'.
  ShaderPlayer.prototype.setStatus = function (text, kind) {
    this.status.textContent = text || '';
    this.status.className = 'shader-status' + (kind ? ' is-' + kind : '');
  };

  // First click: create the WebGL2 context, download and compile, then play.
  // Later clicks on the play button simply resume.
  ShaderPlayer.prototype.start = async function () {
    if (this.loaded) { this.play(); return; }
    if (this.loading) return;
    this.loading = true;
    this.playButton.disabled = true;
    this.setStatus('Loading shader…', 'loading');

    try {
      // 1. GPU context. alpha:false = opaque canvas, antialias:false because
      //    a full-screen pass gains nothing from MSAA.
      this.canvas = makeElement('canvas', 'shader-canvas');
      var gl = this.canvas.getContext('webgl2', {
        alpha: false, antialias: false, depth: false, stencil: false,
        preserveDrawingBuffer: false, powerPreference: 'high-performance'
      });
      if (!gl) throw new Error('WebGL2 is not available in this browser.');
      this.gl = gl;

      // 2. Download the shader code and all textures at the same time.
      var shaderUrl = this.root.getAttribute('data-shader');
      var codePromise = fetch(shaderUrl).then(function (res) {
        if (!res.ok) throw new Error('could not load ' + shaderUrl);
        return res.text();
      });
      var imagePromises = [];
      for (var i = 0; i < 4; i++) {
        var url = this.root.getAttribute('data-channel' + i);
        imagePromises.push(url ? loadImage(url) : Promise.resolve(null));
      }
      var code = await codePromise;
      var images = await Promise.all(imagePromises);

      // 3. Compile and look up uniform locations once.
      this.program = buildProgram(gl, code);
      for (var u = 0; u < UNIFORM_NAMES.length; u++) {
        this.uniforms[UNIFORM_NAMES[u]] =
          gl.getUniformLocation(this.program, UNIFORM_NAMES[u]);
      }

      // 4. Upload textures to the GPU.
      for (var c = 0; c < 4; c++) {
        if (!images[c]) { this.channels.push(null); continue; }
        var prefix = 'data-channel' + c;
        this.channels.push({
          texture: createTexture(gl, images[c], {
            filter: this.root.getAttribute(prefix + '-filter') || 'mipmap',
            wrap: this.root.getAttribute(prefix + '-wrap') || 'repeat',
            vflip: (this.root.getAttribute(prefix + '-vflip') || 'true') === 'true'
          }),
          width: images[c].naturalWidth,
          height: images[c].naturalHeight
        });
      }

      // 5. Swap the poster for the canvas and add the control bar.
      this.root.insertBefore(this.canvas, this.poster);
      this.root.classList.add('is-live');
      this.attachInput();
      this.buildControls();
      this.watchVisibility();
      this.loaded = true;
      this.setStatus('');
      this.play();
    } catch (err) {
      // Typical causes: no WebGL2, a driver rejecting the GLSL, or a
      // texture that failed to download.
      console.error('[shader-player] ' + this.root.getAttribute('data-shader') + '\n' + err.message);
      var link = this.root.getAttribute('data-shadertoy');
      this.setStatus('This shader could not start in your browser.' +
        (link ? ' You can watch it on Shadertoy instead.' : ''), 'error');
      if (link) {
        var a = makeElement('a', 'shader-status-link', 'Open on Shadertoy ↗');
        a.href = link;
        a.target = '_blank';
        a.rel = 'noopener';
        this.status.appendChild(a);
      }
      this.playButton.style.display = 'none';
    } finally {
      this.loading = false;
      this.playButton.disabled = false;
    }
  };

  // Builds the small control bar shown under a live shader.
  ShaderPlayer.prototype.buildControls = function () {
    var self = this;
    var bar = makeElement('div', 'shader-controls');

    // Pause / resume.
    this.pauseButton = makeElement('button', 'shader-ctrl', '<i class="fa-solid fa-pause"></i>');
    this.pauseButton.type = 'button';
    this.pauseButton.title = 'Pause';
    this.pauseButton.addEventListener('click', function () {
      if (self.playing) self.pause(); else self.play();
    });
    bar.appendChild(this.pauseButton);

    // Restart from iTime = 0.
    var restart = makeElement('button', 'shader-ctrl', '<i class="fa-solid fa-rotate-left"></i>');
    restart.type = 'button';
    restart.title = 'Restart';
    restart.addEventListener('click', function () {
      self.time = 0;
      self.frame = 0;
      if (!self.playing) self.renderFrame(0);  // show the first frame
    });
    bar.appendChild(restart);

    // Quality menu: Auto or a fixed render scale.
    var select = makeElement('select', 'shader-quality');
    select.title = 'Render resolution';
    var autoOption = makeElement('option', null, 'Auto');
    autoOption.value = 'auto';
    select.appendChild(autoOption);
    QUALITY_STEPS.forEach(function (step) {
      var opt = makeElement('option', null, Math.round(step * 100) + '%');
      opt.value = String(step);
      select.appendChild(opt);
    });
    select.addEventListener('change', function () {
      self.qualityMode = select.value;
      self.scale = select.value === 'auto' ? AUTO_START_SCALE : parseFloat(select.value);
      self.lowFpsWindows = 0;
    });
    bar.appendChild(select);

    // Live frame rate and render size, e.g. "60 fps · 1200×675".
    this.fpsLabel = makeElement('span', 'shader-fps', '– fps');
    bar.appendChild(this.fpsLabel);

    // Spacer pushes the remaining items to the right edge.
    bar.appendChild(makeElement('span', 'shader-spacer'));

    // Link to the original on Shadertoy.
    var link = this.root.getAttribute('data-shadertoy');
    if (link) {
      var a = makeElement('a', 'shader-ctrl shader-link', 'Shadertoy <i class="fa-solid fa-arrow-up-right-from-square"></i>');
      a.href = link;
      a.target = '_blank';
      a.rel = 'noopener';
      bar.appendChild(a);
    }

    // Fullscreen (not offered where the browser has no element fullscreen,
    // e.g. Safari on iPhone).
    if (document.fullscreenEnabled) {
      var full = makeElement('button', 'shader-ctrl', '<i class="fa-solid fa-expand"></i>');
      full.type = 'button';
      full.title = 'Fullscreen';
      full.addEventListener('click', function () {
        if (document.fullscreenElement) document.exitFullscreen();
        else self.root.requestFullscreen();
      });
      bar.appendChild(full);
    }

    this.root.appendChild(bar);
  };

  // Mouse/touch input mapped to Shadertoy's iMouse convention. Pointer
  // events cover mouse, pen and touch with one set of handlers.
  ShaderPlayer.prototype.attachInput = function () {
    var self = this;
    var canvas = this.canvas;

    // Converts a page position to canvas pixels, with y = 0 at the bottom
    // (GLSL's gl_FragCoord counts rows from the bottom).
    function toPixels(e) {
      var rect = canvas.getBoundingClientRect();
      return [
        (e.clientX - rect.left) * canvas.width / rect.width,
        (rect.bottom - e.clientY) * canvas.height / rect.height
      ];
    }

    canvas.addEventListener('pointerdown', function (e) {
      var p = toPixels(e);
      if (self.dragMouse) {
        // Drag mode: keep the accumulated xy, only mark the button as down.
        // Math.max(…, 1) keeps z/w positive even for a click at pixel 0.
        self.mouse[2] = Math.max(p[0], 1);
        self.mouse[3] = Math.max(p[1], 1);
        self.lastPointer = p;
      } else {
        self.mouse = [p[0], p[1], p[0], p[1]]; // positive z, w: button down
      }
      canvas.setPointerCapture(e.pointerId);    // keep events while dragging outside
    });
    canvas.addEventListener('pointermove', function (e) {
      if (self.mouse[2] <= 0) return;           // only track while pressed
      var p = toPixels(e);
      if (self.dragMouse) {
        // Add how far the pointer moved since the previous event.
        self.mouse[0] += p[0] - self.lastPointer[0];
        self.mouse[1] += p[1] - self.lastPointer[1];
        self.lastPointer = p;
      } else {
        self.mouse[0] = p[0];
        self.mouse[1] = p[1];
      }
    });
    function release() {
      self.mouse[2] = -Math.abs(self.mouse[2]); // negative z: button up
      self.mouse[3] = -Math.abs(self.mouse[3]);
      self.lastPointer = null;
    }
    canvas.addEventListener('pointerup', release);
    canvas.addEventListener('pointercancel', release);

    // The GPU can drop the context (driver reset, too many contexts). Go
    // back to the poster so the visitor can start it again.
    canvas.addEventListener('webglcontextlost', function (e) {
      e.preventDefault();
      self.resetToPoster('The GPU reset this shader. Press play to start it again.');
    });
  };

  // IntersectionObserver tells us when the player scrolls in or out of
  // view, so off-screen shaders stop using the GPU.
  ShaderPlayer.prototype.watchVisibility = function () {
    var self = this;
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        self.onScreen = entry.isIntersecting;
        if (!entry.isIntersecting && self.playing) {
          self.pause();
          self.pausedByScroll = true;
        } else if (entry.isIntersecting && self.pausedByScroll) {
          self.play();
        }
      });
    }, { threshold: 0.05 });
    observer.observe(this.root);

    // Hidden tab: some Chrome setups keep calling requestAnimationFrame at
    // ~1 fps in background tabs, which "Auto" would mistake for a slow GPU.
    // So pause while hidden and resume when the tab is shown again.
    document.addEventListener('visibilitychange', function () {
      if (document.hidden && self.playing) {
        self.pause();
        self.pausedByScroll = true;   // same "resume me later" flag
      } else if (!document.hidden && self.pausedByScroll && self.onScreen) {
        self.play();
      }
    });
  };

  // Starts (or resumes) the render loop and pauses every other player.
  ShaderPlayer.prototype.play = function () {
    var self = this;
    allPlayers.forEach(function (other) {
      if (other !== self && other.playing) other.pause();
      if (other !== self) other.pausedByScroll = false;
    });
    this.pausedByScroll = false;
    if (this.playing) return;
    this.playing = true;
    this.lastNow = 0;                // next frame gets delta 0, no time jump
    this.fpsStart = 0;
    this.root.classList.remove('is-paused');
    if (this.pauseButton) {
      this.pauseButton.innerHTML = '<i class="fa-solid fa-pause"></i>';
      this.pauseButton.title = 'Pause';
    }
    // requestAnimationFrame calls loop() right before the browser paints,
    // in step with the display refresh. Browsers stop calling it in hidden
    // tabs, so a background tab costs nothing.
    this.frameRequest = requestAnimationFrame(function (now) { self.loop(now); });
  };

  // Stops the render loop; the last frame stays visible on the canvas.
  ShaderPlayer.prototype.pause = function () {
    this.playing = false;
    cancelAnimationFrame(this.frameRequest);
    this.root.classList.add('is-paused');
    if (this.pauseButton) {
      this.pauseButton.innerHTML = '<i class="fa-solid fa-play"></i>';
      this.pauseButton.title = 'Play';
    }
  };

  // One step of the render loop: advance time, draw, update the meters,
  // and schedule the next step.
  ShaderPlayer.prototype.loop = function (now) {
    if (!this.playing) return;
    var self = this;

    // Seconds since the previous frame. Clamped so coming back to a tab
    // after minutes does not make the animation jump ahead.
    var delta = this.lastNow ? Math.min((now - this.lastNow) / 1000, 0.1) : 0;
    this.lastNow = now;
    this.time += delta;
    this.lastDelta = delta;

    this.renderFrame(delta);
    this.frame++;
    this.measureFps(now);

    this.frameRequest = requestAnimationFrame(function (t) { self.loop(t); });
  };

  // Resizes the canvas if needed, sets all uniforms and draws one frame.
  ShaderPlayer.prototype.renderFrame = function (delta) {
    var gl = this.gl;
    if (!gl || gl.isContextLost()) return;

    // Backing-store size = displayed size x device pixel ratio x quality.
    // The browser stretches the smaller image to fill the canvas element.
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    var w = Math.max(1, Math.round(this.canvas.clientWidth * dpr * this.scale));
    var h = Math.max(1, Math.round(this.canvas.clientHeight * dpr * this.scale));
    if (this.canvas.width !== w || this.canvas.height !== h) {
      // Keep the mouse at the same spot when the resolution changes.
      var sx = w / (this.canvas.width || w);
      var sy = h / (this.canvas.height || h);
      this.mouse = [this.mouse[0] * sx, this.mouse[1] * sy, this.mouse[2] * sx, this.mouse[3] * sy];
      this.canvas.width = w;
      this.canvas.height = h;
    }
    gl.viewport(0, 0, w, h);
    gl.useProgram(this.program);

    // Bind each texture to its texture unit (0..3) and its sampler uniform.
    var channelRes = new Float32Array(12);
    for (var c = 0; c < 4; c++) {
      var ch = this.channels[c];
      gl.activeTexture(gl.TEXTURE0 + c);
      gl.bindTexture(gl.TEXTURE_2D, ch ? ch.texture : null);
      if (this.uniforms['iChannel' + c]) gl.uniform1i(this.uniforms['iChannel' + c], c);
      if (ch) {
        channelRes[c * 3] = ch.width;
        channelRes[c * 3 + 1] = ch.height;
        channelRes[c * 3 + 2] = 1;
      }
    }

    // Shadertoy uniforms.
    var d = new Date();
    var u = this.uniforms;
    gl.uniform3f(u.iResolution, w, h, 1);
    gl.uniform1f(u.iTime, this.time);
    gl.uniform1f(u.iTimeDelta, delta);
    gl.uniform1f(u.iFrameRate, this.fps || 60);
    gl.uniform1i(u.iFrame, this.frame);
    gl.uniform1fv(u.iChannelTime, [this.time, this.time, this.time, this.time]);
    gl.uniform3fv(u.iChannelResolution, channelRes);
    gl.uniform4fv(u.iMouse, this.mouse);
    gl.uniform4f(u.iDate, d.getFullYear(), d.getMonth(), d.getDate(),
      d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds() + d.getMilliseconds() / 1000);
    gl.uniform1f(u.iSampleRate, 44100);

    // 3 vertices = the one full-screen triangle from VERTEX_SOURCE.
    gl.drawArrays(gl.TRIANGLES, 0, 3);

    // After the first frame of a click, Shadertoy makes w negative.
    if (this.mouse[3] > 0) this.mouse[3] = -this.mouse[3];
  };

  // Counts frames per ~1 s window and shows the result. In Auto mode it
  // lowers the render scale after three slow windows in a row.
  ShaderPlayer.prototype.measureFps = function (now) {
    if (!this.fpsStart) {
      this.fpsStart = now;
      this.fpsFrames = 0;
      this.fpsWarmup = true;   // the first window includes shader warm-up
      return;
    }
    this.fpsFrames++;
    var elapsed = now - this.fpsStart;
    if (elapsed < 1000) return;

    var fps = this.fpsFrames * 1000 / elapsed;
    this.fpsStart = now;
    this.fpsFrames = 0;

    // A window much longer than 1 s means the browser stopped calling us for
    // a while (tab switch, window dragged, debugger). That says nothing
    // about GPU speed, so neither show nor act on it. Same for warm-up.
    if (elapsed > 1500 || this.fpsWarmup) { this.fpsWarmup = false; return; }

    this.fps = fps;
    if (this.fpsLabel) {
      this.fpsLabel.textContent = Math.round(fps) + ' fps · ' +
        this.canvas.width + '×' + this.canvas.height;
    }

    if (this.qualityMode !== 'auto') return;
    this.lowFpsWindows = fps < AUTO_LOW_FPS ? this.lowFpsWindows + 1 : 0;
    if (this.lowFpsWindows >= 3 && this.scale > AUTO_MIN_SCALE) {
      this.scale = Math.max(AUTO_MIN_SCALE, this.scale - 0.15);
      this.lowFpsWindows = 0;
    }
  };

  // Throws the live state away and shows the poster again (used after the
  // GPU context is lost). The next play click rebuilds everything.
  ShaderPlayer.prototype.resetToPoster = function (message) {
    this.pause();
    var controls = this.root.querySelector('.shader-controls');
    if (controls) controls.remove();
    if (this.canvas) this.canvas.remove();
    this.canvas = null;
    this.gl = null;
    this.program = null;
    this.uniforms = {};
    this.channels = [];
    this.loaded = false;
    this.pauseButton = null;
    this.fpsLabel = null;
    this.time = 0;
    this.frame = 0;
    this.root.classList.remove('is-live', 'is-paused');
    this.playButton.style.display = '';
    this.setStatus(message || '', message ? 'error' : null);
  };

  /* ------------------------------------------------------------------ */
  /* Start-up                                                            */
  /* ------------------------------------------------------------------ */

  // DOMContentLoaded fires once the HTML is parsed, so every
  // .shader-player element exists by then.
  document.addEventListener('DOMContentLoaded', function () {
    var roots = document.querySelectorAll('.shader-player');
    for (var i = 0; i < roots.length; i++) new ShaderPlayer(roots[i]);
  });
})();
