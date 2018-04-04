module progressbar;
import std.stdio;
import std.range;
import std.conv;
import std.string;
import std.array;

public import progressbar.parts;
public import progressbar.parser;

public abstract class Part
{
    abstract string toString(Progressbar pb);
}

public class Progressbar
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

public abstract class ProgressbarUI
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
