# One script per phone app; each extends PhoneApp. phone.gd's shell
# dispatches an open app here by state.phoneNav.app — adding an app is one
# script + one row here, plus its systems/phone_apps.gd grid entry and
# systems/phone_nav.gd APPS id.
class_name PhoneAppRegistry
extends RefCounted

static var REGISTRY: Dictionary = {
	"alarms": AlarmsApp,
	"bizbrief": BizBriefApp,
	"dialer": DialerApp,
	"messages": MessagesApp,
	"notes": NotesApp,
	"factions": FactionsApp,
	"ticker": TickerApp,
	"profile": ProfileApp,
	"saveload": SaveLoadApp,
	"settings": SettingsApp,
	"notifications": NotificationsApp,
	"bank": BankApp,
	"property": PropertyApp,
	"debug": DebugApp,
}
