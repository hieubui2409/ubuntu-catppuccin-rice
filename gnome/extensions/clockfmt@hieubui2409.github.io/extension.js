import GLib from 'gi://GLib';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const FORMAT = '%Y-%m-%d  %H:%M:%S';

export default class ClockFormatExtension extends Extension {
    enable() {
        const dateMenu = Main.panel.statusArea.dateMenu;
        this._clock = dateMenu?._clockDisplay;
        if (!this._clock)
            return;

        this._original = this._clock.text;
        this._tick();
        this._timeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this._tick();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _tick() {
        const text = GLib.DateTime.new_now_local().format(FORMAT);
        if (text && this._clock && this._clock.text !== text)
            this._clock.text = text;
    }

    disable() {
        if (this._timeoutId) {
            GLib.Source.remove(this._timeoutId);
            this._timeoutId = null;
        }
        // Trả đồng hồ về cho GNOME tự vẽ
        const dateMenu = Main.panel.statusArea.dateMenu;
        if (this._clock && dateMenu?._clock)
            this._clock.text = dateMenu._clock.clock;
        this._clock = null;
    }
}
