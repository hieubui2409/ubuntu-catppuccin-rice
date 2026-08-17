/* extension.js — Net Speed (Catppuccin)
 *
 * Cổng GJS của plasmoid com.hieubt.netspeed bên bản KDE: hai dòng ↓/↑, bề rộng
 * cố định để số không nhảy, màu peach/teal của Catppuccin Mocha.
 *
 * Tốc độ đọc từ /proc/net/dev, bỏ qua lo/veth/docker/br- để không đếm trùng.
 */

import GObject from 'gi://GObject';
import St from 'gi://St';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Clutter from 'gi://Clutter';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const REFRESH_SECONDS = 1;
const DOWN_COLOR = '#fab387'; // peach
const UP_COLOR = '#94e2d5';   // teal

// Bỏ qua interface ảo — nếu không tốc độ bị đếm hai lần qua docker/veth.
const SKIP_PREFIXES = ['lo', 'veth', 'docker', 'br-', 'virbr', 'vmnet', 'tun', 'tap'];

/** Đọc tổng byte nhận/gửi của mọi interface vật lý. */
function readTotals() {
    let rx = 0, tx = 0;
    try {
        const [ok, bytes] = GLib.file_get_contents('/proc/net/dev');
        if (!ok)
            return null;
        const text = new TextDecoder().decode(bytes);
        for (const line of text.split('\n').slice(2)) {
            const idx = line.indexOf(':');
            if (idx < 0)
                continue;
            const name = line.slice(0, idx).trim();
            if (SKIP_PREFIXES.some(p => name.startsWith(p)))
                continue;
            const cols = line.slice(idx + 1).trim().split(/\s+/);
            rx += parseInt(cols[0], 10) || 0;
            tx += parseInt(cols[8], 10) || 0;
        }
    } catch {
        return null;
    }
    return {rx, tx};
}

/** Định dạng giống hàm fmt() trong QML: 888.8M / 512K / 42 */
function formatSpeed(bytesPerSec) {
    const b = bytesPerSec || 0;
    if (b >= 1073741824)
        return `${(b / 1073741824).toFixed(1)}G`;
    if (b >= 1048576)
        return `${(b / 1048576).toFixed(1)}M`;
    if (b >= 1024)
        return `${Math.round(b / 1024)}K`;
    return `${Math.round(b)}`;
}

const NetSpeedIndicator = GObject.registerClass(
class NetSpeedIndicator extends PanelMenu.Button {
    _init(settings) {
        super._init(0.5, 'Net Speed', true);
        this._settings = settings;
        this._prev = readTotals();
        this._prevTime = GLib.get_monotonic_time();

        const box = new St.BoxLayout({
            vertical: true,
            style_class: 'hieubt-netspeed-box',
            y_align: Clutter.ActorAlign.CENTER,
        });

        this._downLabel = new St.Label({
            style_class: 'hieubt-netspeed-label',
            y_align: Clutter.ActorAlign.CENTER,
        });
        this._upLabel = new St.Label({
            style_class: 'hieubt-netspeed-label',
            y_align: Clutter.ActorAlign.CENTER,
        });

        box.add_child(this._downLabel);
        box.add_child(this._upLabel);
        this.add_child(box);

        this._applyStyle();
        this._styleId = this._settings.connect('changed', () => this._applyStyle());

        this._update();
        this._timeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT, REFRESH_SECONDS, () => {
                this._update();
                return GLib.SOURCE_CONTINUE;
            });
    }

    _applyStyle() {
        const size = this._settings.get_int('font-size');
        const width = this._settings.get_int('label-width');
        const down = this._settings.get_string('download-color') || DOWN_COLOR;
        const up = this._settings.get_string('upload-color') || UP_COLOR;
        // width cố định + text-align:right ⇒ số đổi mà panel không co giãn
        const common = `font-size:${size}px; font-feature-settings:"tnum"; width:${width}px; text-align:right;`;
        this._downLabel.set_style(`${common} color:${down};`);
        this._upLabel.set_style(`${common} color:${up};`);
    }

    _update() {
        const now = readTotals();
        const time = GLib.get_monotonic_time();
        if (!now || !this._prev) {
            this._prev = now;
            this._prevTime = time;
            return;
        }
        const seconds = (time - this._prevTime) / 1e6;
        if (seconds <= 0)
            return;

        // Counter trong /proc reset khi interface down — kẹp về 0 thay vì hiện số âm.
        const down = Math.max(0, (now.rx - this._prev.rx) / seconds);
        const up = Math.max(0, (now.tx - this._prev.tx) / seconds);

        this._downLabel.set_text(`↓ ${formatSpeed(down)}`);
        this._upLabel.set_text(`↑ ${formatSpeed(up)}`);

        this._prev = now;
        this._prevTime = time;
    }

    destroy() {
        if (this._timeoutId) {
            GLib.Source.remove(this._timeoutId);
            this._timeoutId = null;
        }
        if (this._styleId) {
            this._settings.disconnect(this._styleId);
            this._styleId = null;
        }
        super.destroy();
    }
});

/* Đồng hồ panel: GNOME hardcode "%a %b %e" nên locale không đổi được thứ tự
 * ngày/tháng. Ta ghi thẳng nhãn theo GLib.DateTime.format() mỗi giây. */
class ClockFormatter {
    constructor(settings) {
        this._settings = settings;
        this._clock = Main.panel.statusArea.dateMenu?._clockDisplay;
        if (!this._clock)
            return;

        // Giữ lại binding gốc để trả nguyên trạng lúc disable()
        this._original = this._clock.text;
        this._binding = this._clock.get_binding_pool?.() ?? null;
        Main.panel.statusArea.dateMenu._clock?.disconnectObject?.(this._clock);

        this._update();
        this._timeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT, 1, () => {
                this._update();
                return GLib.SOURCE_CONTINUE;
            });
    }

    _update() {
        const fmt = this._settings.get_string('clock-format');
        const text = GLib.DateTime.new_now_local().format(fmt);
        if (text && this._clock.text !== text)
            this._clock.text = text;
    }

    destroy() {
        if (this._timeoutId) {
            GLib.Source.remove(this._timeoutId);
            this._timeoutId = null;
        }
        // Ép GNOME vẽ lại đồng hồ theo cách của nó
        const dateMenu = Main.panel.statusArea.dateMenu;
        if (dateMenu?._clock && this._clock) {
            this._clock.text = dateMenu._clock.clock;
            dateMenu._clock.notify('clock');
        }
        this._clock = null;
    }
}

export default class NetSpeedExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._indicator = new NetSpeedIndicator(this._settings);
        // Chèn vào cuối hộp trái. Tham số thứ 3 là CHỈ SỐ chèn, không phải cờ —
        // truyền -1 làm insert_child_at_index() hỏng và panel dựng ra rỗng.
        const index = Main.panel._leftBox.get_n_children();
        Main.panel.addToStatusArea(this.uuid, this._indicator, index, 'left');

        if (this._settings.get_boolean('clock-format-enabled'))
            this._clockFormatter = new ClockFormatter(this._settings);
    }

    disable() {
        this._clockFormatter?.destroy();
        this._clockFormatter = null;
        this._indicator?.destroy();
        this._indicator = null;
        this._settings = null;
    }
}
