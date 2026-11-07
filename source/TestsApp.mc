import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Timer;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class TestsApp extends Application.AppBase {
    public function initialize() {
        AppBase.initialize();
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new $.TestsView();
        return [view, new $.TestsDelegate(view)];
    }
}

class TestsView extends WatchUi.View {
    private const _COLOR_BG = 0x17100B;
    private const _COLOR_PANEL = 0x281C15;
    private const _COLOR_BORDER = 0x59402D;
    private const _COLOR_TEXT = 0xF4EEE7;
    private const _COLOR_MUTED = 0xB7A28C;
    private const _COLOR_LIME = 0xF2C94C;
    private const _COLOR_CYAN = 0x4797D3;
    private const _COLOR_ORANGE = 0xE8782E;
    private const _COLOR_RED = 0xD44A3E;
    private const _COLOR_BROWN = 0x4A3324;

    private var _section as Number = 0;
    private var _screen as Number = 0;
    private var _lastDrawnScreen as Number = -1;
    private var _transitionTicks as Number = 0;
    private var _choice as Number = 0;
    private var _lucStatsPage as Boolean = false;
    private var _objective as Number = 0;
    private var _sex as Number = 0;
    private var _viewWidth as Number = 454;
    private var _viewHeight as Number = 454;
    private var _running as Boolean = false;
    private var _pauseFlash as Boolean = false;
    private var _pauseTicks as Number = 0;
    private var _countdownDs as Number = 0;
    private var _countdownReturnScreen as Number = 1;
    private var _infoReturnScreen as Number = 1;
    private var _elapsedDs as Number = 0;
    private var _shuttles as Number = 0;
    private var _currentLevel as Number = 1;
    private var _nextShuttleDs as Number = 0;
    private var _reps as Number = 0;
    private var _previousStats as Array<Number>?;
    private var _historyChoice as Number = 0;
    private var _historySection as Number = 1;
    private var _historyFromMenu as Boolean = false;
    private var _historyCursor as Number = 0;
    private var _historyCount as Number = 0;
    private var _historyScores as Array<Number> = [];
    private var _historyElapsed as Array<Number> = [];
    private var _historyAllers as Array<Number> = [];
    private var _historyReps as Array<Number> = [];
    private var _historyTimestamps as Array<Number> = [];
    private var _historyObjectives as Array<Number> = [];
    private var _newRecord as Boolean = false;
    private var _celebrationTicks as Number = 0;
    private var _timer as Timer.Timer?;

    public function initialize() {
        View.initialize();
    }

    public function onShow() as Void {
        var timer = new Timer.Timer();
        timer.start(method(:onTick), 100, true);
        _timer = timer;
    }

    public function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    public function onTick() as Void {
        if (_transitionTicks > 0) {
            _transitionTicks--;
            WatchUi.requestUpdate();
        }

        if (_screen == 7 && _celebrationTicks > 0) {
            _celebrationTicks--;
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 2 && !_running) {
            _pauseTicks++;
            if (_pauseTicks >= 6) {
                _pauseTicks = 0;
                _pauseFlash = !_pauseFlash;
                WatchUi.requestUpdate();
            }
            return;
        }

        if (_screen == 7 && _celebrationTicks > 0) {
            _celebrationTicks--;
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 6) {
            _countdownDs--;
            if (_countdownDs <= 0) {
                _countdownDs = 0;
                _screen = 2;
                _running = true;
                if (Attention has :playTone) {
                    Attention.playTone(Attention.TONE_START);
                }
            }
            WatchUi.requestUpdate();
            return;
        }

        if (!_running) {
            return;
        }

        _elapsedDs++;
        if (_section == 1) {
            if ((_elapsedDs % 600) == 0) {
                _currentLevel++;
            }
            if (_elapsedDs >= _nextShuttleDs) {
                _shuttles++;
                var speedTenths = 85 + ((_currentLevel - 1) * 5);
                _nextShuttleDs += Math.round(7200.0 / speedTenths).toNumber();
                if (Attention has :vibrate) {
                    Attention.vibrate([new Attention.VibeProfile(35, 100)]);
                }
                if (Attention has :playTone) {
                    Attention.playTone(Attention.TONE_LOUD_BEEP);
                }
            }
        }

        if ((_elapsedDs % 10) == 0 || _section == 1) {
            WatchUi.requestUpdate();
        }
    }

    public function changeChoice(direction as Number) as Void {
        if (_screen == 0) {
            _sex = (_sex + direction + 2) % 2;
        } else if (_screen == 5) {
            _choice = (_choice + direction + 3) % 3;
        } else if (_screen == 3) {
            _objective = (_objective + direction + 3) % 3;
        } else if (_screen == 9) {
            _historyChoice = (_historyChoice + direction + 3) % 3;
        } else if (_screen == 7 && _historyCount > 0) {
            _historyCursor = (_historyCursor + direction + _historyCount) % _historyCount;
        } else if (_screen == 2 && _section == 1) {
            _lucStatsPage = direction > 0;
        } else if (_screen == 2 && _section == 3) {
            if (direction > 0) {
                _reps++;
            } else if (direction < 0 && _reps > 0) {
                _reps--;
            }
        }
        WatchUi.requestUpdate();
    }

    public function handleSelect() as Void {
        if (_screen == 0) {
            _screen = 5;
        } else if (_screen == 5) {
            _section = _choice + 1;
            resetSession();
            _screen = 1;
        } else if (_screen == 1) {
            if (_section == 1) {
                _screen = 3;
            } else {
                showActivityInfo(1);
            }
        } else if (_screen == 3) {
            _screen = 4;
        } else if (_screen == 4) {
            showActivityInfo(4);
        } else if (_screen == 8) {
            startRun();
        } else if (_screen == 9) {
            _historySection = _historyChoice + 1;
            _section = _historySection;
            _historyFromMenu = true;
            loadHistory(_historySection);
            _screen = 7;
        } else if (_screen == 7) {
            goHome();
        } else if (_screen == 6) {
            return;
        } else {
            toggleRun();
        }
        WatchUi.requestUpdate();
    }

