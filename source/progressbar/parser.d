module progressbar.parser;

import std.string;
import std.range;
import std.conv;

import progressbar;

struct Parser
{
    string data;
    this(string s)
    {
        this.data = s;
    }

    auto parseFormat()
    {
        auto padding = parsePadding;
        if (data.empty)
        {
            throw new Exception("Expected format specifier");
        }
        auto p = data.front;
        data.popFront;
        switch (p)
        {
        case 's':
            return padding.pad(spinner(THREE_ROUND));
        case 'm':
            return padding.pad(new MessagePart(padding.width)); // todo message with maxwidth
        case 'P':
            return padding.pad(new PercentageBarPart(padding.width)); // todo bar with width
        case 'p':
            return padding.pad(new PadLeftPart(5, new PercentagePart));
        case 'S':
            return padding.pad(new SpeedPart);
        case 't':
            return padding.pad(new TotalDurationPart);
        case 'r':
            return padding.pad(new RestDurationPart);
        case '(':
            return padding.pad(parseComposite());
        default:
            throw new Exception("unkown format %s".format(data.front));
        }
    }

    auto parseComposite()
    {
        if (data.empty)
        {
            throw new Exception("composite not finished, did not find )");
        }

        Part[] res;
        if (data.front == ')')
        {
            data.popFront;
            return new CompositePart(res);
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
                return new CompositePart(res);
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
                return res.length > 0 ? new SeparatorPart(res) : null;
            }
            else if (data.front != '%')
            {
                res ~= data.front;
                data.popFront;
            }
            else
            {
                return new SeparatorPart(res);
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
            data.popFront;
            return parseFormat;
        }
        else
        {
            return parseText;
        }
    }

    enum Pad
    {
        NONE,
        LEFT,
        RIGHT,
        CENTER
    }

    struct Padding
    {
        int width;
        Part delegate(Part) pad;
        static Padding noPadding()
        {
            return Padding(-1, (Part p) => p);
        }

        static Padding from(Pad p, int width)
        {
            switch (p)
            {
            case Pad.CENTER:
                return Padding(width, (Part p) => cast(Part) new CenterPart(width, p));
            case Pad.LEFT:
                return Padding(width, (Part p) => cast(Part) new PadLeftPart(width, p));
            case Pad.RIGHT:
                return Padding(width, (Part p) => cast(Part) new PadRightPart(width, p));
            default:
                throw new Exception("padding %s not implemented".format(p));
            }
        }
    }

    private auto parsePadding()
    {
        if (data.empty)
        {
            throw new Exception("expected data");
        }

        return paddingFor(parseAlignment, parseWidth);
    }

    private auto paddingFor(Pad pad, string widthString)
    {
        if (widthString.length == 0)
        {
            if (pad == Pad.NONE)
            {
                return Padding.noPadding;
            }
            else
            {
                throw new Exception("padding (%s) without width given".format(pad));
            }
        }
        else
        {
            if (pad == Pad.NONE)
            {
                throw new Exception(
                        "width (%s) without padding direction given".format(widthString));
            }
            else
            {
                auto width = widthString.to!int;
                return Padding.from(pad, width);
            }
        }

    }

    private auto parseAlignment()
    {
        auto res = Pad.NONE;
        if (data.front == '>')
        {
            res = Pad.LEFT;
            data.popFront;
        }
        else if (data.front == '<')
        {
            res = Pad.RIGHT;
            data.popFront;
        }
        else if (data.front == '=')
        {
            res = Pad.CENTER;
            data.popFront;
        }
        return res;
    }

    private auto parseWidth()
    {
        import std.ascii;

        string res = "";
        while (!data.empty && data.front.isDigit)
        {
            res ~= data.front;
            data.popFront;
        }
        return res;

    }
}

auto textUi(Progressbar pb, Part[] parts)
{
    return new TextProgressbarUI(pb, parts);
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

class MultiProgressbarUI
{
    import std.algorithm;

    TextProgressbarUI[] textProgressbars;
    this(TextProgressbarUI[] textProgressbars)
    {
        this.textProgressbars = textProgressbars;
    }

    override string toString()
    {
        return textProgressbars.map!(pb => pb.toString ~ "\n")
            .join("") ~ "\033[%dA".format(textProgressbars.length + 1);
    }

    string finish()
    {
        return iota(textProgressbars.length - 1).map!(i => "\n").join("");
    }
}

auto multiTextUi(Progressbar[] progressbars, string[] formats)
{
    if (progressbars.length != formats.length)
    {
        throw new Exception("progressbars and formats must have same size");
    }

    import std.range;
    import std.algorithm;

    auto res = appender!(TextProgressbarUI[]);
    return new MultiProgressbarUI(zip(progressbars, formats)
            .map!(pair => textUi(pair[0], pair[1])).array);
}
