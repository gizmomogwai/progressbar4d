module progressbar;
import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import std.string;
import std.array;

abstract class ProgressbarUI
{
    abstract string toString(Progressbar pb);
}

auto textUi(P...)(P parts)
{
    return new class ProgressbarUI
    {
        override string toString(Progressbar pb)
        {
            string[] res;
            foreach (p; parts)
            {
                res ~= p.toString(pb);
            }
            return res.join("|").to!string;
        }
    };
}

class Progressbar
{
    ProgressbarUI ui;
    size_t total;
    size_t value;
    this(ProgressbarUI ui, size_t total, size_t value = 0)
    {
        this.ui = ui;
        this.total = total;
        this.value = value;
    }

    typeof(this) step(size_t step = 1)
    {
        this.value += step;
        return this;
    }

    typeof(this) setUi(ProgressbarUI ui)
    {
        this.ui = ui;
        return this;
    }

    override string toString()
    {
        return ui.toString(this);
    }
}

abstract class Part
{
    abstract string toString(Progressbar pb);
}

class Percentage : Part
{
    override string toString(Progressbar pb)
    {
        return "%003.1f".format((pb.value.to!float / pb.total.to!float) * 100);
    }
}

class Speed : Part
{
    import std.datetime.stopwatch;

    StopWatch sw;
    override string toString(Progressbar pb)
    {
        import core.time;
        import std.conv;

        if (!sw.running)
        {
            sw.start;
        }

        auto duration = sw.peek;
        auto speed = (pb.value.to!float * 1000) / duration.total!"msecs";
        return "%00.1f".format(speed);
    }
}

class PadLeft : Part
{
    size_t width;
    Part p;
    dchar filler;
    this(size_t width, Part p, dchar filler)
    {
        this.width = width;
        this.p = p;
        this.filler = filler;
    }

    override string toString(Progressbar pb)
    {
        return p.toString(pb).rightJustify(width, filler);
    }
}

class PadRight : Part
{
    size_t width;
    Part p;
    dchar filler;
    this(size_t width, Part p, dchar filler = ' ')
    {
        this.width = width;
        this.p = p;
        this.filler = filler;
    }

    override string toString(Progressbar pb)
    {
        return p.toString(pb).leftJustify(width, filler);
    }
}

class Center : Part
{
    size_t width;
    Part p;
    dchar filler;
    this(size_t width, Part p, dchar filler = ' ')
    {
        this.width = width;
        this.p = p;
        this.filler = filler;
    }

    override string toString(Progressbar pb)
    {
        return p.toString(pb).center(width, filler);
    }
}

public enum BRAILLE = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'];
public enum UPDOWN = ['⠁', '⠂', '⠄', '⡀', '⢀', '⠠', '⠐', '⠈'];
public enum SLASH = ['|', '/', '-', '\\'];
public enum HALVES = ['◐', '◓', '◑', '◒'];
public enum QUARTERS = ['◴', '◷', '◶', '◵'];
public enum QUARTER_SQUARES = ['◰', '◳', '◲', '◱'];
public enum TRIANGLES = ['◢', '◣', '◤', '◥'];
public enum HFILL = [
        '▉', '▊', '▋', '▌', '▍', '▎', '▏', '▎', '▍', '▌', '▋', '▊', '▉'
    ];
public enum VFILL = [
        '▁', '▃', '▄', '▅', '▆', '▇', '█', '▇', '▆', '▅', '▄', '▃'
    ];
public enum ARROWS = ['←', '↖', '↑', '↗', '→', '↘', '↓', '↙'];
public enum POINTS = ['┤', '┘', '┴', '└', '├', '┌', '┬', '┐'];
public enum BALL = ['.', 'o', 'O', 'o'];
public enum INVERSE_ROUND = [
        "⢎⡰", "⢎⡡", "⢎⡑", "⢎⠱", "⠎⡱", "⢊⡱", "⢌⡱", "⢆⡱"
    ];
public enum ROUND = ["⠈⠀", "⠀⠁", "⠀⠐", "⠀⠠", "⠀⡀",
        "⢀⠀", "⠄⠀", "⠂⠀"];
public enum TWO_ROUND = [
        "⠆⠀", "⠊⠀", "⠈⠁", "⠀⠑", "⠀⠰", "⠀⡠", "⢀⡀", "⢄⠀"
    ];
public enum THREE_ROUND = [
        "⠎⠀", "⠊⠁", "⠈⠑", "⠀⠱", "⠀⡰", "⢀⡠", "⢄⡀", "⢆⠀"
    ];
public enum HLINE = ["⠂", "-", "–", "—", "–", "-"];
public enum DOTS = [".  ", ".. ", "...", " ..", "  .", "   "];
public enum CLOCK = [
        "🕐 ", "🕑 ", "🕒 ", "🕓 ", "🕔 ", "🕕 ", "🕖 ", "🕗 ",
        "🕘 ", "🕙 ", "🕚 "
    ];
public enum MOON = ["🌑 ", "🌒 ", "🌓 ", "🌔 ", "🌕 ", "🌖 ", "🌗 ", "🌘 "];
public enum BOUNCING_BAR = [
        "[    ]", "[=   ]", "[==  ]", "[=== ]", "[ ===]", "[  ==]", "[   =]", "[    ]",
        "[   =]", "[  ==]", "[ ===]", "[====]", "[=== ]", "[==  ]", "[=   ]"
    ];
public enum ARC = ["◜", "◠", "◝", "◞", "◡", "◟"];
public enum FLIP = ["_", "_", "_", "-", "`", "`", "'", "´", "-", "_", "_", "_"];
public enum BOUNCING_BALL = [
        "( ●    )", "(  ●   )", "(   ●  )", "(    ● )", "(     ●)",
        "(    ● )", "(   ●  )", "(  ●   )", "( ●    )", "(●     )"
    ];
public enum BULLETS = [
        "*     ", " *    ", "  *   ", "   *  ", "    * ", "     *", "    * ",
        "   *  ", "  *   ", " *    ", "*     ",
    ];
class Spinner(T) : Part
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
    return new Spinner!T(ticks, direction);
}
