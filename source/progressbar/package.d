module progressbar;
import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import std.string;
import std.array;

abstract class Part
{
    abstract string toString(Progressbar pb);
}

class Progressbar
{
    size_t total;
    size_t value;
    string _message = "";
    this(size_t total, size_t value = 0)
    {
        this.total = total;
        this.value = value;
    }

    typeof(this) step(size_t step = 1)
    {
        this.value += step;
        return this;
    }

    typeof(this) message(string message)
    {
        this._message = message;
        return this;
    }

    float currentProgress()
    {
        return value.to!float / total.to!float;
    }

    string message()
    {
        return _message;
    }
}

abstract class ProgressbarUI
{
    Progressbar pb;
    this(Progressbar pb)
    {
        this.pb = pb;
    }

    typeof(this) step(size_t step = 1)
    {
        pb.step(step);
        return this;
    }

    typeof(this) message(string message)
    {
        pb.message(message);
        return this;
    }

    string message()
    {
        return pb.message;
    }
}

class TextProgressbarUI : ProgressbarUI
{
    Part[] parts;
    this(Progressbar pb, Part[] parts)
    {
        super(pb);
        this.parts = parts;
    }

    override string toString()
    {
        string[] res;
        foreach (p; parts)
        {
            res ~= p.toString(pb);
        }
        return res.join("").to!string;
    }
}

auto textUi(P...)(Progressbar pb, P parts)
{
    return new TextProgressbarUI(pb, [parts]);
}

struct Parser
{
    string data;
    this(string s)
    {
        this.data = s;
    }

    auto parseFormat()
    {
        data.popFront;
        auto width = parseOptionalWidth;
        if (data.empty)
        {
            throw new Exception("Expected format specifier");
        }
        auto p = data.front;
        data.popFront;
        switch (p)
        {
        case 's':
            return spinner(THREE_ROUND);
        case 'm':
            return width == -1 ? new Message : new PadRight(width, new Message(width));
        case 'P':
            return new PercentageBar(width == -1 ? 20 : width);
        case 'p':
            return new PadLeft(5, new Percentage);
        case 'S':
            return new Speed;
        case 't':
            return new TotalDuration;
        case 'r':
            return new RestDuration;
        case '(':
            return parseComposite(width);
        default:
            throw new Exception("unkown format %s".format(data.front));
        }
    }

    auto parseComposite(int width)
    {
        if (data.empty)
        {
            throw new Exception("composite not finished, did not find )");
        }

        Part[] res;
        if (data.front == ')')
        {
            data.popFront;
            return width == -1 ? new Composite(res) : new PadRight(width, new Composite(res, width));
        }
        Part n = next;
        while (true)
        {
            res ~= n;
            if (data.empty)
            {
                throw new Exception("composite not finished");
            }
            if (data.front == ')')
            {
                data.popFront;
                return width == -1 ? new Composite(res) : new PadRight(width,
                        new Composite(res, width));
            }
            n = next;
        }
    }

    auto parseText()
    {
        string res = "";
        while (true)
        {
            if (data.empty)
            {
                return res.length > 0 ? new Separator(res) : null;
            }
            else if (data.front != '%')
            {
                res ~= data.front;
                data.popFront;
            }
            else
            {
                return new Separator(res);
            }
        }
    }

    Part next()
    {
        if (data.empty)
        {
            return null;
        }

        if (data.front == '%')
        {
            return parseFormat;
        }
        else
        {
            return parseText;
        }
    }

    int parseOptionalWidth()
    {
        import std.ascii;

        string h = "";
        if (data.empty)
        {
            return -1;
        }

        while (data.front.isDigit)
        {
            h ~= data.front;
            data.popFront;
        }
        if (h.length == 0)
        {
            return -1;
        }
        return h.to!int;
    }
}

auto textUi(Progressbar pb, string format)
{
    auto p = new Parser(format);
    Part[] parts;
    auto n = p.next;
    while (n !is null)
    {
        parts ~= n;
        n = p.next;
    }
    return new TextProgressbarUI(pb, parts);
}

class Percentage : Part
{
    override string toString(Progressbar pb)
    {
        return "%003.1f".format((pb.value.to!float / pb.total.to!float) * 100);
    }
}

class PercentageBar : Part
{
    size_t width;
    this(size_t width)
    {
        this.width = width;
    }

    override string toString(Progressbar pb)
    {
        string res = "";
        for (int i = 0; i < width; ++i)
        {
            import std.math;

            float h = floor(100 * (float(i) / float(width - 1)));
            if (pb.currentProgress == 0)
            {
                res ~= " ";
            }
            else if (h <= pb.currentProgress * 100)
            {
                res ~= "#";
            }
            else
            {
                res ~= " ";
            }
        }
        return res;
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

class DurationPart : Part
{
    import std.datetime.stopwatch;

    StopWatch sw;
    import unit;

    static immutable DURATION = Unit("duration", [Unit.Scale("s", 1),
            Unit.Scale("m", 60), Unit.Scale("h", 60),]);
    static immutable UNKNOWN = "--:--:--";
    override string toString(Progressbar pb)
    {
        if (!sw.running)
        {
            sw.start;
        }
        return "";
    }
}

class TotalDuration : DurationPart
{
    override string toString(Progressbar pb)
    {
        import core.time;
        import std.conv;

        super.toString(pb);

        auto duration = float(sw.peek.total!"msecs");
        import std.math;

        auto totalTime = round(duration / pb.currentProgress / 1000);
        if (totalTime.isNaN)
        {
            return UNKNOWN;
        }

        return DURATION.transform(totalTime.to!int)
            .map!((part) => "%02d".format(part.value)).join(":");

    }
}

class RestDuration : DurationPart
{

    override string toString(Progressbar pb)
    {
        import core.time;
        import std.conv;

        super.toString(pb);

        auto duration = float(sw.peek.total!"msecs");
        auto totalTime = duration / pb.currentProgress;
        import std.math;

        auto eta = round((totalTime - duration) / 1000);
        if (eta.isNaN)
        {
            return "--:--:--";
        }
        return DURATION.transform(eta.to!int).map!((part) => "%02d".format(part.value)).join(":");
    }
}

class PadLeft : Part
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
        return p.toString(pb).rightJustify(width, filler);
    }
}

class Composite : Part
{
    Part[] parts;
    int maxWidth;
    this(Part[] parts, int maxWidth = -1)
    {
        this.parts = parts;
        this.maxWidth = maxWidth;
    }

    override string toString(Progressbar pb)
    {
        string res = "";
        foreach (p; parts)
        {
            res ~= p.toString(pb);
        }
        return maxWidth == -1 ? res : res[0 .. min(maxWidth, res.length)];
    }
}

Part composite(P...)(P parts)
{
    return new Composite([parts]);
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

class Message : Part
{
    int maxWidth;
    this(int maxWidth = -1)
    {
        this.maxWidth = maxWidth;
    }

    override string toString(Progressbar pb)
    {
        string msg = pb.message;
        return maxWidth == -1 ? msg : msg[0 .. min(maxWidth, msg.length)];
    }
}

class Separator : Part
{
    string separator;
    this(string separator)
    {
        this.separator = separator;
    }

    override string toString(Progressbar pb)
    {
        return separator;
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
