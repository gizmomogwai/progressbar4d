/++
 + Authors: Christian Köstlin
 + Copyright: Copyright © 2018, Christian Köstlin
 + License: MIT
 +/

module progressbar.parts;

import progressbar;
import std.string;
import std.algorithm;
import std.conv;

public import progressbar.spinner;

class SeparatorPart : Part
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

class MessagePart : Part
{
    int maxWidth;
    this(int maxWidth = -1)
    {
        this.maxWidth = maxWidth;
    }

    override string toString(Progressbar pb)
    {
        import std.algorithm;

        string msg = pb.message;
        return maxWidth == -1 ? msg : msg[0 .. min(maxWidth, msg.length)];
    }
}

class PadRightPart : Part
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

class CenterPart : Part
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

class PadLeftPart : Part
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

class CompositePart : Part
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
        import std.algorithm;

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
    return new CompositePart([parts]);
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

class CurrentDurationPart : DurationPart
{
    override string toString(Progressbar pb)
    {
        import core.time;
        import std.conv;
        import std.algorithm;

        super.toString(pb);

        auto duration = float(sw.peek.total!"seconds");
        import std.math;

        return DURATION.transform(duration.to!int)
            .map!((part) => "%02d".format(part.value)).join(":");
    }
}

class TotalDurationPart : DurationPart
{
    override string toString(Progressbar pb)
    {
        import core.time;
        import std.conv;
        import std.algorithm;

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

class RestDurationPart : DurationPart
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

class PercentagePart : Part
{
    override string toString(Progressbar pb)
    {
        return "%003.1f".format((pb.value.to!float / pb.total.to!float) * 100);
    }
}

class PercentageBarPart : Part
{
    size_t width;
    this(size_t width)
    {
        this.width = width == -1 ? 30 : width;
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

class SpeedPart : Part
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
