bg = '#1a1f20'
fg = '#313839'
sbg = '#101314'
sfg = '#c8a789'
mfg = '#88a0a0'
sbbg = '#101314'

font_size = 8
v_padding = 3
h_padding = 20

config.load_autoconfig()

c.backend = 'webengine'

c.hints.border = f'2px solid {mfg}'
c.fonts.hints = f'{font_size + 2}pt Roboto'
c.fonts.statusbar = f'{font_size}pt Roboto'
c.fonts.downloads = f'{font_size}pt Roboto'
c.fonts.contextmenu = f'{font_size}pt Roboto'
c.fonts.tabs.selected = f'{font_size}pt Roboto'
c.fonts.tabs.unselected = f'{font_size}pt Roboto'
c.fonts.completion.entry = f'{font_size + 1}pt Roboto'
c.fonts.completion.category = f'{font_size + 2}pt Roboto'

c.completion.height = '35%'
c.completion.scrollbar.width = 0
c.completion.open_categories = ['history']

c.session.lazy_restore = True
c.url.default_page = '~/.orw/dotfiles/.config/qutebrowser/home.html'

c.tabs.background = True
c.tabs.indicator.width = 0
c.tabs.last_close = 'close'
c.tabs.favicons.show = 'never'
c.tabs.title.format = '{audio} {index}: {current_title}'
c.tabs.padding = { 'top': v_padding, 'bottom': v_padding, 'left': h_padding, 'right': h_padding }

c.downloads.position = 'bottom'
c.downloads.remove_finished = 60000
c.downloads.location.prompt = False
c.downloads.location.directory = "~/Downloads"

c.statusbar.show = 'in-mode'
c.statusbar.position = 'bottom'
c.statusbar.widgets = ['history', 'url', 'scroll', 'progress']
c.statusbar.padding = { 'top': v_padding, 'bottom': v_padding, 'left': v_padding, 'right': h_padding }

#c.colors.completion.category.bg = bg
#c.colors.completion.category.border.bottom = bg
#c.colors.completion.category.border.top = bg
#c.colors.completion.category.fg = sfg
#c.colors.completion.even.bg = bg
#c.colors.completion.fg = fg
#c.colors.completion.scrollbar.fg = sbg
#c.colors.completion.item.selected.bg = sbg
#c.colors.completion.item.selected.border.bottom = sbg
#c.colors.completion.item.selected.border.top = sbg
#c.colors.completion.item.selected.fg = sfg
#c.colors.completion.item.selected.match.fg = mfg
#c.colors.completion.match.fg = mfg
#c.colors.completion.odd.bg = bg

c.colors.completion.category.bg = sbg
c.colors.completion.category.border.bottom = sbg
c.colors.completion.category.border.top = sbg
c.colors.completion.category.fg = sfg
c.colors.completion.even.bg = sbg
c.colors.completion.fg = fg
c.colors.completion.scrollbar.fg = sbg
c.colors.completion.item.selected.bg = sbg
c.colors.completion.item.selected.border.bottom = sbg
c.colors.completion.item.selected.border.top = sbg
c.colors.completion.item.selected.fg = sfg
c.colors.completion.item.selected.match.fg = mfg
c.colors.completion.match.fg = mfg
c.colors.completion.odd.bg = sbg

c.colors.contextmenu.menu.bg = bg
c.colors.contextmenu.menu.fg = fg
c.colors.contextmenu.selected.bg = sbg
c.colors.contextmenu.selected.fg = sfg

c.colors.downloads.bar.bg = bg
c.colors.downloads.error.bg = 'red'
c.colors.downloads.error.fg = fg
c.colors.downloads.start.bg = bg
c.colors.downloads.start.fg = sfg
c.colors.downloads.stop.bg = mfg
c.colors.downloads.stop.fg = bg
c.colors.downloads.system.bg = 'rgb'
c.colors.downloads.system.fg = 'rgb'

c.colors.hints.bg = bg
c.colors.hints.fg = sfg
c.colors.hints.match.fg = mfg

c.colors.prompts.bg = bg
c.colors.prompts.border = '3px solid {bg}'
c.colors.prompts.fg = fg
c.colors.prompts.selected.bg = sbg

#c.colors.statusbar.caret.bg = bg
#c.colors.statusbar.caret.fg = fg
#c.colors.statusbar.caret.selection.bg = bg
#c.colors.statusbar.caret.selection.fg = fg
#c.colors.statusbar.command.bg = bg
#c.colors.statusbar.command.fg = fg
#c.colors.statusbar.command.private.bg = bg
#c.colors.statusbar.command.private.fg = fg
#c.colors.statusbar.insert.bg = bg
#c.colors.statusbar.insert.fg = mfg
#c.colors.statusbar.normal.bg = bg
#c.colors.statusbar.normal.fg = fg
#c.colors.statusbar.passthrough.bg = bg
#c.colors.statusbar.passthrough.fg = fg
#c.colors.statusbar.private.bg = bg
#c.colors.statusbar.private.fg = fg
#c.colors.statusbar.progress.bg = mfg
#c.colors.statusbar.url.error.fg = fg
#c.colors.statusbar.url.fg = sfg
#c.colors.statusbar.url.hover.fg = sfg
#c.colors.statusbar.url.success.http.fg = sfg
#c.colors.statusbar.url.success.https.fg = sfg
#c.colors.statusbar.url.warn.fg = 'yellow'

c.colors.statusbar.caret.bg = sbg
c.colors.statusbar.caret.fg = fg
c.colors.statusbar.caret.selection.bg = sbg
c.colors.statusbar.caret.selection.fg = fg
c.colors.statusbar.command.bg = sbg
c.colors.statusbar.command.fg = fg
c.colors.statusbar.command.private.bg = sbg
c.colors.statusbar.command.private.fg = fg
c.colors.statusbar.insert.bg = sbg
c.colors.statusbar.insert.fg = mfg
c.colors.statusbar.normal.bg = sbg
c.colors.statusbar.normal.fg = fg
c.colors.statusbar.passthrough.bg = sbg
c.colors.statusbar.passthrough.fg = fg
c.colors.statusbar.private.bg = sbg
c.colors.statusbar.private.fg = fg
c.colors.statusbar.progress.bg = mfg
c.colors.statusbar.url.error.fg = fg
c.colors.statusbar.url.fg = sfg
c.colors.statusbar.url.hover.fg = sfg
c.colors.statusbar.url.success.http.fg = sfg
c.colors.statusbar.url.success.https.fg = sfg
c.colors.statusbar.url.warn.fg = 'yellow'

c.colors.tabs.bar.bg = bg
c.colors.tabs.even.bg = bg
c.colors.tabs.even.fg = fg
c.colors.tabs.odd.bg = bg
c.colors.tabs.odd.fg = fg
c.colors.tabs.pinned.even.bg = bg
c.colors.tabs.pinned.even.fg = fg
c.colors.tabs.pinned.odd.bg = bg
c.colors.tabs.pinned.odd.fg = fg
c.colors.tabs.pinned.selected.even.bg = sbg
c.colors.tabs.pinned.selected.even.fg = sfg
c.colors.tabs.pinned.selected.odd.bg = sbg
c.colors.tabs.pinned.selected.odd.fg = sfg
c.colors.tabs.selected.even.bg = sbg
c.colors.tabs.selected.even.fg = sfg
c.colors.tabs.selected.odd.bg = sbg
c.colors.tabs.selected.odd.fg = sfg

# Bindings
config.bind('p', 'hint links spawn mpv {hint-url}')
