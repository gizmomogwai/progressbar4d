module progressbar.spinner;
import std.string;
import progressbar;

static immutable BRAILLE = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'];
public static immutable UPDOWN = ['⠁', '⠂', '⠄', '⡀', '⢀', '⠠', '⠐', '⠈'];
public static immutable SLASH = ['|', '/', '-', '\\'];
public static immutable HALVES = ['◐', '◓', '◑', '◒'];
public static immutable QUARTERS = ['◴', '◷', '◶', '◵'];
public static immutable QUARTER_SQUARES = ['◰', '◳', '◲', '◱'];
public static immutable TRIANGLES = ['◢', '◣', '◤', '◥'];
public static immutable HFILL = [
    '▉', '▊', '▋', '▌', '▍', '▎', '▏', '▎', '▍', '▌', '▋', '▊', '▉'
];
public static immutable VFILL = [
    '▁', '▃', '▄', '▅', '▆', '▇', '█', '▇', '▆', '▅', '▄', '▃'
];
public static immutable ARROWS = ['←', '↖', '↑', '↗', '→', '↘', '↓', '↙'];
public static immutable POINTS = ['┤', '┘', '┴', '└', '├', '┌', '┬', '┐'];
public static immutable BALL = ['.', 'o', 'O', 'o'];
public static immutable INVERSE_ROUND = [
    "⢎⡰", "⢎⡡", "⢎⡑", "⢎⠱", "⠎⡱", "⢊⡱", "⢌⡱", "⢆⡱"
];
public static immutable ROUND = [
    "⠈⠀", "⠀⠁", "⠀⠐", "⠀⠠", "⠀⡀", "⢀⠀", "⠄⠀", "⠂⠀"
];
public static immutable TWO_ROUND = [
    "⠆⠀", "⠊⠀", "⠈⠁", "⠀⠑", "⠀⠰", "⠀⡠", "⢀⡀", "⢄⠀"
];
public static immutable THREE_ROUND = [
    "⠎⠀", "⠊⠁", "⠈⠑", "⠀⠱", "⠀⡰", "⢀⡠", "⢄⡀", "⢆⠀"
];
public static immutable HLINE = ["⠂", "-", "–", "—", "–", "-"];
public static immutable DOTS = [".  ", ".. ", "...", " ..", "  .", "   "];
public static immutable CLOCK = [
    "🕐 ", "🕑 ", "🕒 ", "🕓 ", "🕔 ", "🕕 ", "🕖 ", "🕗 ",
    "🕘 ", "🕙 ", "🕚 "
];
public static immutable MOON = [
    "🌑 ", "🌒 ", "🌓 ", "🌔 ", "🌕 ", "🌖 ", "🌗 ", "🌘 "
];
public static immutable BOUNCING_BAR = [
    "[    ]", "[=   ]", "[==  ]", "[=== ]", "[ ===]", "[  ==]", "[   =]", "[    ]",
    "[   =]", "[  ==]", "[ ===]", "[====]", "[=== ]", "[==  ]", "[=   ]"
];
public static immutable ARC = ["◜", "◠", "◝", "◞", "◡", "◟"];
public static immutable FLIP = ["_", "_", "_", "-", "`", "`", "'", "´", "-", "_", "_", "_"];
public static immutable BOUNCING_BALL = [
    "( ●    )", "(  ●   )", "(   ●  )", "(    ● )", "(     ●)",
    "(    ● )", "(   ●  )", "(  ●   )", "( ●    )", "(●     )"
];
public static immutable BULLETS = [
    "*     ", " *    ", "  *   ", "   *  ", "    * ", "     *", "    * ",
    "   *  ", "  *   ", " *    ", "*     ",
];

class SpinnerPart(T) : Part
{
    private int idx = 0;
    private int direction;

    T[] ticks;

    this(T[] ticks, int direction)
    {
        this.ticks = ticks;
        this.direction = direction;
    }

    override string toString(Progressbar pb)
    {
        int i = idx;
        idx = idx + direction;
        if (idx >= cast(int) ticks.length)
        {
            idx -= ticks.length;
        }
        if (idx < 0)
        {
            idx += ticks.length;
        }
        return "%s".format(ticks[i]);
    }
}

Part spinner(T)(T[] ticks, int direction = 1)
{
    return new SpinnerPart!T(ticks, direction);
}
