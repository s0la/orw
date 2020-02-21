bg = '#1c1d21'
fg = '#3a3b3f'
sbg = '#1a1b1f'
sfg = '#ada9a8'
mfg = '#666660'
sbbg = '#191a1e'

font_size = 8
v_padding = 3
h_padding = 20

config.load_autoconfig()

c.fonts.tabs = f'{font_size}pt Roboto'
c.fonts.hints = f'{font_size + 2}pt Roboto'
c.hints.border = f'2px solid {mfg}'
c.fonts.statusbar = f'{font_size}pt Roboto'
c.fonts.downloads = f'{font_size}pt Roboto'
c.fonts.contextmenu = f'{font_size}pt Roboto'
c.fonts.completion.entry = f'{font_size + 1}pt Roboto'
c.fonts.completion.category = f'{font_size + 2}pt Roboto'

# c.scrolling.bar = 'never'
c.completion.height = '35%'
c.completion.scrollbar.width = 0

c.session.lazy_restore = True
#c.url.start_pages = ['/home/sola/Desktop/home.html']
#c.url.start_pages = ['https://start.duckduckgo.com']
c.url.default_page = '~/.orw/dotfiles/.config/qutebrowser/home.html'

#c.tabs.show = 'multiple'
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

c.statusbar.hide = True
c.statusbar.position = 'bottom'
c.statusbar.widgets = ['history', 'url', 'scroll', 'progress']
c.statusbar.padding = { 'top': v_padding, 'bottom': v_padding, 'left': v_padding, 'right': h_padding }

c.colors.completion.category.bg = sbbg
c.colors.completion.category.border.bottom = sbbg
c.colors.completion.category.border.top = sbbg
c.colors.completion.category.fg = sfg
c.colors.completion.even.bg = bg
c.colors.completion.fg = fg
c.colors.completion.scrollbar.fg = sbg
c.colors.completion.item.selected.bg = sbg
c.colors.completion.item.selected.border.bottom = sbg
c.colors.completion.item.selected.border.top = sbg
c.colors.completion.item.selected.fg = sfg
c.colors.completion.item.selected.match.fg = mfg
c.colors.completion.match.fg = mfg
c.colors.completion.odd.bg = bg

c.colors.contextmenu.menu.bg = bg
c.colors.contextmenu.menu.fg = fg
c.colors.contextmenu.selected.bg = sbg
c.colors.contextmenu.selected.fg = sfg

c.colors.downloads.bar.bg = sbbg
c.colors.downloads.error.bg = 'red'
c.colors.downloads.error.fg = fg
c.colors.downloads.start.bg = bg
c.colors.downloads.start.fg = sbg
c.colors.downloads.stop.bg = mfg
c.colors.downloads.stop.fg = bg
c.colors.downloads.system.bg = 'rgb'
c.colors.downloads.system.fg = 'rgb'

c.colors.hints.bg = sbbg
c.colors.hints.fg = sfg
c.colors.hints.match.fg = mfg

c.colors.prompts.bg = sbbg
c.colors.prompts.border = '3px solid {sbbg}'
c.colors.prompts.fg = fg
c.colors.prompts.selected.bg = sbg

c.colors.statusbar.caret.bg = sbbg
c.colors.statusbar.caret.fg = fg
c.colors.statusbar.caret.selection.bg = sbbg
c.colors.statusbar.caret.selection.fg = fg
c.colors.statusbar.command.bg = sbbg
c.colors.statusbar.command.fg = fg
c.colors.statusbar.command.private.bg = sbbg
c.colors.statusbar.command.private.fg = fg
c.colors.statusbar.insert.bg = sbbg
c.colors.statusbar.insert.fg = mfg
c.colors.statusbar.normal.bg = sbbg
c.colors.statusbar.normal.fg = fg
c.colors.statusbar.passthrough.bg = sbbg
c.colors.statusbar.passthrough.fg = fg
c.colors.statusbar.private.bg = sbbg
c.colors.statusbar.private.fg = fg
c.colors.statusbar.progress.bg = mfg
c.colors.statusbar.url.error.fg = fg
c.colors.statusbar.url.fg = sfg
c.colors.statusbar.url.hover.fg = 'aqua'
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
