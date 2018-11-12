/++
 + Authors: Christian Koestlin, Christian Köstlin
 + Copyright: Copyright © 2018, Christian Köstlin
 + License: MIT
 +/

module progressbar;

import std.stdio;
import std.range;
import std.conv;
import std.string;
import std.array;

/++
 + One part of a progressbar text ui.
 +/
public abstract class Part
{
    abstract string toString(Progressbar pb);
}

/++
 + Progressbar holds the core values of a progressbar: total, value and message.
 + Progress can be made with step.
 +/
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

    auto step(size_t step = 1)
    {
        this.value += step;
        return this;
    }

    auto message(string message)
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

/++
 + One progressbar can have several UI's attached.
 +/
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

/++
 + The TextProgressbarUI is made up from several Part's.
 + There are parts for text constants, bars, eta, ...
 +/
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

/++
 + Multiline progressbarui.
 +/
class MultiProgressbarTextUI
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

/++
 + UI for a progressbar specified by its Parts.
 +/
auto textUi(Progressbar pb, Part[] parts)
{
    return new TextProgressbarUI(pb, parts);
}

/++
 + UI for a progressbar specified by a formatstring.
 +
 + The format string may contain printf style parts.
 +
 + The grammer is:
 + $(BR)
 + Parts => Text | Spec
 + $(BR)
 + Spec => % Padding? Specifier | % ( Parts )
 +
 + Specifier might be one of the following symbols:
 $(TABLE
    $(TR $(TH formatting token) $(TH semantincs))
    $(TR $(TD $(LPAREN)) $(TD open up a subexpression, that might be aligned together))
    $(TR $(TD m) $(TD show the progress message))
    $(TR $(TD p) $(TD show percentage as number))
    $(TR $(TD P) $(TD show a percentage bar))
    $(TR $(TD r) $(TD show estimated rest duration))
    $(TR $(TD s) $(TD show a spinner))
    $(TR $(TD S) $(TD show speed))
    $(TR $(TD t) $(TD show used time))
    $(TR $(TD T) $(TD show estimated total duration))
  )
+/
auto textUi(Progressbar pb, string format)
{
    import progressbar.parser;

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

/++
 + Factory function for a progressbars on multiple lines.
 +/
auto multiTextUi(Progressbar[] progressbars, string[] formats)
{
    if (progressbars.length != formats.length)
    {
        throw new Exception("progressbars and formats must have same size");
    }

    import std.range;
    import std.algorithm;

    auto res = appender!(TextProgressbarUI[]);
    return new MultiProgressbarTextUI(zip(progressbars, formats)
            .map!(pair => textUi(pair[0], pair[1])).array);
}

/++
 + Render a progressbar while iterating a range.
 +/
auto withTextUi(Range)(Range range, string format)
{
    import std.stdio;

    struct Wrapper(Range)
    {
        Range range;
        Progressbar pb;
        TextProgressbarUI ui;
        this(Range range, string format)
        {
            this.range = range;
            this.pb = new Progressbar(range.length, 0);
            this.ui = textUi(this.pb, format);
        }

        @property empty() const
        {
            return range.empty;
        }

        auto front()
        {
            return range.front();
        }

        void popFront()
        {
            range.popFront;
            pb.step(1);
            (ui.toString ~ "\r").write;
            stdout.flush;
        }
    }

    return Wrapper!Range(range, format);
}
