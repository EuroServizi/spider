Spider::Template.define_named_asset 'jquery', [
#   [:js, 'js/jquery/jquery-1.5.2.js', Spider::Components, {:cdn => 'https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js'}]
    #[:js, 'js/jquery/jquery-1.8.3.js', Spider::Components, {:cdn => 'https://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js'}]
    #uso il jquery in locale che ha le modifiche per riconoscere il browser IE11
    [:js, 'js/jquery/jquery-1.8.3.min.js', Spider::Components]
 
 ]

Spider::Template.define_named_asset 'spider', [
    [:js, 'js/inheritance.js', Spider::Components],
    [:js, 'js/spider.js', Spider::Components],
    [:js, 'js/jquery/plugins/jquery.query-2.1.6.js', Spider::Components],
    [:js, 'js/jquery/plugins/jquery.form.js', Spider::Components],
    [:js, 'js/plugins/plugin.js', Spider::Components],
    [:css, 'css/spider.css', Spider::Components]
], :depends => ['jquery']

Spider::Template.define_named_asset 'cssgrid', [
    [:css, 'css/grid/1140.css', Spider::Components],
    [:css, 'css/grid/ie.css', Spider::Components, {:if_ie_lte => 9}],
    [:css, 'css/grid/smallerscreen.css', Spider::Components, {:media => "only screen and (max-width: 1023px)"}],
    [:css, 'css/grid/mobile.css', Spider::Components, {:media => "handheld, only screen and (max-width: 767px)"}]
]

Spider::Template.define_named_asset 'spider-utils', [
    [:js, 'js/utils.js', Spider::Components, {:gettext => true}]
], :depends => ['spider']

# jQuery UI

Spider::Template.define_runtime_asset 'jquery-ui-datepicker-locale' do |request, response, scene|
    Spider::Components.pub_url+"/js/jquery/jquery-ui-1.9.2/ui/i18n/jquery.ui.datepicker-#{request.locale.language}.js"
end

Spider::Template.define_named_asset 'jquery-ui', [
], :depends => ['jquery', 'jquery-ui-core', 'jquery-ui-draggable', 'jquery-ui-droppable', 'jquery-ui-resizable', 
    'jquery-ui-selectable', 'jquery-ui-sortable', 'jquery-ui-accordion', 'jquery-ui-menu', 'jquery-ui-autocomplete', 
    'jquery-ui-button', 'jquery-ui-dialog', 'jquery-ui-slider', 'jquery-ui-tabs', 'jquery-ui-datepicker', 
    'jquery-ui-progressbar', 'jquery-effects']




Spider::Template.define_named_asset 'jquery-ui-core', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.core.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.widget.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.mouse.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.position.js', Spider::Components],
    [:css, 'js/jquery/jquery-ui-1.9.2/css/Aristo/jquery-ui.custom.css', Spider::Components]
], :depends => ['jquery']

Spider::Template.define_named_asset 'jquery-ui-draggable', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.draggable.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-droppable', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.droppable.js', Spider::Components]
], :depends => ['jquery-ui-draggable']

Spider::Template.define_named_asset 'jquery-ui-resizable', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.resizable.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-selectable', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.selectable.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-sortable', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.sortable.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-accordion', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.accordion.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-autocomplete', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.autocomplete.js', Spider::Components]
], :depends => ['jquery-ui-core', 'jquery-ui-menu']

Spider::Template.define_named_asset 'jquery-ui-button', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.button.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-dialog', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.dialog.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-slider', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.slider.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-tabs', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.tabs.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-datepicker', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.datepicker.js', Spider::Components],
    [:js, 'jquery-ui-datepicker-locale', :runtime]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-progressbar', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.progressbar.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-menu', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.menu.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-spinner', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.spinner.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-ui-tooltip', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.tooltip.js', Spider::Components]
], :depends => ['jquery-ui-core']

Spider::Template.define_named_asset 'jquery-effects', [
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-blind.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-bounce.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-clip.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-drop.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-explode.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-fade.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-fold.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-highlight.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-pulsate.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-scale.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-shake.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-slide.js', Spider::Components],
    [:js, 'js/jquery/jquery-ui-1.9.2/ui/jquery.ui.effect-transfer.js', Spider::Components]
], :depends => ['jquery-ui-core']

# jQuery Tools (http://flowplayer.org/tools/)

Spider::Template.define_named_asset 'jquery-tools-overlay', [
    [:js, 'js/jquery/jquery-tools-1.2.5/overlay/overlay.js', Spider::Components]
], :depends => ['jquery']

Spider::Template.define_named_asset 'jquery-tools-overlay-apple', [
    [:js, 'js/jquery/jquery-tools-1.2.5/overlay/overlay.apple.js', Spider::Components]
], :depends => ['jquery-tools-overlay']

Spider::Template.define_named_asset 'jquery-tools-scrollable', [
    [:js, 'js/jquery/jquery-tools-1.2.5/scrollable/scrollable.js', Spider::Components]
], :depends => ['jquery']

Spider::Template.define_named_asset 'jquery-tools-tabs', [
    [:js, 'js/jquery/jquery-tools-1.2.5/tabs/tabs.js', Spider::Components],
    [:css, 'js/jquery/jquery-tools-1.2.5/tabs/tabs.css', Spider::Components]
], :depends => ['jquery']

Spider::Template.define_named_asset 'jquery-tools-expose', [
    [:js, 'js/jquery/jquery-tools-1.2.5/toolbox/toolbox.expose.js', Spider::Components]
], :depends => ['jquery']

Spider::Template.define_named_asset 'jquery-tools-tooltip', [
    [:js, 'js/jquery/jquery-tools-1.2.5/tooltip/tooltip.js', Spider::Components],
    [:js, 'js/jquery/jquery-tools-1.2.5/tooltip/tooltip.dynamic.js', Spider::Components]
], :depends => ['jquery']

Spider::Template.define_named_asset 'less', [
     [:js, 'js/less-1.1.3.min.js', Spider::Components, {:compressed => true}]
 ]

Spider::Template.define_named_asset 'bootstrap-sass', [
    [:css, 'bootstrap/scss/bootstrap.scss', Spider::Components]
]

Spider::Template.define_named_asset 'bootstrap-alerts', [
    [:js, 'bootstrap/js/bootstrap-alerts.js', Spider::Components]
]

Spider::Template.define_named_asset 'bootstrap-buttons', [
    [:js, 'bootstrap/js/bootstrap-buttons.js', Spider::Components]
]

Spider::Template.define_named_asset 'bootstrap-dropdown', [
    [:js, 'bootstrap/js/bootstrap-dropdown.js', Spider::Components]
]

Spider::Template.define_named_asset 'bootstrap-modal', [
    [:js, 'bootstrap/js/bootstrap-modal.js', Spider::Components]
]

Spider::Template.define_named_asset 'bootstrap-tooltip', [
    [:js, 'bootstrap/js/bootstrap-tooltip.js', Spider::Components]
]


Spider::Template.define_named_asset 'bootstrap-popover', [
    [:js, 'bootstrap/js/bootstrap-popover.js', Spider::Components]
]

Spider::Template.define_named_asset 'bootstrap-scrollspy', [
    [:js, 'bootstrap/js/bootstrap-scrollspy.js', Spider::Components]
]

Spider::Template.define_named_asset 'bootstrap-tabs', [
    [:js, 'bootstrap/js/bootstrap-tabs.js', Spider::Components]
]

Spider::Template.define_named_asset 'bootstrap-twipsy', [
    [:js, 'bootstrap/js/bootstrap-twipsy.js', Spider::Components]
]