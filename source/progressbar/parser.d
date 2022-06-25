/++
 + Authors: Christian Koestlin
 + Copyright: Copyright (C) 2018, Christian Koestlin
 + License: MIT
 +/

module progressbar.parser;

import std.string;
import std.range;
import std.conv;

import progressbar.parts;
public import progressbar;

struct Parser
{
    string original;
    string data;
    this(string s)
    {
        this.original = s;
        this.data = s;
    }

    private Exception exceptionWithPosition(string msg, size_t pos = -1)
    {
        if (pos == -1)
        {
            pos = data.ptr - original.ptr;
        }
        return new Exception("%s at %d".format(msg, data.ptr - original.ptr));
    }

    auto parseFormat()
    {
        auto padding = parsePadding;
        if (data.empty)
        {
            throw exceptionWithPosition("Expected format specifier");
        }
        auto p = data.front;
        data.popFront;
        switch (p)
        {
        case '(':
            return padding.pad(parseComposite());
        case 'm':
            return padding.pad(new MessagePart(padding.width)); // todo message with maxwidth
        case 'p':
            return padding.pad(new PadLeftPart(5, new PercentagePart));
        case 'P':
            return padding.pad(new PercentageBarPart(padding.width)); // todo bar with width
        case 'r':
            return padding.pad(new RestDurationPart);
        case 's':
            return padding.pad(spinner(THREE_ROUND));
        case 'S':
            return padding.pad(new SpeedPart);
        case 't':
            return padding.pad(new CurrentDurationPart);
        case 'T':
            return padding.pad(new TotalDurationPart);
        default:
            throw new Exception("unkown format %s".format(p));
        }
    }

    auto parseComposite()
    {
        if (data.empty)
        {
            throw exceptionWithPosition("composite not finished, did not find )");
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
                throw exceptionWithPosition("composite not finished");
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
            throw exceptionWithPosition("expected data for padding");
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
                throw exceptionWithPosition("padding (%s) without width given".format(pad));
            }
        }
        else
        {
            if (pad == Pad.NONE)
            {
                throw exceptionWithPosition(
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

        auto res = "";
        while (!data.empty && data.front.isDigit)
        {
            res ~= data.front;
            data.popFront;
        }
        return res;
    }
}