    public function handleTap(x as Number, y as Number) as Void {
        var center = _viewWidth / 2;
        var centerY = _viewHeight / 2;
        var cardWidth = _viewWidth - 160;
        var cardX = center - cardWidth / 2;

        if (_screen == 0) {
            var firstCardY = centerY - 76;
            var secondCardY = centerY + 2;
            if (x >= cardX && x <= cardX + cardWidth && y >= firstCardY && y <= firstCardY + 60) {
                _sex = 0;
                _screen = 5;
            } else if (x >= cardX && x <= cardX + cardWidth && y >= secondCardY && y <= secondCardY + 60) {
                _sex = 1;
                _screen = 5;
            }
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 5) {
            if (y >= centerY - 80 && y <= centerY + 65) {
                handleSelect();
            } else if (y > centerY + 65 && x < center) {
                changeChoice(1);
            } else if (y > centerY + 65) {
                handleSelect();
            }
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 9) {
            if (y >= centerY - 80 && y <= centerY + 65) {
                handleSelect();
            } else if (y > centerY + 65 && x < center) {
                changeChoice(1);
            } else if (y > centerY + 65) {
                handleSelect();
            }
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 1) {
            if (y > centerY + 45 && x < center) {
                handleSelect();
            } else if (y > centerY + 45) {
                goHome();
            }
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 3) {
            var firstObjectiveY = centerY - 82;
            for (var objective = 0; objective < 3; objective++) {
                var cardY = firstObjectiveY + (objective * 51);
                if (x >= cardX && x <= cardX + cardWidth && y >= cardY && y <= cardY + 44) {
                    _objective = objective;
                    _screen = 4;
                    WatchUi.requestUpdate();
                    return;
                }
            }
            if (y > centerY + 45 && x < center) {
                changeChoice(1);
            } else if (y > centerY + 45) {
                handleSelect();
            }
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 4) {
            if (y >= centerY - 80 && y <= centerY + 65) {
                handleSelect();
            } else if (y > centerY + 65 && x < center) {
                goHome();
            } else if (y > centerY + 65) {
                handleSelect();
            }
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 8) {
            if (y > centerY + 20 && x < center) {
                goHome();
            } else if (y > centerY + 20) {
                startRun();
            }
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 7) {
            if (y > centerY + 95) {
                goHome();
            } else {
                selectHistoryPoint(x);
            }
            return;
        }

        if (_screen == 6) {
            if (y > centerY + 20) {
                goHome();
            }
            WatchUi.requestUpdate();
            return;
        }

        if (_screen == 2 && _section == 1) {
            if (y > centerY + 25) {
                if (_lucStatsPage) {
                } else {
                    _lucStatsPage = true;
                }
            }
        } else if (_screen == 2 && _section == 2) {
            if (y > centerY + 25) {
                if (x < center) {
                    toggleRun();
                } else {
                    goHome();
                }
            }
        } else if (_screen == 2 && _section == 3) {
            if (y > centerY + 25) {
                if (x < center - 45) {
                    _reps++;
                } else if (x > center + 45) {
                    if (_reps > 0) {
                        _reps--;
                    }
                } else {
                    toggleRun();
                }
            }
        }
        WatchUi.requestUpdate();
    }

    public function handleKey(key as Key) as Boolean {
        if (key == WatchUi.KEY_ESC) {
            return goHome();
        }
        if (key == WatchUi.KEY_MENU) {
            handleMenu();
            return true;
        }
        return false;
    }

    private function startRun() as Void {
        _countdownReturnScreen = _screen;
        resetSession();
        _countdownDs = 50;
        _screen = 6;
        _running = false;
        _pauseFlash = false;
        _pauseTicks = 0;
        WatchUi.requestUpdate();
    }

    private function showActivityInfo(returnScreen as Number) as Void {
        _infoReturnScreen = returnScreen;
        _screen = 8;
        WatchUi.requestUpdate();
    }

    private function toggleRun() as Void {
        _running = !_running;
        _pauseFlash = false;
        _pauseTicks = 0;
        WatchUi.requestUpdate();
    }

    public function resetSession() as Void {
        if (_screen == 6) {
            _screen = _countdownReturnScreen;
            _countdownDs = 0;
        }
        _running = false;
        _pauseFlash = false;
        _pauseTicks = 0;
        _elapsedDs = 0;
        _shuttles = 0;
        _currentLevel = 1;
        _reps = 0;
        _lucStatsPage = false;
        _nextShuttleDs = 7200 / 85;
        WatchUi.requestUpdate();
    }

    public function handleMenu() as Void {
        if (_screen == 2) {
            goHome();
        } else if (_screen == 7) {
            if (_historyFromMenu) {
                _screen = 9;
            } else {
                _section = 0;
                _screen = 5;
            }
            WatchUi.requestUpdate();
        } else if (_screen == 5 || _screen == 1 || _screen == 3 || _screen == 4 || _screen == 8) {
            if (_screen == 5) {
                _historyChoice = _choice;
                _historySection = _choice + 1;
            } else {
                _historyChoice = _section - 1;
                _historySection = _section;
            }
            _screen = 9;
            _section = _historySection;
            loadHistory(_historySection);
            WatchUi.requestUpdate();
        } else if (_screen == 9) {
            _screen = 5;
            WatchUi.requestUpdate();
        } else {
            resetSession();
        }
    }

    public function goHome() as Boolean {
        if (_screen == 0) {
            return false;
        }
        if (_screen == 2) {
            saveSession();
            _running = false;
            _historySection = _section;
            _historyFromMenu = false;
            loadHistory(_historySection);
            _historyCursor = _historyCount - 1;
            _screen = 7;
            _lucStatsPage = false;
        } else if (_screen == 7) {
            if (_historyFromMenu) {
                _screen = 9;
            } else {
                _section = 0;
                _screen = 5;
            }
        } else if (_screen == 9) {
            _screen = 5;
        } else if (_screen == 6) {
            _running = false;
            _screen = _countdownReturnScreen;
            _countdownDs = 0;
        } else if (_screen == 4) {
            _screen = 3;
        } else if (_screen == 8) {
            _screen = _infoReturnScreen;
        } else if (_screen == 3) {
            _running = false;
            _screen = 1;
        } else if (_screen == 1) {
            _running = false;
            _screen = 5;
        } else if (_screen == 5) {
            _running = false;
            _screen = 0;
            _section = 0;
        } else {
            _running = false;
            _screen = 0;
            _section = 0;
        }
        WatchUi.requestUpdate();
        return true;
    }

    private function drawCentered(dc as Dc, x as Numeric, y as Numeric, font as Graphics.FontType, text as String, color as ColorType) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var fontHeight = dc.getFontHeight(font);
        var diameter = width < height ? width : height;
        var radius = (diameter / 2) - 12 - (fontHeight / 2);
        var verticalOffset = (y + fontHeight / 2) - (height / 2);
        var chordSquared = (radius * radius) - (verticalOffset * verticalOffset);
        if (chordSquared <= 0) {
            return;
        }
        var halfChord = Math.sqrt(chordSquared);
        var textWidth = dc.getTextWidthInPixels(text, font);
        var horizontalOffset = x - width / 2;
        if (horizontalOffset < 0) {
            horizontalOffset = 0 - horizontalOffset;
        }
        if (horizontalOffset + (textWidth / 2) > halfChord) {
            return;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawActionHint(dc as Dc, x as Number, y as Number, key as String, action as String, color as ColorType) as Void {
        var icon = 1;
        if (key == "SELECT") {
            icon = action == "PAUSE" ? 5 : (action == "CHRONO" ? 9 : 4);
        } else if (key == "BACK") {
            icon = 11;
        } else if (key == "DOWN") {
            icon = action == "-1" ? 12 : 7;
        } else if (key == "UP") {
            icon = action == "+1" ? 13 : 7;
        } else if (key == "UP / DOWN") {
            icon = 8;
        }

        drawActionIcon(dc, x, y + 7, icon, color);
    }

    private function drawActionIcon(dc as Dc, x as Number, y as Number, icon as Number, color as ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        if (icon == 1) {
            dc.drawLine(x, y + 7, x, y - 6);
            dc.drawLine(x, y - 6, x - 5, y - 1);
            dc.drawLine(x, y - 6, x + 5, y - 1);
        } else if (icon == 2) {
            dc.drawLine(x, y - 7, x, y + 6);
            dc.drawLine(x, y + 6, x - 5, y + 1);
            dc.drawLine(x, y + 6, x + 5, y + 1);
        } else if (icon == 3) {
            dc.drawLine(x + 7, y, x - 7, y);
            dc.drawLine(x - 7, y, x - 1, y - 6);
            dc.drawLine(x - 7, y, x - 1, y + 6);
        } else if (icon == 4) {
            dc.drawLine(x - 4, y - 7, x + 7, y);
            dc.drawLine(x + 7, y, x - 4, y + 7);
            dc.drawLine(x - 4, y - 7, x - 4, y + 7);
        } else if (icon == 5) {
            dc.drawLine(x - 4, y - 7, x - 4, y + 7);
            dc.drawLine(x + 4, y - 7, x + 4, y + 7);
        } else if (icon == 7) {
            dc.drawLine(x - 7, y + 7, x - 7, y + 1);
            dc.drawLine(x, y + 7, x, y - 4);
            dc.drawLine(x + 7, y + 7, x + 7, y - 7);
            dc.drawLine(x - 9, y + 8, x + 9, y + 8);
        } else if (icon == 8) {
            dc.drawLine(x - 5, y - 8, x - 5, y - 1);
            dc.drawLine(x - 9, y - 5, x - 1, y - 5);
            dc.drawLine(x + 5, y + 1, x + 5, y + 8);
            dc.drawLine(x + 1, y + 5, x + 9, y + 5);
        } else if (icon == 9) {
            dc.drawCircle(x, y, 7);
            dc.drawLine(x, y, x, y - 4);
            dc.drawLine(x, y, x + 4, y + 2);
            dc.drawLine(x - 3, y - 9, x + 3, y - 9);
        } else if (icon == 10) {
            dc.drawLine(x - 4, y + 7, x - 4, y - 7);
            dc.drawLine(x - 4, y - 7, x - 8, y - 3);
            dc.drawLine(x - 4, y - 7, x, y - 3);
            dc.drawLine(x + 4, y - 7, x + 4, y + 7);
            dc.drawLine(x + 4, y + 7, x, y + 3);
            dc.drawLine(x + 4, y + 7, x + 8, y + 3);
        } else if (icon == 11) {
            dc.drawRoundedRectangle(x - 6, y - 9, 12, 18, 2);
            dc.drawLine(x + 1, y - 4, x + 1, y + 4);
        } else if (icon == 12) {
            dc.drawLine(x - 7, y, x + 7, y);
        } else if (icon == 13) {
            dc.drawLine(x - 7, y, x + 7, y);
            dc.drawLine(x, y - 7, x, y + 7);
        }
        dc.setPenWidth(1);
    }

    private function drawAccessibilityGuide(dc as Dc, center as Number, y as Number, accent as ColorType) as Void {
        drawCentered(dc, center, y, Graphics.FONT_XTINY, "MENU: STATS", accent);
        drawCentered(dc, center, y + 14, Graphics.FONT_XTINY, "HAUT/BAS: CHOIX", _COLOR_TEXT);
        drawCentered(dc, center, y + 28, Graphics.FONT_XTINY, "SELECT: OUVRIR  •  BACK: RETOUR", _COLOR_MUTED);
    }

    private function drawBackground(dc as Dc, center as Number, centerY as Number, diameter as Number, accent as ColorType) as Void {
        var backgroundColor = _COLOR_BG;
        var ringColor = _COLOR_BROWN;
        var accentRadius = (diameter / 2) - 28;
        if (_screen == 2 && !_running && _pauseFlash) {
            backgroundColor = 0x37241B;
            ringColor = _COLOR_ORANGE;
        }
        if (_transitionTicks > 0) {
            accentRadius -= _transitionTicks * 3;
        }
        dc.setColor(backgroundColor, backgroundColor);
        dc.clear();
        dc.setColor(ringColor, backgroundColor);
        dc.setPenWidth(18);
        dc.drawCircle(center, centerY, (diameter / 2) - 13);
        dc.setColor(accent, backgroundColor);
        dc.setPenWidth(3);
        dc.drawCircle(center, centerY, accentRadius);
        dc.setPenWidth(1);
    }

    private function drawChoiceCard(dc as Dc, center as Number, y as Number, width as Number, height as Number, selected as Boolean, title as String, accent as ColorType) as Void {
        var x = center - width / 2;
        var fillColor = selected ? accent : _COLOR_PANEL;
        var textColor = selected ? _COLOR_BG : _COLOR_TEXT;
        dc.setColor(fillColor, fillColor);
        dc.fillRoundedRectangle(x, y, width, height, 12);
        dc.setColor(selected ? accent : _COLOR_BORDER, fillColor);
        dc.setPenWidth(selected ? 2 : 1);
        dc.drawRoundedRectangle(x, y, width, height, 12);
        dc.setPenWidth(1);

        var titleHeight = dc.getFontHeight(Graphics.FONT_SMALL);
        drawCentered(dc, center, y + (height - titleHeight) / 2, Graphics.FONT_SMALL, title, textColor);

        var markerX = x + width - 18;
        var markerY = y + height / 2;
        dc.setColor(selected ? _COLOR_BG : accent, fillColor);
        dc.drawCircle(markerX, markerY, 6);
        if (selected) {
            dc.drawLine(markerX - 3, markerY, markerX - 1, markerY + 2);
            dc.drawLine(markerX - 1, markerY + 2, markerX + 4, markerY - 3);
        }
    }

    private function drawEventIcon(dc as Dc, kind as Number, x as Number, y as Number, color as ColorType) as Void {
        dc.setColor(color, _COLOR_PANEL);
        dc.setPenWidth(3);
        if (kind == 1) {
            dc.drawCircle(x, y - 10, 4);
            dc.drawLine(x, y - 6, x - 5, y + 4);
            dc.drawLine(x - 2, y - 3, x + 7, y);
            dc.drawLine(x - 2, y - 3, x - 10, y + 1);
            dc.drawLine(x - 5, y + 4, x - 12, y + 12);
            dc.drawLine(x - 5, y + 4, x + 5, y + 10);
        } else if (kind == 2) {
            dc.drawLine(x - 12, y - 15, x - 12, y + 14);
            dc.drawLine(x - 12, y + 14, x + 14, y + 14);
            dc.drawCircle(x, y - 10, 4);
            dc.drawLine(x, y - 6, x + 2, y + 1);
            dc.drawLine(x + 2, y + 1, x + 13, y + 1);
            dc.drawLine(x + 13, y + 1, x + 13, y + 12);
            dc.drawLine(x + 2, y + 1, x - 5, y + 11);
        } else if (kind == 3) {
            dc.drawLine(x - 16, y - 13, x + 16, y - 13);
            dc.drawLine(x - 12, y - 13, x - 12, y - 7);
            dc.drawLine(x + 12, y - 13, x + 12, y - 7);
            dc.drawCircle(x, y - 2, 4);
            dc.drawLine(x - 4, y - 4, x - 11, y - 12);
            dc.drawLine(x + 4, y - 4, x + 11, y - 12);
            dc.drawLine(x, y + 2, x, y + 13);
            dc.drawLine(x, y + 13, x - 7, y + 17);
            dc.drawLine(x, y + 13, x + 7, y + 17);
        } else {
            dc.drawLine(x - 15, y - 14, x + 15, y - 14);
            dc.drawLine(x, y - 14, x, y - 3);
            dc.drawLine(x - 11, y - 3, x + 11, y - 3);
            dc.drawLine(x - 11, y - 3, x - 11, y + 4);
            dc.drawLine(x + 11, y - 3, x + 11, y + 4);
            dc.drawLine(x - 16, y + 4, x - 6, y + 4);
            dc.drawLine(x + 6, y + 4, x + 16, y + 4);
            dc.drawCircle(x, y + 10, 4);
            dc.drawLine(x, y - 3, x, y + 4);
        }
        dc.setPenWidth(1);
    }

    private function elapsedText() as String {
        return formatElapsed(_elapsedDs);
    }

    private function formatElapsed(deciseconds as Number) as String {
        var totalSeconds = Math.floor(deciseconds / 10.0).toNumber();
        var minutes = Math.floor(totalSeconds / 60.0).toNumber();
        var seconds = totalSeconds % 60;
        var secondsText = seconds < 10 ? "0" + seconds : seconds.toString();
        return minutes.toString() + ":" + secondsText;
    }

    private function sessionStorageKey() as String {
        return "history_" + _section.toString() + "_" + _sex.toString();
    }

    private function storedNumber(key as String, fallback as Number) as Number {
        var value = Storage.getValue(key);
        return value instanceof Number ? value as Number : fallback;
    }

    private function saveSession() as Void {
        var key = sessionStorageKey();
        var count = storedNumber(key + "_count", 0);
        _previousStats = null;
        if (count > 0) {
            var previousIndex = (count - 1) % 15;
            _previousStats = [
                storedNumber(key + "_" + previousIndex.toString() + "_time", 0),
                storedNumber(key + "_" + previousIndex.toString() + "_allers", 0),
                storedNumber(key + "_" + previousIndex.toString() + "_reps", 0),
                storedNumber(key + "_" + previousIndex.toString() + "_level", 1),
                storedNumber(key + "_" + previousIndex.toString() + "_stamp", 0),
                storedNumber(key + "_" + previousIndex.toString() + "_objective", 0),
                storedNumber(key + "_" + previousIndex.toString() + "_score", 0)
            ];
        }

        var currentScore = sessionScore();
        var checkCount = count < 15 ? count : 15;
        var bestScore = -1;
        for (var index = 0; index < checkCount; index++) {
            var oldIndex = (count - checkCount + index) % 15;
            var oldScore = storedNumber(key + "_" + oldIndex.toString() + "_score", -1);
            if (oldScore > bestScore) {
                bestScore = oldScore;
            }
        }
        _newRecord = count > 0 && currentScore > bestScore;
        _celebrationTicks = _newRecord ? 30 : 0;

        var currentIndex = count % 15;
        var currentKey = key + "_" + currentIndex.toString() + "_";
        Storage.setValue(currentKey + "time", _elapsedDs);
        Storage.setValue(currentKey + "allers", _shuttles);
        Storage.setValue(currentKey + "reps", _reps);
        Storage.setValue(currentKey + "level", _currentLevel);
        Storage.setValue(currentKey + "stamp", Time.now().value());
        Storage.setValue(currentKey + "objective", _objective);
        Storage.setValue(currentKey + "score", currentScore);
        Storage.setValue(key + "_count", count + 1);
        loadHistory(_section);
        _historyCursor = _historyCount - 1;
    }

    private function sessionScore() as Number {
        if (_section == 1) {
            return _shuttles;
        }
        return _section == 2 ? _elapsedDs : _reps;
    }

    private function loadHistory(section as Number) as Void {
        var key = "history_" + section.toString() + "_" + _sex.toString();
        var count = storedNumber(key + "_count", 0);
        _historyCount = count < 15 ? count : 15;
        _historyScores = [];
        _historyElapsed = [];
        _historyAllers = [];
        _historyReps = [];
        _historyTimestamps = [];
        _historyObjectives = [];

        var firstRecord = count - _historyCount;
        for (var index = 0; index < _historyCount; index++) {
            var slot = (firstRecord + index) % 15;
            var recordKey = key + "_" + slot.toString() + "_";
            _historyScores.add(storedNumber(recordKey + "score", 0));
            _historyElapsed.add(storedNumber(recordKey + "time", 0));
            _historyAllers.add(storedNumber(recordKey + "allers", 0));
            _historyReps.add(storedNumber(recordKey + "reps", 0));
            _historyTimestamps.add(storedNumber(recordKey + "stamp", 0));
            _historyObjectives.add(storedNumber(recordKey + "objective", 0));
        }
        _historyCursor = _historyCount > 0 ? _historyCount - 1 : 0;
    }

    private function selectHistoryPoint(x as Number) as Void {
        if (_historyCount == 0) {
            return;
        }
        var plotWidth = _viewWidth - 116;
        var plotLeft = (_viewWidth - plotWidth) / 2;
        if (x < plotLeft || x >= plotLeft + plotWidth) {
            return;
        }
        var barSlot = plotWidth / _historyCount;
        _historyCursor = Math.floor((x - plotLeft) / barSlot).toNumber();
        if (_historyCursor >= _historyCount) {
            _historyCursor = _historyCount - 1;
        }
        WatchUi.requestUpdate();
    }

    private function historyDateText(index as Number) as String {
        var moment = new Time.Moment(_historyTimestamps[index]);
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        var hourText = info.hour < 10 ? "0" + info.hour.toString() : info.hour.toString();
        var minuteText = info.min < 10 ? "0" + info.min.toString() : info.min.toString();
        return info.day.toString() + "/" + info.month.toString() + " " + hourText + ":" + minuteText;
    }

    private function historyValueText(index as Number) as String {
        if (_historySection == 1) {
            return _historyAllers[index].toString() + " ALLERS";
        }
        if (_historySection == 2) {
            return formatElapsed(_historyElapsed[index]);
        }
        return _historyReps[index].toString() + " REP";
    }

    private function historyBestScore() as Number {
        var best = 0;
        for (var index = 0; index < _historyCount; index++) {
            if (_historyScores[index] > best) {
                best = _historyScores[index];
            }
        }
        return best;
    }

    private function drawHistoryGraph(dc as Dc, center as Number, centerY as Number, width as Number, accent as ColorType) as Void {
        drawCentered(dc, center, centerY - 132, Graphics.FONT_XTINY, "HISTORIQUE " + _historyCount.toString() + "/15", _COLOR_MUTED);
        if (_historyCount == 0) {
            drawCentered(dc, center, centerY - 12, Graphics.FONT_SMALL, "AUCUNE SESSION", _COLOR_TEXT);
            drawActionHint(dc, center, centerY + 82, "BACK", "", _COLOR_CYAN);
            return;
        }

        var bestScore = historyBestScore();
        drawCentered(dc, center, centerY - 108, Graphics.FONT_XTINY, historyDateText(_historyCursor), _COLOR_TEXT);
        drawCentered(dc, center, centerY - 84, Graphics.FONT_NUMBER_MILD, historyValueText(_historyCursor), accent);
        drawCentered(dc, center, centerY - 51, Graphics.FONT_XTINY, "MAX " + historyValueTextForScore(bestScore), _COLOR_LIME);

        var plotWidth = width - 116;
        var plotLeft = (width - plotWidth) / 2;
        var baseline = centerY + 54;
        var chartHeight = 67;
        var slotWidth = plotWidth / 15;
        var barWidth = slotWidth - 5;
        dc.setColor(_COLOR_BORDER, _COLOR_BG);
        dc.drawLine(plotLeft, baseline, plotLeft + plotWidth, baseline);

        for (var index = 0; index < _historyCount; index++) {
            var score = _historyScores[index];
            var barHeight = bestScore > 0 ? Math.max(3, (score * chartHeight / bestScore).toNumber()) : 3;
            var x = plotLeft + (index * slotWidth) + ((slotWidth - barWidth) / 2);
            var color = index == _historyCursor ? _COLOR_LIME : accent;
            if (score == bestScore) {
                color = _COLOR_ORANGE;
            }
            dc.setColor(color, color);
            dc.fillRectangle(x, baseline - barHeight, barWidth, barHeight);
            var info = Gregorian.info(new Time.Moment(_historyTimestamps[index]), Time.FORMAT_SHORT);
            drawCentered(dc, x + barWidth / 2, baseline + 5, Graphics.FONT_XTINY, info.day.toString(), _COLOR_MUTED);
        }

        if (_newRecord && _celebrationTicks > 0) {
            var celebrationColor = (_celebrationTicks % 6) < 3 ? _COLOR_LIME : _COLOR_RED;
            drawCentered(dc, center, centerY + 79, Graphics.FONT_XTINY, "NOUVEAU RECORD", celebrationColor);
            dc.setColor(celebrationColor, celebrationColor);
            dc.drawLine(center - 84, centerY - 85, center - 70, centerY - 75);
            dc.drawLine(center + 84, centerY - 85, center + 70, centerY - 75);
        }
        drawActionHint(dc, center, centerY + 108, "BACK", "", _COLOR_CYAN);
    }

    private function historyValueTextForScore(score as Number) as String {
        if (_historySection == 2) {
            return formatElapsed(score);
        }
        return score.toString() + (_historySection == 1 ? " ALLERS" : " REP");
    }

    private function previousResultText() as String {
        if (_previousStats == null) {
            return "AUCUNE SESSION";
        }
        var previous = _previousStats as Array<Number>;
        if (_section == 1) {
            return previous[1].toString() + " ALLERS";
        }
        if (_section == 3) {
            return previous[2].toString() + " REP";
        }
        return formatElapsed(previous[0]);
    }

    private function sessionDeltaText() as String {
        if (_previousStats == null) {
            return "PREMIERE SESSION";
        }
        var previous = _previousStats as Array<Number>;
        var difference = _section == 3 ? _reps - previous[2] : _elapsedDs - previous[0];
        var sign = "+";
        if (difference < 0) {
            sign = "-";
            difference = 0 - difference;
        }
        if (_section == 3) {
            return sign + difference.toString() + " REP";
        }
        return sign + formatElapsed(difference);
    }

    private function nextShuttleText() as String {
        var remainingDs = _nextShuttleDs - _elapsedDs;
        if (remainingDs < 0) {
            remainingDs = 0;
        }
        var seconds = Math.floor(remainingDs / 10.0).toNumber();
        var tenth = (remainingDs % 10).toNumber();
        return "Prochain bip " + seconds.toString() + "," + tenth.toString() + " s";
    }

    private function objectiveName() as String {
        var names = ["NIVEAU 1", "NIVEAU 2", "NIVEAU 3"];
        return names[_objective];
    }

    private function objectiveNameAt(index as Number) as String {
        var names = ["NIVEAU 1", "NIVEAU 2", "NIVEAU 3"];
        return names[index];
    }

    private function objectiveRange() as String {
        var maleRanges = ["10:00-12:00", "7:00-9:45", "0:00-6:45"];
        var femaleRanges = ["7:00-12:00", "4:45-6:45", "0:00-4:30"];
        return _sex == 0 ? maleRanges[_objective] : femaleRanges[_objective];
    }

    private function objectiveRangeAt(index as Number) as String {
        var maleRanges = ["10:00-12:00", "7:00-9:45", "0:00-6:45"];
        var femaleRanges = ["7:00-12:00", "4:45-6:45", "0:00-4:30"];
        return _sex == 0 ? maleRanges[index] : femaleRanges[index];
    }

    private function levelThreeObjectiveText() as String {
        if (_section == 1) {
            return _sex == 0 ? "0:00-6:45" : "0:00-4:30";
        }
        if (_section == 2) {
            return "0:00-1:49";
        }
        return _sex == 0 ? "0-4 TRACTIONS" : "0-21 TIRAGES";
    }

    private function goodTargetText() as String {
        if (_section == 1) {
            return _sex == 0 ? "N2: 7:00-9:45" : "N2: 4:45-6:45";
        }
        if (_section == 2) {
            return "N2: 1:50-3:19";
        }
        return _sex == 0 ? "N2: 5-12 REP" : "N2: 22-36 REP";
    }

    private function excellentTargetText() as String {
        if (_section == 1) {
            return _sex == 0 ? "10:00-12:00" : "7:00-12:00";
        }
        if (_section == 2) {
            return "3:20-4:20";
        }
        return _sex == 0 ? "13-30" : "37-70";
    }

    private function currentRank() as Number {
        var elapsedSeconds = Math.floor(_elapsedDs / 10.0).toNumber();
        if (_sex == 0) {
            if (elapsedSeconds >= 600 && elapsedSeconds <= 720) {
                return 1;
            }
            if (elapsedSeconds >= 420 && elapsedSeconds <= 585) {
                return 2;
            }
            return elapsedSeconds <= 405 ? 3 : 0;
        }
        if (elapsedSeconds >= 420 && elapsedSeconds <= 720) {
            return 1;
        }
        if (elapsedSeconds >= 285 && elapsedSeconds <= 405) {
            return 2;
        }
        return elapsedSeconds <= 270 ? 3 : 0;
    }

    private function killyRank() as Number {
        var elapsedSeconds = Math.floor(_elapsedDs / 10.0).toNumber();
        var levelOneStart = 200;
        var levelTwoEnd = _sex == 0 ? 199 : 209;
        if (elapsedSeconds >= levelOneStart && elapsedSeconds <= 260) {
            return 1;
        }
        if (elapsedSeconds >= 110 && elapsedSeconds <= levelTwoEnd) {
            return 2;
        }
        return elapsedSeconds <= 109 ? 3 : 0;
    }

    private function upperBodyRank() as Number {
        if (_sex == 0) {
            if (_reps >= 13 && _reps <= 30) {
                return 1;
            }
            if (_reps >= 5 && _reps <= 12) {
                return 2;
            }
            return _reps <= 4 ? 3 : 0;
        }
        if (_reps >= 37 && _reps <= 70) {
            return 1;
        }
        if (_reps >= 22 && _reps <= 36) {
            return 2;
        }
        return _reps <= 21 ? 3 : 0;
    }

    private function rankName(rank as Number) as String {
        if (rank == 0) {
            return "HORS PLAGE";
        }
        var names = ["NIVEAU 1", "NIVEAU 2", "NIVEAU 3"];
        return names[rank - 1];
    }

    private function rankColor(rank as Number) as ColorType {
        if (rank == 0) {
            return _COLOR_RED;
        }
        if (rank == 1) {
            return _COLOR_LIME;
        }
        if (rank == 2) {
            return _COLOR_CYAN;
        }
        return _COLOR_ORANGE;
    }

    public function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var center = width / 2;
        var centerY = dc.getHeight() / 2;
        if (_lastDrawnScreen != _screen) {
            _lastDrawnScreen = _screen;
            _transitionTicks = 4;
        }
        _viewWidth = width;
        _viewHeight = dc.getHeight();
        var tinyHeight = dc.getFontHeight(Graphics.FONT_XTINY);
        var smallHeight = dc.getFontHeight(Graphics.FONT_SMALL);
        var mediumHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var numberHeight = dc.getFontHeight(Graphics.FONT_NUMBER_MILD);
        var actionHeight = 16;
        dc.setColor(_COLOR_TEXT, _COLOR_BG);
        dc.clear();

        var accents = [_COLOR_LIME, _COLOR_ORANGE, _COLOR_CYAN];
        var upperBodyName = _sex == 0 ? "TRACTIONS" : "TIRAGES";
        var names = ["LUC LEGER", "KILLY", upperBodyName];
        var backgroundAccent = _sex == 0 ? _COLOR_LIME : _COLOR_ORANGE;
        if (_screen == 5) {
            backgroundAccent = accents[_choice];
        } else if (_screen > 0) {
            backgroundAccent = accents[_section - 1];
        }
        drawBackground(dc, center, centerY, width < _viewHeight ? width : _viewHeight, backgroundAccent);

        if (_screen == 0) {
            drawCentered(dc, center, centerY - 129, Graphics.FONT_SMALL, "CATEGORIE", _COLOR_TEXT);
            drawCentered(dc, center, centerY - 109, Graphics.FONT_XTINY, "SEXE / UTILISATEUR", _COLOR_MUTED);
            var cardWidth = width - 160;
            drawChoiceCard(dc, center, centerY - 76, cardWidth, 60, _sex == 0, "HOMME", _COLOR_LIME);
            drawChoiceCard(dc, center, centerY + 2, cardWidth, 60, _sex == 1, "FEMME", _COLOR_ORANGE);
            drawAccessibilityGuide(dc, center, centerY + 118, _COLOR_LIME);
            return;
        }

        if (_screen == 5) {
            var accent = accents[_choice];
            drawCentered(dc, center, centerY - 125, Graphics.FONT_SMALL, "EPREUVES", _COLOR_TEXT);
            drawCentered(dc, center, centerY - 105, Graphics.FONT_XTINY, "CHOIX DE TEST", _COLOR_MUTED);
            var iconCenterY = centerY - 48;
            dc.setColor(_COLOR_PANEL, _COLOR_PANEL);
            dc.fillCircle(center, iconCenterY, 29);
            dc.setColor(accent, _COLOR_PANEL);
            dc.drawCircle(center, iconCenterY, 29);
            var eventKind = _choice == 2 && _sex == 1 ? 4 : _choice + 1;
            drawEventIcon(dc, eventKind, center, iconCenterY, accent);
            drawChoiceCard(dc, center, centerY + 1, width - 160, 62, true, names[_choice], accent);
            drawCentered(dc, center, centerY + 91, Graphics.FONT_XTINY, (_choice + 1).toString() + " / 3", _COLOR_MUTED);
            drawCentered(dc, center, centerY + 119, Graphics.FONT_XTINY, "MENU = STATS  •  SELECT = LANCER", accent);
            return;
        }

        if (_screen == 9) {
            var historyNames = ["LUC LEGER", "KILLY", upperBodyName];
            var historyAccent = accents[_historyChoice];
            drawCentered(dc, center, centerY - 125, Graphics.FONT_SMALL, "STATISTIQUES", _COLOR_TEXT);
            drawCentered(dc, center, centerY - 105, Graphics.FONT_XTINY, "DERNIERES SESSIONS", _COLOR_MUTED);
            var historyIconY = centerY - 48;
            dc.setColor(_COLOR_PANEL, _COLOR_PANEL);
            dc.fillCircle(center, historyIconY, 29);
            dc.setColor(historyAccent, _COLOR_PANEL);
            dc.drawCircle(center, historyIconY, 29);
            var historyEventKind = _historyChoice == 2 && _sex == 1 ? 4 : _historyChoice + 1;
            drawEventIcon(dc, historyEventKind, center, historyIconY, historyAccent);
            drawChoiceCard(dc, center, centerY + 1, width - 160, 62, true, historyNames[_historyChoice], historyAccent);
            drawCentered(dc, center, centerY + 91, Graphics.FONT_XTINY, (_historyChoice + 1).toString() + " / 3", _COLOR_MUTED);
            drawCentered(dc, center, centerY + 119, Graphics.FONT_XTINY, "HAUT/BAS = CHOIX  •  SELECT = AFFICHER", _COLOR_TEXT);
            drawActionHint(dc, center, centerY + 146, "SELECT", "", _COLOR_LIME);
            return;
        }

        var accent = accents[_section - 1];

        if (_screen == 1) {
            var iconRadius = 27;
            var contentHeight = tinyHeight + 10 + iconRadius * 2 + 10 + tinyHeight + 7 + tinyHeight + 12 + actionHeight;
            var top = centerY - contentHeight / 2;
            drawCentered(dc, center, top, Graphics.FONT_XTINY, names[_section - 1], _COLOR_MUTED);
            var iconCenterY = top + tinyHeight + 10 + iconRadius;
            dc.setColor(accent, _COLOR_BG);
            dc.drawCircle(center, iconCenterY, iconRadius);
            var eventKind = _section == 3 && _sex == 1 ? 4 : _section;
            drawEventIcon(dc, eventKind, center, iconCenterY, accent);
            var lineOneY = iconCenterY + iconRadius + 10;
            var lineTwoY = lineOneY + tinyHeight + 7;

            if (_section == 1) {
                drawCentered(dc, center, lineOneY, Graphics.FONT_XTINY, "NAVETTE 20 M", _COLOR_TEXT);
                drawCentered(dc, center, lineTwoY, Graphics.FONT_XTINY, "8,5 KM/H +0,5/MIN", accent);
            } else if (_section == 2) {
                drawCentered(dc, center, lineOneY, Graphics.FONT_XTINY, "DOS AU MUR", _COLOR_TEXT);
                drawCentered(dc, center, lineTwoY, Graphics.FONT_XTINY, "CUISSES A 90 DEG", accent);
            } else {
                drawCentered(dc, center, lineOneY, Graphics.FONT_XTINY, _sex == 0 ? "TRACTIONS STRICTES" : "POULIE HAUTE", _COLOR_TEXT);
                drawCentered(dc, center, lineTwoY, Graphics.FONT_XTINY, _sex == 0 ? "PRISE STRICTE" : "TIRAGES CONTROLES", accent);
            }

            var actionsY = lineTwoY + tinyHeight + 12;
            drawActionHint(dc, center - 70, actionsY, "SELECT", "", accent);
            drawActionHint(dc, center + 70, actionsY, "BACK", "", _COLOR_CYAN);
            return;
        }

        if (_screen == 3) {
            var cardWidth = width - 160;
            drawCentered(dc, center, centerY - 129, Graphics.FONT_SMALL, "OBJECTIF", _COLOR_TEXT);
            for (var objective = 0; objective < 3; objective++) {
                var cardY = centerY - 82 + (objective * 51);
                drawChoiceCard(dc, center, cardY, cardWidth, 44, _objective == objective, objectiveNameAt(objective), accents[objective]);
            }
            return;
        }

        if (_screen == 4) {
            var detailHeight = tinyHeight + 10 + smallHeight + 10 + tinyHeight + 18 + actionHeight;
            var detailTop = centerY - detailHeight / 2;
            drawCentered(dc, center, detailTop, Graphics.FONT_XTINY, "OBJECTIF", _COLOR_MUTED);
            var levelY = detailTop + tinyHeight + 10;
            drawCentered(dc, center, levelY, Graphics.FONT_SMALL, objectiveName(), accents[_objective]);
            var rangeY = levelY + smallHeight + 10;
            drawCentered(dc, center, rangeY, Graphics.FONT_XTINY, objectiveRange(), _COLOR_TEXT);
            var actionsY = rangeY + tinyHeight + 18;
            drawActionHint(dc, center - 70, actionsY, "SELECT", "", _COLOR_LIME);
            drawActionHint(dc, center + 70, actionsY, "BACK", "", _COLOR_CYAN);
            return;
        }

        if (_screen == 8) {
            var infoLines = ["AVANT DEPART"];
            if (_section == 1) {
                infoLines.add("OBJECTIF " + objectiveName());
                infoLines.add("PLAGE " + objectiveRange());
            } else if (_section == 2) {
                infoLines.add("KILLY | DOS AU MUR");
            } else {
                infoLines.add(_sex == 0 ? "TRACTIONS STRICTES" : "POULIE HAUTE");
            }
            infoLines.add("NIVEAU 3: " + levelThreeObjectiveText());
            infoLines.add("BON NIVEAU 2: " + goodTargetText());
            infoLines.add("EXCELLENT N1");
            if (_section == 3) {
                infoLines.add(excellentTargetText() + (_sex == 0 ? " TRACTIONS" : " TIRAGES"));
            } else {
                infoLines.add(excellentTargetText());
            }

            var lineStep = tinyHeight + 7;
            var top = centerY - ((infoLines.size() * lineStep + 25) / 2);
            for (var index = 0; index < infoLines.size(); index++) {
                var lineColor = index == 0 ? _COLOR_MUTED : _COLOR_TEXT;
                drawCentered(dc, center, top + (index * lineStep), Graphics.FONT_XTINY, infoLines[index], lineColor);
            }
            var actionsY = top + (infoLines.size() * lineStep) + 10;
            drawActionHint(dc, center - 70, actionsY, "BACK", "", _COLOR_CYAN);
            drawActionHint(dc, center + 70, actionsY, "SELECT", "", _COLOR_LIME);
            return;
        }

        if (_screen == 6) {
            var countdown = Math.floor((_countdownDs + 9) / 10.0).toNumber();
            var countdownY = centerY - (numberHeight / 2);
            drawCentered(dc, center, countdownY - tinyHeight - 10, Graphics.FONT_XTINY, "DEPART DANS", _COLOR_MUTED);
            drawCentered(dc, center, countdownY, Graphics.FONT_NUMBER_MILD, countdown.toString(), _COLOR_LIME);
            drawActionHint(dc, center, countdownY + numberHeight + 14, "BACK", "", _COLOR_CYAN);
            return;
        }

        if (_screen == 7) {
            drawHistoryGraph(dc, center, centerY, width, accents[_historySection - 1]);
            drawCentered(dc, center, centerY + 150, Graphics.FONT_XTINY, "HAUT/BAS = CHOIX  •  BACK = RETOUR", _COLOR_TEXT);
            return;
        }

        if (_section == 1) {
            if (_lucStatsPage) {
                var contentHeight = tinyHeight + 8 + smallHeight + 8 + tinyHeight + 10 + mediumHeight + 8 + tinyHeight + 7 + tinyHeight + 12 + actionHeight;
                var top = centerY - contentHeight / 2;
                drawCentered(dc, center, top, Graphics.FONT_XTINY, "OBJECTIF " + objectiveName(), _COLOR_MUTED);
                var rangeY = top + tinyHeight + 8;
                drawCentered(dc, center, rangeY, Graphics.FONT_SMALL, objectiveRange(), _COLOR_TEXT);
                var rankY = rangeY + smallHeight + 8;
                drawCentered(dc, center, rankY, Graphics.FONT_XTINY, "CLASSEMENT", _COLOR_MUTED);
                var rankNameY = rankY + tinyHeight + 10;
                var lucRank = currentRank();
                drawCentered(dc, center, rankNameY, Graphics.FONT_MEDIUM, rankName(lucRank), rankColor(lucRank));
                var timeY = rankNameY + dc.getFontHeight(Graphics.FONT_MEDIUM) + 8;
                drawCentered(dc, center, timeY, Graphics.FONT_XTINY, "SCORE " + elapsedText(), _COLOR_TEXT);
                var shuttlesY = timeY + tinyHeight + 7;
                drawCentered(dc, center, shuttlesY, Graphics.FONT_XTINY, "ALLERS " + _shuttles.toString(), _COLOR_MUTED);
                var actionsY = shuttlesY + tinyHeight + 12;
                drawActionHint(dc, center - 70, actionsY, "UP", "", _COLOR_CYAN);
                drawActionHint(dc, center + 70, actionsY, "BACK", "", _COLOR_LIME);
            } else {
                var speedTenths = 85 + ((_currentLevel - 1) * 5);
                var speedText = Math.floor(speedTenths / 10.0).toNumber().toString() + "," + (speedTenths % 10).toString();
                var contentHeight = tinyHeight + 8 + numberHeight + 6 + tinyHeight + 12 + actionHeight;
                var top = centerY - contentHeight / 2;
                drawCentered(dc, center, top, Graphics.FONT_XTINY, "PALIER " + (_shuttles + 1).toString(), _COLOR_MUTED);
                var speedY = top + tinyHeight + 10;
                drawCentered(dc, center, speedY, Graphics.FONT_NUMBER_MILD, speedText, accent);
                var unitY = speedY + numberHeight + 6;
                drawCentered(dc, center, unitY, Graphics.FONT_XTINY, "ALLURE KM/H", _COLOR_TEXT);
                var actionsY = unitY + tinyHeight + 12;
                drawActionHint(dc, center - 70, actionsY, "SELECT", _running ? "PAUSE" : "REPRISE", accent);
                drawActionHint(dc, center + 70, actionsY, "DOWN", "SUIVI", _COLOR_CYAN);
            }
            return;
        }

        if (_section == 2) {
            var contentHeight = tinyHeight + 12 + numberHeight + 8 + tinyHeight + 8 + tinyHeight + 12 + actionHeight;
            var top = centerY - contentHeight / 2;
            drawCentered(dc, center, top, Graphics.FONT_XTINY, "KILLY", _COLOR_MUTED);
            var timeY = top + tinyHeight + 12;
            drawCentered(dc, center, timeY, Graphics.FONT_NUMBER_MILD, elapsedText(), accent);
            var statusY = timeY + numberHeight + 8;
            drawCentered(dc, center, statusY, Graphics.FONT_XTINY, _running ? "EN COURS" : "EN PAUSE", _COLOR_TEXT);
            var rankY = statusY + tinyHeight + 8;
            var killyResult = killyRank();
            drawCentered(dc, center, rankY, Graphics.FONT_XTINY, "RANG " + rankName(killyResult), rankColor(killyResult));
            var actionsY = rankY + tinyHeight + 12;
            drawActionHint(dc, center - 70, actionsY, "SELECT", _running ? "PAUSE" : "REPRISE", accent);
            drawActionHint(dc, center + 70, actionsY, "BACK", "RETOUR", _COLOR_CYAN);
            return;
        }

        var contentHeight = tinyHeight + 8 + numberHeight + 8 + tinyHeight + 8 + smallHeight + 7 + tinyHeight + 12 + actionHeight;
        var top = centerY - contentHeight / 2;
        drawCentered(dc, center, top, Graphics.FONT_XTINY, names[2], _COLOR_MUTED);
        var countY = top + tinyHeight + 8;
        drawCentered(dc, center, countY, Graphics.FONT_NUMBER_MILD, _reps.toString(), accent);
        var repsY = countY + numberHeight + 8;
        drawCentered(dc, center, repsY, Graphics.FONT_XTINY, "REPS", _COLOR_MUTED);
        var chronoY = repsY + tinyHeight + 10;
        drawCentered(dc, center, chronoY, Graphics.FONT_SMALL, elapsedText(), _COLOR_TEXT);
        var rankY = chronoY + smallHeight + 7;
        var upperResult = upperBodyRank();
        drawCentered(dc, center, rankY, Graphics.FONT_XTINY, "RANG " + rankName(upperResult), rankColor(upperResult));
        var actionsY = rankY + tinyHeight + 12;
        drawActionHint(dc, center - 100, actionsY, "UP", "+1", accent);
        drawActionHint(dc, center, actionsY, "SELECT", _running ? "PAUSE" : "CHRONO", _COLOR_CYAN);
        drawActionHint(dc, center + 100, actionsY, "DOWN", "-1", _COLOR_ORANGE);
    }
}

class TestsDelegate extends WatchUi.BehaviorDelegate {
    private var _view as TestsView;

    public function initialize(view as TestsView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    public function onNextPage() as Boolean {
        _view.changeChoice(1);
        return true;
    }

    public function onPreviousPage() as Boolean {
        _view.changeChoice(-1);
        return true;
    }

    public function onSelect() as Boolean {
        _view.handleSelect();
        return true;
    }

    public function onTap(evt as ClickEvent) as Boolean {
        var coordinates = evt.getCoordinates();
        _view.handleTap(coordinates[0], coordinates[1]);
        return true;
    }

    public function onKey(evt as KeyEvent) as Boolean {
        return _view.handleKey(evt.getKey());
    }

    public function onMenu() as Boolean {
        _view.handleMenu();
        return true;
    }

    public function onBack() as Boolean {
        return _view.goHome();
    }
}
